from pathlib import Path
import argparse
import shutil
import subprocess
import sys
import tempfile


def find_ffmpeg(explicit_path: str | None) -> str | None:
    if explicit_path:
        ffmpeg_path = Path(explicit_path).expanduser().resolve()
        if ffmpeg_path.exists():
            return str(ffmpeg_path)

    return shutil.which("ffmpeg")


def convert_to_pcm_f32le_16k_mono(audio_file: Path, ffmpeg: str) -> Path:
    temp_dir = Path(tempfile.mkdtemp(prefix="srs_ogg_"))
    pcm_file = temp_dir / f"{audio_file.stem}.f32le"

    command = [
        ffmpeg,
        "-y",
        "-i",
        str(audio_file),
        "-ac",
        "1",
        "-ar",
        "16000",
        "-f",
        "f32le",
        str(pcm_file),
    ]

    print("Converting audio:")
    print(" ".join(command))

    process = subprocess.run(
        command,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
    )

    if process.stdout:
        print(process.stdout)

    if process.returncode != 0:
        raise RuntimeError(f"ffmpeg failed with exit code {process.returncode}")

    if not pcm_file.exists() or pcm_file.stat().st_size == 0:
        raise RuntimeError(f"PCM file was not created correctly: {pcm_file}")

    return pcm_file


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Convert an audio file to raw PCM and transmit it with srs-tts-send.exe."
    )

    parser.add_argument(
        "file",
        help="Path to the audio file to transmit, for example .ogg, .mp3, or .wav.",
    )

    parser.add_argument(
        "--exe",
        default=str(Path(__file__).with_name("srs-tts-send.exe")),
        help="Path to srs-tts-send.exe. Defaults to srs-tts-send.exe beside this script.",
    )

    parser.add_argument(
        "--ffmpeg",
        default=None,
        help="Optional path to ffmpeg.exe. If omitted, the script looks for ffmpeg on PATH.",
    )

    parser.add_argument(
        "--freqs",
        "--frequency",
        dest="frequency",
        default="250.0",
        help='SRS frequency in MHz, for example "264.0".',
    )

    parser.add_argument(
        "--modulation",
        default="AM",
        help="SRS modulation: AM or FM.",
    )

    parser.add_argument(
        "--coalition",
        default="2",
        help="SRS coalition: 1 red, 2 blue, other neutral.",
    )

    parser.add_argument(
        "--host",
        default="127.0.0.1",
        help="SRS server host.",
    )

    parser.add_argument(
        "--port",
        default="5002",
        help="SRS server port.",
    )

    parser.add_argument(
        "--volume",
        default="1.0",
        help="Playback volume multiplier.",
    )

    parser.add_argument(
        "--client-name",
        default="NASGroup File Player",
        help="SRS client name.",
    )

    parser.add_argument(
        "--external-awacs-password",
        default="",
        help="Optional SRS external AWACS mode password.",
    )

    args = parser.parse_args()

    audio_file = Path(args.file).expanduser().resolve()
    srs_exe = Path(args.exe).expanduser().resolve()

    if not audio_file.exists():
        print(f"ERROR: Audio file not found: {audio_file}", file=sys.stderr)
        return 1

    if not srs_exe.exists():
        print(f"ERROR: SRS sender executable not found: {srs_exe}", file=sys.stderr)
        return 1

    ffmpeg = find_ffmpeg(args.ffmpeg)
    if not ffmpeg:
        print(
            "ERROR: ffmpeg was not found. Install ffmpeg or pass --ffmpeg=\"C:\\path\\to\\ffmpeg.exe\"",
            file=sys.stderr,
        )
        return 1

    pcm_file = None

    try:
        pcm_file = convert_to_pcm_f32le_16k_mono(audio_file, ffmpeg)

        command = [
            str(srs_exe),
            f"-file={pcm_file}",
            f"-srs-address={args.host}:{args.port}",
            f"-client-name={args.client_name}",
            f"-coalition={args.coalition}",
            f"-frequency={args.frequency}",
            f"-modulation={args.modulation}",
            f"-volume={args.volume}",
        ]

        if args.external_awacs_password:
            command.append(f"-external-awacs-password={args.external_awacs_password}")

        print("Running SRS sender:")
        print(" ".join(command))

        process = subprocess.run(
            command,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
        )

        if process.stdout:
            print(process.stdout)

        if process.returncode != 0:
            print(
                f"ERROR: SRS sender failed with exit code {process.returncode}",
                file=sys.stderr,
            )
            return process.returncode

        print("Done.")
        return 0

    except Exception as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1

    finally:
        if pcm_file is not None:
            try:
                temp_dir = pcm_file.parent
                pcm_file.unlink(missing_ok=True)
                temp_dir.rmdir()
            except Exception:
                pass


if __name__ == "__main__":
    raise SystemExit(main())