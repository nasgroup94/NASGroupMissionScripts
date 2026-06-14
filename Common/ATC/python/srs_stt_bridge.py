import argparse
import json
import os
import queue
import re
import signal
import struct
import subprocess
import sys
import threading
import time
import traceback
import wave
from dataclasses import dataclass
from pathlib import Path


CREATE_NO_WINDOW = subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0

LOG_FILE = Path(__file__).resolve().parent / "tmp" / "nasg_stt_bridge.log"


def write_log_file(message: str):
    try:
        LOG_FILE.parent.mkdir(parents=True, exist_ok=True)
        with LOG_FILE.open("a", encoding="utf-8") as file:
            file.write(message)
            file.write("\n")
    except Exception:
        pass

@dataclass
class BridgeConfig:
    config_file: Path
    stop_file: Path
    lock_file: Path
    srs_listener_exe: Path
    srs_address: str
    client_name: str
    coalition: int
    frequency: float
    modulation: str
    external_awacs_password: str
    output_dir: Path
    ignored_client_names: list[str]
    dcs_event_file: Path
    default_airport_id: str
    stt_backend: str
    whisper_model: str
    whisper_device: str
    whisper_compute_type: str
    verbose: bool
    cleanup_audio_retention_seconds: int
    cleanup_interval_seconds: int
    delete_processed_audio: bool


@dataclass
class ListenerChannel:
    id: str
    airport_id: str
    service: str
    client_name: str
    frequency: float
    modulation: str
    coalition: int


@dataclass
class RuntimeConfig:
    srs_address: str
    event_file: Path
    channels: list[ListenerChannel]
    intent_patterns: dict

def log_info(message: str):
    print(message, flush=True)
    write_log_file(message)


def log_debug(config: BridgeConfig, message: str):
    if config.verbose:
        print(message, flush=True)
        write_log_file(message)


def log_error(message: str):
    print(message, file=sys.stderr, flush=True)
    write_log_file(f"ERROR: {message}")


def parse_args() -> BridgeConfig:
    base_dir = Path(__file__).resolve().parent

    parser = argparse.ArgumentParser(
        description="NASGroup SRS STT bridge manager. Lua writes channel config; this process starts listeners and forwards STT events to DCS."
    )

    parser.add_argument(
        "--config-file",
        default=str(base_dir / "tmp" / "nasg_stt_config.json"),
        help="Lua-written STT bridge config file.",
    )
    parser.add_argument(
        "--stop-file",
        default=str(base_dir / "tmp" / "nasg_stt_bridge.stop"),
        help="If this file exists, the bridge manager exits cleanly.",
    )
    parser.add_argument(
        "--lock-file",
        default=str(base_dir / "tmp" / "nasg_stt_bridge.lock"),
        help="Lock file used to prevent duplicate bridge starts.",
    )
    parser.add_argument(
        "--cleanup-audio-retention-seconds",
        type=int,
        default=3600,
        help="Delete STT received audio files older than this many seconds.",
    )
    parser.add_argument(
        "--cleanup-interval-seconds",
        type=int,
        default=300,
        help="How often to clean old STT received audio files.",
    )
    parser.add_argument(
        "--delete-processed-audio",
        action="store_true",
        help="Delete .pcm and .wav files immediately after successful STT processing.",
    )
    parser.add_argument(
        "--srs-listener",
        default=str(base_dir / "srs-tts-send" / "srs-stt-listen.exe"),
        help="Path to srs-stt-listen.exe.",
    )
    parser.add_argument("--srs-address", default="127.0.0.1:5002")
    parser.add_argument("--client-name", default="NASGroup Ground Listener")
    parser.add_argument("--coalition", type=int, default=2)
    parser.add_argument("--frequency", type=float, default=250.1)
    parser.add_argument("--modulation", default="AM")
    parser.add_argument(
        "--external-awacs-password",
        default=os.getenv("SRS_EXTERNAL_AWACS_PASSWORD", ""),
    )
    parser.add_argument(
        "--output-dir",
        default=str(base_dir / "tmp" / "srs_stt_rx"),
    )
    parser.add_argument(
        "--ignore-client-name",
        action="append",
        default=["NASGroup TTS"],
        help="SRS client name to ignore. Can be specified multiple times.",
    )
    parser.add_argument(
        "--dcs-event-file",
        default=str(base_dir / "tmp" / "nasg_ground_control_events.jsonl"),
    )
    parser.add_argument("--default-airport-id", default="al_minhad")

    parser.add_argument(
        "--stt-backend",
        choices=("dummy", "faster-whisper"),
        default="dummy",
    )
    parser.add_argument("--whisper-model", default="small.en")
    parser.add_argument("--whisper-device", default="cpu")
    parser.add_argument("--whisper-compute-type", default="int8")
    parser.add_argument("--verbose", action="store_true")

    args = parser.parse_args()

    return BridgeConfig(
        config_file=Path(args.config_file).expanduser().resolve(),
        stop_file=Path(args.stop_file).expanduser().resolve(),
        lock_file=Path(args.lock_file).expanduser().resolve(),
        srs_listener_exe=Path(args.srs_listener).expanduser().resolve(),
        srs_address=args.srs_address,
        client_name=args.client_name,
        coalition=args.coalition,
        frequency=args.frequency,
        modulation=args.modulation,
        external_awacs_password=args.external_awacs_password,
        output_dir=Path(args.output_dir).expanduser().resolve(),
        ignored_client_names=args.ignore_client_name,
        dcs_event_file=Path(args.dcs_event_file).expanduser().resolve(),
        default_airport_id=args.default_airport_id,
        stt_backend=args.stt_backend,
        whisper_model=args.whisper_model,
        whisper_device=args.whisper_device,
        whisper_compute_type=args.whisper_compute_type,
        verbose=args.verbose,
        cleanup_audio_retention_seconds=args.cleanup_audio_retention_seconds,
        cleanup_interval_seconds=args.cleanup_interval_seconds,
        delete_processed_audio=args.delete_processed_audio,
    )


def load_runtime_config(config: BridgeConfig) -> RuntimeConfig:
    if config.config_file.exists():
        raw_config_text = config.config_file.read_text(encoding="utf-8")

        try:
            data = json.loads(raw_config_text)
        except json.JSONDecodeError as exc:
            start = max(exc.pos - 200, 0)
            end = min(exc.pos + 200, len(raw_config_text))
            nearby = raw_config_text[start:end]

            raise RuntimeError(
                f"Invalid JSON in STT config file: {config.config_file}\n"
                f"JSON error: {exc}\n"
                f"Near character {exc.pos}:\n{nearby!r}"
            ) from exc

        channels: list[ListenerChannel] = []

        for item in data.get("channels", []):
            channels.append(
                ListenerChannel(
                    id=str(item.get("id") or f"channel_{len(channels) + 1}"),
                    airport_id=str(item.get("airport_id") or config.default_airport_id),
                    service=str(item.get("service") or item.get("facility") or "ground"),
                    client_name=str(item.get("client_name") or config.client_name),
                    frequency=float(item.get("frequency") or config.frequency),
                    modulation=str(item.get("modulation") or config.modulation),
                    coalition=int(item.get("coalition") or config.coalition),
                )
            )

        if channels:
            return RuntimeConfig(
                srs_address=str(data.get("srs_address") or config.srs_address),
                event_file=Path(data.get("event_file") or config.dcs_event_file).expanduser().resolve(),
                channels=channels,
                intent_patterns=data.get("intent_patterns") or {},
            )

    return RuntimeConfig(
        srs_address=config.srs_address,
        event_file=config.dcs_event_file,
        channels=[
            ListenerChannel(
                id="default_ground",
                airport_id=config.default_airport_id,
                service="ground",
                client_name=config.client_name,
                frequency=config.frequency,
                modulation=config.modulation,
                coalition=config.coalition,
            )
        ],
        intent_patterns={},
    )

def get_subprocess_startupinfo():
    if os.name != "nt":
        return None

    startupinfo = subprocess.STARTUPINFO()
    startupinfo.dwFlags |= subprocess.STARTF_USESHOWWINDOW
    startupinfo.wShowWindow = 0
    return startupinfo


def pcm_f32le_to_wav(pcm_file: Path, sample_rate: int = 16000) -> Path:
    pcm_file = Path(pcm_file)
    wav_file = pcm_file.with_suffix(".wav")
    raw = pcm_file.read_bytes()

    if len(raw) == 0:
        raise RuntimeError(f"PCM file is empty: {pcm_file}")

    if len(raw) % 4 != 0:
        raise RuntimeError(f"PCM file size is not divisible by 4 bytes: {pcm_file}")

    sample_count = len(raw) // 4
    floats = struct.unpack("<" + "f" * sample_count, raw)

    pcm16 = bytearray()

    for sample in floats:
        if sample > 1.0:
            sample = 1.0
        elif sample < -1.0:
            sample = -1.0

        pcm16.extend(struct.pack("<h", int(sample * 32767.0)))

    with wave.open(str(wav_file), "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(sample_rate)
        wav.writeframes(bytes(pcm16))

    return wav_file


class STTService:
    def __init__(self, config: BridgeConfig):
        self.config = config
        self.model = None

        if config.stt_backend == "faster-whisper":
            try:
                from faster_whisper import WhisperModel
            except ModuleNotFoundError:
                log_error(
                    "faster-whisper requested but not installed. Falling back to dummy STT."
                )
                self.config.stt_backend = "dummy"
                return

            log_info(
                f"Loading faster-whisper model={config.whisper_model}, "
                f"device={config.whisper_device}, compute_type={config.whisper_compute_type}"
            )

            self.model = WhisperModel(
                config.whisper_model,
                device=config.whisper_device,
                compute_type=config.whisper_compute_type,
            )

    def transcribe(self, wav_file: Path) -> str:
        if self.config.stt_backend == "dummy":
            return "request startup information echo"

        if self.config.stt_backend == "faster-whisper":
            segments, _ = self.model.transcribe(
                str(wav_file),
                language="en",
                vad_filter=True,
                initial_prompt=(
                    "DCS aviation radio communication. "
                    "Ground control, tower, center, AWACS. "
                    "Request startup, request taxi, holding short, ready for departure. "
                    "Request direct, request vectors, request recovery, request divert. "
                    "Request MARSA, cancel MARSA, own separation, own navigation, VFR on top. "
                    "Request block altitude, block sixteen thousand to twenty thousand. "
                    "Request tanker, request AAR, request range, vector to tanker, vector to range. "
                    "Information alpha bravo charlie delta echo foxtrot golf hotel india juliet kilo lima mike november oscar papa quebec "
                    "romeo sierra tango uniform victor whiskey xray yankee zulu."
                ),
            )

            parts = []

            for segment in segments:
                if segment.text:
                    parts.append(segment.text.strip())

            return " ".join(parts).strip()

        raise RuntimeError(f"Unsupported STT backend: {self.config.stt_backend}")

def normalize_dcs_client_name(name: str) -> str:
    text = str(name or "").strip()

    if "|" in text:
        text = text.split("|", 1)[0].strip()

    return text

class GroundSpeechEventBuilder:
    ATIS_WORDS = {
        "alpha": "A",
        "bravo": "B",
        "charlie": "C",
        "delta": "D",
        "echo": "E",
        "foxtrot": "F",
        "golf": "G",
        "hotel": "H",
        "india": "I",
        "juliett": "J",
        "juliet": "J",
        "kilo": "K",
        "lima": "L",
        "mike": "M",
        "november": "N",
        "oscar": "O",
        "papa": "P",
        "quebec": "Q",
        "romeo": "R",
        "sierra": "S",
        "tango": "T",
        "uniform": "U",
        "victor": "V",
        "whiskey": "W",
        "xray": "X",
        "x-ray": "X",
        "yankee": "Y",
        "zulu": "Z",
    }

    def __init__(self, channel: ListenerChannel):
        self.channel = channel

    def detect_intent(self, text: str) -> str | None:
        normalized = " ".join((text or "").lower().split())

        if not normalized:
            return None

        if "radio check" in normalized:
            return "radio_check"

        if "say again" in normalized:
            return "say_again"

        if (
                "request startup" in normalized
                or "request start up" in normalized
                or "startup" in normalized
                or "start up" in normalized
        ):
            return "request_startup"

        if (
                "request taxi" in normalized
                or "ready to taxi" in normalized
                or "taxi request" in normalized
                or "ready for taxi" in normalized
        ):
            return "request_taxi"

        return None

    def extract_atis_letter(self, text: str) -> str | None:
        normalized = " ".join((text or "").lower().split())
        match = re.search(r"\binformation\s+([a-zA-Z-]+)\b", normalized)

        if not match:
            return None

        atis_word = match.group(1).strip().lower().rstrip(".,!?")

        if len(atis_word) == 1 and atis_word.isalpha():
            return atis_word.upper()

        return self.ATIS_WORDS.get(atis_word)

class ATCSpeechEventBuilder:
    ATIS_WORDS = {
        "alpha": "A",
        "bravo": "B",
        "charlie": "C",
        "delta": "D",
        "echo": "E",
        "foxtrot": "F",
        "golf": "G",
        "hotel": "H",
        "india": "I",
        "juliett": "J",
        "juliet": "J",
        "kilo": "K",
        "lima": "L",
        "mike": "M",
        "november": "N",
        "oscar": "O",
        "papa": "P",
        "quebec": "Q",
        "romeo": "R",
        "sierra": "S",
        "tango": "T",
        "uniform": "U",
        "victor": "V",
        "whiskey": "W",
        "xray": "X",
        "x-ray": "X",
        "yankee": "Y",
        "zulu": "Z",
    }

    NUMBER_WORDS = {
        "zero": "0",
        "one": "1",
        "two": "2",
        "three": "3",
        "four": "4",
        "five": "5",
        "six": "6",
        "seven": "7",
        "eight": "8",
        "nine": "9",
        "niner": "9",
    }

    def __init__(self, channel: ListenerChannel, intent_patterns: dict):
        self.channel = channel
        self.intent_patterns = intent_patterns or {}

    def normalize_text(self, text: str) -> str:
        return " ".join((text or "").lower().split())

    def normalize_compact(self, text: str) -> str:
        return re.sub(r"[^a-z0-9]", "", (text or "").lower())

    def callsign_variants(self, client_name: str) -> list[str]:
        base = normalize_dcs_client_name(client_name)
        compact = self.normalize_compact(base)

        variants = []

        if compact:
            variants.append(compact)

        # HOBO11 -> hobo one one / hobo 11 variants.
        match = re.match(r"^([a-zA-Z]+)([0-9]+)$", compact)

        if match:
            word_part = match.group(1)
            digits = match.group(2)

            digit_words = {
                "0": "zero",
                "1": "one",
                "2": "two",
                "3": "three",
                "4": "four",
                "5": "five",
                "6": "six",
                "7": "seven",
                "8": "eight",
                "9": "nine",
            }

            spoken_digits = " ".join(digit_words.get(digit, digit) for digit in digits)

            variants.append(self.normalize_compact(f"{word_part} {spoken_digits}"))
            variants.append(self.normalize_compact(f"{word_part} {' '.join(digits)}"))

        return list(dict.fromkeys(variants))

    def has_callsign_at_end(self, text: str, srs_event: dict) -> bool:
        srs_client_name = str(srs_event.get("client_name") or "").strip()
        client_name = normalize_dcs_client_name(srs_client_name)

        if not client_name:
            return False

        compact_text = self.normalize_compact(text)

        if not compact_text:
            return False

        variants = self.callsign_variants(client_name)

        for variant in variants:
            if variant and compact_text.endswith(variant):
                return True

        # Allow callsign to be near the end if STT adds extra punctuation/short filler.
        tail = compact_text[-40:]

        for variant in variants:
            if variant and variant in tail:
                return True

        return False

    def detect_intent(self, text: str) -> str | None:
        normalized = self.normalize_text(text)

        if not normalized:
            return None

        service = str(self.channel.service or "ground").lower()
        service_patterns = self.intent_patterns.get(service) or {}

        best_intent = None
        best_length = -1

        for intent, phrases in service_patterns.items():
            for phrase in phrases or []:
                normalized_phrase = self.normalize_text(str(phrase))

                if not normalized_phrase:
                    continue

                if normalized_phrase in normalized and len(normalized_phrase) > best_length:
                    best_intent = str(intent)
                    best_length = len(normalized_phrase)

        return best_intent

    def extract_atis_letter(self, text: str) -> str | None:
        normalized = self.normalize_text(text)
        match = re.search(r"\binformation\s+([a-zA-Z-]+)\b", normalized)

        if not match:
            return None

        atis_word = match.group(1).strip().lower().rstrip(".,!?")

        if len(atis_word) == 1 and atis_word.isalpha():
            return atis_word.upper()

        return self.ATIS_WORDS.get(atis_word)

    def extract_runway(self, text: str) -> str | None:
        normalized = self.normalize_text(text)

        mixed_match = re.search(
            r"\brunway\s+"
            r"((?:[0-9]|zero|one|two|three|four|five|six|seven|eight|nine|niner)"
            r"(?:\s+(?:[0-9]|zero|one|two|three|four|five|six|seven|eight|nine|niner))?)"
            r"\s*([lrc])?\b",
            normalized,
        )

        if mixed_match:
            parts = mixed_match.group(1).split()
            digits = ""

            for part in parts:
                if part.isdigit():
                    digits += part
                else:
                    digits += self.NUMBER_WORDS.get(part, "")

            suffix = mixed_match.group(2) or ""

            if digits:
                return (digits + suffix).upper()

        digit_match = re.search(r"\brunway\s+([0-9]{1,2}[lrc]?)\b", normalized)

        if digit_match:
            return digit_match.group(1).upper()

        return None

    def extract_altitude(self, text: str) -> str | None:
        normalized = self.normalize_text(text)
        match = re.search(r"\b(?:passing|level|climbing through|descending through)\s+([a-z0-9\s]+)", normalized)

        if match:
            return match.group(0)

        return None

    def parse_altitude_token(self, value: str) -> int | None:
        text = self.normalize_text(value)

        if not text:
            return None

        digit_match = re.search(r"\b([0-9]{2,3})(?:,?000| thousand)?\b", text)

        if digit_match:
            number = int(digit_match.group(1))

            if number < 1000:
                return number * 1000

            return number

        parts = text.split()
        number_words = {
            "zero": 0,
            "one": 1,
            "two": 2,
            "three": 3,
            "four": 4,
            "five": 5,
            "six": 6,
            "seven": 7,
            "eight": 8,
            "nine": 9,
            "ten": 10,
            "eleven": 11,
            "twelve": 12,
            "thirteen": 13,
            "fourteen": 14,
            "fifteen": 15,
            "sixteen": 16,
            "seventeen": 17,
            "eighteen": 18,
            "nineteen": 19,
            "twenty": 20,
            "twentyone": 21,
            "twenty-one": 21,
            "thirty": 30,
            "forty": 40,
        }

        compact = "".join(parts)

        if compact in number_words:
            return number_words[compact] * 1000

        if len(parts) == 1 and parts[0] in number_words:
            return number_words[parts[0]] * 1000

        return None

    def extract_block_altitude(self, text: str) -> dict | None:
        normalized = self.normalize_text(text)

        match = re.search(
            r"\bblock(?: altitude)?\s+(.+?)\s+(?:to|through|thru)\s+(.+?)(?:\s|$)",
            normalized,
        )

        if not match:
            return None

        min_ft = self.parse_altitude_token(match.group(1))
        max_ft = self.parse_altitude_token(match.group(2))

        if min_ft and max_ft:
            return {
                "min_ft": min(min_ft, max_ft),
                "max_ft": max(min_ft, max_ft),
            }

        return None

    def extract_direct_fix(self, text: str) -> str | None:
        normalized = self.normalize_text(text)
        match = re.search(r"\bdirect\s+([a-zA-Z0-9_-]+)\b", normalized)

        if match:
            return match.group(1).upper()

        return None

    def contains_readback_phrase(self, normalized: str, service: str) -> bool:
        if service == "tower":
            tower_phrases = (
                "line up and wait",
                "cleared for takeoff",
                "cleared for take off",
                "cleared to land",
                "go around",
                "runway",
            )

            return any(phrase in normalized for phrase in tower_phrases)

        if service == "ground":
            ground_phrases = (
                "taxi",
                "hold short",
                "cross runway",
                "contact tower",
                "runway",
            )

            return any(phrase in normalized for phrase in ground_phrases)

        if service == "center":
            center_phrases = (
                "radar contact",
                "proceed direct",
                "direct",
                "contact tower",
                "contact awacs",
                "maintain",
                "climb",
                "descend",
                "marsa",
                "block",
            )

            return any(phrase in normalized for phrase in center_phrases)

        if service == "awacs":
            awacs_phrases = (
                "picture",
                "bogey dope",
                "vector",
                "home plate",
                "proceed",
                "contact tower",
            )

            return any(phrase in normalized for phrase in awacs_phrases)

        return False

    def build_event(self, text: str, srs_event: dict) -> dict | None:
        service = str(self.channel.service or "ground").lower()
        normalized = self.normalize_text(text)

        intent = self.detect_intent(text)

        if not intent:
            if self.has_callsign_at_end(text, srs_event) and self.contains_readback_phrase(normalized, service):
                intent = "readback"
                log_info(
                    f"[{self.channel.id}] Classified as readback using callsign-at-end heuristic, "
                    f"service={service!r}, text={normalized!r}"
                )

        if not intent:
            return None

        srs_client_name = str(srs_event.get("client_name") or "").strip()
        client_name = normalize_dcs_client_name(srs_client_name)

        speech_event = {
            "source": "srs_stt_bridge",
            "channel_id": self.channel.id,
            "airport_id": self.channel.airport_id,
            "service": service,
            "facility": service,
            "intent": intent,
            "client_name": client_name,
            "srs_client_name": srs_client_name,
            "callsign": client_name,
            "atis_letter": self.extract_atis_letter(text),
            "raw_text": text,
            "frequency_mhz": self.channel.frequency,
            "modulation": self.channel.modulation,
            "coalition": self.channel.coalition,
            "created_at": time.time(),
        }

        runway = self.extract_runway(text)

        if runway:
            speech_event["runway"] = runway

        altitude = self.extract_altitude(text)

        if altitude:
            speech_event["altitude"] = altitude

        block_altitude = self.extract_block_altitude(text)

        if block_altitude:
            speech_event["block_altitude"] = block_altitude

        fix = self.extract_direct_fix(text)

        if fix:
            speech_event["fix"] = fix

        return speech_event

class DCSEventWriter:
    def __init__(self, event_file: Path):
        self.event_file = event_file
        self.lock = threading.Lock()

    def write(self, event: dict):
        self.event_file.parent.mkdir(parents=True, exist_ok=True)

        with self.lock:
            with self.event_file.open("a", encoding="utf-8") as file:
                file.write(json.dumps(event, separators=(",", ":")))
                file.write("\n")



def start_srs_listener(config: BridgeConfig, runtime: RuntimeConfig, channel: ListenerChannel) -> subprocess.Popen:
    if not config.srs_listener_exe.exists():
        raise RuntimeError(f"SRS listener executable not found: {config.srs_listener_exe}")

    channel_output_dir = config.output_dir / channel.id
    channel_output_dir.mkdir(parents=True, exist_ok=True)

    command = [
        str(config.srs_listener_exe),
        f"--srs-address={runtime.srs_address}",
        f"--client-name={channel.client_name}",
        f"--coalition={channel.coalition}",
        f"--frequency={channel.frequency}",
        f"--modulation={channel.modulation}",
        f"--external-awacs-password={config.external_awacs_password}",
        f"--output-dir={str(channel_output_dir)}",
    ]

    log_info(f"Starting SRS listener for channel={channel.id}:")
    log_info(" ".join(command))

    return subprocess.Popen(
        command,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        bufsize=1,
        creationflags=CREATE_NO_WINDOW,
        startupinfo=get_subprocess_startupinfo(),
    )

def delete_file_quietly(path: Path):
    try:
        if path and path.exists():
            path.unlink()
    except Exception as exc:
        log_error(f"Failed to delete file {path}: {exc}")


def cleanup_stt_audio_files(config: BridgeConfig):
    output_dir = config.output_dir

    if not output_dir.exists():
        return

    now = time.time()
    retention_seconds = max(int(config.cleanup_audio_retention_seconds or 0), 0)

    if retention_seconds <= 0:
        return

    cleanup_patterns = (
        "*.pcm",
        "*.wav",
    )

    deleted_count = 0

    for pattern in cleanup_patterns:
        for file_path in output_dir.rglob(pattern):
            try:
                age_seconds = now - file_path.stat().st_mtime

                if age_seconds >= retention_seconds:
                    file_path.unlink()
                    deleted_count += 1

            except Exception as exc:
                log_error(f"Failed to clean up STT audio file {file_path}: {exc}")

    if deleted_count > 0:
        log_info(f"Cleaned up {deleted_count} old STT audio files from {output_dir}")


def cleanup_empty_directories(root_dir: Path):
    if not root_dir.exists():
        return

    directories = sorted(
        [path for path in root_dir.rglob("*") if path.is_dir()],
        key=lambda path: len(str(path)),
        reverse=True,
    )

    removed_count = 0

    for directory in directories:
        try:
            if directory == root_dir:
                continue

            # Preserve per-channel listener output directories while the bridge is running.
            # srs-stt-listen.exe receives these directories at startup and expects them
            # to continue existing for later transmissions.
            if directory.parent == root_dir:
                continue

            if not any(directory.iterdir()):
                directory.rmdir()
                removed_count += 1

        except Exception:
            pass

    if removed_count > 0:
        log_info(f"Removed {removed_count} empty STT audio subdirectories from {root_dir}")


def cleanup_loop(config: BridgeConfig, stop_event: threading.Event):
    while not stop_event.is_set():
        cleanup_stt_audio_files(config)
        cleanup_empty_directories(config.output_dir)

        wait_seconds = max(int(config.cleanup_interval_seconds or 300), 30)

        if stop_event.wait(wait_seconds):
            return

def read_stderr(process: subprocess.Popen, stop_event: threading.Event):
    while not stop_event.is_set():
        line = process.stderr.readline()

        if not line:
            if process.poll() is not None:
                return

            time.sleep(0.05)
            continue

        line = line.rstrip()

        try:
            data = json.loads(line)
            level = str(data.get("level") or "").lower()

            if level in ("trace", "debug"):
                write_log_file(f"[srs-listener] {line}")
            elif level in ("info", "warning", "warn"):
                log_info(f"[srs-listener] {line}")
            else:
                log_error(f"[srs-listener] {line}")

        except Exception:
            log_error(f"[srs-listener] {line}")


def read_stdout_events(process: subprocess.Popen, events: queue.Queue, stop_event: threading.Event):
    while not stop_event.is_set():
        line = process.stdout.readline()

        if not line:
            if process.poll() is not None:
                return

            time.sleep(0.05)
            continue

        line = line.strip()

        if not line:
            continue

        try:
            event = json.loads(line)
        except Exception:
            log_error(f"[srs-listener] non-json stdout: {line}")
            continue

        events.put(event)


def process_events(
        config: BridgeConfig,
        channel: ListenerChannel,
        intent_patterns: dict,
        event_writer: DCSEventWriter,
        events: queue.Queue,
        stop_event: threading.Event,
):
    stt = STTService(config)
    event_builder = ATCSpeechEventBuilder(channel, intent_patterns)

    ignored_client_names = {
        name.strip().lower()
        for name in config.ignored_client_names
        if name and name.strip()
    }

    while not stop_event.is_set():
        try:
            event = events.get(timeout=0.25)
        except queue.Empty:
            continue

        try:
            audio_file = Path(event["audio_file"])
            audio_file.parent.mkdir(parents=True, exist_ok=True)
            client_name = str(event.get("client_name") or "").strip()

            if client_name.lower() in ignored_client_names:
                log_info(f"[{channel.id}] Ignoring SRS transmission from ignored client: {client_name!r}")
                continue

            log_info(
                f"[{channel.id}] Received SRS transmission: client={event.get('client_name')!r}, "
                f"duration={event.get('duration_seconds'):.2f}s, file={audio_file}"
            )

            wav_file = pcm_f32le_to_wav(
                audio_file,
                sample_rate=int(event.get("sample_rate") or 16000),
            )

            text = stt.transcribe(wav_file)

            log_info(f"[{channel.id}] STT: {text!r}")

            speech_event = event_builder.build_event(text, event)

            if not speech_event:
                log_info(f"[{channel.id}] No ATC intent matched for service={channel.service!r}. Event not forwarded to DCS.")
                continue

            event_writer.write(speech_event)

            log_info(f"[{channel.id}] Forwarded speech event to DCS: {speech_event}")

            if config.delete_processed_audio:
                delete_file_quietly(audio_file)
                delete_file_quietly(wav_file)

        except Exception as exc:
            log_error(f"[{channel.id}] Failed to process SRS event: {exc}")
            log_error(traceback.format_exc())

def main():
    config = parse_args()

    if config.stop_file.exists():
        try:
            config.stop_file.unlink()
        except Exception:
            pass

    runtime = load_runtime_config(config)

    stop_event = threading.Event()
    event_writer = DCSEventWriter(runtime.event_file)
    processes: list[tuple[ListenerChannel, subprocess.Popen]] = []

    cleanup_stt_audio_files(config)
    cleanup_empty_directories(config.output_dir)

    cleanup_thread = threading.Thread(
        target=cleanup_loop,
        args=(config, stop_event),
        daemon=True,
    )
    cleanup_thread.start()

    log_info(f"Loaded STT runtime config from: {config.config_file}")
    log_info(f"DCS event file: {runtime.event_file}")
    log_info(f"Stop file: {config.stop_file}")
    log_info(f"Lock file: {config.lock_file}")
    log_info(f"Configured channels: {len(runtime.channels)}")
    log_info(f"Loaded STT runtime config from: {config.config_file}")
    log_info(f"DCS event file: {runtime.event_file}")
    log_info(f"Stop file: {config.stop_file}")
    log_info(f"Lock file: {config.lock_file}")
    log_info(f"Configured channels: {len(runtime.channels)}")

    for service, patterns in (runtime.intent_patterns or {}).items():
        intent_count = len(patterns or {})
        phrase_count = sum(len(phrases or []) for phrases in (patterns or {}).values())
        log_info(f"Intent patterns loaded: service={service}, intents={intent_count}, phrases={phrase_count}")

    for channel in runtime.channels:
        events = queue.Queue()
        process = start_srs_listener(config, runtime, channel)
        processes.append((channel, process))
        stderr_thread = threading.Thread(
            target=read_stderr,
            args=(process, stop_event),
            daemon=True,
        )
        stderr_thread.start()

        stdout_thread = threading.Thread(
            target=read_stdout_events,
            args=(process, events, stop_event),
            daemon=True,
        )
        stdout_thread.start()

        worker_thread = threading.Thread(
            target=process_events,
            args=(config, channel, runtime.intent_patterns, event_writer, events, stop_event),
            daemon=True,
        )
        worker_thread.start()

    def request_stop(*_):
        if stop_event.is_set():
            return

        stop_event.set()

        for channel, process in processes:
            try:
                if process.poll() is None:
                    log_info(f"[{channel.id}] Terminating SRS listener")
                    process.terminate()
            except Exception as exc:
                log_error(f"[{channel.id}] Failed to terminate SRS listener: {exc}")

    signal.signal(signal.SIGINT, request_stop)

    if hasattr(signal, "SIGTERM"):
        signal.signal(signal.SIGTERM, request_stop)

    log_info("SRS STT bridge manager running.")

    try:
        while not stop_event.is_set():
            if config.stop_file.exists():
                log_info(f"Stop file detected: {config.stop_file}")
                request_stop()
                break

            for channel, process in list(processes):
                return_code = process.poll()

                if return_code is not None:
                    log_error(
                        f"[{channel.id}] SRS listener exited unexpectedly with code {return_code}. "
                        f"frequency={channel.frequency}, modulation={channel.modulation}, "
                        f"client_name={channel.client_name!r}"
                    )
                    request_stop()
                    break

            time.sleep(0.25)

    except KeyboardInterrupt:
        request_stop()

    except Exception as exc:
        log_error(f"SRS STT bridge manager error: {exc}")
        log_error(traceback.format_exc())
        request_stop()

    finally:
        stop_event.set()

        for channel, process in processes:
            try:
                if process.poll() is None:
                    process.terminate()
                    process.wait(timeout=5)
            except Exception:
                try:
                    process.kill()
                except Exception:
                    pass

        try:
            if config.stop_file.exists():
                config.stop_file.unlink()
        except Exception:
            pass

        try:
            if config.lock_file.exists():
                config.lock_file.unlink()
        except Exception:
            pass

        log_info("SRS STT bridge manager stopped.")
        sys.exit(0)

if __name__ == "__main__":
    main()