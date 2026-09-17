@echo off
REM Reproduces the exact GitHub Actions web build sequence in a clean clone of
REM the repo (C:\Users\Abhinav\SIH\ci_test) to find out why
REM .github/workflows/deploy-web.yml fails on the runner.
set "PATH=C:\flutter\flutter\bin;C:\Program Files\Git\cmd;C:\Program Files\Git\bin;C:\Windows\System32;C:\Windows;C:\Windows\System32\WindowsPowerShell\v1.0"
REM Private pub cache so no other dart process can hold the cache lock.
set "PUB_CACHE=C:\Users\Abhinav\SIH\pubcache_ci"
cd /d C:\Users\Abhinav\SIH\ci_test

echo ===FLUTTER VERSION=== > ci_build.log
flutter --version >> ci_build.log 2>&1

echo ===PUB GET=== >> ci_build.log
flutter pub get >> ci_build.log 2>&1
echo ===PUBGET EXIT %ERRORLEVEL%=== >> ci_build.log

echo ===BUILD WEB=== >> ci_build.log
flutter build web --release --base-href /S_I_H/ --pwa-strategy=none >> ci_build.log 2>&1
echo ===BUILD EXIT %ERRORLEVEL%=== >> ci_build.log
