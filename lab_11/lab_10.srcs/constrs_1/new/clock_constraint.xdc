# ===========================================================
# XDC CONSTRAINTS FILE FOR TOP LEVEL PROCESSOR
# ===========================================================

# ===========================================================
# CLOCK CONSTRAINT
# ===========================================================
# Define the system clock with 100 MHz frequency (10 ns period)
# Adjust the clock port name if necessary

# Single-cycle processor: 50 MHz (20 ns period)
# This allows enough time for ALU + immediate generation + memory access
create_clock -period 20.000 -name clk [get_ports clk]

# ===========================================================
# INPUT/OUTPUT CONSTRAINTS
# ===========================================================
# These are typical for a Basys 3 or similar FPGA board
# Modify port names/locations based on your target board

# Clock input
set_property PACKAGE_PIN W5 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]

# Reset button
set_property PACKAGE_PIN U18 [get_ports rst]
set_property IOSTANDARD LVCMOS33 [get_ports rst]

# Slide switches (switches_in[15:0])
set_property PACKAGE_PIN V17 [get_ports {switches_in[0]}]
set_property PACKAGE_PIN V16 [get_ports {switches_in[1]}]
set_property PACKAGE_PIN W16 [get_ports {switches_in[2]}]
set_property PACKAGE_PIN W17 [get_ports {switches_in[3]}]
set_property PACKAGE_PIN W15 [get_ports {switches_in[4]}]
set_property PACKAGE_PIN V15 [get_ports {switches_in[5]}]
set_property PACKAGE_PIN W14 [get_ports {switches_in[6]}]
set_property PACKAGE_PIN W13 [get_ports {switches_in[7]}]
set_property PACKAGE_PIN V2 [get_ports {switches_in[8]}]
set_property PACKAGE_PIN T3 [get_ports {switches_in[9]}]
set_property PACKAGE_PIN T2 [get_ports {switches_in[10]}]
set_property PACKAGE_PIN R3 [get_ports {switches_in[11]}]
set_property PACKAGE_PIN W2 [get_ports {switches_in[12]}]
set_property PACKAGE_PIN U2 [get_ports {switches_in[13]}]
set_property PACKAGE_PIN T1 [get_ports {switches_in[14]}]
set_property PACKAGE_PIN R2 [get_ports {switches_in[15]}]

# IO voltage standard for switches
set_property IOSTANDARD LVCMOS33 [get_ports {switches_in[*]}]

# LEDs (leds_out[15:0])
set_property PACKAGE_PIN U16 [get_ports {leds_out[0]}]
set_property PACKAGE_PIN E19 [get_ports {leds_out[1]}]
set_property PACKAGE_PIN U19 [get_ports {leds_out[2]}]
set_property PACKAGE_PIN V19 [get_ports {leds_out[3]}]
set_property PACKAGE_PIN W18 [get_ports {leds_out[4]}]
set_property PACKAGE_PIN U15 [get_ports {leds_out[5]}]
set_property PACKAGE_PIN U14 [get_ports {leds_out[6]}]
set_property PACKAGE_PIN V14 [get_ports {leds_out[7]}]
set_property PACKAGE_PIN V13 [get_ports {leds_out[8]}]
set_property PACKAGE_PIN V3 [get_ports {leds_out[9]}]
set_property PACKAGE_PIN W3 [get_ports {leds_out[10]}]
set_property PACKAGE_PIN U3 [get_ports {leds_out[11]}]
set_property PACKAGE_PIN P3 [get_ports {leds_out[12]}]
set_property PACKAGE_PIN N3 [get_ports {leds_out[13]}]
set_property PACKAGE_PIN P1 [get_ports {leds_out[14]}]
set_property PACKAGE_PIN L1 [get_ports {leds_out[15]}]

# IO voltage standard for LEDs
set_property IOSTANDARD LVCMOS33 [get_ports {leds_out[*]}]

# ===========================================================
# TIMING ANALYSIS AND OPTIMIZATION DIRECTIVES
# ===========================================================
# No combinatorial loops in this design