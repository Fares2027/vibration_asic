# Vibration Anomaly Detection ASIC

Hardware-based vibration anomaly detection system implemented in Verilog for ASIC development and FPGA validation.

The system reads vibration data from a digital accelerometer, extracts several vibration features directly in hardware, learns the normal operating behavior of a machine, and raises an alert when the vibration pattern significantly deviates from the learned baseline.

The project is currently developed for:

- ASIC implementation using Sky130 and LibreLane
- FPGA validation using the Tang Nano 20K
- LIS3DH accelerometer through SPI


PROJECT CONCEPT

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
Anomaly Detection
    ↓
Persistence Check
    ↓
Alert

During the learning phase, the circuit observes normal machine vibration and builds a statistical baseline.

After the learning phase, each new vibration window is compared against the stored baseline.

If the difference becomes large enough and persists for multiple observations, the system generates an anomaly alert.


EXAMPLE DEMONSTRATION

Normal fan operation
    ↓
System learns normal vibration
    ↓
Mechanical imbalance is introduced
    ↓
Vibration characteristics change
    ↓
Anomaly is detected
    ↓
Alert is triggered


MAIN RTL MODULES

spi_master.v
Generic SPI communication engine.

lis3dh_controller.v
Initializes the LIS3DH accelerometer, verifies the sensor identity, and reads X, Y, and Z acceleration data.

sample_tick.v
Generates the accelerometer sampling timing.

dc_filter.v
Removes the DC component from acceleration signals.

window_engine.v
Controls vibration processing windows.

peak_detector.v
Extracts peak vibration amplitude.

zcr_detector.v
Calculates zero-crossing rate.

rms_energy.v
Calculates vibration energy.

goertzel_shared.v
Shared Goertzel processing architecture for monitoring selected vibration frequency components.

feature_scaler.v
Scales extracted vibration features before statistical processing.

running_stats.v
Maintains running statistical values for individual features.

learning_bank.v
Maintains the learned baseline for all monitored vibration features.

anomaly_score.v
Compares current vibration features against the learned baseline.

alert_persistence.v
Requires anomaly conditions to persist before generating the final alert.

vibration_asic_top.v
Top-level module integrating the complete system.


SYSTEM ARCHITECTURE

LIS3DH Accelerometer
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


CURRENT STATUS

The complete RTL design has been integrated and verified using simulation.

Current full-chip simulation sequence:

FULL CHIP: SENSOR INITIALIZED
FULL CHIP: LEARNING COMPLETE
FULL CHIP: IMBALANCE INTRODUCED
FULL CHIP: ALERT TRIGGERED
FULL CHIP SIMULATION: PASS

Individual RTL modules also have dedicated Verilog testbenches.


ASIC DEVELOPMENT

ASIC toolchain:

Verilog RTL
Yosys
LibreLane
OpenROAD
Sky130 PDK

The design has passed synthesis and technology mapping.

An optimized top-level mapped logic area measured approximately:

0.775 mm²

This value represents synthesized standard-cell logic area and is not the final fabricated die size.

The ASIC physical-design flow includes:

Synthesis
Floorplanning
Placement
Clock Tree Synthesis
Timing Optimization
Routing
Static Timing Analysis
DRC
LVS
GDSII

ASIC configuration files are located under:

openlane/


FPGA VALIDATION

Target FPGA:

Sipeed Tang Nano 20K

FPGA family:

Gowin GW2A / GW2AR

FPGA toolchain:

Yosys
OSS CAD Suite
nextpnr-himbaechel
Project Apicula

A recent Yosys version successfully mapped arithmetic operations to Gowin multiplier resources.

Example synthesis result:

LUT1        146
LUT2       1064
LUT3        645
LUT4       1914

MULT18X18     7
MULT36X36     8
MULT9X9       1

FPGA place-and-route and physical hardware validation are the next development steps.


REPOSITORY STRUCTURE

vibration_asic/

rtl/
    alert_persistence.v
    anomaly_score.v
    dc_filter.v
    feature_scaler.v
    goertzel_bank.v
    goertzel_core.v
    goertzel_shared.v
    learning_bank.v
    lis3dh_controller.v
    peak_detector.v
    rms_energy.v
    running_stats.v
    sample_tick.v
    spi_master.v
    vibration_asic_top.v
    window_engine.v
    zcr_detector.v

tb/
    Verilog testbenches

sim/
    Simulation outputs

openlane/
    ASIC and LibreLane configuration

fpga/
    FPGA implementation files

docs/
    Project documentation


FULL-CHIP SIMULATION

From the project directory:

iverilog -s tb_full_chip \
-o sim/full_chip.vvp \
rtl/*.v \
tb/tb_full_chip.v

Run:

vvp sim/full_chip.vvp

Expected successful result:

FULL CHIP: SENSOR INITIALIZED
FULL CHIP: LEARNING COMPLETE
FULL CHIP: IMBALANCE INTRODUCED
FULL CHIP: ALERT TRIGGERED
FULL CHIP SIMULATION: PASS


FPGA SYNTHESIS

Using a recent Yosys version with Gowin support:

yosys -p "read_verilog rtl/*.v; synth_gowin -top vibration_asic_top -family gw2a -json fpga/vibration_asic.json; stat"

The generated JSON netlist can then be used with nextpnr-himbaechel for Gowin FPGA place-and-route.


DESIGN GOALS

Fully local vibration processing

No cloud dependency

No large neural-network inference engine

Online learning of normal machine behavior

Real-time anomaly detection

Low-latency hardware processing

ASIC-oriented architecture

FPGA-verifiable RTL

Potential low-power embedded deployment


POTENTIAL APPLICATIONS

Electric motors

Fans

Pumps

Industrial machinery

Rotating equipment

Bearings

HVAC systems

Predictive maintenance nodes

Embedded condition-monitoring systems


DEVELOPMENT STATUS

RTL Design                  COMPLETE

Module Verification         COMPLETE

Full-Chip Simulation        COMPLETE

ASIC Synthesis              COMPLETE

ASIC Optimization           COMPLETE

ASIC Physical Design        IN PROGRESS

FPGA Synthesis              COMPLETE

FPGA Place and Route        NEXT

FPGA Hardware Validation    NEXT

Accelerometer Demo          PLANNED

ASIC Tapeout                FUTURE


PLANNED HARDWARE DEMO

Machine running normally
    ↓
Learn vibration baseline
    ↓
Introduce mechanical imbalance
    ↓
Detect abnormal vibration
    ↓
Trigger hardware alert


PROJECT PURPOSE

This project explores the implementation of vibration anomaly detection directly in digital hardware.

The system is intended to perform feature extraction, online learning, anomaly comparison, and alert generation without relying on a general-purpose CPU, cloud service, or large machine-learning model.

Development path:

Algorithm
    ↓
RTL
    ↓
Simulation
    ↓
FPGA
    ↓
ASIC
    ↓
Physical Silicon
