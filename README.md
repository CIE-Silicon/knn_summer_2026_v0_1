# VIVADO_BLOCK_DESIGN_V01

A portable RISC-V SoC integration project based on the **PicoRV32** processor, designed for rapid deployment using a scripted Tcl flow.

---

##  Project Structure

* **`IP_REPO/`**
    * **`pico_core_ip/`**: Portable PicoRV32 wrapper IP.
        * **`src/`**: Contains PicoRV32 RTL, BootROM `.coe` files, and BRAM IP.
* **`SCRIPTS/`**
    * **`build_project.tcl`**: Script for the end-to-end establishment of the SoC block diagram.
* **`SoC_PJT/`**: Sample project along with simulation and flash model files.
    * **`flashmodels/`**: Contains memory files required for flash emulation.
    * **`sim/`**: Testbench files and simulation dependencies.
* **`master_tcl.tcl`**: Entry-point script. Sets up directory variables and launches the build by invoking `build_project.tcl`.

---

##  Setup Instructions

### 1. Clone the Repository

### 2. Launch and Build
Navigate into the parent folder (VIVADO_BLOCK_DESIGN_V01) and launch Vivado using the master script:


`cd VIVADO_BLOCK_DESIGN-V01`

`vivado -mode gui -source master_tcl.tcl`

IMPORTANT: The project setup will only initialize correctly if the script is invoked from the parent repository directory.

### 3. Generate and Simulate
Once the Vivado GUI opens and the project is created:

In the Sources pane, locate and right-click on design_1.bd.

Select Reset Output Products.

Select Generate Output Products.

Right-click design_1.bd again and select Create HDL Wrapper (ensure "Let Vivado manage wrapper" is selected).

Run Simulation from the Flow Navigator.


## Setup Video Reference
If you prefer a visual guide, click on the link to watch the setup and build process:
[Setup Video](https://drive.google.com/file/d/12DXg1meAnCka_F7diMZOxisBL-jpe2b8/view?usp=sharing)
