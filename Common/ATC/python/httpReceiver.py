import json
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

EVENT_FILE = Path(r"C:\NASGroup\NASGroupMissionScripts\Common\ATC\tmp\nasg_ground_control_events.jsonl")

class EventHandler(BaseHTTPRequestHandler):
    def send_json(self, status_code: int, payload: dict):
        body = json.dumps(payload).encode("utf-8")
        self.send_response(status_code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_POST(self):
        if self.path != "/events":
            self.send_json(404, {"success": False, "error": "not found"})
            return

        try:
            length = int(self.headers.get("Content-Length", "0"))
            payload = json.loads(self.rfile.read(length).decode("utf-8"))

            EVENT_FILE.parent.mkdir(parents=True, exist_ok=True)

            with EVENT_FILE.open("a", encoding="utf-8") as file:
                file.write(json.dumps(payload, separators=(",", ":")))
                file.write("\n")

            self.send_json(202, {"success": True})
        except Exception as exc:
            self.send_json(500, {"success": False, "error": str(exc)})

if __name__ == "__main__":
    server = ThreadingHTTPServer(("0.0.0.0", 8787), EventHandler)
    print("NASG ATC event receiver running on http://0.0.0.0:8787/events", flush=True)
    server.serve_forever()