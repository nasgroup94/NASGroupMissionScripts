@echo off
rem stop_services.bat
rem Signals the NASG TTS service and STT bridge to exit cleanly by
rem writing the stop files each service polls.  Run this manually if you
rem need to kill the services without ending the DCS mission.

setlocal
set "NASG_ATC_TMP=%~dp0..\tmp"

echo Stopping NASG ATC services...

if not exist "%NASG_ATC_TMP%" (
    echo Tmp dir not found: %NASG_ATC_TMP%
    echo Services may not be running.
    goto :done
)

echo. > "%NASG_ATC_TMP%\nasg_tts_service.stop"
echo TTS service stop file written.

echo. > "%NASG_ATC_TMP%\nasg_stt_bridge.stop"
echo STT bridge stop file written.

:done
echo Done.  Services will exit within a few seconds.
timeout /t 3 /nobreak >nul
exit /b 0
