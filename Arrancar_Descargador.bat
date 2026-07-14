@echo off
title Lanzador de Gestor de Descargas MUNDO
:: Obtiene la ruta exacta de la carpeta donde esta guardado este archivo .bat
cd /d "%~dp0"
:: Lanza PowerShell de forma transparente, salta politicas y ejecuta el script .ps1
powershell -NoProfile -ExecutionPolicy Bypass -File "descargar_musica.ps1"
pause
