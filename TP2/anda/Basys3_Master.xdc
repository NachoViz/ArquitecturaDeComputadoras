## ==============================================================================
## Constraints (.xdc) para Digilent Basys 3 (Artix-7 XC7A35T-1CPG236C)
## Proyecto: TP2 - UART + Interfaz + ALU (anda)
## ==============================================================================

## Reloj de 100 MHz
set_property -dict { PACKAGE_PIN W5 IOSTANDARD LVCMOS33 } [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.000 -waveform {0.000 5.000} [get_ports clk]

## Botón de Reset (Botón Central U18)
set_property -dict { PACKAGE_PIN U18 IOSTANDARD LVCMOS33 } [get_ports i_reset]

## Puente USB-UART (FTDI)
##   i_rx: entrada serie hacia la FPGA (Pin B18)
##   o_tx: salida serie hacia la PC   (Pin A18)
set_property -dict { PACKAGE_PIN B18 IOSTANDARD LVCMOS33 } [get_ports i_rx]
set_property -dict { PACKAGE_PIN A18 IOSTANDARD LVCMOS33 } [get_ports o_tx]

## Los 16 LEDs (LD0 a LD15)
##   LD0..LD7  : resultado de la ALU
##   LD8       : flag de carry
##   LD9..LD11 : apagados (separador)
##   LD12..LD15: estado de la FSM de interfaz (one-hot)
set_property -dict { PACKAGE_PIN U16 IOSTANDARD LVCMOS33 } [get_ports {o_led[0]}]
set_property -dict { PACKAGE_PIN E19 IOSTANDARD LVCMOS33 } [get_ports {o_led[1]}]
set_property -dict { PACKAGE_PIN U19 IOSTANDARD LVCMOS33 } [get_ports {o_led[2]}]
set_property -dict { PACKAGE_PIN V19 IOSTANDARD LVCMOS33 } [get_ports {o_led[3]}]
set_property -dict { PACKAGE_PIN W18 IOSTANDARD LVCMOS33 } [get_ports {o_led[4]}]
set_property -dict { PACKAGE_PIN U15 IOSTANDARD LVCMOS33 } [get_ports {o_led[5]}]
set_property -dict { PACKAGE_PIN U14 IOSTANDARD LVCMOS33 } [get_ports {o_led[6]}]
set_property -dict { PACKAGE_PIN V14 IOSTANDARD LVCMOS33 } [get_ports {o_led[7]}]
set_property -dict { PACKAGE_PIN V13 IOSTANDARD LVCMOS33 } [get_ports {o_led[8]}]
set_property -dict { PACKAGE_PIN V3  IOSTANDARD LVCMOS33 } [get_ports {o_led[9]}]
set_property -dict { PACKAGE_PIN W3  IOSTANDARD LVCMOS33 } [get_ports {o_led[10]}]
set_property -dict { PACKAGE_PIN U3  IOSTANDARD LVCMOS33 } [get_ports {o_led[11]}]
set_property -dict { PACKAGE_PIN P3  IOSTANDARD LVCMOS33 } [get_ports {o_led[12]}]
set_property -dict { PACKAGE_PIN N3  IOSTANDARD LVCMOS33 } [get_ports {o_led[13]}]
set_property -dict { PACKAGE_PIN P1  IOSTANDARD LVCMOS33 } [get_ports {o_led[14]}]
set_property -dict { PACKAGE_PIN L1  IOSTANDARD LVCMOS33 } [get_ports {o_led[15]}]

## Como la linea i_rx es asincrónica y pasa por el sincronizador de 2 FF,
## no se le exige restricción de timing de llegada de reloj:
set_false_path -from [get_ports i_rx]
