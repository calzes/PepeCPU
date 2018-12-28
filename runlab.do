# Create work library
vlib work

# Compile Verilog
#     All Verilog files that are part of this design should have
#     their own "vlog" line below.

#####################################################################
# Multiplexers
vlog "./Multiplexers/mux_2x1.sv"
vlog "./Multiplexers/mux_4x1.sv"
vlog "./Multiplexers/mux_8x1.sv"
vlog "./Multiplexers/mux_16x1.sv"
vlog "./Multiplexers/mux_32x1.sv"
vlog "./Multiplexers/mux_64x32x1.sv"
vlog "./Multiplexers/mux_64x2x1.sv"
vlog "./Multiplexers/mux_5x2x1.sv"

# Decoders
vlog "./Decoders/decoder_1x2.sv"
vlog "./Decoders/decoder_2x4.sv"
vlog "./Decoders/decoder_3x8.sv"
vlog "./Decoders/decoder_4x16.sv"
vlog "./Decoders/decoder_5x32.sv"



# Path elements
vlog "./Elements/regfile.sv"
vlog "./Elements/alu_new.sv"
vlog "./Elements/register.sv"
vlog "./Elements/D_FF.sv"
vlog "./Elements/register_nbit.sv"

vlog "./Elements/full_adder.sv"
vlog "./Elements/is_zero.sv"
vlog "./Elements/bit_slice.sv"
vlog "./Elements/adder_64.sv"
vlog "./Elements/enable_DFF.sv"

# Provided elements
vlog "./Supplementary/datamem.sv"
vlog "./Supplementary/instructmem.sv"
vlog "./Supplementary/math.sv"

# Datapath Subsections
vlog "./Paths/control.sv"
# vlog "./Paths/datapath.sv"
vlog "./Paths/instruction_stuff.sv"
vlog "./Paths/forwarding.sv"

# Top level Module
vlog "./Pipelined_CPU.sv"

# Simulation file
vlog "./cpustim.sv"


######################################################################

# Call vsim to invoke simulator
#     Make sure the last item on the line is the name of the
#     testbench module you want to execute.
vsim -voptargs="+acc" -t 1ps -lib work cpustim

# Source the wave do file
#     This should be the file that sets up the signal window for
#     the module you are testing.
do cpustim_wave.do

# Set the window types
view wave
view structure
view signals

# Run the simulation
run -all

# End
