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
