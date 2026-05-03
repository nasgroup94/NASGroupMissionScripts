@echo off
cd /d "C:\NASGroup\NASGroupMissionScripts\Common\TTS Test"

py -u ".\tts_service.py" --instance main --port 8765

pause