# Changelog

All notable changes to **bluedeath** are documented here.

---

## [1.2.0] – 2026-03-24

### Added
- `detect_stack()`: deteccion automatica de stack Bluetooth disponible.
- Soporte stack **moderno**: `bluetoothctl` + `btmgmt` (kernels >= 5.x).
- Soporte stack **legacy**: `hcitool` + `hciconfig` (BlueZ antiguo) como fallback.
- `scan_modern()` usa `btmgmt find` + `bluetoothctl scan` con timeout robusto via coproc.
- `inquiry_modern()` usa `btmgmt find --bredr` con fallback a bluetoothctl.
- `list_connected_modern()` usa `bluetoothctl devices Connected`.
- `check_interface()` adaptado a cada stack.
- Banner ASCII en color purple integrado en el script.
- Menu opcion 6 muestra info de interfaz con `btmgmt info` o `hciconfig` segun stack.
- `l2ping` comprobado solo en las fases que lo necesitan, no al arranque.

### Changed
- Repo renombrado: `tool-bluedeath` → `bluedeath`.
- `check_dependencies()` reemplazado por `detect_stack()`.
- `select_device_from_last_scan()` extrae MACs con grep regex, compatible con ambos formatos de salida.
- `set -o errexit` eliminado (interferia con CTRL+C en flood).

### Fixed
- `hcitool scan` deprecated en kernels >= 5.x: ahora usa `bluetoothctl`/`btmgmt` si estan disponibles.

---

## [1.1.0] – 2025-11-17

### Added
- Version inicial publica: scan, inquiry, l2ping check, DoS flood, menu interactivo, logging.
