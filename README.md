# tool-bluedeath v2.0

Herramienta avanzada de auditoría Bluetooth (BR/EDR + BLE) para Linux con soporte JSON y múltiples modos de ataque.

---

## 🚀 Novedades v2.0 (2026)

### Mejoras Técnicas
- ✅ **BLE scan support**: Escaneo de Bluetooth Low Energy
- ✅ **JSON export**: Salida estructurada para automatización
- ✅ **Attack modes**: l2ping flood + BlueSmack
- ✅ **Service enumeration**: SDP service discovery
- ✅ **Better UX**: Menú mejorado, progress indicators, colores
- ✅ **Batch operations**: Soporte para múltiples interfaces
- ✅ **Enhanced logging**: Logs detallados con timestamps

### Funcionalidades

**Scanning:**
- BR/EDR device scan (Bluetooth clásico)
- BLE device scan (Low Energy)
- Inquiry scan (dispositivos conectables)
- Service enumeration (SDP)

**Testing:**
- l2ping connectivity check
- DoS attacks (flood, BlueSmack)
- Connection monitoring

**Output:**
- Text format (legible)
- JSON format (automatización)
- Enhanced logging

---

## 📦 Requisitos

### Hardware
- Adaptador Bluetooth compatible (interno o USB)
- Linux real (no WSL, no VMs sin passthrough)

### Software
```bash
# Debian/Ubuntu/Kali
sudo apt install bluez jq

# Arch
sudo pacman -S bluez-utils jq

# Fedora
sudo dnf install bluez jq
```

### Compatibilidad

| Entorno     | Estado          | Motivo                        |
|-------------|-----------------|-------------------------------|
| Linux       | ✔️ Compatible   | BlueZ nativo                  |
| macOS       | ❌ No compatible | Sin BlueZ                     |
| Windows     | ❌ No compatible | Sin stack BlueZ               |
| WSL         | ❌ No compatible | Sin acceso hardware           |
| VM          | ⚠️ Limitado     | Requiere USB passthrough      |

---

## 🔧 Instalación

```bash
git clone https://github.com/theoffsecgirl/tool-bluedeath
cd tool-bluedeath
chmod +x bluedeath.sh
```

---

## 🔥 Uso Básico

### Menú interactivo

```bash
sudo ./bluedeath.sh --menu
```

### Escaneo BR/EDR

```bash
# Texto
sudo ./bluedeath.sh --scan

# JSON
sudo ./bluedeath.sh --scan --format json --output scan.json
```

**Salida ejemplo (texto):**
```
╭──────────────────────────────────────────────────╮
│  BLUEDEATH v2.0 - Bluetooth Security Tool       │
│  Interface: hci0                                 │
╰──────────────────────────────────────────────────╯

[i] Escaneando dispositivos BR/EDR con hci0...
[✓] Escaneo completado. Dispositivos encontrados: 3

  ● 00:1A:7D:DA:71:13  (Altavoz Bluetooth)
  ● D8:AB:C1:22:3F:90  (Banda Fitness)
  ● 5C:31:3E:2F:4B:8A  (Unknown)
```

**Salida ejemplo (JSON):**
```json
{
  "scanner_version": "2.0",
  "timestamp": "2026-03-04T18:30:00Z",
  "interface": "hci0",
  "scan_type": "BR/EDR",
  "devices": [
    {
      "mac": "00:1A:7D:DA:71:13",
      "name": "Altavoz Bluetooth",
      "class": "",
      "timestamp": "2026-03-04T18:30:05Z"
    }
  ],
  "total_devices": 3
}
```

### Escaneo BLE

```bash
sudo ./bluedeath.sh --scan-ble --format json
```

### Enumerar servicios

```bash
sudo ./bluedeath.sh --services AA:BB:CC:DD:EE:FF
```

### Test de conectividad

```bash
sudo ./bluedeath.sh --ping AA:BB:CC:DD:EE:FF
```

### Ataque DoS

```bash
# l2ping flood
sudo ./bluedeath.sh --dos AA:BB:CC:DD:EE:FF --mode flood

# BlueSmack (oversized packets)
sudo ./bluedeath.sh --dos AA:BB:CC:DD:EE:FF --mode bluesmack
```

---

## ⚙️ Opciones CLI

### Scanning

| Flag            | Descripción                              |
|-----------------|------------------------------------------|
| `--scan`        | Escanear dispositivos BR/EDR             |
| `--scan-ble`    | Escanear dispositivos BLE                |
| `--inquiry`     | Inquiry scan (dispositivos conectables)  |
| `--services MAC`| Enumerar servicios SDP                   |
| `--connected`   | Mostrar conexiones actuales              |

### Testing

| Flag            | Descripción                              |
|-----------------|------------------------------------------|
| `--ping MAC`    | Test l2ping al dispositivo               |
| `--dos MAC`     | Ejecutar ataque DoS                      |
| `--mode MODE`   | Modo ataque: flood, bluesmack            |

### Output

| Flag            | Descripción                              |
|-----------------|------------------------------------------|
| `--format FMT`  | Formato: text, json                      |
| `--output FILE` | Guardar resultados en archivo            |
| `--interface IF`| Usar interfaz específica (hci0, hci1)    |

### Interactive

| Flag            | Descripción                              |
|-----------------|------------------------------------------|
| `--menu`        | Menú interactivo                         |
| `-h, --help`    | Mostrar ayuda                            |

---

## 🎯 Modos de Ataque

### l2ping Flood

**Funcionamiento:**
- Envía paquetes l2ping continuos sin delay
- Satura la conexión Bluetooth del target
- Causa DoS temporal

**Uso:**
```bash
sudo ./bluedeath.sh --dos AA:BB:CC:DD:EE:FF --mode flood
```

**Efectos:**
- Conexión inestable
- Lag severo
- Posible desconexión

### BlueSmack

**Funcionamiento:**
- Envía paquetes L2CAP oversized (>600 bytes)
- Explota vulnerabilidades en parsing de paquetes
- Crash en stacks Bluetooth antiguos

**Uso:**
```bash
sudo ./bluedeath.sh --dos AA:BB:CC:DD:EE:FF --mode bluesmack
```

**Efectos:**
- Crash del stack Bluetooth (dispositivos vulnerables)
- DoS permanente hasta reboot
- Mayor impacto que flood

**Targets vulnerables:**
- Dispositivos Android antiguos (<5.0)
- Windows XP/Vista Bluetooth stacks
- Hardware Bluetooth sin parches 2010-2015

---

## 📊 Ejemplos Avanzados

### Bug Bounty Workflow

```bash
# 1. Escaneo inicial
sudo ./bluedeath.sh --scan --format json --output scan_initial.json

# 2. Enumerar servicios de cada dispositivo
jq -r '.devices[].mac' scan_initial.json | while read mac; do
  sudo ./bluedeath.sh --services "$mac" > "services_${mac//:/_}.txt"
done

# 3. Test de conectividad
jq -r '.devices[].mac' scan_initial.json | while read mac; do
  sudo ./bluedeath.sh --ping "$mac" >> connectivity_results.txt
done
```

### Pentesting de IoT

```bash
# BLE scan para IoT devices
sudo ./bluedeath.sh --scan-ble --format json --output iot_devices.json

# Análisis de devices por RSSI (requiere processing manual)
# Los dispositivos más cercanos tienen mayor prioridad
```

### Múltiples interfaces

```bash
# Escanear con hci0 y hci1 simultáneamente
sudo BT_INTERFACE=hci0 ./bluedeath.sh --scan --output scan_hci0.json &
sudo BT_INTERFACE=hci1 ./bluedeath.sh --scan --output scan_hci1.json &
wait

# Consolidar resultados
jq -s 'map(.devices) | add | unique_by(.mac)' scan_hci*.json > consolidated.json
```

---

## 🔍 Comparación vs v1.0

| Feature               | v1.0          | v2.0              |
|-----------------------|---------------|-------------------|
| BR/EDR scan           | ✔️            | ✔️                |
| BLE scan              | ❌            | ✔️                |
| JSON export           | ❌            | ✔️                |
| Service enumeration   | ❌            | ✔️                |
| Attack modes          | 1 (flood)     | 2 (flood+bluesmack)|
| UI                    | Basic         | Enhanced          |
| Logging               | Simple        | Timestamped       |
| Batch operations      | No            | Yes               |

---

## ⚠️ Limitaciones

- **Hardware dependency**: Requiere adaptador Bluetooth compatible
- **Linux only**: No funciona en macOS/Windows sin modificaciones
- **Range**: Limitado a ~10-100m según clase del adaptador
- **Stack dependency**: Requiere BlueZ actualizado
- **BLE support**: Algunos adaptadores antiguos no soportan BLE

---

## 🧪 Testing

Tested en:
- ✅ Kali Linux 2025.x (Bluetooth 5.0 USB adapters)
- ✅ Ubuntu 22.04/24.04 (interno + USB)
- ✅ Arch Linux (btusb kernel module)
- ✅ Raspberry Pi 4 (Bluetooth integrado)

**Targets testeados:**
- Altavoces Bluetooth (JBL, Bose, Sony)
- Auriculares (AirPods, Sony WH-1000XM)
- IoT devices (smartwatches, fitness bands)
- Smartphones (Android, iPhone en modo discoverable)

---

## 📚 Uso Ético

**⚠️ USO EXCLUSIVO EN ENTORNOS AUTORIZADOS**

Utiliza BLUEDEATH únicamente en:
- ✅ Laboratorios de prueba
- ✅ Equipos propios
- ✅ Entornos con autorización explícita por escrito
- ✅ Investigación con consentimiento informado

**❌ NO utilices en:**
- Dispositivos ajenos sin permiso
- Espacios públicos
- Redes corporativas sin autorización
- Con fines maliciosos

**El uso indebido es ilegal y penado por ley.**

---

## 🔮 Roadmap

- [ ] GATT service enumeration (BLE)
- [ ] MAC address spoofing
- [ ] Automated pairing attacks
- [ ] RFCOMM fuzzing
- [ ] BlueJacking/BlueSnarfing modes
- [ ] HTML reporting
- [ ] Integration con databases (SQLite)

---

## 📖 Referencias

- [BlueZ Official Documentation](http://www.bluez.org)
- [Bluetooth Core Specification](https://www.bluetooth.com/specifications/specs/)
- [OWASP IoT Testing Guide](https://owasp.org/www-project-iot-security-testing-guide/)
- [CVE-2017-0785 (BlueBorne)](https://nvd.nist.gov/vuln/detail/CVE-2017-0785)

---

## 📜 Licencia

BSD 3-Clause License
