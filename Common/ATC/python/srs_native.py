from __future__ import annotations

import math
import os
import socket
import struct
import time
import uuid
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

if os.name == "nt":
    os.add_dll_directory(str(Path(__file__).resolve().parent))

import av
import opuslib



SRS_SAMPLE_RATE = 48000
SRS_CHANNELS = 1
SRS_FRAME_MS = 20
SRS_SAMPLES_PER_FRAME = int(SRS_SAMPLE_RATE * SRS_FRAME_MS / 1000)

# This is intentionally isolated here because SRS native packet framing is the
# part most likely to need adjustment if SRS changes protocol versions.
#
# The shape below follows the usual SRS concept:
# - client GUID / packet identity
# - radio/frequency metadata
# - Opus voice frame payload
#
# If your installed SRS version expects a different framing, only this function
# should need changing.
SRS_AUDIO_PACKET_MAGIC = b"SRS1"


@dataclass(frozen=True)
class SRSRadioOptions:
    host: str = "127.0.0.1"
    port: int = 5002
    freqs: str = "250.0"
    modulations: str = "AM"
    coalition: int = 2
    volume: float = 1.0
    client_name: str = "NASGroup TTS"
    unit_id: int = 1000000


def parse_first_frequency(freqs: str) -> float:
    value = str(freqs or "250.0").split(",")[0].strip()
    return float(value)


def parse_first_modulation(modulations: str) -> int:
    value = str(modulations or "AM").split(",")[0].strip().upper()

    if value in ("0", "AM"):
        return 0

    if value in ("1", "FM"):
        return 1

    raise ValueError(f"Unsupported SRS modulation: {value!r}")


def decode_audio_to_pcm16_mono_48k(audio_file: Path) -> bytes:
    audio_file = Path(audio_file)

    if not audio_file.exists():
        raise FileNotFoundError(audio_file)

    pcm = bytearray()

    with av.open(str(audio_file)) as container:
        stream = next((s for s in container.streams if s.type == "audio"), None)

        if stream is None:
            raise RuntimeError(f"No audio stream found in {audio_file}")

        resampler = av.audio.resampler.AudioResampler(
            format="s16",
            layout="mono",
            rate=SRS_SAMPLE_RATE,
        )

        for packet in container.demux(stream):
            for frame in packet.decode():
                resampled = resampler.resample(frame)

                if not isinstance(resampled, list):
                    resampled = [resampled]

                for out_frame in resampled:
                    for plane in out_frame.planes:
                        pcm.extend(bytes(plane))

    return bytes(pcm)


def iter_pcm_frames(pcm16: bytes) -> Iterable[bytes]:
    bytes_per_sample = 2
    frame_size_bytes = SRS_SAMPLES_PER_FRAME * SRS_CHANNELS * bytes_per_sample

    offset = 0

    while offset < len(pcm16):
        frame = pcm16[offset:offset + frame_size_bytes]

        if len(frame) < frame_size_bytes:
            frame += b"\x00" * (frame_size_bytes - len(frame))

        yield frame
        offset += frame_size_bytes


def build_srs_audio_packet(
        *,
        client_guid: uuid.UUID,
        packet_id: int,
        frequency: float,
        modulation: int,
        coalition: int,
        unit_id: int,
        opus_payload: bytes,
) -> bytes:
    frequency_hz = int(frequency * 1_000_000)

    # Native SRS packet framing lives here.
    #
    # Packet layout used by this Python sender:
    #
    #   4s      magic/version marker
    #   16s     client GUID bytes
    #   uint32  packet id
    #   uint64  frequency in Hz
    #   uint8   modulation, 0 AM / 1 FM
    #   uint8   coalition
    #   int32   unit id
    #   uint16  opus payload length
    #   bytes   opus payload
    #
    # If you compare against SkyEye's pkg/simpleradio implementation and your
    # SRS build expects the protobuf-style packet instead, replace this encoder
    # only; the rest of the service integration remains the same.
    header = struct.pack(
        "<4s16sIQBBiH",
        SRS_AUDIO_PACKET_MAGIC,
        client_guid.bytes,
        packet_id,
        frequency_hz,
        modulation,
        int(coalition),
        int(unit_id),
        len(opus_payload),
    )

    return header + opus_payload


class NativeSRSClient:
    def __init__(self, options: SRSRadioOptions):
        self.options = options
        self.client_guid = uuid.uuid4()

    def transmit_file(self, audio_file: Path) -> dict:
        pcm16 = decode_audio_to_pcm16_mono_48k(audio_file)

        if not pcm16:
            raise RuntimeError(f"Decoded audio was empty: {audio_file}")

        encoder = opuslib.Encoder(
            SRS_SAMPLE_RATE,
            SRS_CHANNELS,
            opuslib.APPLICATION_VOIP,
        )

        frequency = parse_first_frequency(self.options.freqs)
        modulation = parse_first_modulation(self.options.modulations)

        address = (self.options.host, int(self.options.port))
        frame_count = 0
        started_at = time.time()

        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as sock:
            next_send_time = time.monotonic()

            for packet_id, pcm_frame in enumerate(iter_pcm_frames(pcm16), start=1):
                opus_payload = encoder.encode(pcm_frame, SRS_SAMPLES_PER_FRAME)

                packet = build_srs_audio_packet(
                    client_guid=self.client_guid,
                    packet_id=packet_id,
                    frequency=frequency,
                    modulation=modulation,
                    coalition=int(self.options.coalition),
                    unit_id=int(self.options.unit_id),
                    opus_payload=opus_payload,
                )

                sock.sendto(packet, address)
                frame_count += 1

                next_send_time += SRS_FRAME_MS / 1000.0
                sleep_for = next_send_time - time.monotonic()

                if sleep_for > 0:
                    time.sleep(sleep_for)

        elapsed = time.time() - started_at

        return {
            "success": True,
            "backend": "native_srs",
            "host": self.options.host,
            "port": self.options.port,
            "freqs": self.options.freqs,
            "modulations": self.options.modulations,
            "coalition": self.options.coalition,
            "frames": frame_count,
            "duration_seconds": elapsed,
        }


def transmit_file_to_srs(audio_file: Path, options: dict) -> dict:
    radio_options = SRSRadioOptions(
        host=str(options.get("srs_host") or options.get("host") or "127.0.0.1"),
        port=int(options.get("port") or 5002),
        freqs=str(options.get("freqs") or "250.0"),
        modulations=str(options.get("modulations") or "AM"),
        coalition=int(options.get("coalition") or 2),
        volume=float(options.get("volume") or 1.0),
        client_name=str(options.get("client_name") or "NASGroup TTS"),
        unit_id=int(options.get("unit_id") or 1000000),
    )

    client = NativeSRSClient(radio_options)
    return client.transmit_file(Path(audio_file))

