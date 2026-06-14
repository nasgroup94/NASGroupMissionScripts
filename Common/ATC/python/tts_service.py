import argparse
import asyncio
import base64
import hashlib
import json
import os
import shutil
import subprocess
import threading
import time
import traceback
import uuid
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

import websockets

CREATE_NO_WINDOW = subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0


def parse_args() -> argparse.Namespace:
    script_path = Path(__file__).resolve()
    python_dir = script_path.parent
    atc_root = python_dir.parent
    atc_bin_dir = atc_root / "bin"
    atc_tmp_dir = atc_root / "tmp"
    atc_tts_cache_dir = atc_root / "tts_cache"

    parser = argparse.ArgumentParser(description="NASG TTS websocket service")

    parser.add_argument("--host", default=os.getenv("TTS_SERVICE_HOST", "127.0.0.1"))
    parser.add_argument("--port", type=int, default=int(os.getenv("TTS_SERVICE_PORT", "8765")))
    parser.add_argument(
        "--stop-file",
        default=os.getenv("TTS_SERVICE_STOP_FILE", str(atc_tmp_dir / "nasg_tts_service.stop")),
    )
    parser.add_argument(
        "--upstream-uri",
        default=os.getenv("TTS_UPSTREAM_URI", "ws://127.0.0.1:8766"),
    )

    parser.add_argument("--srs-host", default=os.getenv("SRS_HOST", "127.0.0.1"))
    parser.add_argument(
        "--srs-backend",
        choices=("native", "external_audio", "go_native"),
        default=os.getenv("TTS_SERVICE_SRS_BACKEND", "go_native"),
    )
    parser.add_argument(
        "--srs-go-sender",
        default=os.getenv(
            "SRS_GO_SENDER_EXE",
            str(atc_bin_dir / "srs-tts-send.exe"),
        ),
    )
    parser.add_argument(
        "--external-awacs-password",
        default=os.getenv("SRS_EXTERNAL_AWACS_PASSWORD", ""),
    )
    parser.add_argument(
        "--srs-exe",
        default=os.getenv(
            "SRS_EXTERNAL_AUDIO_EXE",
            r"C:\DCS-SimpleRadioStandalone\ExternalAudio\DCS-SR-ExternalAudio.exe",
        ),
    )

    parser.add_argument("--instance", default=os.getenv("TTS_SERVICE_INSTANCE", None))
    parser.add_argument(
        "--output-dir",
        default=os.getenv(
            "TTS_SERVICE_OUTPUT_DIR",
            str(atc_tmp_dir / "tts_output"),
        ),
    )
    parser.add_argument(
        "--cache-dir",
        default=os.getenv(
            "TTS_SERVICE_CACHE_DIR",
            str(atc_tts_cache_dir),
        ),
    )
    parser.add_argument(
        "--inbox-dir",
        default=os.getenv(
            "TTS_SERVICE_INBOX_DIR",
            str(atc_tmp_dir / "tts_inbox" / "main"),
        ),
    )
    parser.add_argument("--verbose", action="store_true")

    return parser.parse_args()


ARGS = parse_args()

INSTANCE_NAME = ARGS.instance or f"tts_{ARGS.port}"
URI = ARGS.upstream_uri

OUTPUT_DIR = Path(ARGS.output_dir)
INSTANCE_OUTPUT_DIR = OUTPUT_DIR / "tmp" / INSTANCE_NAME
CACHE_DIR = Path(ARGS.cache_dir) if ARGS.cache_dir else OUTPUT_DIR / "tts_cache" / INSTANCE_NAME
INBOX_DIR = Path(ARGS.inbox_dir) if ARGS.inbox_dir else OUTPUT_DIR / "tts_inbox" / INSTANCE_NAME

CACHE_INDEX_FILE = CACHE_DIR / "cache_index.json"

SRS_EXTERNAL_AUDIO_EXE = Path(ARGS.srs_exe)
SRS_GO_SENDER_EXE = Path(ARGS.srs_go_sender)
SRS_HOST = ARGS.srs_host
SRS_BACKEND = ARGS.srs_backend
SRS_EXTERNAL_AWACS_PASSWORD = ARGS.external_awacs_password

TTS_CONNECT_TIMEOUT_SECONDS = 10
TTS_RESPONSE_TIMEOUT_SECONDS = 60
TTS_MAX_RESPONSE_TIMEOUT_SECONDS = 240
TTS_TIMEOUT_SECONDS_PER_CHARACTER = 0.08
TTS_MAX_RESPONSE_BYTES = 16 * 1024 * 1024

TTS_INBOX_POLL_SECONDS = 0.10
TTS_INBOX_DONE_RETENTION_SECONDS = 30
TTS_INBOX_ERROR_RETENTION_SECONDS = 300

SRS_HARD_TIMEOUT_SECONDS = 600

jobs = {}
jobs_lock = threading.Lock()

initiator_cache = {}
cache_lock = threading.Lock()


def log_info(message: str):
    print(message, flush=True)


def log_debug(message: str):
    if ARGS.verbose:
        print(message, flush=True)


def log_error(message: str):
    print(message, flush=True)


def get_subprocess_startupinfo():
    if os.name != "nt":
        return None

    startupinfo = subprocess.STARTUPINFO()
    startupinfo.dwFlags |= subprocess.STARTF_USESHOWWINDOW
    startupinfo.wShowWindow = 0
    return startupinfo


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
        return f"{initiator}|freqs={freqs}|modulations={modulations}|coalition={coalition}"

    return f"freqs={freqs}|modulations={modulations}|coalition={coalition}"


def get_tts_response_timeout_seconds(text: str) -> int:
    text_length = len(text or "")
    estimated_timeout = int(
        TTS_RESPONSE_TIMEOUT_SECONDS + (text_length * TTS_TIMEOUT_SECONDS_PER_CHARACTER)
    )
    return min(estimated_timeout, TTS_MAX_RESPONSE_TIMEOUT_SECONDS)


def load_cache_index():
    global initiator_cache

    CACHE_DIR.mkdir(parents=True, exist_ok=True)

    if not CACHE_INDEX_FILE.exists():
        initiator_cache = {}
        return

    try:
        data = json.loads(CACHE_INDEX_FILE.read_text(encoding="utf-8"))
        initiator_cache = data if isinstance(data, dict) else {}
    except Exception as exc:
        log_error(f"Failed to load TTS cache index {CACHE_INDEX_FILE}: {exc}")
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
                    log_error(f"Failed to delete old cached TTS file {old_file}: {exc}")

        if cache_file.exists():
            try:
                cache_file.unlink(missing_ok=True)
            except Exception as exc:
                log_error(f"Failed to replace cached TTS file {cache_file}: {exc}")

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


def set_job(job_id: str, updates: dict):
    with jobs_lock:
        job = jobs.get(job_id, {})
        job.update(updates)
        jobs[job_id] = job


TTS_RUNTIME_CONFIG_FILE = os.environ.get(
    "NASG_TTS_CONFIG_FILE",
    str(Path(__file__).parent / "tmp" / "nasg_tts_config.json"),
)

TTS_RUNTIME_CONFIG = {
    "default_voice": None,
    "default_rate": None,
    "default_pitch": None,
    "default_volume": 1.0,
    "facilities": {},
}

TTS_RUNTIME_CONFIG_MTIME = None


def load_tts_runtime_config_if_changed() -> None:
    global TTS_RUNTIME_CONFIG
    global TTS_RUNTIME_CONFIG_MTIME

    config_path = Path(TTS_RUNTIME_CONFIG_FILE)

    if not config_path.exists():
        return

    try:
        current_mtime = config_path.stat().st_mtime
    except OSError:
        return

    if TTS_RUNTIME_CONFIG_MTIME == current_mtime:
        return

    try:
        data = json.loads(config_path.read_text(encoding="utf-8"))
    except Exception as exc:
        log_debug(f"Failed to load TTS runtime config {config_path}: {exc}")
        return

    if not isinstance(data, dict):
        return

    TTS_RUNTIME_CONFIG.update(data)
    TTS_RUNTIME_CONFIG_MTIME = current_mtime

    log_debug(f"Loaded TTS runtime config: {config_path}")


def resolve_tts_options(options: dict) -> dict:
    load_tts_runtime_config_if_changed()

    options = options or {}

    facility = options.get("facility") or options.get("service") or "ground"
    airport_id = options.get("airport_id")

    facility_key = None

    if airport_id:
        facility_key = f"{airport_id}_{facility}"

    facility_defaults = {}

    facilities = TTS_RUNTIME_CONFIG.get("facilities") or {}

    if facility_key and facility_key in facilities:
        facility_defaults = facilities.get(facility_key) or {}
    elif facility in facilities:
        facility_defaults = facilities.get(facility) or {}

    return {
        "facility": facility,
        "airport_id": airport_id,
        "callsign": options.get("callsign") or facility_defaults.get("callsign"),
        "voice": options.get("voice") or facility_defaults.get("voice") or TTS_RUNTIME_CONFIG.get("default_voice"),
        "rate": options.get("rate") or facility_defaults.get("rate") or TTS_RUNTIME_CONFIG.get("default_rate"),
        "pitch": options.get("pitch") or facility_defaults.get("pitch") or TTS_RUNTIME_CONFIG.get("default_pitch"),
        "volume": options.get("volume") or facility_defaults.get("volume") or TTS_RUNTIME_CONFIG.get("default_volume"),
        "format": options.get("format") or TTS_RUNTIME_CONFIG.get("default_format"),
        "radio_effect": options.get("radio_effect", facility_defaults.get("radio_effect", True)),
    }


async def generate_tts(text: str, job_id: str, options: dict) -> Path:
    INSTANCE_OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    resolved_options = resolve_tts_options(options)

    request_payload = {
        "text": text,
    }

    if resolved_options.get("voice") is not None:
        request_payload["voice"] = resolved_options["voice"]

    if resolved_options.get("rate") is not None:
        request_payload["rate"] = resolved_options["rate"]

    if resolved_options.get("pitch") is not None:
        request_payload["pitch"] = resolved_options["pitch"]

    if resolved_options.get("format") is not None:
        request_payload["format"] = resolved_options["format"]

    response_timeout_seconds = get_tts_response_timeout_seconds(text)

    log_debug(f"[{job_id}] Connecting to upstream TTS websocket: {URI}")
    log_debug(
        f"[{job_id}] facility={resolved_options.get('facility')} "
        f"airport={resolved_options.get('airport_id')} "
        f"callsign={resolved_options.get('callsign')} "
        f"voice={resolved_options.get('voice')} "
        f"rate={resolved_options.get('rate')} "
        f"pitch={resolved_options.get('pitch')} "
        f"text length={len(text or '')}, response timeout={response_timeout_seconds}s"
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

    async with websocket:
        message_to_send = json.dumps(request_payload)

        log_debug(f"[{job_id}] Sending TTS request to upstream websocket: {message_to_send}")
        await websocket.send(message_to_send)

        log_debug(f"[{job_id}] Waiting for upstream TTS response...")

        try:
            message = await asyncio.wait_for(
                websocket.recv(),
                timeout=response_timeout_seconds,
            )
        except asyncio.TimeoutError as exc:
            raise RuntimeError(
                f"Timed out after {response_timeout_seconds} seconds waiting for upstream TTS response."
            ) from exc

    log_debug(f"[{job_id}] Received upstream TTS response length: {len(message)}")

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

    log_debug(f"[{job_id}] Wrote TTS audio file: {output_file} ({len(audio)} bytes)")

    if not output_file.exists() or output_file.stat().st_size == 0:
        raise RuntimeError(f"TTS audio file was not written correctly: {output_file}")

    return output_file


def convert_audio_to_skyeye_pcm_f32le(audio_file: Path) -> Path:
    import av

    audio_file = Path(audio_file)
    pcm_file = audio_file.with_suffix(audio_file.suffix + ".16k_mono_f32le.pcm")

    resampler = av.audio.resampler.AudioResampler(
        format="flt",
        layout="mono",
        rate=16000,
    )

    bytes_per_sample = 4

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
                        expected_bytes = out_frame.samples * bytes_per_sample

                        for plane in out_frame.planes:
                            out.write(bytes(plane)[:expected_bytes])

    if not pcm_file.exists() or pcm_file.stat().st_size == 0:
        raise RuntimeError(f"Failed to convert audio to SkyEye PCM: {pcm_file}")

    return pcm_file


def concatenate_audio_files_to_skyeye_pcm_f32le(audio_files: list[Path], job_id: str) -> Path:
    import av

    INSTANCE_OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    pcm_file = INSTANCE_OUTPUT_DIR / f"{INSTANCE_NAME}_{job_id}_combined.16k_mono_f32le.pcm"

    resampler = av.audio.resampler.AudioResampler(
        format="flt",
        layout="mono",
        rate=16000,
    )

    bytes_per_sample = 4

    with pcm_file.open("wb") as out:
        for audio_file in audio_files:
            audio_file = Path(audio_file)

            if not audio_file.exists():
                raise RuntimeError(f"Audio file not found for combined playback: {audio_file}")

            if not audio_file.is_file():
                raise RuntimeError(f"Audio path is not a file for combined playback: {audio_file}")

            log_debug(f"[{job_id}] Adding audio segment to combined transmission: {audio_file}")

            with av.open(str(audio_file)) as input_container:
                input_stream = next((s for s in input_container.streams if s.type == "audio"), None)

                if input_stream is None:
                    raise RuntimeError(f"No audio stream found in {audio_file}")

                for packet in input_container.demux(input_stream):
                    for frame in packet.decode():
                        resampled = resampler.resample(frame)

                        if not isinstance(resampled, list):
                            resampled = [resampled]

                        for out_frame in resampled:
                            expected_bytes = out_frame.samples * bytes_per_sample

                            for plane in out_frame.planes:
                                out.write(bytes(plane)[:expected_bytes])

    if not pcm_file.exists() or pcm_file.stat().st_size == 0:
        raise RuntimeError(f"Combined PCM file was not created correctly: {pcm_file}")

    return pcm_file


def get_srs_command_common(options: dict) -> dict:
    return {
        "freqs": str(options.get("freqs") or "250.0"),
        "modulations": str(options.get("modulations") or "AM"),
        "coalition": str(options.get("coalition") or "2"),
        "port": str(options.get("port") or "5002"),
        "volume": str(options.get("volume") or "1.0"),
        "srs_host": str(options.get("srs_host") or options.get("host") or SRS_HOST),
        "password": str(
            options.get("external_awacs_mode_password")
            or SRS_EXTERNAL_AWACS_PASSWORD
            or ""
        ),
    }


def run_srs_go_sender(pcm_file: Path, options: dict, combined: bool = False) -> dict:
    srs = get_srs_command_common(options)

    command = [
        str(SRS_GO_SENDER_EXE),
        f"--srs-address={srs['srs_host']}:{srs['port']}",
        "--client-name=NASGroup TTS",
        f"--coalition={srs['coalition']}",
        f"--frequency={srs['freqs']}",
        f"--modulation={srs['modulations']}",
        f"--volume={srs['volume']}",
        f"--external-awacs-password={srs['password']}",
        f"--file={str(pcm_file)}",
    ]

    label = "combined PCM" if combined else "PCM"

    log_info(
        f"[{INSTANCE_NAME}] Starting Go native SRS sender with {label}: "
        f"host={srs['srs_host']}, port={srs['port']}, freqs={srs['freqs']}, "
        f"modulations={srs['modulations']}, coalition={srs['coalition']}, volume={srs['volume']}"
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
        log_debug(process.stdout)

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


def play_srs_go_native(output_file: Path, options: dict) -> dict:
    pcm_file = convert_audio_to_skyeye_pcm_f32le(output_file)

    try:
        return run_srs_go_sender(pcm_file, options, combined=False)
    finally:
        try:
            pcm_file.unlink(missing_ok=True)
        except Exception as exc:
            log_error(f"Failed to delete temporary SkyEye PCM file {pcm_file}: {exc}")


def play_srs_go_native_pcm(pcm_file: Path, options: dict) -> dict:
    return run_srs_go_sender(pcm_file, options, combined=True)


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
        f"--modulations={modulations}",
        f"--coalition={coalition}",
        f"--port={port}",
    ]

    if gender:
        command.append(f"-g={gender}")

    if volume:
        command.append(f"--volume={volume}")

    log_info(f"[{INSTANCE_NAME}] Starting SRS ExternalAudio fallback: {' '.join(command)}")

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
        log_debug(process.stdout)

    if process.returncode != 0:
        raise RuntimeError(
            f"SRS ExternalAudio failed with exit code {process.returncode}: {process.stdout}"
        )

    return {
        "success": True,
        "backend": "external_audio",
        "returncode": process.returncode,
    }


def play_srs_native(output_file: Path, options: dict):
    from srs_native import transmit_file_to_srs

    native_options = dict(options)
    native_options["srs_host"] = native_options.get("srs_host") or SRS_HOST

    log_info(
        f"[{INSTANCE_NAME}] Starting native Python SRS playback: "
        f"file={output_file}, host={native_options.get('srs_host')}, "
        f"port={native_options.get('port')}, freqs={native_options.get('freqs')}, "
        f"modulations={native_options.get('modulations')}, "
        f"coalition={native_options.get('coalition')}"
    )

    return transmit_file_to_srs(output_file, native_options)


def play_srs(output_file: Path, options: dict):
    if SRS_BACKEND == "native":
        return play_srs_native(output_file, options)

    if SRS_BACKEND == "go_native":
        return play_srs_go_native(output_file, options)

    return play_srs_external_audio(output_file, options)


def process_job(job_id: str, text: str, options: dict, initiator: str, text_hash: str):
    output_file = None
    cache_file = None
    cache_hit = False

    try:
        log_info(f"[{job_id}] TTS job started: initiator={initiator!r}")

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
            output_file = copy_cached_audio_to_job_file(cached_file, job_id)
            log_debug(f"[{job_id}] Replaying cached TTS audio: {cached_file}")
        else:
            generated_file = asyncio.run(generate_tts(text, job_id, options))
            cache_file = replace_cached_file_for_initiator(initiator, text_hash, generated_file)
            output_file = generated_file
            log_debug(f"[{job_id}] Updated TTS cache: {cache_file}")

        srs_result = play_srs(output_file, options)

        filename = output_file.name
        folder = str(output_file.parent) + "\\"
        path = str(output_file)

        try:
            if output_file and output_file.exists() and output_file != cache_file:
                output_file.unlink(missing_ok=True)
            deleted = True
        except Exception as delete_exc:
            deleted = False
            log_error(f"[{job_id}] Failed to delete temporary TTS file {output_file}: {delete_exc}")

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

        log_info(f"[{job_id}] TTS job completed successfully. cache_hit={cache_hit}")

    except Exception as exc:
        log_error(f"[{job_id}] TTS job failed: {exc}")

        if output_file:
            try:
                if output_file.exists() and output_file != cache_file:
                    output_file.unlink(missing_ok=True)
            except Exception as delete_exc:
                log_error(f"[{job_id}] Failed to delete temporary TTS file after error {output_file}: {delete_exc}")

        set_job(job_id, {
            "status": "error",
            "success": False,
            "error": str(exc),
            "initiator": initiator,
            "text_hash": text_hash,
            "completed_at": time.time(),
        })


def process_audio_file_job(job_id: str, audio_file: Path, options: dict, initiator: str):
    try:
        log_info(f"[{job_id}] Audio file job started: {audio_file}")

        set_job(job_id, {
            "status": "running",
            "initiator": initiator,
            "audio_file": str(audio_file),
            "started_at": time.time(),
        })

        if not audio_file.exists():
            raise RuntimeError(f"Audio file not found: {audio_file}")

        if not audio_file.is_file():
            raise RuntimeError(f"Audio path is not a file: {audio_file}")

        if audio_file.suffix.lower() != ".ogg":
            raise RuntimeError(f"Only .ogg inbox audio files are currently allowed: {audio_file}")

        srs_result = play_srs(audio_file, options)

        set_job(job_id, {
            "status": "done",
            "success": True,
            "filename": audio_file.name,
            "folder": str(audio_file.parent) + "\\",
            "path": str(audio_file),
            "deleted": False,
            "cache_hit": False,
            "cache_file": None,
            "initiator": initiator,
            "audio_file": str(audio_file),
            "srs": srs_result,
            "completed_at": time.time(),
        })

        log_info(f"[{job_id}] Audio file job completed successfully.")

    except Exception as exc:
        log_error(f"[{job_id}] Audio file job failed: {exc}")

        set_job(job_id, {
            "status": "error",
            "success": False,
            "error": str(exc),
            "initiator": initiator,
            "audio_file": str(audio_file),
            "completed_at": time.time(),
        })


def process_audio_files_job(job_id: str, audio_files: list[Path], options: dict, initiator: str):
    combined_file = None

    try:
        log_info(f"[{job_id}] Combined audio job started: files={len(audio_files)}")

        set_job(job_id, {
            "status": "running",
            "initiator": initiator,
            "audio_files": [str(path) for path in audio_files],
            "started_at": time.time(),
        })

        combined_file = concatenate_audio_files_to_skyeye_pcm_f32le(audio_files, job_id)

        if SRS_BACKEND == "go_native":
            srs_result = play_srs_go_native_pcm(combined_file, options)
        else:
            srs_result = play_srs(combined_file, options)

        set_job(job_id, {
            "status": "done",
            "success": True,
            "filename": combined_file.name,
            "folder": str(combined_file.parent) + "\\",
            "path": str(combined_file),
            "deleted": False,
            "cache_hit": False,
            "cache_file": None,
            "initiator": initiator,
            "audio_files": [str(path) for path in audio_files],
            "srs": srs_result,
            "completed_at": time.time(),
        })

        log_info(f"[{job_id}] Combined audio job completed successfully.")

    except Exception as exc:
        log_error(f"[{job_id}] Combined audio job failed: {exc}")

        set_job(job_id, {
            "status": "error",
            "success": False,
            "error": str(exc),
            "initiator": initiator,
            "audio_files": [str(path) for path in audio_files],
            "completed_at": time.time(),
        })

    finally:
        if combined_file:
            try:
                combined_file.unlink(missing_ok=True)
            except Exception as exc:
                log_error(f"[{job_id}] Failed to delete combined audio file {combined_file}: {exc}")


def get_srs_options_from_payload(payload: dict) -> dict:
    return {
        "initiator": payload.get("initiator"),
        "label": payload.get("label"),

        "voice": payload.get("voice"),
        "rate": payload.get("rate"),
        "pitch": payload.get("pitch"),

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


def queue_audio_file_payload(payload: dict) -> dict:
    audio_file_value = payload.get("file") or payload.get("audio_file") or payload.get("ogg_file")

    if not audio_file_value:
        raise ValueError("Missing file, audio_file, or ogg_file")

    audio_file = Path(audio_file_value).expanduser().resolve()
    options = get_srs_options_from_payload(payload)
    initiator = get_initiator(payload, options)
    job_id = uuid.uuid4().hex

    log_info(f"[{job_id}] Received audio file request: initiator={initiator!r}, file={audio_file}")

    with jobs_lock:
        jobs[job_id] = {
            "status": "queued",
            "success": None,
            "initiator": initiator,
            "audio_file": str(audio_file),
            "options": options,
            "created_at": time.time(),
        }

    thread = threading.Thread(
        target=process_audio_file_job,
        args=(job_id, audio_file, options, initiator),
        daemon=True,
    )
    thread.start()

    return {
        "success": True,
        "status": "queued",
        "job_id": job_id,
        "initiator": initiator,
        "audio_file": str(audio_file),
    }


def queue_audio_files_payload(payload: dict) -> dict:
    audio_file_values = payload.get("files") or payload.get("audio_files") or payload.get("ogg_files")

    if not audio_file_values:
        raise ValueError("Missing files, audio_files, or ogg_files")

    if not isinstance(audio_file_values, list):
        raise ValueError("files, audio_files, or ogg_files must be a list")

    audio_files = [Path(value).expanduser().resolve() for value in audio_file_values]

    options = get_srs_options_from_payload(payload)
    initiator = get_initiator(payload, options)
    job_id = uuid.uuid4().hex

    log_info(f"[{job_id}] Received combined audio request: initiator={initiator!r}, files={len(audio_files)}")

    with jobs_lock:
        jobs[job_id] = {
            "status": "queued",
            "success": None,
            "initiator": initiator,
            "audio_files": [str(path) for path in audio_files],
            "options": options,
            "created_at": time.time(),
        }

    thread = threading.Thread(
        target=process_audio_files_job,
        args=(job_id, audio_files, options, initiator),
        daemon=True,
    )
    thread.start()

    return {
        "success": True,
        "status": "queued",
        "job_id": job_id,
        "initiator": initiator,
        "audio_files": [str(path) for path in audio_files],
    }


def queue_tts_payload(payload: dict) -> dict:
    if payload.get("files") or payload.get("audio_files") or payload.get("ogg_files"):
        return queue_audio_files_payload(payload)

    if payload.get("file") or payload.get("audio_file") or payload.get("ogg_file"):
        return queue_audio_file_payload(payload)

    text = payload.get("text", "")

    if not text:
        raise ValueError("Missing text")

    options = get_srs_options_from_payload(payload)

    initiator = get_initiator(payload, options)
    text_hash = get_text_hash(text, options)
    job_id = uuid.uuid4().hex

    log_info(f"[{job_id}] Received TTS request: initiator={initiator!r}, text_length={len(text)}")

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
                log_error(f"Failed to clean up TTS inbox status file {file_path}: {exc}")


def process_inbox_file(file_path: Path):
    processing_file = file_path.with_suffix(file_path.suffix + ".processing")
    done_file = file_path.with_suffix(file_path.suffix + ".done")
    error_file = file_path.with_suffix(file_path.suffix + ".error")

    try:
        file_path.replace(processing_file)

        payload = json.loads(processing_file.read_text(encoding="utf-8-sig"))
        log_debug(f"Loaded TTS inbox payload from {processing_file}: {payload}")

        result = queue_tts_payload(payload)

        done_file.write_text(json.dumps(result, indent=2), encoding="utf-8")
        processing_file.unlink(missing_ok=True)

    except Exception:
        error_text = traceback.format_exc()
        log_error(f"Failed to process TTS inbox file {file_path}: {error_text}")

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

    log_info(f"TTS inbox:   {INBOX_DIR}")

    while True:
        try:
            for file_path in sorted(INBOX_DIR.glob("*.json")):
                process_inbox_file(file_path)

            cleanup_inbox_status_files()

        except Exception as exc:
            log_error(f"TTS inbox watcher error: {exc}")

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

    stop_file = Path(ARGS.stop_file).expanduser().resolve()

    if stop_file.exists():
        try:
            stop_file.unlink()
        except OSError:
            pass

    while True:
        try:
            server = ThreadingHTTPServer((ARGS.host, ARGS.port), TTSHandler)
            server.daemon_threads = True
            server.timeout = 1.0

            log_info(f"TTS service instance: {INSTANCE_NAME}")
            log_info(f"TTS service running at http://{ARGS.host}:{ARGS.port}")
            log_info(f"POST job:   http://{ARGS.host}:{ARGS.port}/tts")
            log_info(f"GET status: http://{ARGS.host}:{ARGS.port}/tts/<job_id>")
            log_info(f"TTS output: {INSTANCE_OUTPUT_DIR}")
            log_info(f"TTS cache:  {CACHE_DIR}")
            log_info(f"TTS inbox:  {INBOX_DIR}")
            log_info(f"TTS stop file: {stop_file}")
            log_info(f"SRS backend: {SRS_BACKEND}")
            log_info(f"SRS host:    {SRS_HOST}")
            log_info(f"SRS sender:  {SRS_GO_SENDER_EXE}")
            log_info(f"Verbose:     {ARGS.verbose}")

            while not stop_file.exists():
                server.handle_request()

            log_info(f"TTS service stop file detected: {stop_file}")
            server.server_close()

            try:
                stop_file.unlink()
            except OSError:
                pass

            break

        except KeyboardInterrupt:
            log_info(f"TTS service stopped by user: {INSTANCE_NAME}")
            break

        except Exception as exc:
            log_error(f"TTS service crashed: {INSTANCE_NAME}: {exc}")