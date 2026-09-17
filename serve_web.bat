@echo off
REM Serves the prebuilt web bundle so it can be opened in a real browser to
REM verify the release output (not the dev server).
set "PATH=C:\flutter\flutter\bin;C:\Program Files\Git\cmd;C:\Program Files\Git\bin;C:\Windows\System32;C:\Windows;C:\Windows\System32\WindowsPowerShell\v1.0"
cd /d "%~dp0build\web"
flutter run -d web-server --web-port 8088 --web-hostname 127.0.0.1 --release
