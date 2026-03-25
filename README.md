<div align="center">

# bluedeath

**Auditoría ofensiva Bluetooth BR/EDR para Linux**

![Language](https://img.shields.io/badge/Bash-Linux-9E4AFF?style=flat-square&logo=gnubash&logoColor=white)
![Version](https://img.shields.io/badge/version-1.2.0-9E4AFF?style=flat-square)
![License](https://img.shields.io/badge/License-BSD%203--Clause-9E4AFF?style=flat-square)
![Category](https://img.shields.io/badge/Category-Offensive%20Security%20%7C%20Wireless-111111?style=flat-square)

*by [theoffsecgirl](https://github.com/theoffsecgirl)*

</div>

---

```text
┌──────────────────────────────────────────────────────┐
│                                                      │
│  ██████╗ ██╗     ██╗   ██████╗ ███████╗             │
│  ██╔══██╗██║     ██║  ██╔════╝ ██╔════╝             │
│  ██████╔╝██║     ██║  ██║  ███╗█████╗               │
│  ██╔══██╗██║     ██║  ██║   ██║██╔══╝               │
│  ██████╔╝███████╗██║  ╚██████╔╝███████╗             │
│  ╚═════╝ ╚══════╝╚═╝   ╚═════╝ ╚══════╝             │
│                                                      │
│  ██████╗ ███████╗ ███████╗██║  ██╗             │
│  ██╔══██╗██╔════╝ ██╔════╝██║  ██║             │
│  ██║  ██║█████╗  █████╗  ███████║             │
│  ██║  ██║██╔══╝  ██╔══╝  ██╔══██║             │
│  ██████╔╝███████╗███████╗██║  ██║             │
│  ╚═════╝ ╚══════╝╚══════╝╚═╝  ╚═╝             │
│                                                      │
│  Bluetooth BR/EDR offensive auditor  v1.2.0          │
│  bluetoothctl · btmgmt · l2ping · Linux only         │
│  by theoffsecgirl                                    │
└──────────────────────────────────────────────────────┘
```

---

## ¿Qué hace?

Herramienta para auditar dispositivos Bluetooth BR/EDR en Linux usando la pila BlueZ. Detecta automáticamente si el stack disponible es moderno (`bluetoothctl` + `btmgmt`) o legacy (`hcitool` + `hciconfig`) y adapta todas las operaciones.

---

## Funcionalidades

- Escaneo BR/EDR vía `btmgmt find` + `bluetoothctl` (coproc, no interactivo)
- Comprobación de actividad vía `l2ping`
- Prueba de estrés controlada con confirmación
- Soporte stack moderno (`bluetoothctl`/`btmgmt`) y legacy (`hcitool`/`hciconfig`)
- `SCAN_TIMEOUT` configurable por variable de entorno (default: 15s)
- Menú interactivo y flags CLI
- Logging y exportación de resultados

---

## Requisitos

- Linux (Debian, Ubuntu, Arch, Kali…)
- Bash 4.x + BlueZ (`bluetoothctl`, `btmgmt`, `l2ping`)
- Adaptador Bluetooth compatible
- Privilegios de superusuario

---

## Compatibilidad

| Entorno | Estado |
|---------|--------|
| Linux (BlueZ moderno) | ✅ Preferido |
| Linux (BlueZ legacy) | ✅ Fallback |
| macOS | ❌ No (sin BlueZ) |
| Windows / WSL | ❌ No (sin hardware real) |
| VPS / cloud | ❌ No (sin hardware Bluetooth) |

---

## Instalación

```bash
git clone https://github.com/theoffsecgirl/bluedeath
cd bluedeath
chmod +x bluedeath.sh
```

---

## Uso

```bash
# Menú interactivo
sudo ./bluedeath.sh --menu

# Escaneo (15s por defecto)
sudo ./bluedeath.sh --scan

# Escaneo con timeout personalizado
sudo SCAN_TIMEOUT=30 ./bluedeath.sh --scan

# Inquiry scan BR/EDR
sudo ./bluedeath.sh --inquiry

# Comprobar actividad
sudo ./bluedeath.sh --active

# Prueba de estrés controlada
sudo ./bluedeath.sh --dos AA:BB:CC:DD:EE:FF

# Interfaz específica
sudo BT_INTERFACE=hci1 ./bluedeath.sh --scan
```

---

## Uso ético

Solo para laboratorios controlados y sistemas con autorización explícita.

---

## Licencia

BSD 3-Clause · [theoffsecgirl](https://theoffsecgirl.com)
