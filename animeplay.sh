#!/bin/bash

# Script interactivo para ver anime en terminal desde JKAnime
# Requiere: mpv, yt-dlp, curl, jq
# Instalación: sudo pacman -S mpv curl jq yt-dlp

set -e

# Colores para mejor visualización
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Configuración
JKANIME_URL="https://jkanime.net"
CACHE_DIR="${HOME}/.cache/animeplay"
CACHE_FILE="${CACHE_DIR}/anime_cache.json"

# Crear directorio de caché
mkdir -p "$CACHE_DIR"

# Función para limpiar pantalla con estilo
clear_screen() {
    clear
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════╗"
    echo "║     🎌 REPRODUCTOR DE ANIME EN TERMINAL 🎌   ║"
    echo "║              JKAnime Español                 ║"
    echo "╚════════════════════════════════════════════╝"
    echo -e "${NC}\n"
}

# Verificar dependencias
check_dependencies() {
    local missing_deps=()
    
    if ! command -v mpv &> /dev/null; then
        missing_deps+=("mpv")
    fi
    
    if ! command -v yt-dlp &> /dev/null; then
        missing_deps+=("yt-dlp")
    fi
    
    if ! command -v curl &> /dev/null; then
        missing_deps+=("curl")
    fi
    
    if ! command -v jq &> /dev/null; then
        missing_deps+=("jq")
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo -e "${RED}❌ Faltan dependencias:${NC}"
        for dep in "${missing_deps[@]}"; do
            echo "  - $dep"
        done
        echo -e "\n${YELLOW}Instala con:${NC}"
        echo "  sudo pacman -S mpv curl jq yt-dlp"
        exit 1
    fi
}

# Función para buscar anime
search_anime() {
    clear_screen
    read -p "$(echo -e ${CYAN})Ingresa el nombre del anime:${NC} " search_query
    
    if [ -z "$search_query" ]; then
        echo -e "${RED}❌ Búsqueda vacía${NC}"
        sleep 2
        return 1
    fi
    
    echo -e "\n${YELLOW}⏳ Buscando anime...${NC}\n"
    
    # URL de búsqueda
    local search_url="${JKANIME_URL}/buscar/?q=$(echo "$search_query" | sed 's/ /%20/g')"
    
    # Obtener HTML de búsqueda
    local html=$(curl -s "$search_url" 2>/dev/null)
    
    if [ -z "$html" ]; then
        echo -e "${RED}❌ Error de conexión${NC}"
        sleep 2
        return 1
    fi
    
    # Extraer resultados (títulos y URLs)
    local results=$(echo "$html" | grep -oP '(?<=<a href=")[^"]*(?:anime|serie).*?(?=")' | head -20)
    
    if [ -z "$results" ]; then
        echo -e "${RED}❌ No se encontraron resultados${NC}"
        sleep 2
        return 1
    fi
    
    # Mostrar resultados
    echo -e "${GREEN}Resultados encontrados:${NC}\n"
    
    local i=1
    declare -a anime_urls
    
    while IFS= read -r url; do
        if [ ! -z "$url" ]; then
            # Extraer nombre del URL
            local name=$(echo "$url" | sed 's/.*\///' | sed 's/-/ /g' | sed 's/%20/ /g')
            echo -e "${YELLOW}$i)${NC} $name"
            anime_urls[$i]="$JKANIME_URL$url"
            ((i++))
        fi
    done <<< "$results"
    
    echo -e "\n${YELLOW}0)${NC} Volver al menú principal"
    echo
    read -p "Selecciona un anime (0-$((i-1))): " selection
    
    if [ "$selection" -eq 0 ] 2>/dev/null; then
        return 0
    fi
    
    if [ -z "${anime_urls[$selection]}" ]; then
        echo -e "${RED}❌ Opción inválida${NC}"
        sleep 2
        return 1
    fi
    
    # Mostrar episodios del anime seleccionado
    show_episodes "${anime_urls[$selection]}"
}

# Función para mostrar episodios y temporadas
show_episodes() {
    local anime_url="$1"
    clear_screen
    
    echo -e "${YELLOW}⏳ Obteniendo información del anime...${NC}\n"
    
    # Obtener HTML del anime
    local html=$(curl -s "$anime_url" 2>/dev/null)
    
    if [ -z "$html" ]; then
        echo -e "${RED}❌ Error al obtener información${NC}"
        sleep 2
        return 1
    fi
    
    # Obtener nombre del anime
    local anime_name=$(echo "$html" | grep -oP '(?<=<h1>)[^<]*' | head -1)
    echo -e "${CYAN}🎌 Anime: ${GREEN}$anime_name${NC}\n"
    
    # Buscar todas las temporadas disponibles
    local seasons=$(echo "$html" | grep -oP '(?<=Season )[0-9]+' | sort -u)
    
    if [ -z "$seasons" ]; then
        # Si no hay temporadas, mostrar todos los episodios
        show_all_episodes "$anime_url" "$anime_name"
    else
        # Mostrar menú de temporadas
        show_season_menu "$seasons" "$anime_url" "$anime_name"
    fi
}

# Función para mostrar menú de temporadas
show_season_menu() {
    local seasons="$1"
    local anime_url="$2"
    local anime_name="$3"
    
    clear_screen
    echo -e "${CYAN}🎌 Anime: ${GREEN}$anime_name${NC}\n"
    echo -e "${YELLOW}Temporadas disponibles:${NC}\n"
    
    local i=1
    declare -a season_array
    
    while IFS= read -r season; do
        echo -e "${YELLOW}$i)${NC} Temporada $season"
        season_array[$i]=$season
        ((i++))
    done <<< "$seasons"
    
    echo -e "\n${YELLOW}0)${NC} Volver al menú principal"
    echo
    read -p "Selecciona una temporada (0-$((i-1))): " season_selection
    
    if [ "$season_selection" -eq 0 ] 2>/dev/null; then
        return 0
    fi
    
    if [ -z "${season_array[$season_selection]}" ]; then
        echo -e "${RED}❌ Opción inválida${NC}"
        sleep 2
        return 1
    fi
    
    # Mostrar episodios de la temporada seleccionada
    show_season_episodes "$anime_url" "${season_array[$season_selection]}" "$anime_name"
}

# Función para mostrar episodios de una temporada específica
show_season_episodes() {
    local anime_url="$1"
    local season="$2"
    local anime_name="$3"
    
    clear_screen
    echo -e "${CYAN}🎌 Anime: ${GREEN}$anime_name${NC}"
    echo -e "${CYAN}📺 Temporada: ${GREEN}$season${NC}\n"
    
    # Obtener HTML
    local html=$(curl -s "$anime_url" 2>/dev/null)
    
    # Extraer episodios de la temporada (esto es una aproximación)
    local episodes=$(echo "$html" | grep -oP "(?<=ep=)[0-9]+" | sort -u)
    
    if [ -z "$episodes" ]; then
        echo -e "${YELLOW}⏳ Buscando episodios de otra forma...${NC}"
        # Alternativa: buscar enlaces de episodios
        show_all_episodes "$anime_url" "$anime_name"
        return
    fi
    
    echo -e "${YELLOW}Episodios disponibles:${NC}\n"
    
    local i=1
    declare -a ep_array
    
    while IFS= read -r ep; do
        echo -e "${YELLOW}$i)${NC} Episodio $ep"
        ep_array[$i]=$ep
        ((i++))
    done <<< "$episodes"
    
    echo -e "\n${YELLOW}0)${NC} Volver al menú principal"
    echo
    read -p "Selecciona un episodio (0-$((i-1))): " ep_selection
    
    if [ "$ep_selection" -eq 0 ] 2>/dev/null; then
        return 0
    fi
    
    if [ -z "${ep_array[$ep_selection]}" ]; then
        echo -e "${RED}❌ Opción inválida${NC}"
        sleep 2
        return 1
    fi
    
    # Reproducir episodio
    play_episode "$anime_url?ep=${ep_array[$ep_selection]}" "$anime_name" "${ep_array[$ep_selection]}"
}

# Función para mostrar todos los episodios (si no hay temporadas)
show_all_episodes() {
    local anime_url="$1"
    local anime_name="$2"
    
    clear_screen
    echo -e "${CYAN}🎌 Anime: ${GREEN}$anime_name${NC}\n"
    echo -e "${YELLOW}Episodios disponibles:${NC}\n"
    
    # Obtener HTML
    local html=$(curl -s "$anime_url" 2>/dev/null)
    
    # Extraer episodios
    local episodes=$(echo "$html" | grep -oP "(?<=ep=)[0-9]+" | sort -n -u | head -50)
    
    if [ -z "$episodes" ]; then
        echo -e "${RED}❌ No se encontraron episodios${NC}"
        sleep 2
        return 1
    fi
    
    local i=1
    declare -a ep_array
    
    while IFS= read -r ep; do
        if [ ! -z "$ep" ]; then
            echo -e "${YELLOW}$i)${NC} Episodio $ep"
            ep_array[$i]=$ep
            ((i++))
        fi
    done <<< "$episodes"
    
    echo -e "\n${YELLOW}0)${NC} Volver al menú principal"
    echo
    read -p "Selecciona un episodio (0-$((i-1))): " ep_selection
    
    if [ "$ep_selection" -eq 0 ] 2>/dev/null; then
        return 0
    fi
    
    if [ -z "${ep_array[$ep_selection]}" ]; then
        echo -e "${RED}❌ Opción inválida${NC}"
        sleep 2
        return 1
    fi
    
    # Reproducir episodio
    play_episode "$anime_url?ep=${ep_array[$ep_selection]}" "$anime_name" "${ep_array[$ep_selection]}"
}

# Función para reproducir episodio
play_episode() {
    local url="$1"
    local anime_name="$2"
    local episode="$3"
    
    clear_screen
    echo -e "${CYAN}🎌 $anime_name${NC}"
    echo -e "${CYAN}📺 Episodio: $episode${NC}\n"
    echo -e "${YELLOW}⏳ Obteniendo stream...${NC}\n"
    
    # Intentar obtener el stream con yt-dlp
    local stream_url=$(yt-dlp -g "$url" 2>/dev/null)
    
    if [ -z "$stream_url" ]; then
        echo -e "${RED}❌ No se pudo obtener el stream${NC}"
        echo -e "${YELLOW}URL intentada: $url${NC}"
        sleep 3
        return 1
    fi
    
    echo -e "${GREEN}✓ Stream encontrado${NC}"
    echo -e "${YELLOW}⏳ Iniciando reproducción...${NC}\n"
    sleep 2
    
    # Reproducir con mpv con soporte para subtítulos en español
    # mpv intentará descargar subtítulos automáticamente
    mpv \
        --sub-auto=fuzzy \
        --sub-file-paths=ass:srt:sub:subs:subtitles \
        --alang=es,es-ES,esp \
        --slang=es,es-ES,spa \
        --title="${anime_name} - Episodio ${episode}" \
        "$stream_url"
    
    # Menú post-reproducción
    post_play_menu "$url" "$anime_name" "$episode"
}

# Menú después de ver un episodio
post_play_menu() {
    local url="$1"
    local anime_name="$2"
    local current_ep="$3"
    
    clear_screen
    echo -e "${CYAN}🎌 $anime_name${NC}"
    echo -e "${CYAN}📺 Episodio: $current_ep${NC}\n"
    echo -e "${YELLOW}1)${NC} Ver siguiente episodio"
    echo -e "${YELLOW}2)${NC} Ver otro episodio"
    echo -e "${YELLOW}3)${NC} Volver al menú principal"
    echo
    read -p "Selecciona una opción (1-3): " post_selection
    
    case $post_selection in
        1)
            local next_ep=$((current_ep + 1))
            play_episode "${url%\?*}?ep=$next_ep" "$anime_name" "$next_ep"
            ;;
        2)
            show_all_episodes "${url%\?*}" "$anime_name"
            ;;
        3)
            return 0
            ;;
        *)
            echo -e "${RED}Opción inválida${NC}"
            sleep 1
            post_play_menu "$url" "$anime_name" "$current_ep"
            ;;
    esac
}

# Reproducir por URL directa
play_from_url() {
    clear_screen
    read -p "$(echo -e ${CYAN})Ingresa la URL del episodio:${NC} " episode_url
    
    if [ -z "$episode_url" ]; then
        echo -e "${RED}❌ URL vacía${NC}"
        sleep 2
        return 1
    fi
    
    # Validar que sea de JKAnime
    if [[ ! "$episode_url" =~ jkanime ]]; then
        echo -e "${YELLOW}⚠️  Advertencia: URL no es de JKAnime${NC}"
        read -p "¿Continuar de todos modos? (s/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Ss]$ ]]; then
            return 1
        fi
    fi
    
    echo -e "\n${YELLOW}⏳ Procesando URL...${NC}\n"
    sleep 1
    
    # Intentar reproducir
    play_episode "$episode_url" "Anime" "?"
}

# Menú principal
main_menu() {
    while true; do
        clear_screen
        echo -e "${YELLOW}OPCIONES PRINCIPALES:${NC}\n"
        echo -e "${GREEN}1)${NC} Buscar anime por nombre"
        echo -e "${GREEN}2)${NC} Reproducir por URL"
        echo -e "${GREEN}3)${NC} Ver historial de búsquedas"
        echo -e "${GREEN}4)${NC} Configuración"
        echo -e "${RED}5)${NC} Salir"
        echo
        read -p "Selecciona una opción (1-5): " main_option
        
        case $main_option in
            1)
                search_anime
                ;;
            2)
                play_from_url
                ;;
            3)
                show_history
                ;;
            4)
                show_settings
                ;;
            5)
                clear
                echo -e "${GREEN}¡Que disfrutes viendo anime! 🎌${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}❌ Opción inválida${NC}"
                sleep 1
                ;;
        esac
    done
}

# Mostrar historial
show_history() {
    clear_screen
    echo -e "${YELLOW}Historial de búsquedas:${NC}\n"
    echo -e "${CYAN}Función aún en desarrollo${NC}"
    sleep 2
}

# Mostrar configuración
show_settings() {
    clear_screen
    echo -e "${YELLOW}CONFIGURACIÓN:${NC}\n"
    echo -e "${GREEN}1)${NC} Idioma de audio (Español)"
    echo -e "${GREEN}2)${NC} Subtítulos (Automático)"
    echo -e "${GREEN}3)${NC} Limpiar caché"
    echo -e "${YELLOW}0)${NC} Volver"
    echo
    read -p "Selecciona una opción: " settings_option
    
    case $settings_option in
        3)
            rm -rf "$CACHE_DIR"
            mkdir -p "$CACHE_DIR"
            echo -e "${GREEN}✓ Caché limpiado${NC}"
            sleep 2
            ;;
        0)
            return 0
            ;;
        *)
            echo -e "${RED}❌ Opción inválida${NC}"
            sleep 2
            ;;
    esac
}

# Punto de entrada principal
main() {
    check_dependencies
    main_menu
}

# Ejecutar script
main "$@"
