############################################################
# Arty A7-100T - KNN SoC Final Constraints (AXI UART 16550 rev)
# Wrapper: design_1_wrapper
#
# Ports confirmed from wrapper HDL:
#   clk_in1_0            input
#   led_4bits_tri_o      output [3:0]
#   qspi_flash_io0_io    inout
#   qspi_flash_io1_io    inout
#   qspi_flash_io2_io    inout
#   qspi_flash_io3_io    inout
#   qspi_flash_ss_io     inout [0:0]
#   resetn_0             input [0:0]
#   trap_0               output
#   usb_uart_rxd         input
#   usb_uart_txd         output
#   usb_uart_baudoutn    output   <- new, 16550 modem/status bus
#   usb_uart_ctsn        input    <- new
#   usb_uart_dcdn        input    <- new
#   usb_uart_ddis        output   <- new
#   usb_uart_dsrn        input    <- new
#   usb_uart_dtrn        output   <- new
#   usb_uart_out1n       output   <- new
#   usb_uart_out2n       output   <- new
#   usb_uart_ri          input    <- new
#   usb_uart_rtsn        output   <- new
#   usb_uart_rxrdyn      output   <- new
#   usb_uart_txrdyn      output   <- new
#
# SCK has NO port - axi_quad_spi routes it via STARTUPE2 internally.
# Do NOT add a constraint for CCLK/L16 - it will cause a DRC error.
#
# The AXI UART 16550 IP config brought out full RS-232 modem control
# signals to the wrapper. Nothing external is attached to them (no
# real modem/DTE), and RTS/CTS hardware flow control isn't wanted, so
# every one of these is routed to a spare Pmod pin (JB/JC) with an
# internal weak pull resistor instead of a real wire. That satisfies
# Vivado's DRC (every port needs a PACKAGE_PIN) without touching any
# external hardware.
#
# Correct long-term fix instead of this: re-customize the AXI UART
# 16550 IP and disable the modem-signal option so these 12 ports never
# get generated in the first place (same approach as the working AXI
# UART Lite design, which only has rxd/txd). This patch is the
# "keep the bitstream you already have working" path.
############################################################

############################################################
# Clock
# (No create_clock here on purpose - clk_wiz_0's own auto-generated
#  .xdc already constrains clk_in1_0 at the right period. Adding a
#  second create_clock on the same port just produces the
#  "completely overrides" warning for no benefit.)
############################################################
set_property PACKAGE_PIN E3       [get_ports clk_in1_0]
set_property IOSTANDARD  LVCMOS33 [get_ports clk_in1_0]

############################################################
# UART - data lines (real, connected to the USB-UART bridge)
############################################################
set_property PACKAGE_PIN D10      [get_ports usb_uart_txd]
set_property IOSTANDARD  LVCMOS33 [get_ports usb_uart_txd]

set_property PACKAGE_PIN A9       [get_ports usb_uart_rxd]
set_property IOSTANDARD  LVCMOS33 [get_ports usb_uart_rxd]

############################################################
# UART 16550 modem/status bus - tied off, no external device
#
# Inputs (nothing drives these unless pulled): pull to whichever
# level means "inactive" for that active-low signal, so the 16550
# core never blocks/misbehaves waiting on a modem that isn't there.
#   CTSN (Clear To Send)     -> pull LOW  = permanently asserted/OK
#   DCDN (Data Carrier Det.) -> pull LOW  = permanently asserted
#   DSRN (Data Set Ready)    -> pull LOW  = permanently asserted
#   RI   (Ring Indicator)    -> pull HIGH = permanently inactive
#
# Outputs (FPGA drives these; nothing needs to read them, so they
# just need a legal pin - no pull, no external connection required):
#   RTSN, DTRN, OUT1N, OUT2N, DDIS, RXRDYN, TXRDYN, BAUDOUTN
############################################################

# -- Inputs, tied via internal pull (Pmod JB) --
set_property PACKAGE_PIN E15      [get_ports usb_uart_ctsn]
set_property IOSTANDARD  LVCMOS33 [get_ports usb_uart_ctsn]
set_property PULLTYPE    PULLDOWN [get_ports usb_uart_ctsn]

set_property PACKAGE_PIN E16      [get_ports usb_uart_dcdn]
set_property IOSTANDARD  LVCMOS33 [get_ports usb_uart_dcdn]
set_property PULLTYPE    PULLDOWN [get_ports usb_uart_dcdn]

set_property PACKAGE_PIN D15      [get_ports usb_uart_dsrn]
set_property IOSTANDARD  LVCMOS33 [get_ports usb_uart_dsrn]
set_property PULLTYPE    PULLDOWN [get_ports usb_uart_dsrn]

set_property PACKAGE_PIN C15      [get_ports usb_uart_ri]
set_property IOSTANDARD  LVCMOS33 [get_ports usb_uart_ri]
set_property PULLTYPE    PULLUP   [get_ports usb_uart_ri]

# -- Outputs, no pull needed (Pmod JB continued) --
set_property PACKAGE_PIN J17      [get_ports usb_uart_rtsn]
set_property IOSTANDARD  LVCMOS33 [get_ports usb_uart_rtsn]

set_property PACKAGE_PIN J18      [get_ports usb_uart_dtrn]
set_property IOSTANDARD  LVCMOS33 [get_ports usb_uart_dtrn]

set_property PACKAGE_PIN K15      [get_ports usb_uart_out1n]
set_property IOSTANDARD  LVCMOS33 [get_ports usb_uart_out1n]

set_property PACKAGE_PIN J15      [get_ports usb_uart_out2n]
set_property IOSTANDARD  LVCMOS33 [get_ports usb_uart_out2n]

# -- Outputs, Pmod JC --
set_property PACKAGE_PIN U12      [get_ports usb_uart_ddis]
set_property IOSTANDARD  LVCMOS33 [get_ports usb_uart_ddis]

set_property PACKAGE_PIN V12      [get_ports usb_uart_baudoutn]
set_property IOSTANDARD  LVCMOS33 [get_ports usb_uart_baudoutn]

set_property PACKAGE_PIN V10      [get_ports usb_uart_rxrdyn]
set_property IOSTANDARD  LVCMOS33 [get_ports usb_uart_rxrdyn]

set_property PACKAGE_PIN V11      [get_ports usb_uart_txrdyn]
set_property IOSTANDARD  LVCMOS33 [get_ports usb_uart_txrdyn]

############################################################
# Reset - dedicated CPU_RESET button, active-low (was D9/btn0,
# which is active-HIGH and idles at 0 -- that held resetn_0 in
# permanent reset except while physically pressed. C2 idles high
# and pulls low when pressed, matching resetn_0's active-low sense
# directly, no inverter needed).
############################################################
set_property PACKAGE_PIN C2       [get_ports {resetn_0[0]}]
set_property IOSTANDARD  LVCMOS33 [get_ports {resetn_0[0]}]

############################################################
# LEDs - pure output [3:0]
# LD4=H5, LD5=J5, LD6=T9, LD7=T10
############################################################
set_property PACKAGE_PIN H5       [get_ports {led_4bits_tri_o[0]}]
set_property IOSTANDARD  LVCMOS33 [get_ports {led_4bits_tri_o[0]}]

set_property PACKAGE_PIN J5       [get_ports {led_4bits_tri_o[1]}]
set_property IOSTANDARD  LVCMOS33 [get_ports {led_4bits_tri_o[1]}]

set_property PACKAGE_PIN T9       [get_ports {led_4bits_tri_o[2]}]
set_property IOSTANDARD  LVCMOS33 [get_ports {led_4bits_tri_o[2]}]

set_property PACKAGE_PIN T10      [get_ports {led_4bits_tri_o[3]}]
set_property IOSTANDARD  LVCMOS33 [get_ports {led_4bits_tri_o[3]}]

############################################################
# QSPI Flash - W25Q128JV on Arty A7-100T
# IO0=K17, IO1=K18, IO2=L14, IO3=M14, CS=L13
# IOSTANDARD must be LVCMOS33 - this fixes the NSTD-1 DRC
# PACKAGE_PIN must be set    - this fixes the UCIO-1 DRC
############################################################
set_property PACKAGE_PIN K17      [get_ports qspi_flash_io0_io]
set_property IOSTANDARD  LVCMOS33 [get_ports qspi_flash_io0_io]

set_property PACKAGE_PIN K18      [get_ports qspi_flash_io1_io]
set_property IOSTANDARD  LVCMOS33 [get_ports qspi_flash_io1_io]

set_property PACKAGE_PIN L14      [get_ports qspi_flash_io2_io]
set_property IOSTANDARD  LVCMOS33 [get_ports qspi_flash_io2_io]

set_property PACKAGE_PIN M14      [get_ports qspi_flash_io3_io]
set_property IOSTANDARD  LVCMOS33 [get_ports qspi_flash_io3_io]

set_property PACKAGE_PIN L13      [get_ports {qspi_flash_ss_io[0]}]
set_property IOSTANDARD  LVCMOS33 [get_ports {qspi_flash_ss_io[0]}]

############################################################
# Trap - PMOD JA pin 1
############################################################
set_property PACKAGE_PIN G13      [get_ports trap_0]
set_property IOSTANDARD  LVCMOS33 [get_ports trap_0]

############################################################
# False paths - async I/O not timed against fabric clock
# These paths are: UART TX/RX registers → pads, LED registers
# → pads, reset pad → sync chain. None are real timing paths.
############################################################
set_false_path -from [get_ports usb_uart_rxd]
set_false_path -to   [get_ports usb_uart_txd]
set_false_path -to   [get_ports {led_4bits_tri_o[*]}]
set_false_path -to   [get_ports trap_0]
set_false_path -from [get_ports {resetn_0[0]}]

# Modem/status bus - tied-off Pmod pins, not real timing paths either
set_false_path -from [get_ports usb_uart_ctsn]
set_false_path -from [get_ports usb_uart_dcdn]
set_false_path -from [get_ports usb_uart_dsrn]
set_false_path -from [get_ports usb_uart_ri]
set_false_path -to   [get_ports usb_uart_rtsn]
set_false_path -to   [get_ports usb_uart_dtrn]
set_false_path -to   [get_ports usb_uart_out1n]
set_false_path -to   [get_ports usb_uart_out2n]
set_false_path -to   [get_ports usb_uart_ddis]
set_false_path -to   [get_ports usb_uart_baudoutn]
set_false_path -to   [get_ports usb_uart_rxrdyn]
set_false_path -to   [get_ports usb_uart_txrdyn]

# QSPI data lines are source-synchronous to SPI clock, not the
# system clock. Mark them false w.r.t. sys_clk to avoid spurious failures.
set_false_path -to   [get_ports qspi_flash_io0_io]
set_false_path -from [get_ports qspi_flash_io0_io]
set_false_path -to   [get_ports qspi_flash_io1_io]
set_false_path -from [get_ports qspi_flash_io1_io]
set_false_path -to   [get_ports qspi_flash_io2_io]
set_false_path -from [get_ports qspi_flash_io2_io]
set_false_path -to   [get_ports qspi_flash_io3_io]
set_false_path -from [get_ports qspi_flash_io3_io]
set_false_path -to   [get_ports {qspi_flash_ss_io[0]}]
set_false_path -from [get_ports {qspi_flash_ss_io[0]}]

############################################################
# Bitstream - configure for Quad SPI flash boot
# Without these, the FPGA will NOT boot from flash on power-on
############################################################
set_property CFGBVS                        VCCO  [current_design]
set_property CONFIG_VOLTAGE                 3.3   [current_design]
set_property BITSTREAM.GENERAL.COMPRESS     TRUE  [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH  4     [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE    33    [current_design]
set_property CONFIG_MODE                    SPIx4 [current_design]
