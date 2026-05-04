```python
import argparse
import os
import shutil
import subprocess
import threading
import time
import uuid
from pathlib import Path
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import asyncio
import base64
import hashlib
import json

import websockets


CREATE_NO_WINDOW = 0x08000000 if os.name == "nt" else 0


def get_subprocess_startupinfo():
    if os.name != "nt":
        return None

    startupinfo = subprocess.STARTUPINFO()
    startupinfo.dwFlags |= subprocess.STARTF_USESHOWWINDOW
    startupinfo.wShowWindow = 0
    return startupinfo


def get_srs_channel_key(options: dict) -> str:
    freqs = str(options.get("freqs") or "250.0")
    modulations = str(options.get("modulations") or "AM")
    coalition = str(options.get("coalition") or "2")
    port = str(options.get("port") or "5002")

    return f"freqs={freqs}|modulations={modulations}|coalition={coalition}|port={port}"


def get_srs_channel_lock(options: dict) -> threading.Lock:
    channel_key = get_srs_channel_key(options)

    with srs_channel_locks_lock:
        lock = srs_channel_locks.get(channel_key)

        if lock is None:
            lock = threading.Lock()
            srs_channel_locks[channel_key] = lock

        return lock


def parse_args():
    parser = argparse.ArgumentParser(description="NASGroupMissionScripts TTS HTTP service.")

    parser.add_argument(
        "--host",
        default=os.getenv("TTS_SERVICE_HOST", "127.0.0.1"),
        help="HTTP bind host.",
    )

    parser.add_argument(
        "--port",
        type=int,
        default=int(os.getenv("TTS_SERVICE_PORT", "8765")),
        help="HTTP bind port.",
    )

    parser.add_argument(
        "--instance",
        default=os.getenv("TTS_SERVICE_INSTANCE", None),
        help="Instance name used for logs/cache/temp files. Defaults to port-based name.",
    )

    parser.add_argument(
        "--output-dir",
        default=os.getenv(
            "TTS_SERVICE_OUTPUT_DIR",
            r"C:\NASGroup\NASGroupMissionScripts\Common\TTS Test",
        ),
        help="Directory for temporary generated audio files.",
    )

    parser.add_argument(
        "--cache-dir",
        default=os.getenv("TTS_SERVICE_CACHE_DIR", None),
        help="Directory for persistent TTS cache. Defaults to output-dir/tts_cache/<instance>.",
    )

    parser.add_argument(
        "--upstream-uri",
        default=os.getenv("TTS_UPSTREAM_URI", "ws://96.32.24.78:8080"),
        help="Upstream websocket TTS URI.",
    )

    parser.add_argument(
        "--srs-exe",
        default=os.getenv(
            "SRS_EXTERNAL_AUDIO_EXE",
            r"C:\DCS-SimpleRadioStandalone\ExternalAudio\DCS-SR-ExternalAudio.exe",
        ),
        help="Path to DCS-SR-ExternalAudio.exe.",
    )

    return parser.parse_args()


ARGS = parse_args()
INSTANCE_NAME = ARGS.instance or f"tts_{ARGS.port}"

URI = ARGS.upstream_uri

OUTPUT_DIR = Path(ARGS.output_dir)
INSTANCE_OUTPUT_DIR = OUTPUT_DIR / "tmp" / INSTANCE_NAME

if ARGS.cache_dir:
    CACHE_DIR = Path(ARGS.cache_dir)
else:
    CACHE_DIR = OUTPUT_DIR / "tts_cache" / INSTANCE_NAME

CACHE_INDEX_FILE = CACHE_DIR / "cache_index.json"

SRS_EXTERNAL_AUDIO_EXE = Path(ARGS.srs_exe)

SUPPRESS_UNCHANGED_TEXT = True
CACHE_TTS_AUDIO = True

SRS_NO_OUTPUT_TIMEOUT_SECONDS = 30
SRS_HARD_TIMEOUT_SECONDS = 600
SRS_MAX_ATTEMPTS = 2
SRS_FINISH_GRACE_SECONDS = 5.0
SRS_COOLDOWN_SECONDS = 2.0

# SRS_TIMEOUT_SECONDS = 45

TTS_CONNECT_TIMEOUT_SECONDS = 10
TTS_RESPONSE_TIMEOUT_SECONDS = 60
TTS_MAX_RESPONSE_TIMEOUT_SECONDS = 240
TTS_TIMEOUT_SECONDS_PER_CHARACTER = 0.08
TTS_MAX_RESPONSE_BYTES = 16 * 1024 * 1024

jobs = {}
jobs_lock = threading.Lock()

srs_channel_locks = {}
srs_channel_locks_lock = threading.Lock()
srs_lock = threading.Lock()

initiator_cache = {}
cache_lock = threading.Lock()


def normalize_tts_text(text: str) -> str:
    return " ".join((text or "").split()).strip()


def safe_filename(value: str) -> str:
    value = str(value or "unknown")
    safe = []

    for char in value:
        if char.isalnum() or char in ("-", "_", "."):
            safe.append(char)
        else:
            safe.append("_")

    return "".join(safe).strip("_") or "unknown"


def get_text_hash(text: str, options: dict) -> str:
    cache_payload = {
        "text": normalize_tts_text(text),
        "voice": options.get("voice"),
        "rate": options.get("rate"),
        "pitch": options.get("pitch"),
        "gender": options.get("gender"),
    }

    encoded = json.dumps(cache_payload, sort_keys=True).encode("utf-8")
    return hashlib.sha256(encoded).hexdigest()


def get_initiator(payload: dict, options: dict) -> str:
    initiator = (
        payload.get("initiator")
        or payload.get("label")
        or options.get("initiator")
        or options.get("label")
    )

    freqs = str(options.get("freqs") or "250.0")
    modulations = str(options.get("modulations") or "AM")
    coalition = str(options.get("coalition") or "2")

    if initiator:
        # Include radio routing so two different ATIS/radio sources do not accidentally share.
        return f"{initiator}|freqs={freqs}|modulations={modulations}|coalition={coalition}"

    return f"freqs={freqs}|modulations={modulations}|coalition={coalition}"


def load_cache_index():
    global initiator_cache

    CACHE_DIR.mkdir(parents=True, exist_ok=True)

    if not CACHE_INDEX_FILE.exists():
        initiator_cache = {}
        return

    try:
        data = json.loads(CACHE_INDEX_FILE.read_text(encoding="utf-8"))

        if isinstance(data, dict):
            initiator_cache = data
        else:
            initiator_cache = {}

    except Exception as exc:
        print(f"Failed to load TTS cache index {CACHE_INDEX_FILE}: {exc}", flush=True)
        initiator_cache = {}


def save_cache_index():
    CACHE_DIR.mkdir(parents=True, exist_ok=True)

    temp_file = CACHE_INDEX_FILE.with_suffix(".json.tmp")
    temp_file.write_text(
        json.dumps(initiator_cache, indent=2, sort_keys=True),
        encoding="utf-8",
    )
    temp_file.replace(CACHE_INDEX_FILE)


def get_cached_file_for_initiator(initiator: str, text_hash: str) -> Path | None:
    with cache_lock:
        entry = initiator_cache.get(initiator)

        if not entry:
            return None

        if entry.get("text_hash") != text_hash:
            return None

        file_path = Path(entry.get("file_path", ""))

        if not file_path.exists() or file_path.stat().st_size <= 0:
            return None

        return file_path


def replace_cached_file_for_initiator(initiator: str, text_hash: str, generated_file: Path) -> Path:
    CACHE_DIR.mkdir(parents=True, exist_ok=True)

    safe_initiator = safe_filename(initiator)
    cache_file = CACHE_DIR / f"{safe_initiator}{generated_file.suffix}"

    with cache_lock:
        old_entry = initiator_cache.get(initiator)

        if old_entry:
            old_file = Path(old_entry.get("file_path", ""))

            if old_file.exists() and old_file != cache_file:
                try:
                    old_file.unlink(missing_ok=True)
                except Exception as exc:
                    print(f"Failed to delete old cached TTS file {old_file}: {exc}", flush=True)

        if cache_file.exists():
            try:
                cache_file.unlink(missing_ok=True)
            except Exception as exc:
                print(f"Failed to replace cached TTS file {cache_file}: {exc}", flush=True)

        shutil.copy2(generated_file, cache_file)

        initiator_cache[initiator] = {
            "initiator": initiator,
            "text_hash": text_hash,
            "file_path": str(cache_file),
            "updated_at": time.time(),
        }

        save_cache_index()

    return cache_file


def copy_cached_audio_to_job_file(cached_file: Path, job_id: str) -> Path:
    INSTANCE_OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    output_file = INSTANCE_OUTPUT_DIR / f"{INSTANCE_NAME}_{job_id}{cached_file.suffix}"
    shutil.copy2(cached_file, output_file)

    return output_file




def get_tts_response_timeout_seconds(text: str) -> int:
    text_length = len(text or "")

    estimated_timeout = int(
        TTS_RESPONSE_TIMEOUT_SECONDS + (text_length * TTS_TIMEOUT_SECONDS_PER_CHARACTER)
    )

    return min(estimated_timeout, TTS_MAX_RESPONSE_TIMEOUT_SECONDS)


def srs_output_indicates_audio_sent(output: str) -> bool:
    output = output or ""

    success_markers = [
        "Finished Sending Audio",
    ]

    return any(marker in output for marker in success_markers)


def srs_output_indicates_disconnect_problem(output: str) -> bool:
    output_lower = (output or "").lower()

    disconnect_markers = [
        "disconnect",
        "disconnecting",
        "connection reset",
        "forcibly closed",
        "udp voice handler thread stop",
        "closing",
    ]

    return any(marker in output_lower for marker in disconnect_markers)


async def generate_tts(text: str, job_id: str, options: dict) -> Path:
    INSTANCE_OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    request_payload = {
        "text": text,
    }

    if options.get("voice") is not None:
        request_payload["voice"] = options["voice"]

    if options.get("rate") is not None:
        request_payload["rate"] = options["rate"]

    if options.get("pitch") is not None:
        request_payload["pitch"] = options["pitch"]

    response_timeout_seconds = get_tts_response_timeout_seconds(text)

    print(f"[{job_id}] Connecting to upstream TTS websocket: {URI}", flush=True)
    print(
        f"[{job_id}] TTS text length={len(text or '')}, response timeout={response_timeout_seconds}s",
        flush=True,
    )

    try:
        websocket = await asyncio.wait_for(
            websockets.connect(
                URI,
                max_size=TTS_MAX_RESPONSE_BYTES,
            ),
            timeout=TTS_CONNECT_TIMEOUT_SECONDS,
        )
    except Exception as exc:
        raise RuntimeError(f"Failed to connect to upstream TTS websocket {URI}: {exc}") from exc

    try:
        async with websocket:
            message_to_send = json.dumps(request_payload)
            print(f"[{job_id}] Sending TTS request to upstream websocket: {message_to_send}", flush=True)

            await websocket.send(message_to_send)

            print(f"[{job_id}] Waiting for upstream TTS response...", flush=True)

            try:
                message = await asyncio.wait_for(
                    websocket.recv(),
                    timeout=response_timeout_seconds,
                )
            except asyncio.TimeoutError as exc:
                raise RuntimeError(
                    f"Timed out after {response_timeout_seconds} seconds waiting for upstream TTS response."
                ) from exc

    except Exception:
        raise

    print(f"[{job_id}] Received upstream TTS response length: {len(message)}", flush=True)

    try:
        data = json.loads(message)
    except Exception as exc:
        raise RuntimeError(f"Upstream TTS response was not valid JSON: {message[:500]!r}") from exc

    if not data.get("success"):
        raise RuntimeError(data.get("error", "unknown server error"))

    if "audio" not in data:
        raise RuntimeError(f"Upstream TTS response did not include audio. Response keys: {list(data.keys())}")

    audio = base64.b64decode(data["audio"])
    ext = data.get("format", "mp3")

    output_file = INSTANCE_OUTPUT_DIR / f"{INSTANCE_NAME}_{job_id}.{ext}"
    output_file.write_bytes(audio)

    print(f"[{INSTANCE_NAME}][{job_id}] Wrote TTS audio file: {output_file} ({len(audio)} bytes)", flush=True)

    if not output_file.exists() or output_file.stat().st_size == 0:
        raise RuntimeError(f"TTS audio file was not written correctly: {output_file}")

    return output_file


def play_srs(output_file: Path, options: dict):
    freqs = str(options.get("freqs") or "250.0")
    modulations = str(options.get("modulations") or "AM")
    coalition = str(options.get("coalition") or "2")
    port = str(options.get("port") or "5002")
    gender = options.get("gender")
    volume = options.get("volume")

    command = [
        str(SRS_EXTERNAL_AUDIO_EXE),
        "--minimized",
        f"--file={str(output_file)}",
        f"--freqs={freqs}",
        f"--modulations={modulations}",
        f"--coalition={coalition}",
        f"--port={port}",
    ]

    if gender:
        command.append(f"-g={gender}")

    if volume:
        command.append(f"--volume={volume}")

    last_error = None

    channel_key = get_srs_channel_key(options)
    channel_lock = get_srs_channel_lock(options)

    # Serialize only messages for the same SRS radio channel.
    # Different frequencies/modulations/coalitions can play concurrently.
    with channel_lock:
        for attempt in range(1, SRS_MAX_ATTEMPTS + 1):
            print(
                f"[{INSTANCE_NAME}] Starting SRS ExternalAudio attempt "
                f"{attempt}/{SRS_MAX_ATTEMPTS} on {channel_key}: {' '.join(command)}",
                flush=True,
            )

            process = None
            output_lines = []
            audio_sent = False
            start_time = time.time()
            last_output_time = start_time

            try:
                process = subprocess.Popen(
                    command,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT,
                    text=True,
                    bufsize=1,
                    creationflags=CREATE_NO_WINDOW,
                    startupinfo=get_subprocess_startupinfo(),
                )

                while True:
                    if process.stdout:
                        line = process.stdout.readline()
                    else:
                        line = ""

                    if line:
                        last_output_time = time.time()
                        print(line, end="")
                        output_lines.append(line)

                        if srs_output_indicates_audio_sent(line):
                            audio_sent = True
                            print("SRS ExternalAudio reported Finished Sending Audio; treating job as successful.")

                            try:
                                process.wait(timeout=SRS_FINISH_GRACE_SECONDS)
                            except subprocess.TimeoutExpired:
                                print(
                                    "SRS ExternalAudio did not exit during cleanup grace period; "
                                    "terminating child process after audio completed."
                                )
                                process.terminate()

                                try:
                                    process.wait(timeout=2)
                                except subprocess.TimeoutExpired:
                                    print("SRS ExternalAudio did not terminate; killing child process.")
                                    process.kill()
                                    process.wait(timeout=2)

                            time.sleep(SRS_COOLDOWN_SECONDS)

                            return {
                                "success": True,
                                "returncode": process.returncode,
                                "attempts": attempt,
                                "warning": "ExternalAudio was stopped after Finished Sending Audio to avoid disconnect crash.",
                            }

                    returncode = process.poll()
                    if returncode is not None:
                        remaining_output = ""

                        if process.stdout:
                            remaining_output = process.stdout.read() or ""

                        if remaining_output:
                            print(remaining_output, end="")
                            output_lines.append(remaining_output)

                        combined_output = "".join(output_lines)

                        if returncode == 0:
                            return {
                                "success": True,
                                "returncode": returncode,
                                "attempts": attempt,
                                "warning": None,
                            }

                        if audio_sent or srs_output_indicates_audio_sent(combined_output):
                            warning = (
                                "SRS ExternalAudio exited non-zero after audio appears to have been sent. "
                                "Treating as success."
                            )
                            print(warning)
                            return {
                                "success": True,
                                "returncode": returncode,
                                "attempts": attempt,
                                "warning": warning,
                            }

                        last_error = (
                            f"SRS ExternalAudio failed before audio was sent. "
                            f"Exit code={returncode}. Output={combined_output!r}"
                        )
                        break

                    # if time.time() - start_time > SRS_TIMEOUT_SECONDS:
                    #     combined_output = "".join(output_lines)
                    #
                    #     if audio_sent or srs_output_indicates_audio_sent(combined_output):
                    #         warning = (
                    #             f"SRS ExternalAudio timed out after {SRS_TIMEOUT_SECONDS} seconds, "
                    #             "but audio appears to have been sent. Treating as success."
                    #         )
                    #         print(warning)
                    #
                    #         if process.poll() is None:
                    #             process.terminate()
                    #             try:
                    #                 process.wait(timeout=2)
                    #             except subprocess.TimeoutExpired:
                    #                 process.kill()
                    #                 process.wait(timeout=2)
                    #
                    #         return {
                    #             "success": True,
                    #             "returncode": process.returncode,
                    #             "attempts": attempt,
                    #             "warning": warning,
                    #         }
                    #
                    #     last_error = f"SRS ExternalAudio timed out after {SRS_TIMEOUT_SECONDS} seconds before audio was sent."
                    #
                    #     if process.poll() is None:
                    #         process.terminate()
                    #         try:
                    #             process.wait(timeout=2)
                    #         except subprocess.TimeoutExpired:
                    #             process.kill()
                    #             process.wait(timeout=2)
                    #
                    #     break

                    now = time.time()

                    if now - last_output_time > SRS_NO_OUTPUT_TIMEOUT_SECONDS:
                        combined_output = "".join(output_lines)

                        if audio_sent or srs_output_indicates_audio_sent(combined_output):
                            warning = (
                                f"SRS ExternalAudio had no output for {SRS_NO_OUTPUT_TIMEOUT_SECONDS} seconds, "
                                "but audio appears to have been sent. Treating as success."
                            )
                            print(warning)

                            if process.poll() is None:
                                process.terminate()
                                try:
                                    process.wait(timeout=2)
                                except subprocess.TimeoutExpired:
                                    process.kill()
                                    process.wait(timeout=2)

                            return {
                                "success": True,
                                "returncode": process.returncode,
                                "attempts": attempt,
                                "warning": warning,
                            }

                        last_error = (
                            f"SRS ExternalAudio produced no output for "
                            f"{SRS_NO_OUTPUT_TIMEOUT_SECONDS} seconds before audio completed."
                        )

                        if process.poll() is None:
                            process.terminate()
                            try:
                                process.wait(timeout=2)
                            except subprocess.TimeoutExpired:
                                process.kill()
                                process.wait(timeout=2)

                        break

                    if now - start_time > SRS_HARD_TIMEOUT_SECONDS:
                        combined_output = "".join(output_lines)

                        if audio_sent or srs_output_indicates_audio_sent(combined_output):
                            warning = (
                                f"SRS ExternalAudio hit hard timeout after {SRS_HARD_TIMEOUT_SECONDS} seconds, "
                                "but audio appears to have been sent. Treating as success."
                            )
                            print(warning)

                            if process.poll() is None:
                                process.terminate()
                                try:
                                    process.wait(timeout=2)
                                except subprocess.TimeoutExpired:
                                    process.kill()
                                    process.wait(timeout=2)

                            return {
                                "success": True,
                                "returncode": process.returncode,
                                "attempts": attempt,
                                "warning": warning,
                            }

                        last_error = (
                            f"SRS ExternalAudio exceeded hard timeout of "
                            f"{SRS_HARD_TIMEOUT_SECONDS} seconds before audio completed."
                        )

                        if process.poll() is None:
                            process.terminate()
                            try:
                                process.wait(timeout=2)
                            except subprocess.TimeoutExpired:
                                process.kill()
                                process.wait(timeout=2)

                        break

                    time.sleep(0.05)

            except Exception as exc:
                last_error = f"SRS ExternalAudio crashed/failed: {exc}"

                if process and process.poll() is None:
                    try:
                        process.terminate()
                        process.wait(timeout=2)
                    except Exception:
                        try:
                            process.kill()
                        except Exception:
                            pass

            print(last_error)

            if attempt < SRS_MAX_ATTEMPTS:
                time.sleep(1)

    raise RuntimeError(last_error or "SRS ExternalAudio failed for an unknown reason.")


def set_job(job_id: str, updates: dict):
    with jobs_lock:
        job = jobs.get(job_id, {})
        job.update(updates)
        jobs[job_id] = job


def process_job(job_id: str, text: str, options: dict, initiator: str, text_hash: str):
    output_file = None
    cache_hit = False
    cache_file = None

    try:
        print(
            f"[{job_id}] Job started: initiator={initiator!r}, text_hash={text_hash}",
            flush=True,
        )

        set_job(job_id, {
            "status": "running",
            "initiator": initiator,
            "text_hash": text_hash,
            "started_at": time.time(),
        })

        cached_file = get_cached_file_for_initiator(initiator, text_hash)

        if cached_file:
            cache_hit = True
            cache_file = cached_file

            print(
                f"[{job_id}] Text unchanged for initiator={initiator!r}. "
                f"Replaying cached MP3: {cached_file}",
                flush=True,
            )

            output_file = copy_cached_audio_to_job_file(cached_file, job_id)

        else:
            cache_hit = False

            print(
                f"[{job_id}] Text changed or no cache exists for initiator={initiator!r}. "
                "Generating new TTS MP3 from websocket.",
                flush=True,
            )

            generated_file = asyncio.run(generate_tts(text, job_id, options))
            cache_file = replace_cached_file_for_initiator(initiator, text_hash, generated_file)

            # Use the generated file for this immediate playback.
            output_file = generated_file

            print(
                f"[{job_id}] Updated cache for initiator={initiator!r}: {cache_file}",
                flush=True,
            )

        print(f"[{job_id}] Starting SRS playback for: {output_file}", flush=True)

        srs_result = play_srs(output_file, options)

        filename = output_file.name
        folder = str(output_file.parent) + "\\"
        path = str(output_file)

        # Delete only the temporary per-job file.
        # Do not delete the cached initiator file.
        try:
            if output_file and output_file.exists() and output_file != cache_file:
                output_file.unlink(missing_ok=True)
            deleted = True
        except Exception as delete_exc:
            deleted = False
            print(f"[{job_id}] Failed to delete temporary TTS file {output_file}: {delete_exc}", flush=True)

        set_job(job_id, {
            "status": "done",
            "success": True,
            "filename": filename,
            "folder": folder,
            "path": path,
            "deleted": deleted,
            "cache_hit": cache_hit,
            "cache_file": str(cache_file) if cache_file else None,
            "initiator": initiator,
            "text_hash": text_hash,
            "srs": srs_result,
            "completed_at": time.time(),
        })

        print(
            f"[{job_id}] Job completed successfully. "
            f"initiator={initiator!r}, cache_hit={cache_hit}",
            flush=True,
        )

    except Exception as exc:
        print(f"[{job_id}] Job failed: {exc}", flush=True)

        if output_file:
            try:
                if output_file.exists() and output_file != cache_file:
                    output_file.unlink(missing_ok=True)
            except Exception as delete_exc:
                print(
                    f"[{job_id}] Failed to delete temporary TTS file after error {output_file}: {delete_exc}",
                    flush=True,
                )

        set_job(job_id, {
            "status": "error",
            "success": False,
            "error": str(exc),
            "initiator": initiator,
            "text_hash": text_hash,
            "completed_at": time.time(),
        })


class TTSHandler(BaseHTTPRequestHandler):
    def send_json(self, status_code: int, payload: dict):
        response_body = json.dumps(payload).encode("utf-8")

        self.send_response(status_code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(response_body)))
        self.end_headers()
        self.wfile.write(response_body)

    def do_POST(self):
        if self.path != "/tts":
            self.send_json(404, {
                "success": False,
                "error": "Not found",
            })
            return

        content_length = int(self.headers.get("Content-Length", "0"))
        body = self.rfile.read(content_length).decode("utf-8")

        try:
            payload = json.loads(body)
            text = payload.get("text", "")

            if not text:
                raise ValueError("Missing text")

            options = {
                # Per-initiator repeat cache
                "initiator": payload.get("initiator"),
                "label": payload.get("label"),

                # Upstream TTS server options
                "voice": payload.get("voice"),
                "rate": payload.get("rate"),
                "pitch": payload.get("pitch"),

                # SRS ExternalAudio options
                "freqs": payload.get("freqs", "250.0"),
                "modulations": payload.get("modulations", "AM"),
                "coalition": payload.get("coalition", 2),
                "port": payload.get("port", 5002),
                "gender": payload.get("gender"),
                "volume": payload.get("volume"),
            }

            initiator = get_initiator(payload, options)
            text_hash = get_text_hash(text, options)
            job_id = uuid.uuid4().hex

            print(
                f"[{job_id}] Received TTS request: initiator={initiator!r}, "
                f"text_hash={text_hash}, text_length={len(text)}",
                flush=True,
            )

            with jobs_lock:
                jobs[job_id] = {
                    "status": "queued",
                    "success": None,
                    "text": text,
                    "initiator": initiator,
                    "text_hash": text_hash,
                    "options": options,
                    "created_at": time.time(),
                }

            thread = threading.Thread(
                target=process_job,
                args=(job_id, text, options, initiator, text_hash),
                daemon=True,
            )
            thread.start()

            self.send_json(202, {
                "success": True,
                "status": "queued",
                "job_id": job_id,
                "initiator": initiator,
                "text_hash": text_hash,
            })

        except Exception as exc:
            self.send_json(500, {
                "success": False,
                "error": str(exc),
            })

    def do_GET(self):
        if not self.path.startswith("/tts/"):
            self.send_json(404, {
                "success": False,
                "error": "Not found",
            })
            return

        job_id = self.path.replace("/tts/", "", 1).strip()

        with jobs_lock:
            job = jobs.get(job_id)

        if not job:
            self.send_json(404, {
                "success": False,
                "error": "Unknown job_id",
                "job_id": job_id,
            })
            return

        response = {
            "success": job.get("success"),
            "job_id": job_id,
            "status": job.get("status"),
            "initiator": job.get("initiator"),
            "text_hash": job.get("text_hash"),
        }

        if job.get("status") == "skipped":
            response.update({
                "success": True,
                "skipped": True,
                "reason": job.get("reason"),
            })

        if job.get("status") == "done":
            response.update({
                "success": True,
                "filename": job.get("filename"),
                "folder": job.get("folder"),
                "path": job.get("path"),
                "deleted": job.get("deleted"),
                "cache_hit": job.get("cache_hit"),
                "cache_file": job.get("cache_file"),
                "srs": job.get("srs"),
            })

        if job.get("status") == "error":
            response.update({
                "success": False,
                "error": job.get("error"),
            })

        self.send_json(200, response)


if __name__ == "__main__":
    load_cache_index()

    while True:
        try:
            server = ThreadingHTTPServer((ARGS.host, ARGS.port), TTSHandler)
            server.daemon_threads = True

            print(f"TTS service instance: {INSTANCE_NAME}")
            print(f"TTS service running at http://{ARGS.host}:{ARGS.port}")
            print(f"POST job:   http://{ARGS.host}:{ARGS.port}/tts")
            print(f"GET status: http://{ARGS.host}:{ARGS.port}/tts/<job_id>")
            print(f"TTS output: {INSTANCE_OUTPUT_DIR}")
            print(f"TTS cache:  {CACHE_DIR}")
            print(f"TTS upstream websocket: {URI}")
            print(f"SRS ExternalAudio: {SRS_EXTERNAL_AUDIO_EXE}")

            server.serve_forever()

        except KeyboardInterrupt:
            print(f"TTS service stopped by user: {INSTANCE_NAME}")
            break

        except Exception as exc:
            print(f"TTS service crashed: {INSTANCE_NAME}: {exc}")