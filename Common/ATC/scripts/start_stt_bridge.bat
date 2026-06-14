@echo off
setlocal

cd /d "%~dp0"

set "NASG_ATC_ROOT=%~dp0.."
set "NASG_ATC_BIN=%NASG_ATC_ROOT%\bin"
set "NASG_ATC_PYTHON=%NASG_ATC_ROOT%\python"
set "NASG_ATC_TMP=%NASG_ATC_ROOT%\tmp"

set "SRS_EXTERNAL_AWACS_PASSWORD=blue"

rem Set to 1 to enable verbose/debug STT bridge logging, or 0 to disable it.
set "NASG_STT_DEBUG_LOGS=0"

rem CPU affinity mask for the STT/Whisper worker.
rem F000 = logical CPU threads 12-15 on a 16-thread CPU.
set "NASG_STT_AFFINITY_MASK=3000"

rem Limit common Python/ML worker thread pools so Whisper does not fight DCS.
set "OMP_NUM_THREADS=2"
set "OPENBLAS_NUM_THREADS=2"
set "MKL_NUM_THREADS=2"
set "NUMEXPR_NUM_THREADS=2"

if not exist "%NASG_ATC_TMP%" mkdir "%NASG_ATC_TMP%"

echo [%date% %time%] start_stt_bridge.bat launched > "%NASG_ATC_TMP%\nasg_stt_bridge_process.log"
echo Working directory: %cd% >> "%NASG_ATC_TMP%\nasg_stt_bridge_process.log"
echo ATC root: %NASG_ATC_ROOT% >> "%NASG_ATC_TMP%\nasg_stt_bridge_process.log"
echo STT affinity mask: %NASG_STT_AFFINITY_MASK% >> "%NASG_ATC_TMP%\nasg_stt_bridge_process.log"
echo STT debug logs: %NASG_STT_DEBUG_LOGS% >> "%NASG_ATC_TMP%\nasg_stt_bridge_process.log"
echo OMP_NUM_THREADS: %OMP_NUM_THREADS% >> "%NASG_ATC_TMP%\nasg_stt_bridge_process.log"
echo OPENBLAS_NUM_THREADS: %OPENBLAS_NUM_THREADS% >> "%NASG_ATC_TMP%\nasg_stt_bridge_process.log"
echo MKL_NUM_THREADS: %MKL_NUM_THREADS% >> "%NASG_ATC_TMP%\nasg_stt_bridge_process.log"
echo NUMEXPR_NUM_THREADS: %NUMEXPR_NUM_THREADS% >> "%NASG_ATC_TMP%\nasg_stt_bridge_process.log"

if exist "%NASG_ATC_TMP%\nasg_stt_bridge.lock" (
    echo STT bridge lock already exists; not starting another worker. >> "%NASG_ATC_TMP%\nasg_stt_bridge_process.log"
    exit /b 0
)

if exist "%NASG_ATC_TMP%\nasg_stt_bridge.stop" del "%NASG_ATC_TMP%\nasg_stt_bridge.stop"

set "STT_VERBOSE_ARG="
if "%NASG_STT_DEBUG_LOGS%"=="1" set "STT_VERBOSE_ARG=--verbose"

start /b /affinity %NASG_STT_AFFINITY_MASK% /wait py -u "%NASG_ATC_PYTHON%\srs_stt_bridge.py" ^
  --config-file "%NASG_ATC_TMP%\nasg_atc_stt_config.json" ^
  --stop-file "%NASG_ATC_TMP%\nasg_stt_bridge.stop" ^
  --lock-file "%NASG_ATC_TMP%\nasg_stt_bridge.lock" ^
  --srs-listener "%NASG_ATC_BIN%\srs-stt-listen.exe" ^
  --external-awacs-password "%SRS_EXTERNAL_AWACS_PASSWORD%" ^
  --stt-backend faster-whisper ^
  --cleanup-audio-retention-seconds 3600 ^
  --cleanup-interval-seconds 300 ^
  --delete-processed-audio ^
  %STT_VERBOSE_ARG% ^
  >> "%NASG_ATC_TMP%\nasg_stt_bridge_process.log" 2>&1

set "NASG_STT_BRIDGE_EXIT_CODE=%ERRORLEVEL%"
echo [%date% %time%] start_stt_bridge.bat exiting with code %NASG_STT_BRIDGE_EXIT_CODE% >> "%NASG_ATC_TMP%\nasg_stt_bridge_process.log"

exit /b %NASG_STT_BRIDGE_EXIT_CODE%