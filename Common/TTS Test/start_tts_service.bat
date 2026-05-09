@echo off
setlocal

REM Always run from the folder this .bat file is in.
cd /d "%~dp0"

REM External AWACS password for SRS.
REM Replace this value with your real SRS External AWACS password.
set "SRS_EXTERNAL_AWACS_PASSWORD=blue"

REM Service settings.
set "TTS_SERVICE_HOST=127.0.0.1"
set "TTS_SERVICE_PORT=8765"
set "TTS_SERVICE_INSTANCE=main"
set "TTS_SERVICE_SRS_BACKEND=go_native"
set "SRS_HOST=96.32.24.78"
set "SRS_GO_SENDER_EXE=%~dp0srs-tts-send.exe"

if not exist "%~dp0tts_service.py" (
    echo ERROR: tts_service.py was not found in:
    echo %~dp0
    pause
    exit /b 1
)

if not exist "%SRS_GO_SENDER_EXE%" (
    echo ERROR: srs-tts-send.exe was not found:
    echo %SRS_GO_SENDER_EXE%
    pause
    exit /b 1
)

py -u "%~dp0tts_service.py" ^
  --host "%TTS_SERVICE_HOST%" ^
  --port %TTS_SERVICE_PORT% ^
  --instance "%TTS_SERVICE_INSTANCE%" ^
  --srs-backend "%TTS_SERVICE_SRS_BACKEND%" ^
  --srs-host "%SRS_HOST%" ^
  --srs-go-sender "%SRS_GO_SENDER_EXE%" ^
  --external-awacs-password "%SRS_EXTERNAL_AWACS_PASSWORD%" ^
  --inbox-dir "%USERPROFILE%\Saved Games\DCS.Test\Logs\tts_inbox\main"

pause