#!/bin/bash

# AnimePlay - Buscador y reproductor de anime desde JKAnime
# Accede directamente al servidor de video y reproduce en mpv

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

JKANIME_URL="https://jkanime.net"
CACHE_DIR="${HOME}/.cache/animeplay"
mkdir -p "$CACHE_DIR"

# Banner
banner() {
    clear
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║   🎌 ANIMEPLAY - BUSCADOR DE ANIME 🎌   ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
    echo -e ""
}

# Verificar dependencias
check_deps() {
    for cmd in mpv yt-dlp curl grep sed; do
        if ! command -v "$cmd" &> /dev/null; then
            echo -e "${RED}❌ Falta: $cmd${NC}"
            exit 1
        fi
    done
}

# Buscar anime
search_anime() {
    banner
    echo -e "${CYAN}🔍 Busca un anime:${NC}"
    read query
    
    [ -z "$query" ] && return 1
    
    echo -e "\n${YELLOW}⏳ Buscando en JKAnime...${NC}\n"
    
    local search_url="${JKANIME_URL}/buscar/?q=$(echo "$query" | sed 's/ /%20/g')"
    local html=$(curl -s -A "Mozilla/5.0" "$search_url" 2>/dev/null)
    
    [ -z "$html" ] && echo -e "${RED}❌ Error de conexión${NC}" && return 1
    
    # Extraer links de anime
    local links=$(echo "$html" | grep -oP 'href="([^"]*/(anime|manga)/[^"]*)"' | sed 's/href="//;s/"$//' | sort -u)
    
    [ -z "$links" ] && echo -e "${RED}❌ Sin resultados${NC}" && return 1
    
    local count=$(echo "$links" | wc -l)
    echo -e "${GREEN}✓ $count resultados:${NC}\n"
    
    local i=1
    declare -a urls
    
    while IFS= read -r link; do
        local name=$(echo "$link" | sed 's/.*\///' | sed 's/-/ /g' | sed 's/%20/ /g')
        echo -e "${YELLOW}$i)${NC} $name"
        urls[$i]="${JKANIME_URL}${link}"
        ((i++))
    done <<< "$links"
    
    echo -e "\n${YELLOW}0)${NC} Volver"
    read -p "Elige (0-$((i-1))): " choice
    
    [ "$choice" -eq 0 ] 2>/dev/null && return 0
    [ -z "${urls[$choice]}" ] && echo -e "${RED}Inválido${NC}" && sleep 1 && return 1
    
    get_episodes "${urls[$choice]}"
}

# Obtener episodios de un anime
get_episodes() {
    local anime_url="$1"
    
    banner
    echo -e "${YELLOW}⏳ Cargando episodios...${NC}\n"
    
    local html=$(curl -s -A "Mozilla/5.0" "$anime_url" 2>/dev/null)
    [ -z "$html" ] && echo -e "${RED}❌ Error${NC}" && read -p "Enter..." && return 1
    
    # Nombre del anime
    local title=$(echo "$html" | grep -oP '<title>\K[^<]*' | sed 's/ -.*//;s/|.*//' | head -1)
    [ -z "$title" ] && title=$(echo "$anime_url" | sed 's/.*\///')
    
    # Extraer episodios
    local episodes=$(echo "$html" | grep -oP '(?<=ep=)[0-9]+' | sort -n -u)
    
    if [ -z "$episodes" ]; then
        episodes=$(echo "$html" | grep -oP '(?<=\?ep=)[0-9]+' | sort -n -u)
    fi
    
    if [ -z "$episodes" ]; then
        episodes=$(echo "$html" | grep -oP 'episodio[^0-9]*\K[0-9]+' | sort -n -u)
    fi
    
    [ -z "$episodes" ] && echo -e "${RED}❌ Sin episodios${NC}" && read -p "Enter..." && return 1
    
    banner
    echo -e "${CYAN}📺 $title${NC}\n"
    echo -e "${GREEN}Episodios:${NC}\n"
    
    local i=1
    declare -a ep_array
    
    while IFS= read -r ep; do
        [ ! -z "$ep" ] && echo -e "${YELLOW}$i)${NC} Episodio $ep" && ep_array[$i]=$ep && ((i++))
    done <<< "$episodes"
    
    echo -e "\n${YELLOW}0)${NC} Volver"
    read -p "Elige episodio (0-$((i-1))): " ep_choice
    
    [ "$ep_choice" -eq 0 ] 2>/dev/null && return 0
    [ -z "${ep_array[$ep_choice]}" ] && echo -e "${RED}Inválido${NC}" && sleep 1 && return 1
    
    play_episode "$anime_url" "$title" "${ep_array[$ep_choice]}"
}

# Reproducir episodio
play_episode() {
    local base_url="$1"
    local title="$2"
    local ep="$3"
    
    banner
    echo -e "${CYAN}🎬 $title${NC}"
    echo -e "${CYAN}📺 Episodio $ep${NC}\n"
    echo -e "${YELLOW}⏳ Obteniendo video...${NC}\n"
    
    local ep_url="${base_url}?ep=${ep}"
    
    # Obtener stream directo con yt-dlp
    local video_url=$(timeout 30 yt-dlp -f best -g "$ep_url" 2>/dev/null | head -1)
    
    if [ -z "$video_url" ]; then
        echo -e "${RED}❌ No se pudo obtener el video${NC}"
        echo -e "Intentando método alternativo..."
        
        # Método alternativo: extraer HTML y buscar video
        local html=$(curl -s -A "Mozilla/5.0" "$ep_url" 2>/dev/null)
        video_url=$(echo "$html" | grep -oP 'https?://[^"\s]*\.m3u8' | head -1)
        
        if [ -z "$video_url" ]; then
            video_url=$(echo "$html" | grep -oP 'https?://[^"\s]*\.mp4' | head -1)
        fi
    fi
    
    if [ -z "$video_url" ]; then
        echo -e "${RED}❌ No se encontró video${NC}"
        echo -e "${YELLOW}URL probada: $ep_url${NC}"
        read -p "Presiona Enter..."
        return 1
    fi
    
    echo -e "${GREEN}✓ Video encontrado${NC}"
    echo -e "${YELLOW}▶️  Reproduciendo...${NC}\n"
    sleep 2
    
    # Reproducir con mpv
    mpv \
        --sub-auto=fuzzy \
        --alang=es,es-ES,spa,eng,en \
        --slang=es,es-ES,spa \
        --title="$title - Ep $ep" \
        --no-terminal \
        "$video_url" 2>/dev/null
    
    # Menú post-reproducción
    show_menu_post "$base_url" "$title" "$ep"
}

# Menú después de reproducir
show_menu_post() {
    local base_url="$1"
    local title="$2"
    local ep="$3"
    
    banner
    echo -e "${CYAN}$title - Episodio $ep${NC}\n"
    echo -e "${YELLOW}1)${NC} ▶️  Siguiente episodio"
    echo -e "${YELLOW}2)${NC} ⏮️  Episodio anterior"
    echo -e "${YELLOW}3)${NC} 📺 Seleccionar episodio"
    echo -e "${YELLOW}4)${NC} 🏠 Menú principal"
    echo
    read -p "Elige opción: " opt
    
    case $opt in
        1)
            local next=$((ep + 1))
            play_episode "$base_url" "$title" "$next"
            ;;
        2)
            if [ $ep -gt 1 ]; then
                local prev=$((ep - 1))
                play_episode "$base_url" "$title" "$prev"
            else
                echo -e "${RED}❌ No hay episodio anterior${NC}"
                sleep 2
                show_menu_post "$base_url" "$title" "$ep"
            fi
            ;;
        3)
            get_episodes "$base_url"
            ;;
        4)
            return 0
            ;;
        *)
            echo -e "${RED}Opción inválida${NC}"
            sleep 1
            show_menu_post "$base_url" "$title" "$ep"
            ;;
    esac
}

# Reproducir por URL directa
play_direct_url() {
    banner
    echo -e "${CYAN}Ingresa URL del episodio de JKAnime:${NC}"
    read url
    
    [ -z "$url" ] && return 1
    
    echo -e "\n${YELLOW}⏳ Procesando...${NC}\n"
    
    local video_url=$(timeout 30 yt-dlp -f best -g "$url" 2>/dev/null | head -1)
    
    [ -z "$video_url" ] && echo -e "${RED}Error${NC}" && read -p "Enter..." && return 1
    
    mpv --no-terminal "$video_url" 2>/dev/null
}

# Menú principal
main_menu() {
    while true; do
        banner
        echo -e "${YELLOW}MENÚ:${NC}\n"
        echo -e "${GREEN}1)${NC} 🔍 Buscar anime"
        echo -e "${GREEN}2)${NC} 🔗 URL directa"
        echo -e "${RED}3)${NC} 🚪 Salir"
        echo
        read -p "Elige: " opt
        
        case $opt in
            1) search_anime ;;
            2) play_direct_url ;;
            3) 
                clear
                echo -e "${GREEN}¡Que disfrutes viendo anime! 🎌${NC}\n"
                exit 0
                ;;
            *)
                echo -e "${RED}Opción inválida${NC}"
                sleep 1
                ;;
        esac
    done
}

# Ejecutar
check_deps
main_menu
