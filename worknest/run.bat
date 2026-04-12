@echo off
echo Killing stuck Gradle/Java processes...
taskkill /F /IM java.exe 2>nul
taskkill /F /IM javaw.exe 2>nul
cd /d C:\wn
flutter run
