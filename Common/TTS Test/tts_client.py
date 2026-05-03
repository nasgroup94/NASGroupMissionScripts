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


async def main():
    text = sys.argv[1] if len(sys.argv) > 1 else "hello from python"
    output_dir = Path(sys.argv[2]) if len(sys.argv) > 2 else Path(".")

    output_dir.mkdir(parents=True, exist_ok=True)

    async with websockets.connect(URI) as websocket:
        await websocket.send(text)
        message = await websocket.recv()

    data = json.loads(message)

    if not data.get("success"):
        raise RuntimeError(data.get("error", "unknown server error"))

    audio = base64.b64decode(data["audio"])
    ext = data.get("format", "ogg")
    output_file = output_dir / f"output.{ext}"

    output_file.write_bytes(audio)

    print(output_file)

    subprocess.run(
        [
            str(SRS_EXTERNAL_AUDIO_EXE),
            f"-i={str(output_file)}",
            "--freqs=250.0",
            "--modulations=AM",
            "-g=male",
            "--coalition=2",
        ],
        check=True,
    )


if __name__ == "__main__":
    asyncio.run(main())