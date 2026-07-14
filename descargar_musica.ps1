# Force UTF-8 encoding in PowerShell to handle titles properly
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# --- ARCHIVOS DE CONFIGURACIÓN Y ESTADO ---
$CONFIG_FILE = "config_downloader.txt"
$ARCHIVO_PLAYLISTS = "playlists.txt"

# Valores predeterminados
$CARPETA_DESTINO = "$HOME\Music\MUNDO\Descargas"
$AlertaDiscoPorcentaje = 11

# Cargar configuración guardada
if (Test-Path $CONFIG_FILE) {
    $Conf = Get-Content $CONFIG_FILE | ConvertFrom-StringData
    if ($Conf.Destino) { $CARPETA_DESTINO = $Conf.Destino }
    if ($Conf.AlertaDisco) { $AlertaDiscoPorcentaje = [int]$Conf.AlertaDisco }
}

# Crear carpetas si no existen
if (-not (Test-Path $CARPETA_DESTINO)) { New-Item -ItemType Directory -Path $CARPETA_DESTINO | Out-Null }
if (-not (Test-Path $ARCHIVO_PLAYLISTS)) { New-Item -ItemType File -Path $ARCHIVO_PLAYLISTS | Out-Null }

function Guardar-Configuracion {
    "Destino=$CARPETA_DESTINO`nAlertaDisco=$AlertaDiscoPorcentaje" | Out-File -FilePath $CONFIG_FILE -Encoding utf8
}

function Obtener-EspacioDisco {
    $LetraUnidad = [System.IO.Path]::GetPathRoot($CARPETA_DESTINO).Replace("\","")
    $Disco = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$LetraUnidad'"
    $Total = $Disco.Size
    $Libre = $Disco.FreeSpace
    $PorcentajeLibre = [math]::Round(($Libre / $Total) * 100, 1)
    return [PSCustomObject]@{ LibreGB = [math]::Round($Libre/1GB, 1); Porcentaje = $PorcentajeLibre; Unidad = $LetraUnidad }
}

function Mostrar-MenuConfig {
    do {
        Clear-Host
        Write-Host "==========================================================" -ForegroundColor Cyan
        Write-Host "                PANEL DE CONFIGURACIÓN                    " -ForegroundColor Cyan
        Write-Host "==========================================================" -ForegroundColor Cyan
        Write-Host " 1. Cambiar carpeta de descargas" -ForegroundColor White
        Write-Host "    [Actual: $CARPETA_DESTINO]" -ForegroundColor Gray
        Write-Host " 2. Ajustar límite de alerta de almacenamiento" -ForegroundColor White
        Write-Host "    [Actual: Detener si queda menos del $AlertaDiscoPorcentaje%]" -ForegroundColor Gray
        Write-Host " 3. Volver al menú principal" -ForegroundColor White
        Write-Host "==========================================================" -ForegroundColor Cyan
        
        $Opcion = Read-Host "Seleccione una opción (1-3)"
        switch ($Opcion) {
            "1" {
                $NuevaRuta = Read-Host "Introduce la ruta completa de la nueva carpeta"
                if (-not [string]::IsNullOrWhiteSpace($NuevaRuta)) {
                    $CARPETA_DESTINO = $NuevaRuta
                    if (-not (Test-Path $CARPETA_DESTINO)) { New-Item -ItemType Directory -Path $CARPETA_DESTINO | Out-Null }
                    Guardar-Configuracion
                }
            }
            "2" {
                $NuevoPorcentaje = Read-Host "Introduce el porcentaje mínimo de espacio libre deseado (ej. 11)"
                if ($NuevoPorcentaje -match '^\d+$') { $Global:AlertaDiscoPorcentaje = [int]$NuevoPorcentaje; Guardar-Configuracion }
            }
            "3" { return }
        }
    } while ($true)
}

# --- BUCLE PRINCIPAL ---
$PrimerArranque = $true

do {
    Clear-Host
    $DiscoInfo = Obtener-EspacioDisco
    $ColorDisco = if ($DiscoInfo.Porcentaje -le $AlertaDiscoPorcentaje) { "Red" } else { "Gray" }

    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "         GESTOR DE DESCARGAS MINIMALISTA (MUNDO)          " -ForegroundColor Cyan
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host " DESTINO: $CARPETA_DESTINO" -ForegroundColor Gray
    Write-Host " DISCO ($($DiscoInfo.Unidad)): $($DiscoInfo.LibreGB) GB libres ($($DiscoInfo.Porcentaje)%)" -ForegroundColor $ColorDisco
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host " [1] Pegar un enlace manualmente ahora mismo" -ForegroundColor White
    Write-Host " [2] Procesar lista de '$ARCHIVO_PLAYLISTS' [Auto-inicio]" -ForegroundColor White
    Write-Host " [3] Configuración básica" -ForegroundColor White
    Write-Host " [4] Salir" -ForegroundColor White
    Write-Host "==========================================================" -ForegroundColor Cyan
    
    $MenuPrincipal = $null
    
    if ($PrimerArranque) {
        $PrimerArranque = $false
        Write-Host "Iniciando lista automática en 5 segundos... (Presiona cualquier opción para cancelar)" -ForegroundColor Yellow
        $Timeout = 5
        while ($Timeout -gt 0 -and -not $Host.UI.RawUI.KeyAvailable) {
            Write-Host "$Timeout... " -NoNewline -ForegroundColor Yellow
            Start-Sleep -Seconds 1
            $Timeout--
        }
        if (-not $Host.UI.RawUI.KeyAvailable) {
            $MenuPrincipal = "2"
            Write-Host "`nArranque automático seleccionado..." -ForegroundColor Green
            Start-Sleep -Milliseconds 500
        } else {
            $Key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            $MenuPrincipal = $Key.Character
        }
    } else {
        $MenuPrincipal = Read-Host "Seleccione una opción (1-4)"
    }
    
    if ($MenuPrincipal -eq "3") { Mostrar-MenuConfig; continue }
    if ($MenuPrincipal -eq "4") { break }
    
    $EnlacesBrutos = @()
    if ($MenuPrincipal -eq "1") {
        $EntradaUsuario = Read-Host "Pega el enlace de YouTube aquí"
        if (-not [string]::IsNullOrWhiteSpace($EntradaUsuario)) { $EnlacesBrutos += $EntradaUsuario }
    }
    elseif ($MenuPrincipal -eq "2") {
        $EnlacesBrutos = Get-Content $ARCHIVO_PLAYLISTS | Where-Object { -not [string]::IsNullOrWhiteSpace($_) -and -not $_.StartsWith("#") }
        if (-not $EnlacesBrutos) {
            Write-Host "`n[!] NO HAY LINKS EN EL ARCHIVO '$ARCHIVO_PLAYLISTS'." -ForegroundColor Red
            Read-Host "Presiona Enter para continuar"
            continue
        }
    }

    if ($EnlacesBrutos.Count -gt 0) {
        Write-Host "`n[*] Analizando enlaces..." -ForegroundColor Yellow
        
        $RutaSalidaYtdl = Join-Path $CARPETA_DESTINO "%(uploader)s\%(title)s.%(ext)s"
        $ArchivoHistorial = Join-Path $CARPETA_DESTINO "descargados_historial.txt"
        
        foreach ($Url in $EnlacesBrutos) {
            $EstadoDisco = Obtener-EspacioDisco
            if ($EstadoDisco.Porcentaje -le $AlertaDiscoPorcentaje) {
                Write-Host "`n[ALERTA] ¡Almacenamiento crítico ($($EstadoDisco.Porcentaje)%)!" -ForegroundColor Red
                while ((Obtener-EspacioDisco).Porcentaje -le $AlertaDiscoPorcentaje) { Start-Sleep -Seconds 5 }
                Write-Host "[*] Espacio recuperado. Reanudando..." -ForegroundColor Green
            }

            Write-Host "`n=======================================================" -ForegroundColor Cyan
            Write-Host "                PROCESANDO PLAYLIST/MIX                " -ForegroundColor Yellow
            Write-Host "=======================================================" -ForegroundColor Cyan

            $Parametros = @(
                "-x", "--audio-format", "mp3", "--audio-quality", "0", "--ignore-errors",
                "--no-overwrites", "--download-archive", $ArchivoHistorial,
                "--yes-playlist", "--concurrent-fragments", "3", "--no-warnings",
                "-o", $RutaSalidaYtdl, $Url,
                "--progress-template", "[barra] %(progress._percent_str)s a %(progress._speed_str)s ETA %(progress._eta_str)s"
            )

            $ProgresoActivo = $false
            $RutaImpresa = $false  # Bandera anti-redundancia

            & python -m yt_dlp @Parametros 2>$null | ForEach-Object {
                $Linea = $_
                
                if ($Linea -match "Extracting URL" -or $Linea -match "Downloading playlist" -or $Linea -match "Downloading API JSON" -or $Linea -match "Downloading webpage" -or $Linea -match "Deleting original file" -or $Linea -match "ExtractAudio") {
                    # Ignorar metadatos
                }
                elseif ($Linea -match "has already been recorded in the archive") {
                    if ($ProgresoActivo) { Write-Host ""; $ProgresoActivo = $false }
                    $TextoLimpio = $Linea.Replace("[download] ","")
                    if ($TextoLimpio -match "^[a-zA-Z0-9_-]{11}:") {
                        $TextoLimpio = ($TextoLimpio -split ":\s+", 2)[1]
                    }
                    $TituloCorto = ($TextoLimpio -split "has already been recorded")[0].Trim()
                    Write-Host "[YA TIENES] $TituloCorto" -ForegroundColor DarkGray
                }
                elseif ($Linea -match "Destination: " -and $Linea -like "*.webm*") {
                    if ($ProgresoActivo) { Write-Host ""; $ProgresoActivo = $false }
                    $Global:CarpetaArtistaActual = [System.IO.Path]::GetFileName([System.IO.Path]::GetDirectoryName(($Linea -split "Destination: ")[1]))
                    $CancionActual = [System.IO.Path]::GetFileNameWithoutExtension(($Linea -split "Destination: ")[1])
                    Write-Host "`n-------------------------------------------------------" -ForegroundColor Cyan
                    Write-Host "[DESCARGANDO] $CancionActual" -ForegroundColor Green
                    Write-Host "-------------------------------------------------------" -ForegroundColor Cyan
                    $RutaImpresa = $false # Reiniciamos la bandera para el nuevo archivo
                }
                elseif ($Linea -match "\[barra\]") {
                    $Progreso = $Linea.Replace("[barra]","").Trim()
                    
                    # Si ya se imprimió la ruta, no seguimos mostrando variaciones flojas del 100% final
                    if (-not $RutaImpresa) {
                        Write-Host "`r$Progreso" -NoNewline
                        $ProgresoActivo = $true
                    }
                    
                    # Capturamos el primer 100% real
                    if ($Progreso -match "100\.0%" -and -not $RutaImpresa) {
                        Write-Host "" 
                        $RutaFinalCompleta = Join-Path $CARPETA_DESTINO $Global:CarpetaArtistaActual
                        Write-Host "   -> Guardado en: $RutaFinalCompleta" -ForegroundColor Gray
                        $RutaImpresa = $true
                        $ProgresoActivo = $false
                    }
                }
            }

            if ($ProgresoActivo) { Write-Host "" }

            Write-Host "=======================================================" -ForegroundColor Cyan
        }
        
        Write-Host "`n==========================================================" -ForegroundColor Cyan
        Write-Host " ¡Todas las canciones nuevas se procesaron! " -ForegroundColor Green
        Write-Host "==========================================================" -ForegroundColor Cyan
        
        if ($MenuPrincipal -eq "2") {
            Write-Host " ¿Qué deseas hacer con el archivo '$ARCHIVO_PLAYLISTS'?" -ForegroundColor White
            Write-Host " [1] Borrar todo el contenido (Dejarlo limpio para la próxima)" -ForegroundColor Yellow
            Write-Host " [2] Dejar los links actuales intactos" -ForegroundColor White
            $AccionTxt = Read-Host "Selecciona una opción (1-2)"
            if ($AccionTxt -eq "1") {
                Clear-Content -Path $ARCHIVO_PLAYLISTS -ErrorAction SilentlyContinue
                Write-Host "¡Archivo vaciado!" -ForegroundColor Green
                Start-Sleep -Seconds 2
            }
        } else {
            Read-Host "Presiona Enter para volver al menú"
        }
    }
} while ($true)
