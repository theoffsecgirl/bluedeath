<div align="center">

# bluedeath

**Auditoría ofensiva Bluetooth BR/EDR para Linux**

![Language](https://img.shields.io/badge/Bash-Linux-9E4AFF?style=flat-square&logo=gnubash&logoColor=white)
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
│  ██████╔╝██║     ██║  ███████╗█████╗               │
│  ██╔══██╗██║     ██║  ╚════██║██╔══╝               │
│  ██████╔╝███████╗██║  ██████╔╝███████╗             │
│  ╚═════╝ ╚══════╝╚═╝  ╚═════╝ ╚══════╝             │
│                                                      │
│  ██████╗ ███████╗ ███████╗██╗  ██╗             │
│  ██╔══██╗██╔════╝ ██╔════╝██║  ██║             │
│  ██║  ██║█████╗  █████╗  ███████║             │
│  ██║  ██║██╔══╝  ██╔══╝  ██╔══██║             │
│  ██████╔╝███████╗███████╗██║  ██║             │
│  ╚═════╝ ╚══════╝╚══════╝╚═╝  ╚═╝             │
│                                                      │
│  Bluetooth BR/EDR offensive auditor · Linux only     │
│  by theoffsecgirl                                    │
└──────────────────────────────────────────────────────┘
```

---

## ¿Qué hace?

Herramienta minimalista para auditar dispositivos Bluetooth BR/EDR (Bluetooth clásico) en Linux usando la pila BlueZ. Sin frameworks, sin adornos: escaneo, fingerprinting, comprobación de actividad y pruebas de estrés controladas.

---

## Funcionalidades

- Escaneo e inquiry scan de dispositivos BR/EDR
- Comprobación de actividad vía `l2ping`
- Prueba de estrés controlada con confirmación
- Soporte para múltiples interfaces (`hci0`, `hci1`, …)
- Menú interactivo y flags CLI
- Logging y exportación de resultados

---

## Requisitos

- Linux (Debian, Ubuntu, Arch, Kali…)
- Bash + BlueZ (`hcitool`, `hciconfig`, `l2ping`)
- Adaptador Bluetooth compatible
- Privilegios de superusuario

---

## Compatibilidad

| Entorno | Estado |
|---------|--------|
| Linux | ✅ Compatible |
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

# Escaneo
sudo ./bluedeath.sh --scan

# Inquiry scan
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
