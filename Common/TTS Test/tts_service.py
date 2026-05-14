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
import traceback
import websockets

CREATE_NO_WINDOW = subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0



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
        "--srs-host",
        default=os.getenv("SRS_HOST", "127.0.0.1"),
        help="SRS server host for native Python SRS playback.",
    )

    parser.add_argument(
        "--srs-backend",
        choices=("native", "external_audio", "go_native"),
        default=os.getenv("TTS_SERVICE_SRS_BACKEND", "native"),
        help=(
            "SRS playback backend. "
            "Use native for the experimental Python UDP sender, "
            "external_audio for DCS-SR-ExternalAudio.exe, "
            "or go_native for the SkyEye-based SRS sender."
        ),
    )

    parser.add_argument(
        "--srs-go-sender",
        default=os.getenv(
            "SRS_GO_SENDER_EXE",
            str(Path(__file__).resolve().parent / "srs-tts-send.exe"),
        ),
        help="Path to the SkyEye-based native SRS sender executable.",
    )

    parser.add_argument(
        "--external-awacs-password",
        default=os.getenv("SRS_EXTERNAL_AWACS_PASSWORD", ""),
        help="External AWACS mode password for SRS native Go sender.",
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
        "--inbox-dir",
        default=os.getenv("TTS_SERVICE_INBOX_DIR", None),
        help="Directory watched for JSON TTS request files. Defaults to output-dir/tts_inbox/<instance>.",
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

if ARGS.inbox_dir:
    INBOX_DIR = Path(ARGS.inbox_dir)
else:
    INBOX_DIR = OUTPUT_DIR / "tts_inbox" / INSTANCE_NAME

CACHE_INDEX_FILE = CACHE_DIR / "cache_index.json"

SRS_EXTERNAL_AUDIO_EXE = Path(ARGS.srs_exe)
SRS_GO_SENDER_EXE = Path(ARGS.srs_go_sender)
SRS_HOST = ARGS.srs_host
SRS_BACKEND = ARGS.srs_backend
SRS_EXTERNAL_AWACS_PASSWORD = ARGS.external_awacs_password

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

TTS_INBOX_POLL_SECONDS = 0.25
TTS_INBOX_DONE_RETENTION_SECONDS = 30
TTS_INBOX_ERROR_RETENTION_SECONDS = 300

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


def play_srs_external_audio(output_file: Path, options: dict):
    freqs = str(options.get("freqs") or "250.0")
    modulations = str(options.get("modulations") or "AM")
    coalition = str(options.get("coalition") or "2")
    port = str(options.get("port") or "5002")
    gender = options.get("gender")
    volume = options.get("volume")

    command = [
        str(SRS_EXTERNAL_AUDIO_EXE),
        f"--file={str(output_file)}",
        f"--freqs={freqs}",
        # f"--modulations={modulations}",
        f"--coalition={coalition}",
        f"--port={port}",
    ]

    if gender:
        command.append(f"-g={gender}")

    if volume:
        command.append(f"--volume={volume}")

    print(
        f"[{INSTANCE_NAME}] Starting SRS ExternalAudio fallback: {' '.join(command)}",
        flush=True,
    )

    process = subprocess.run(
        command,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        creationflags=CREATE_NO_WINDOW,
        startupinfo=get_subprocess_startupinfo(),
        timeout=SRS_HARD_TIMEOUT_SECONDS,
    )

    if process.stdout:
        print(process.stdout, flush=True)

    if process.returncode != 0:
        raise RuntimeError(
            f"SRS ExternalAudio failed with exit code {process.returncode}: {process.stdout}"
        )

    return {
        "success": True,
        "backend": "external_audio",
        "returncode": process.returncode,
    }

def convert_audio_to_skyeye_pcm_f32le(audio_file: Path) -> Path:
    import av

    audio_file = Path(audio_file)
    pcm_file = audio_file.with_suffix(audio_file.suffix + ".16k_mono_f32le.pcm")

    resampler = av.audio.resampler.AudioResampler(
        format="flt",
        layout="mono",
        rate=16000,
    )

    with av.open(str(audio_file)) as container:
        stream = next((s for s in container.streams if s.type == "audio"), None)

        if stream is None:
            raise RuntimeError(f"No audio stream found in {audio_file}")

        with pcm_file.open("wb") as out:
            for packet in container.demux(stream):
                for frame in packet.decode():
                    resampled = resampler.resample(frame)

                    if not isinstance(resampled, list):
                        resampled = [resampled]

                    for out_frame in resampled:
                        for plane in out_frame.planes:
                            out.write(bytes(plane))

    if not pcm_file.exists() or pcm_file.stat().st_size == 0:
        raise RuntimeError(f"Failed to convert audio to SkyEye PCM: {pcm_file}")

    return pcm_file

def play_srs_go_native(output_file: Path, options: dict):
    freqs = str(options.get("freqs") or "250.0")
    modulations = str(options.get("modulations") or "AM")
    coalition = str(options.get("coalition") or "2")
    port = str(options.get("port") or "5002")
    volume = str(options.get("volume") or "1.0")
    password = str(
        options.get("external_awacs_mode_password")
        or SRS_EXTERNAL_AWACS_PASSWORD
        or ""
    )

    pcm_file = convert_audio_to_skyeye_pcm_f32le(output_file)

    command = [
        str(SRS_GO_SENDER_EXE),
        f"--srs-address={SRS_HOST}:{port}",
        "--client-name=NASGroup TTS",
        f"--coalition={coalition}",
        f"--frequency={freqs}",
        f"--modulation={modulations}",
        f"--volume={volume}",
        f"--external-awacs-password={password}",
        f"--file={str(pcm_file)}",
    ]

    print(
        f"[{INSTANCE_NAME}] Starting Go native SRS sender: "
        f"exe={SRS_GO_SENDER_EXE}, file={output_file}, pcm={pcm_file}, "
        f"host={SRS_HOST}, port={port}, freqs={freqs}, "
        f"modulations={modulations}, coalition={coalition}",
        flush=True,
    )

    try:
        process = subprocess.run(
            command,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            creationflags=CREATE_NO_WINDOW,
            startupinfo=get_subprocess_startupinfo(),
            timeout=SRS_HARD_TIMEOUT_SECONDS,
        )

        if process.stdout:
            print(process.stdout, flush=True)

        if process.returncode != 0:
            raise RuntimeError(
                f"Go native SRS sender failed with exit code {process.returncode}: {process.stdout}"
            )

        return {
            "success": True,
            "backend": "go_native",
            "sender": str(SRS_GO_SENDER_EXE),
            "returncode": process.returncode,
        }

    finally:
        try:
            pcm_file.unlink(missing_ok=True)
        except Exception as exc:
            print(f"Failed to delete temporary SkyEye PCM file {pcm_file}: {exc}", flush=True)


def play_srs_native(output_file: Path, options: dict):
    from srs_native import transmit_file_to_srs

    native_options = dict(options)
    native_options["srs_host"] = native_options.get("srs_host") or SRS_HOST

    print(
        f"[{INSTANCE_NAME}] Starting native Python SRS playback: "
        f"file={output_file}, host={native_options.get('srs_host')}, "
        f"port={native_options.get('port')}, freqs={native_options.get('freqs')}, "
        f"modulations={native_options.get('modulations')}, "
        f"coalition={native_options.get('coalition')}",
        flush=True,
    )

    return transmit_file_to_srs(output_file, native_options)


def play_srs(output_file: Path, options: dict):
    if SRS_BACKEND == "native":
        return play_srs_native(output_file, options)

    if SRS_BACKEND == "go_native":
        return play_srs_go_native(output_file, options)

    return play_srs_external_audio(output_file, options)

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

def queue_tts_payload(payload: dict) -> dict:
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

        # SRS options
        "srs_host": payload.get("srs_host", SRS_HOST),
        "freqs": payload.get("freqs", "250.0"),
        "modulations": payload.get("modulations", "AM"),
        "coalition": payload.get("coalition", 2),
        "port": payload.get("port", 5002),
        "gender": payload.get("gender"),
        "volume": payload.get("volume"),
        "external_awacs_mode_password": payload.get(
            "external_awacs_mode_password",
            SRS_EXTERNAL_AWACS_PASSWORD,
        ),
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

    return {
        "success": True,
        "status": "queued",
        "job_id": job_id,
        "initiator": initiator,
        "text_hash": text_hash,
    }

def cleanup_inbox_status_files():
    now = time.time()

    cleanup_patterns = [
        ("*.done", TTS_INBOX_DONE_RETENTION_SECONDS),
        ("*.error", TTS_INBOX_ERROR_RETENTION_SECONDS),
    ]

    for pattern, retention_seconds in cleanup_patterns:
        for file_path in INBOX_DIR.glob(pattern):
            try:
                age_seconds = now - file_path.stat().st_mtime

                if age_seconds >= retention_seconds:
                    file_path.unlink(missing_ok=True)

            except Exception as exc:
                print(f"Failed to clean up TTS inbox status file {file_path}: {exc}", flush=True)


def process_inbox_file(file_path: Path):
    processing_file = file_path.with_suffix(file_path.suffix + ".processing")
    done_file = file_path.with_suffix(file_path.suffix + ".done")
    error_file = file_path.with_suffix(file_path.suffix + ".error")

    try:
        file_path.replace(processing_file)

        payload = json.loads(processing_file.read_text(encoding="utf-8-sig"))
        result = queue_tts_payload(payload)

        done_file.write_text(json.dumps(result, indent=2), encoding="utf-8")
        processing_file.unlink(missing_ok=True)

    except Exception as exc:
        error_text = traceback.format_exc()
        print(f"Failed to process TTS inbox file {file_path}: {exc}", flush=True)

        try:
            error_file.write_text(error_text, encoding="utf-8")
        except Exception:
            pass

        try:
            processing_file.unlink(missing_ok=True)
        except Exception:
            pass


def inbox_watcher_loop():
    INBOX_DIR.mkdir(parents=True, exist_ok=True)

    print(f"TTS inbox:   {INBOX_DIR}", flush=True)

    while True:
        try:
            for file_path in sorted(INBOX_DIR.glob("*.json")):
                process_inbox_file(file_path)

            cleanup_inbox_status_files()

        except Exception as exc:
            print(f"TTS inbox watcher error: {exc}", flush=True)

        time.sleep(TTS_INBOX_POLL_SECONDS)



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
            result = queue_tts_payload(payload)
            self.send_json(202, result)

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

    inbox_thread = threading.Thread(
        target=inbox_watcher_loop,
        daemon=True,
    )
    inbox_thread.start()

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
            print(f"TTS inbox:  {INBOX_DIR}")

            server.serve_forever()

        except KeyboardInterrupt:
            print(f"TTS service stopped by user: {INSTANCE_NAME}")
            break

        except Exception as exc:
            print(f"TTS service crashed: {INSTANCE_NAME}: {exc}")