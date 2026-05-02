import asyncio
import base64
import json
import websockets

async def main():
    uri = "ws://96.32.24.78:8080"
    async with websockets.connect(uri) as ws:
        text = "hello from python"
        await ws.send(text)

        message = await ws.recv()
        data = json.loads(message)

        if data.get("success") and data.get("audio"):
            audio_bytes = base64.b64decode(data["audio"])
            filename = f"output.{data.get('format', 'ogg')}"
            with open(filename, "wb") as f:
                f.write(audio_bytes)
            print("Saved audio to", filename)
        else:
            print("Error:", data.get("error"))

if __name__ == "__main__":
    asyncio.run(main())