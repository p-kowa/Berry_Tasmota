# Berry Tasmota Scripts

This folder contains two Berry scripts designed to work with Tasmota on Arduino devices.

## Scripts Overview

### 1. raincounter.be

A comprehensive rain gauge monitoring script for Tasmota that tracks rainfall data and integrates with Home Assistant via MQTT.

**Features:**
- Tracks total rainfall and daily rainfall accumulation
- Persistent storage in Flash memory (survives device resets)
- Automatic periodic saving of data every 5 minutes
- Home Assistant MQTT Discovery support for seamless integration
- Web interface display of rainfall metrics
- JSON sensor data formatting for Tasmota reporting

**Configuration:**
- `rain_per_tip`: Set to 0.2 liters per tilt (0.3mm precipitation). Adjust this value based on your rain gauge's specifications.

**How it works:**
- Listens for rain gauge switch state changes (tip events)
- Increments both `total_rain` and `today_rain` counters
- Publishes MQTT discovery messages for Home Assistant sensor integration
- Exposes data through Tasmota's web interface and JSON responses

**Persistent Storage:**
- `total_rain`: Cumulative rainfall (persists across reboots)
- `today_rain`: Daily rainfall accumulation

---

### 2. showsensordata.be

A sensor data display script that rotates through multiple SEN0600 sensors on a Tasmota display device.

**Features:**
- Automatically detects all connected SEN0600 environmental sensors
- Cycles through sensors every minute to show temperature and humidity
- Displays sensor readings on Tasmota DisplayText interface
- Handles both single and multiple sensor configurations
- Graceful error handling for missing sensors

**How it works:**
- Reads sensor data from `tasmota.read_sensors()`
- Looks for sensors with keys starting with `SEN0600_`
- Extracts Temperature and Humidity readings from nested sensor structure
- Rotates through sensors based on elapsed time (changes every minute)
- Updates display with current sensor name, temperature, and humidity

**Display Format:**
```
Temp: XX.XC
Hum: YY%
Sensor: SEN0600_X
```

**Execution:**
- Runs on a 5-second timer for responsiveness
- Also triggers on every minute change via the "Time#Minute" rule

---

## Installation

1. Place these `.be` files in your Tasmota Berry scripts folder
2. Load them via Tasmota console using:
   ```
   load_file raincounter.be
   load_file showsensordata.be
   ```

## Requirements

- **raincounter.be**: Requires a rain gauge sensor connected to Tasmota with MQTT broker configured
- **showsensordata.be**: Requires one or more SEN0600 sensors and a display device (DisplayText compatible)

## Tasmota Integration

Both scripts integrate with Tasmota's event system:
- Timers for periodic updates
- Rules system for event-driven execution
- Persistent storage for data retention
- MQTT publishing for smart home integration
