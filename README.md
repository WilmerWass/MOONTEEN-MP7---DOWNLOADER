# 🎵 WASSLink MPDL — Media Player Downloader

> **WASSLink MPDL** es una herramienta de consola (CLI) totalmente **portable, modular y ligera** diseñada para descargar audio y video en alta calidad desde múltiples plataformas (YouTube, TikTok, Instagram y más) sin necesidad de instalación ni dependencias externas en el sistema.

---

## ✨ Características Principales

* 🚀 **100% Portable:** No requiere instalación de Python, Node.js ni componentes administrativos. Corre directamente desde cualquier unidad USB o carpeta.
* 📂 **Organización Automática Inteligente:** Clasifica las descargas por Red Social y Creador/Artista:
  `Descargas / [Red Social] / [Creador_o_Artista] / [Título].ext`
* 🎨 **Inyección Automática de Metadatos y Carátulas:** Convierte a MP3 (320 kbps) e inyecta la portada (thumbnail), artista, título y etiquetas ID3 de forma nativa.
* 🛡️ **Historiales Separados:** Mantiene registros de descargas independientes para audio (`historial_audio.txt`) y video (`historial_video.txt`), permitiendo obtener el MP3 y el MP4 del mismo enlace sin bloqueos.
* ⚡ **Control de Rendimiento Multihilo:** Configuración dinámica de hilos (1 a 5+) para adaptar la velocidad según tu conexión.
* 🔄 **Actualizador del Motor con 1-Clic:** Opción integrada para actualizar `yt-dlp.exe` en tiempo real y prevenir fallos por cambios en las APIs de las plataformas.

---

## 🛠️ Estructura del Proyecto

```text
WASSLink-MPDL/
├── engine/
│   ├── yt-dlp.exe            # Motor principal de extracción
│   └── ffmpeg.exe            # Procesador/convertidor de medios
├── scripts/
│   └── main.ps1              # Lógica principal del sistema en PowerShell
├── downloads/                # Carpeta predeterminada de salida
├── config_wasslink.json      # Configuración del usuario (Se auto-genera)
├── playlists.txt             # Lista para procesamiento de enlaces en lote
└── WASSLink_MPDL.bat         # Lanzador ejecutable principal
