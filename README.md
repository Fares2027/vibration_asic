
```markdown
# Vibration Anomaly Detection ASIC

A hardware-based vibration anomaly detection system designed for implementation as an ASIC and validation on FPGA.

The system learns the normal vibration behavior of a machine using accelerometer data, extracts multiple vibration features in hardware, and raises an alert when the observed vibration significantly deviates from the learned baseline.

The project is implemented in Verilog and currently targets:

- ASIC implementation using the Sky130 PDK and LibreLane
- FPGA validation using the Tang Nano 20K
- LIS3DH digital accelerometer through SPI

---

## Concept

The basic operating principle is:

```text
Accelerometer
     ↓
SPI Interface
     ↓
Signal Conditioning
     ↓
Feature Extraction
     ↓
Online Learning
     ↓
Anomaly Scoring
     ↓
Persistence Check
     ↓
Alert
```

During the learning phase, the circuit observes normal machine vibration and builds a statistical baseline.

After learning is complete, incoming vibration windows are compared against this baseline. If the deviation is sufficiently large and persists for multiple observations, the system generates an anomaly alert.

A simple demonstration scenario is:

```text
Normal fan operation
        ↓
Learn normal vibration
        ↓
Introduce mechanical imbalance
        ↓
Vibration characteristics change
        ↓
Anomaly detected
        ↓
Alert triggered
```

---

## Architecture

The design contains the following main RTL modules.

### Sensor Interface

`spi_master.v`

Generic SPI communication engine.

`lis3dh_controller.v`

Controls the LIS3DH accelerometer, performs initialization, verifies the sensor identity, and reads X/Y/Z acceleration samples.

---

### Sampling and Signal Processing

`sample_tick.v`

Generates the accelerometer sampling timing.

`dc_filter.v`

Removes the DC component from the acceleration signal.

`window_engine.v`

Divides the signal into processing windows.

---

### Feature Extraction

The design extracts several vibration characteristics.

`peak_detector.v`

Measures peak vibration amplitude.

`zcr_detector.v`

Calculates the zero-crossing rate.

`rms_energy.v`

Calculates vibration energy.

`goertzel_shared.v`

Implements a shared Goertzel processing engine for monitoring selected vibration frequency components.

The shared implementation reduces arithmetic hardware compared with using multiple independent Goertzel engines.

---

### Feature Processing

`feature_scaler.v`

Scales extracted vibration features before statistical processing.

---

### Online Learning

`running_stats.v`

Maintains the running statistical baseline for a feature.

`learning_bank.v`

Maintains the learned baseline for all monitored vibration features.

The system learns normal behavior directly from the machine instead of requiring a pre-trained machine-learning model.

---

### Anomaly Detection

`anomaly_score.v`

Compares current vibration features with the learned baseline and determines whether individual features are abnormal.

`alert_persistence.v`

Prevents isolated spikes from immediately generating an alarm by requiring the anomaly condition to persist.

---

### Top Level

`vibration_asic_top.v`

Integrates the complete system:

```text
LIS3DH
  ↓
SPI Controller
  ↓
DC Filtering
  ↓
Window Processing
  ↓
Peak / ZCR / Energy / Goertzel
  ↓
Feature Scaling
  ↓
Learning Bank
  ↓
Anomaly Score
  ↓
Persistence Logic
  ↓
Alert
```

---

## Current Status

The complete RTL design has been integrated and verified using simulation.

Current full-chip simulation sequence:

```text
SENSOR INITIALIZED
LEARNING COMPLETE
IMBALANCE INTRODUCED
ALERT TRIGGERED
FULL CHIP SIMULATION: PASS
```

Individual modules also have dedicated Verilog testbenches under the `tb/` directory.

---

## ASIC Implementation

The ASIC flow uses:

- Verilog RTL
- Yosys
- LibreLane
- OpenROAD
- Sky130 PDK

The design has successfully passed RTL synthesis and technology mapping.

A previously measured optimized top-level mapped logic area was approximately:

```text
0.775 mm²
```

This value represents synthesized standard-cell logic and should not be interpreted as final fabricated die area.

Physical design work includes:

```text
Synthesis
Floorplanning
Placement
Clock Tree Synthesis
Timing Optimization
Routing
STA
DRC
LVS
GDSII
```

ASIC configuration files are located under:

```text
openlane/
```

Generated LibreLane runs are intentionally excluded from the repository because they can become very large.

---

## FPGA Validation

The project is also being prepared for hardware validation on:

**Sipeed Tang Nano 20K**

FPGA family:

```text
Gowin GW2A / GW2AR
```

The FPGA flow uses:

- Yosys
- OSS CAD Suite
- nextpnr-himbaechel
- Project Apicula / Gowin support

Modern Yosys versions successfully infer Gowin multiplier resources from the arithmetic blocks.

Example FPGA synthesis results:

```text
LUT1        146
LUT2       1064
LUT3        645
LUT4       1914

MULT18X18     7
MULT36X36     8
MULT9X9       1
```

Place-and-route and physical FPGA validation are the next steps.

---

## Repository Structure

```text
vibration_asic/
│
├── rtl/
│   ├── alert_persistence.v
│   ├── anomaly_score.v
│   ├── dc_filter.v
│   ├── feature_scaler.v
│   ├── goertzel_bank.v
│   ├── goertzel_core.v
│   ├── goertzel_shared.v
│   ├── learning_bank.v
│   ├── lis3dh_controller.v
│   ├── peak_detector.v
│   ├── rms_energy.v
│   ├── running_stats.v
│   ├── sample_tick.v
│   ├── spi_master.v
│   ├── vibration_asic_top.v
│   ├── window_engine.v
│   └── zcr_detector.v
│
├── tb/
│   └── Verilog testbenches
│
├── sim/
│   └── Simulation outputs
│
├── openlane/
│   └── ASIC / LibreLane configuration
│
├── fpga/
│   └── FPGA implementation files
│
└── docs/
    └── Project documentation
```

---

## Running the Full-Chip Simulation

The design can be simulated using Icarus Verilog.

From the project directory:

```bash
iverilog -s tb_full_chip \
-o sim/full_chip.vvp \
rtl/*.v \
tb/tb_full_chip.v
```

Run the simulation:

```bash
vvp sim/full_chip.vvp
```

A successful test should end with:

```text
FULL CHIP: SENSOR INITIALIZED
FULL CHIP: LEARNING COMPLETE
FULL CHIP: IMBALANCE INTRODUCED
FULL CHIP: ALERT TRIGGERED
FULL CHIP SIMULATION: PASS
```

---

## FPGA Synthesis

With a recent Yosys version supporting Gowin DSP inference:

```bash
yosys -p "read_verilog rtl/*.v; \
synth_gowin -top vibration_asic_top \
-family gw2a \
-json fpga/vibration_asic.json; \
stat"
```

The resulting JSON netlist can then be used by the Gowin-compatible nextpnr flow.

---

## Design Goals

The project is intended to explore a compact hardware architecture for vibration condition monitoring with several characteristics:

- Fully local processing
- No cloud dependency
- No large neural-network inference engine
- Online learning of normal machine behavior
- Real-time vibration monitoring
- Low-latency anomaly detection
- ASIC-oriented architecture
- FPGA-verifiable RTL
- Potential low-power embedded deployment

---

## Potential Applications

Possible applications include:

- Electric motors
- Fans
- Pumps
- Industrial machinery
- Rotating equipment
- Bearings
- HVAC systems
- Predictive maintenance nodes
- Embedded condition-monitoring systems

---

## Development Roadmap

Current development direction:

```text
RTL Design                 ✅
Module Verification        ✅
Full-Chip Simulation       ✅
ASIC Synthesis             ✅
ASIC Optimization          ✅
Physical Design            In Progress
FPGA Synthesis             ✅
FPGA Place & Route         Next
FPGA Hardware Validation   Next
Accelerometer Demo         Planned
ASIC Tapeout               Future
```

The planned physical demonstration is:

```text
Machine running normally
        ↓
Learn vibration baseline
        ↓
Introduce mechanical imbalance
        ↓
Detect abnormal vibration
        ↓
Trigger hardware alert
```

---

## Project Purpose

This repository is primarily an engineering and research project exploring how vibration anomaly detection can be implemented directly in digital hardware rather than relying on a general-purpose processor or cloud-based analytics system.

The goal is to progress from:

```text
Algorithm
→ RTL
→ Simulation
→ FPGA
→ ASIC
→ Physical Silicon
```

and validate the complete hardware architecture experimentally.
```
