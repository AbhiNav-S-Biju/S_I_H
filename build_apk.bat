@echo off
REM Helper used to run the Android release build with the toolchain on this machine.
set "PATH=C:\flutter\flutter\bin;C:\Program Files\Git\cmd;C:\Program Files\Git\bin;C:\Windows\System32;C:\Windows;C:\Windows\System32\WindowsPowerShell\v1.0"
set "JAVA_HOME=C:\Program Files\Android\Android Studio\jbr"
cd /d "%~dp0"
flutter build apk --release
