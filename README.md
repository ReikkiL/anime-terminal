# 🎌 AnimePlay - Reproductor de Anime en Terminal

Script interactivo para ver anime en español directamente desde la terminal de Linux, usando **JKAnime** como fuente.

## ✨ Características

- 🔍 **Búsqueda interactiva** de anime por nombre
- 📺 **Selección de temporadas** (si están disponibles)
- 📝 **Selección de episodios** específicos
- 🌐 **Audio en español** (cuando está disponible)
- 📖 **Subtítulos automáticos** en español
- 🎨 **Interfaz colorida y amigable** en terminal
- ▶️ **Reproducción continua** (siguiente episodio sin salir)
- 🔗 **Reproducción por URL** directa

## 📋 Requisitos

- Linux (Arch, Cachyos, etc.)
- `mpv` - Reproductor de video
- `yt-dlp` - Descargador de streams
- `curl` - Cliente HTTP
- `jq` - Procesador JSON
- `bash` o `fish` shell

## 🚀 Instalación

### 1. Instala las dependencias (Cachyos/Arch)

```bash
sudo pacman -S mpv curl jq yt-dlp
```

### 2. Clona el repositorio

```bash
git clone https://github.com/ReikkiL/anime-terminal.git
cd anime-terminal
chmod +x animeplay.sh
```

### 3. Ejecuta el script

```bash
./animeplay.sh
```

## 📖 Cómo usar

1. **Selecciona "Buscar anime por nombre"**
2. **Escribe el nombre del anime** (ej: "Naruto", "One Piece", "Death Note")
3. **Elige de los resultados encontrados**
4. **Selecciona temporada** (si hay varias disponibles)
5. **Elige el episodio** que quieres ver
6. **¡A disfrutar!** 🎌

## ⌨️ Controles en mpv (mientras ves)

| Tecla | Acción |
|-------|--------|
| `q` | Cerrar video |
| `f` | Pantalla completa |
| `Space` | Pausa/Reproducción |
| `→` / `←` | Avanzar/Retroceder 5 segundos |
| `,` / `.` | Retroceder/Avanzar frame a frame |
| `c` | Mostrar/ocultar subtítulos |
| `j` / `J` | Ciclo de subtítulos |
| `+` / `-` | Aumentar/disminuir volumen |

## 📚 Opciones del menú

- **Buscar anime** - Buscar por nombre en JKAnime
- **Reproducir por URL** - Introducir URL directa del episodio
- **Historial** - Ver búsquedas recientes (en desarrollo)
- **Configuración** - Ajustes de audio, subtítulos y caché
- **Salir** - Cerrar el programa

## ⚙️ Configuración

El script almacena caché en: `~/.cache/animeplay/`

Para limpiar caché desde el menú:
1. Selecciona **Configuración**
2. Elige **Limpiar caché**

O desde terminal:
```bash
rm -rf ~/.cache/animeplay/
```

## 🌍 Sitio de origen

Este script usa **JKAnime** como fuente de anime en español.

⚠️ **Nota legal**: Úsalo responsablemente y respeta los derechos de autor. Si es posible, apoya plataformas oficiales de streaming.

## 🛠️ Solución de problemas

### Error: "comando no encontrado"

```bash
# Verifica que el script tiene permisos
chmod +x animeplay.sh

# O ejecuta con bash directamente
bash animeplay.sh
```

### No se encuentran episodios

- Verifica tu conexión a internet
- Intenta otro anime
- La estructura de JKAnime puede cambiar ocasionalmente

### Sin audio en español

- El audio disponible depende de los episodios en JKAnime
- Los subtítulos en español deberían funcionar automáticamente

## 📝 Créditos

- **mpv** - Reproductor de video
- **yt-dlp** - Descargador de streams
- **JKAnime** - Fuente de contenido

## 📄 Licencia

Este proyecto es de código abierto. Úsalo bajo tu responsabilidad.

## 🤝 Contribuciones

¿Encuentras bugs o tienes sugerencias? Abre un issue o un pull request.

---

**¡Que disfrutes viendo anime! 🎌**
