@echo off
setlocal

cd /d "%~dp0"

set "NASG_ATC_ROOT=%~dp0.."
set "NASG_ATC_BIN=%NASG_ATC_ROOT%\bin"
set "NASG_ATC_PYTHON=%NASG_ATC_ROOT%\python"
set "NASG_ATC_TMP=%NASG_ATC_ROOT%\tmp"

set "TTS_SERVICE_HOST=127.0.0.1"
set "TTS_SERVICE_PORT=8765"
set "TTS_SERVICE_INSTANCE=main"
set "TTS_SERVICE_SRS_BACKEND=go_native"
set "SRS_HOST=127.0.0.1"
set "SRS_EXTERNAL_AWACS_PASSWORD=blue"

rem Set to 1 to enable verbose/debug TTS service logging, or 0 to disable it.
set "NASG_TTS_DEBUG_LOGS=0"

rem CPU affinity mask for the TTS service.
rem C000 = logical CPU threads 14-15 on a 16-thread CPU.
set "NASG_TTS_AFFINITY_MASK=C000"

rem Keep Python/audio helper libraries from spawning too many worker threads.
set "OMP_NUM_THREADS=1"
set "OPENBLAS_NUM_THREADS=1"
set "MKL_NUM_THREADS=1"
set "NUMEXPR_NUM_THREADS=1"

set "SRS_GO_SENDER_EXE=%NASG_ATC_BIN%\srs-tts-send.exe"
set "TTS_SERVICE_SCRIPT=%NASG_ATC_PYTHON%\tts_service.py"
set "TTS_INBOX_DIR=C:\Users\naval\Saved Games\DCS.Test\Logs\tts_inbox\main"
set "TTS_SERVICE_LOG=%NASG_ATC_TMP%\nasg_tts_service_process.log"
set "TTS_SERVICE_STOP_FILE=%NASG_ATC_TMP%\nasg_tts_service.stop"
set "TTS_UPSTREAM_URI=ws://96.32.24.78:8080"

if not exist "%NASG_ATC_TMP%" mkdir "%NASG_ATC_TMP%"

if exist "%TTS_SERVICE_STOP_FILE%" del "%TTS_SERVICE_STOP_FILE%"

echo [%date% %time%] start_tts_service.bat launched > "%TTS_SERVICE_LOG%"
echo Working directory: %cd% >> "%TTS_SERVICE_LOG%"
echo ATC root: %NASG_ATC_ROOT% >> "%TTS_SERVICE_LOG%"
echo TTS affinity mask: %NASG_TTS_AFFINITY_MASK% >> "%TTS_SERVICE_LOG%"
echo TTS service script: %TTS_SERVICE_SCRIPT% >> "%TTS_SERVICE_LOG%"
echo TTS stop file: %TTS_SERVICE_STOP_FILE% >> "%TTS_SERVICE_LOG%"
echo SRS GO sender: %SRS_GO_SENDER_EXE% >> "%TTS_SERVICE_LOG%"
echo TTS inbox dir: %TTS_INBOX_DIR% >> "%TTS_SERVICE_LOG%"
echo TTS backend: %TTS_SERVICE_SRS_BACKEND% >> "%TTS_SERVICE_LOG%"
echo TTS debug logs: %NASG_TTS_DEBUG_LOGS% >> "%TTS_SERVICE_LOG%"
echo OMP_NUM_THREADS: %OMP_NUM_THREADS% >> "%TTS_SERVICE_LOG%"
echo OPENBLAS_NUM_THREADS: %OPENBLAS_NUM_THREADS% >> "%TTS_SERVICE_LOG%"
echo MKL_NUM_THREADS: %MKL_NUM_THREADS% >> "%TTS_SERVICE_LOG%"
echo NUMEXPR_NUM_THREADS: %NUMEXPR_NUM_THREADS% >> "%TTS_SERVICE_LOG%"

if not exist "%TTS_SERVICE_SCRIPT%" (
    echo ERROR: tts_service.py was not found: >> "%TTS_SERVICE_LOG%"
    echo %TTS_SERVICE_SCRIPT% >> "%TTS_SERVICE_LOG%"
    echo ERROR: tts_service.py was not found:
    echo %TTS_SERVICE_SCRIPT%
    pause
    exit /b 1
)

if not exist "%SRS_GO_SENDER_EXE%" (
    echo ERROR: srs-tts-send.exe was not found: >> "%TTS_SERVICE_LOG%"
    echo %SRS_GO_SENDER_EXE% >> "%TTS_SERVICE_LOG%"
    echo ERROR: srs-tts-send.exe was not found:
    echo %SRS_GO_SENDER_EXE%
    pause
    exit /b 1
)

if not exist "%TTS_INBOX_DIR%" mkdir "%TTS_INBOX_DIR%"

netstat -ano | findstr /R /C:":%TTS_SERVICE_PORT% .*LISTENING" >nul
if not errorlevel 1 (
    echo TTS service appears to already be listening on port %TTS_SERVICE_PORT%; not starting another worker. >> "%TTS_SERVICE_LOG%"
    exit /b 0
)

set "TTS_VERBOSE_ARG="
if "%NASG_TTS_DEBUG_LOGS%"=="1" set "TTS_VERBOSE_ARG=--verbose"

set "TTS_PYTHON_COMMAND=py -u "%TTS_SERVICE_SCRIPT%" --upstream-uri "%TTS_UPSTREAM_URI%" --host "%TTS_SERVICE_HOST%" --port %TTS_SERVICE_PORT% --instance "%TTS_SERVICE_INSTANCE%" --srs-backend "%TTS_SERVICE_SRS_BACKEND%" --srs-host "%SRS_HOST%" --srs-go-sender "%SRS_GO_SENDER_EXE%" --external-awacs-password "%SRS_EXTERNAL_AWACS_PASSWORD%" --inbox-dir "%TTS_INBOX_DIR%" --stop-file "%TTS_SERVICE_STOP_FILE%" %TTS_VERBOSE_ARG%"

echo Starting TTS service worker... >> "%TTS_SERVICE_LOG%"
echo Command: %TTS_PYTHON_COMMAND% >> "%TTS_SERVICE_LOG%"

start /b /affinity %NASG_TTS_AFFINITY_MASK% /wait cmd /c "%TTS_PYTHON_COMMAND% >> "%TTS_SERVICE_LOG%" 2>&1"

set "NASG_TTS_SERVICE_EXIT_CODE=%ERRORLEVEL%"
echo [%date% %time%] start_tts_service.bat exiting with code %NASG_TTS_SERVICE_EXIT_CODE% >> "%TTS_SERVICE_LOG%"

exit /b %NASG_TTS_SERVICE_EXIT_CODE%