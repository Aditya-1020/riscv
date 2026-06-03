yosys -import

set top_module $::env(TOPLEVEL)
set sources [split $::env(VERILOG_SOURCES) " "]

foreach src $sources {
    puts "Reading source: $src"
    read_verilog -sv $src
}

hierarchy -check -top $top_module

synth -top $top_module

abc -g AND,OR,XOR
opt -full

clean

stat
write_verilog -noattr dump/${top_module}_synth.v
puts "\n\[SUCCESS\] Synthesis complete. Netlist saved to dump/${top_module}_synth.v"
