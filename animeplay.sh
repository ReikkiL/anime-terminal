#!/bin/bash

# Script mejorado para buscar y reproducir anime desde JKAnime
# Requiere: mpv, yt-dlp, curl, fzf (opcional pero recomendado)
# Instalación: sudo pacman -S mpv yt-dlp curl fzf

set -e

# Colores
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
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════╗"
    echo "║   🎌 BUSCADOR DE ANIME - JKANIME 🎌    ║"
    echo "╚════════════════════════════════════════╝"
    echo -e "${NC}\n"
}

# Verificar dependencias
check_deps() {
    for cmd in mpv yt-dlp curl; do
        if ! command -v "$cmd" &> /dev/null; then
            echo -e "${RED}❌ Falta instalar: $cmd${NC}"
            exit 1
        fi
    done
}

# Buscar anime en JKAnime
search_anime() {
    banner
    read -p "$(echo -e ${CYAN}Busca un anime:${NC} )" query
    
    if [ -z "$query" ]; then
        echo -e "${RED}Búsqueda vacía${NC}"
        return 1
    fi
    
    echo -e "\n${YELLOW}🔍 Buscando...${NC}\n"
    
    # Hacer la búsqueda
    local url="${JKANIME_URL}/buscar/?q=$(echo "$query" | sed 's/ /%20/g')"
    local html=$(curl -s -A "Mozilla/5.0" "$url" 2>/dev/null)
    
    if [ -z "$html" ]; then
        echo -e "${RED}❌ Error de conexión${NC}"
        return 1
    fi
    
    # Extraer todos los links de anime/manga
    local links=$(echo "$html" | grep -oP 'href="[^"]*/(anime|manga)/[^"]*"' | sed 's/href="//;s/"$//' | sort -u)
    
    if [ -z "$links" ]; then
        echo -e "${RED}❌ Sin resultados${NC}"
        return 1
    fi
    
    # Contar y mostrar resultados
    local count=$(echo "$links" | wc -l)
    echo -e "${GREEN}✓ Encontrados $count resultados:${NC}\n"
    
    local i=1
    declare -a urls
    
    while IFS= read -r link; do
        # Extraer nombre legible
        local name=$(echo "$link" | sed 's/.*\///' | sed 's/-/ /g' | sed 's/%20/ /g')
        echo -e "${YELLOW}$i)${NC} $name"
        urls[$i]="${JKANIME_URL}${link}"
        ((i++))
    done <<< "$links"
    
    echo -e "\n${YELLOW}0)${NC} Volver"
    echo
    read -p "Elige uno (0-$((i-1))): " choice
    
    if [ "$choice" -eq 0 ] 2>/dev/null; then
        return 0
    fi
    
    if [ -z "${urls[$choice]}" ]; then
        echo -e "${RED}Opción inválida${NC}"
        sleep 1
        return 1
    fi
    
    # Mostrar episodios
    show_episodes_from_url "${urls[$choice]}"
}

# Mostrar episodios de una página
show_episodes_from_url() {
    local page_url="$1"
    banner
    
    echo -e "${YELLOW}⏳ Obteniendo episodios...${NC}\n"
    
    local html=$(curl -s -A "Mozilla/5.0" "$page_url" 2>/dev/null)
    
    if [ -z "$html" ]; then
        echo -e "${RED}❌ No se pudo acceder${NC}"
        read -p "Presiona Enter..."
        return 1
    fi
    
    # Obtener nombre
    local title=$(echo "$html" | grep -oP '<h1[^>]*>\K[^<]+' | head -1)
    echo -e "${CYAN}📺 $title${NC}\n"
    
    # Buscar episodios en los enlaces
    local episodes=$(echo "$html" | grep -oP "(?<=ep=)[0-9]+" | sort -n -u)
    
    if [ -z "$episodes" ]; then
        # Método alternativo
        episodes=$(echo "$html" | grep -oP 'episodio["\s]*[:=]["\s]*\K[0-9]+' | sort -n -u | head -50)
    fi
    
    if [ -z "$episodes" ]; then
        echo -e "${RED}❌ No hay episodios${NC}"
        read -p "Presiona Enter..."
        return 1
    fi
    
    echo -e "${GREEN}Episodios:${NC}\n"
    
    local i=1
    declare -a ep_array
    
    while IFS= read -r ep; do
        if [ ! -z "$ep" ]; then
            echo -e "${YELLOW}$i)${NC} Episodio $ep"
            ep_array[$i]=$ep
            ((i++))
        fi
    done <<< "$episodes"
    
    echo -e "\n${YELLOW}0)${NC} Volver"
    echo
    read -p "Elige episodio (0-$((i-1))): " ep_choice
    
    if [ "$ep_choice" -eq 0 ] 2>/dev/null; then
        return 0
    fi
    
    if [ -z "${ep_array[$ep_choice]}" ]; then
        echo -e "${RED}Opción inválida${NC}"
        sleep 1
        return 1
    fi
    
    # Reproducir
    play_episode "$page_url" "$title" "${ep_array[$ep_choice]}"
}

# Reproducir episodio
play_episode() {
    local base_url="$1"
    local title="$2"
    local ep="$3"
    
    banner
    echo -e "${CYAN}🎬 $title${NC}"
    echo -e "${CYAN}📺 Episodio $ep${NC}\n"
    echo -e "${YELLOW}⏳ Obteniendo stream...${NC}\n"
    
    # Construir URL del episodio
    local ep_url="${base_url}?ep=${ep}"
    
    # Obtener stream con yt-dlp
    local stream=$(yt-dlp -g "$ep_url" 2>/dev/null)
    
    if [ -z "$stream" ]; then
        echo -e "${RED}❌ No se pudo obtener el video${NC}"
        echo -e "URL: $ep_url"
        read -p "Presiona Enter..."
        return 1
    fi
    
    echo -e "${GREEN}✓ Stream listo${NC}"
    echo -e "${YELLOW}▶️  Iniciando mpv...${NC}\n"
    sleep 2
    
    # Reproducir
    mpv \
        --sub-auto=fuzzy \
        --alang=es,es-ES,spa \
        --slang=es,es-ES,spa \
        --title="$title - Ep $ep" \
        "$stream"
    
    # Menú post-reproducción
    menu_post "$base_url" "$title" "$ep"
}

# Menú después de ver
menu_post() {
    local base_url="$1"
    local title="$2"
    local current_ep="$3"
    
    banner
    echo -e "${CYAN}$title - Ep $current_ep${NC}\n"
    echo -e "${YELLOW}1)${NC} Siguiente episodio"
    echo -e "${YELLOW}2)${NC} Episodio anterior"
    echo -e "${YELLOW}3)${NC} Otro episodio"
    echo -e "${YELLOW}4)${NC} Menú principal"
    echo
    read -p "Elige: " opt
    
    case $opt in
        1)
            local next=$((current_ep + 1))
            play_episode "$base_url" "$title" "$next"
            ;;
        2)
            if [ $current_ep -gt 1 ]; then
                local prev=$((current_ep - 1))
                play_episode "$base_url" "$title" "$prev"
            else
                echo -e "${RED}No hay anterior${NC}"
                sleep 2
                menu_post "$base_url" "$title" "$current_ep"
            fi
            ;;
        3)
            show_episodes_from_url "$base_url"
            ;;
        4)
            return 0
            ;;
        *)
            echo -e "${RED}Inválido${NC}"
            sleep 1
            menu_post "$base_url" "$title" "$current_ep"
            ;;
    esac
}

# URL directa
play_url() {
    banner
    read -p "$(echo -e ${CYAN})URL del episodio:${NC} " url
    
    if [ -z "$url" ]; then
        return 1
    fi
    
    echo -e "\n${YELLOW}⏳ Procesando...${NC}\n"
    sleep 1
    
    local stream=$(yt-dlp -g "$url" 2>/dev/null)
    
    if [ -z "$stream" ]; then
        echo -e "${RED}❌ Error${NC}"
        read -p "Presiona Enter..."
        return 1
    fi
    
    mpv "$stream"
}

# Menú principal
main_menu() {
    while true; do
        banner
        echo -e "${YELLOW}OPCIONES:${NC}\n"
        echo -e "${GREEN}1)${NC} Buscar anime"
        echo -e "${GREEN}2)${NC} URL directa"
        echo -e "${RED}3)${NC} Salir"
        echo
        read -p "Elige: " opt
        
        case $opt in
            1) search_anime ;;
            2) play_url ;;
            3) 
                clear
                echo -e "${GREEN}¡Que disfrutes! 🎌${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Inválido${NC}"
                sleep 1
                ;;
        esac
    done
}

# Ejecutar
check_deps
main_menu
