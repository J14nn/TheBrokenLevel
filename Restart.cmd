@echo off

set "ZIP=%~dp0..\TheBrokenLevel.zip"
set "TARGET=%~dp0.."

powershell -NoProfile -Command "Expand-Archive -LiteralPath '%ZIP%' -DestinationPath '%TARGET%' -Force"

pause
