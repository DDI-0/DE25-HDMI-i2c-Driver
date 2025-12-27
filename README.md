# DE25 HDMI I²C Driver (ADV7513) – VHDL

## Overview

This repository contains a **VHDL implementation of a single-byte I²C driver** used to configure the **ADV7513 HDMI transmitter** on the **DE25 FPGA board**. The I²C driver initializes the ADV7513, enabling the board to output video through the HDMI port.

## Project Purpose

The ADV7513 HDMI transmitter requires configuration over I²C before HDMI video output can function. This project implements a minimal I²C master in VHDL to perform the required single-byte write transactions for ADV7513 initialization on the DE25 board.

## Features

* VHDL-based I²C master
* Single-byte I²C write support
* ADV7513 HDMI transmitter initialization
* Designed for the DE25 FPGA board
* Simple finite state machine (FSM) architecture

## Hardware

* **FPGA Board:** DE25
* **HDMI Transmitter:** ADV7513
* **Interface:** HDMI
* **Protocol:** I²C

## How It Works

1. The I²C master generates START and STOP conditions.
2. The ADV7513 I²C slave address is transmitted.
3. Register address and configuration data are written one byte at a time.
4. After initialization, the ADV7513 is ready to transmit HDMI video data from the FPGA.

## Files

* `inc/vga_controller.vhd` – VGA controller module definitions and constants
* `vga_fsm.vhd` – VGA finite state machine for video timing control
* `vga_delay.vhd` – Delay logic used in VGA signal timing
* `hyper_pipe.vhd` – Pipelining module for video data path
* `top_level.vhd` – Top-level design integrating VGA, I²C, and HDMI control
* `i2c_controller.vhd` – I²C master controller implementation
* `i2c_hdmi_config.vhd` – ADV7513 HDMI transmitter configuration over I²C
* `top_timing.sdc` – Timing constraints for the DE25 FPGA design
  
## Usage

1. Add the VHDL source files to your Quartus project.
2. Assign SDA and SCL pins according to the DE25 schematic.
3. Compile and program the FPGA.
4. Connect an HDMI display to the DE25 board to verify HDMI output(should be a centered white square)

## License

This project is intended for educational use. You are free to modify and reuse the code.
