@echo off
REM Helper used to run Flutter builds with the toolchain on this machine.
set "PATH=C:\flutter\flutter\bin;C:\Program Files\Git\cmd;C:\Program Files\Git\bin;C:\Windows\System32;C:\Windows;C:\Windows\System32\WindowsPowerShell\v1.0"
cd /d "%~dp0"
flutter build web --release --base-href /S_I_H/
