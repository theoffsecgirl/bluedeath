# **BLUEDEATH**

Herramienta de auditoría Bluetooth (BR/EDR) para Linux.
Permite escanear, identificar actividad, comprobar conectividad y ejecutar pruebas de estrés controladas basadas en `l2ping` usando la pila BlueZ.

## ¿Por qué existe BLUEDEATH?

La mayoría de herramientas para auditoría Bluetooth clásico están desfasadas, incompletas o son demasiado ruidosas.
`BLUEDEATH` nace para ofrecer una alternativa **clara, minimalista y funcional**, pensada para:

* enumerar dispositivos BR/EDR de forma fiable,
* verificar actividad mediante `l2ping`,
* realizar pruebas de estrés controladas,
* registrar resultados de forma limpia y consistente.

Sin adornos. Sin frameworks innecesarios. Funcionalidad pura.

## Funcionalidades

* Escaneo de dispositivos BR/EDR
* Inquiry scan (dispositivos descubribles/conectables)
* Comprobación de actividad (respuesta a `l2ping`)
* Prueba de estrés controlada (l2ping flood con confirmación)
* Exportación de resultados
* Logging automático
* Flags CLI y menú interactivo
* Soporte para múltiples interfaces (`hci0`, `hci1`, …)

## Requisitos

* Linux real (Debian, Ubuntu, Arch, Kali…)
* Bash
* BlueZ (`hcitool`, `hciconfig`, `l2ping`)
* Privilegios de superusuario
* Adaptador Bluetooth compatible

## Compatibilidad

| Entorno     | Estado          | Motivo                        |
| ----------- | --------------- | ----------------------------- |
| Linux       | ✔️ Compatible   | BlueZ soportado               |
| macOS       | ❌ No compatible | macOS no usa BlueZ            |
| Windows     | ❌ No compatible | Sin stack BlueZ               |
| WSL         | ❌ No compatible | No hay acceso a hardware real |
| VPS / cloud | ❌ No compatible | No existe hardware Bluetooth  |

## Instalación

```bash
git clone https://github.com/theoffsecgirl/tool-bluedeath
cd tool-bluedeath
chmod +x bluedeath.sh
```

## Uso

### Menú interactivo

```bash
sudo ./bluedeath.sh --menu
```

### Escaneo

```bash
sudo ./bluedeath.sh --scan
```

**Ejemplo de salida:**

```
Escaneando…
    00:1A:7D:DA:71:13  Altavoz_1
    D8:AB:C1:22:3F:90  BandaFitness
```

### Inquiry scan

```bash
sudo ./bluedeath.sh --inquiry
```

### Comprobar actividad (ping Bluetooth)

```bash
sudo ./bluedeath.sh --active
```

### Prueba de estrés controlada

```bash
sudo ./bluedeath.sh --dos AA:BB:CC:DD:EE:FF
```

### Usar una interfaz concreta

```bash
sudo BT_INTERFACE=hci1 ./bluedeath.sh --scan
```

## Uso ético

Esta herramienta debe emplearse únicamente en laboratorios controlados o en sistemas donde tengas autorización explícita.
El uso indebido es ilegal y no forma parte del propósito del proyecto.

## Licencia

BSD 3-Clause (incluida en el repositorio).
