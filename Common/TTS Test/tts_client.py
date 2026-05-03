import asyncio
import base64
import json
import subprocess
import argparse
import asyncio
import base64
import json
import subprocess
import sys
from pathlib import Path

import websockets


URI = "ws://96.32.24.78:8080"

SRS_EXTERNAL_AUDIO_EXE = Path(
    r"E:\DCS-SimpleRadioStandalone-2.0.8.5\ExternalAudio\DCS-SR-ExternalAudio.exe"
)


def parse_args():
    parser = argparse.ArgumentParser(description="Generate TTS audio and send it through SRS ExternalAudio.")

    parser.add_argument("text", nargs="?", default="hello from python")
    parser.add_argument("output_dir", nargs="?", default=".")

    parser.add_argument("--freqs", default="250.0")
    parser.add_argument("--modulations", default="AM")
    parser.add_argument("--coalition", default="2")
    parser.add_argument("--port", default="5002")
    parser.add_argument("--name", default="NASG")
    parser.add_argument("--latitude", default=None)
    parser.add_argument("--longitude", default=None)
    parser.add_argument("--altitude", default=None)
    parser.add_argument("--volume", default=0.8)
    parser.add_argument("--timeout", type=int, default=15)

    return parser.parse_args()


async def generate_tts(text: str, output_dir: Path) -> Path:
    output_dir.mkdir(parents=True, exist_ok=True)

    async with websockets.connect(URI) as websocket:
        await websocket.send(text)
        message = await websocket.recv()

    data = json.loads(message)

    if not data.get("success"):
        raise RuntimeError(data.get("error", "unknown server error"))

    audio = base64.b64decode(data["audio"])
    ext = data.get("format", "mp3")
    output_file = output_dir / f"output.{ext}"

    output_file.write_bytes(audio)

    return output_file


def play_srs(output_file: Path, args):
    command = [
        str(SRS_EXTERNAL_AUDIO_EXE),
        f"--file={str(output_file)}",
        f"--freqs={args.freqs}",
        f"--modulations={args.modulations}",
        f"--coalition={args.coalition}",
        f"--port={args.port}",
        f"--volume={args.volume}",
        f"--name={args.name}",
    ]

    if args.latitude:
        command.append(f"--latitude={args.latitude}")

    if args.longitude:
        command.append(f"--longitude={args.longitude}")

    if args.altitude:
        command.append(f"--altitude={args.altitude}")


    try:
        result = subprocess.run(
            command,
            capture_output=True,
            text=True,
            timeout=args.timeout,
        )

        if result.stdout:
            print(result.stdout)

        if result.stderr:
            print(result.stderr, file=sys.stderr)

        result.check_returncode()

    except subprocess.TimeoutExpired:
        print(f"SRS ExternalAudio timed out after {args.timeout} seconds; assuming audio was sent.")


async def main():
    args = parse_args()

    text = args.text
    output_dir = Path(args.output_dir)

    output_file = await generate_tts(text, output_dir)

    print(output_file)

    play_srs(output_file, args)

    try:
        output_file.unlink(missing_ok=True)
        print(f"Deleted {output_file}")
    except Exception as exc:
        print(f"Failed to delete {output_file}: {exc}", file=sys.stderr)


if __name__ == "__main__":
    asyncio.run(main())