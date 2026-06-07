#!/bin/bash

# AnimePlay v2 - Reproductor de anime desde terminal
# Uso simple y directo

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

banner() {
    clear
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════╗"
    echo "║   🎌 ANIMEPLAY - REPRODUCTOR 🎌        ║"
    echo "╚════════════════════════════════════════╝"
    echo -e "${NC}\n"
}

# Verificar herramientas
check_tools() {
    command -v mpv >/dev/null 2>&1 || { echo "Instala: sudo pacman -S mpv"; exit 1; }
    command -v yt-dlp >/dev/null 2>&1 || { echo "Instala: sudo pacman -S yt-dlp"; exit 1; }
    command -v curl >/dev/null 2>&1 || { echo "Instala: sudo pacman -S curl"; exit 1; }
}

# Función para reproducir video
reproducir_video() {
    local url="$1"
    local nombre="$2"
    
    banner
    echo -e "${CYAN}📺 $nombre${NC}\n"
    echo -e "${YELLOW}⏳ Obteniendo video...${NC}"
    
    # Obtener URL de video con yt-dlp
    local video=$(yt-dlp -f best -g "$url" 2>/dev/null)
    
    if [ -z "$video" ]; then
        echo -e "${RED}❌ Error obteniendo video${NC}"
        sleep 2
        return 1
    fi
    
    echo -e "${GREEN}✓ Video listo${NC}\n"
    sleep 1
    
    # Reproducir
    mpv "$video" 2>/dev/null
    
    return 0
}

# Menú de opciones post-reproducción
menu_despues() {
    while true; do
        banner
        echo -e "${CYAN}¿Qué deseas hacer?${NC}\n"
        echo -e "${YELLOW}1)${NC} Reproducir otro episodio"
        echo -e "${YELLOW}2)${NC} Buscar otro anime"
        echo -e "${YELLOW}3)${NC} Salir"
        echo
        read -p "Opción: " opcion
        
        case $opcion in
            1) return 1 ;;
            2) return 2 ;;
            3) return 3 ;;
            *) echo -e "${RED}Inválido${NC}"; sleep 1 ;;
        esac
    done
}

# Buscar y reproducir
buscar_y_reproducir() {
    banner
    echo -e "${CYAN}🔍 Ingresa nombre del anime:${NC}"
    read -p "> " query
    
    if [ -z "$query" ]; then
        echo -e "${RED}Vacío${NC}"
        sleep 1
        return 0
    fi
    
    banner
    echo -e "${YELLOW}⏳ Buscando...${NC}\n"
    
    # Buscar en JKAnime
    local url_busqueda="https://jkanime.net/buscar/?q=$(echo "$query" | sed 's/ /%20/g')"
    local html=$(curl -s -A "Mozilla/5.0" "$url_busqueda" 2>/dev/null)
    
    if [ -z "$html" ]; then
        echo -e "${RED}❌ Sin conexión${NC}"
        sleep 2
        return 0
    fi
    
    # Extraer enlaces
    local enlaces=$(echo "$html" | grep -oP 'href="([^"]*/(anime|manga)/[^"]*)"' | sed 's/href="//;s/"$//' | sort -u | head -20)
    
    if [ -z "$enlaces" ]; then
        echo -e "${RED}❌ Sin resultados${NC}"
        sleep 2
        return 0
    fi
    
    # Mostrar resultados
    banner
    echo -e "${GREEN}Resultados encontrados:${NC}\n"
    
    declare -a urls
    local i=1
    
    while IFS= read -r enlace; do
        local nombre=$(echo "$enlace" | sed 's/.*\///' | sed 's/-/ /g' | sed 's/%20/ /g')
        echo -e "${YELLOW}$i)${NC} $nombre"
        urls[$i]="https://jkanime.net${enlace}"
        ((i++))
    done <<< "$enlaces"
    
    echo -e "\n${YELLOW}0)${NC} Volver"
    read -p "Elige (0-$((i-1))): " seleccion
    
    if [ "$seleccion" -eq 0 ] 2>/dev/null; then
        return 0
    fi
    
    if [ -z "${urls[$seleccion]}" ]; then
        echo -e "${RED}Inválido${NC}"
        sleep 1
        return 0
    fi
    
    local anime_url="${urls[$seleccion]}"
    
    # Obtener episodios
    banner
    echo -e "${YELLOW}⏳ Cargando episodios...${NC}\n"
    
    local html_anime=$(curl -s -A "Mozilla/5.0" "$anime_url" 2>/dev/null)
    
    if [ -z "$html_anime" ]; then
        echo -e "${RED}❌ Error${NC}"
        sleep 2
        return 0
    fi
    
    # Extraer nombre del anime
    local titulo=$(echo "$html_anime" | grep -oP '<title>\K[^<]*' | head -1 | sed 's/ -.*//;s/|.*//' | xargs)
    
    # Buscar episodios
    local episodios=$(echo "$html_anime" | grep -oP '(?<=ep=)[0-9]+' | sort -n -u | head -50)
    
    if [ -z "$episodios" ]; then
        echo -e "${RED}❌ Sin episodios${NC}"
        sleep 2
        return 0
    fi
    
    # Mostrar episodios
    banner
    echo -e "${CYAN}📺 ${titulo}${NC}\n"
    echo -e "${GREEN}Episodios:${NC}\n"
    
    declare -a ep_array
    local j=1
    
    while IFS= read -r ep; do
        echo -e "${YELLOW}$j)${NC} Episodio $ep"
        ep_array[$j]=$ep
        ((j++))
    done <<< "$episodios"
    
    echo -e "\n${YELLOW}0)${NC} Volver"
    read -p "Elige episodio (0-$((j-1))): " ep_seleccion
    
    if [ "$ep_seleccion" -eq 0 ] 2>/dev/null; then
        return 0
    fi
    
    if [ -z "${ep_array[$ep_seleccion]}" ]; then
        echo -e "${RED}Inválido${NC}"
        sleep 1
        return 0
    fi
    
    # Reproducir episodio
    local ep_numero="${ep_array[$ep_seleccion]}"
    local url_episodio="${anime_url}?ep=${ep_numero}"
    
    while true; do
        reproducir_video "$url_episodio" "${titulo} - Episodio ${ep_numero}"
        
        menu_despues
        local resultado=$?
        
        if [ $resultado -eq 1 ]; then
            # Pedir siguiente episodio
            banner
            echo -e "${CYAN}Siguiente episodio:${NC}"
            read -p "> " siguiente_ep
            [ -z "$siguiente_ep" ] && continue
            ep_numero=$siguiente_ep
            url_episodio="${anime_url}?ep=${ep_numero}"
        elif [ $resultado -eq 2 ]; then
            # Volver a buscar
            return 1
        else
            # Salir
            exit 0
        fi
    done
}

# Menú principal
menu_principal() {
    while true; do
        banner
        echo -e "${YELLOW}OPCIONES:${NC}\n"
        echo -e "${GREEN}1)${NC} 🔍 Buscar anime"
        echo -e "${GREEN}2)${NC} 🔗 URL directa"
        echo -e "${RED}3)${NC} ❌ Salir"
        echo
        read -p "Opción: " opcion
        
        case $opcion in
            1)
                while [ $? -ne 0 ]; do
                    buscar_y_reproducir
                done
                ;;
            2)
                banner
                echo -e "${CYAN}Pega URL del episodio:${NC}"
                read -p "> " url_directa
                [ ! -z "$url_directa" ] && reproducir_video "$url_directa" "Reproduciendo..."
                ;;
            3)
                clear
                echo -e "${GREEN}¡Hasta luego! 🎌${NC}\n"
                exit 0
                ;;
            *)
                echo -e "${RED}Inválido${NC}"
                sleep 1
                ;;
        esac
    done
}

# Iniciar
check_tools
menu_principal
