@echo off
title WASSLink MPDL - Media Player Downloader
color 0A
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "scripts\main.ps1"
pause
