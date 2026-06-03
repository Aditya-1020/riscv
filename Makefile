.PHONY: clean sim lint

TOPLEVEL ?= pc
TEST_BENCH   ?= tb/tb_$(TOPLEVEL).sv
VERILOG_SOURCES ?= rv32/$(TOPLEVEL).sv

# PDK
PDK_HASH  ?= 0fe599b2afb6708d281543108caf8310912f54af
PDK_ROOT   = $(HOME)/.volare/volare/sky130/versions/$(PDK_HASH)
PDK        ?= sky130A
PDK_PATH    = $(PDK_ROOT)/$(PDK)
SC_LIB      = $(PDK_PATH)/libs.ref/sky130_fd_sc_hd/verilog
PRIMITIVES  = $(SC_LIB)/primitives.v
SIMLIB      = $(SC_LIB)/sky130_fd_sc_hd.v

VLT_WARN  = -Wno-STMTDLY -Wno-ASSIGNDLY -Wno-BLKSEQ -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC -Wno-UNUSEDSIGNAL

IVL_WARN  = -Wno-timescale
LIBRELANE_CONFIG ?= config.json

export TOPLEVEL
export VERILOG_SOURCES
export PDK_PATH
# export LIBRELANE_CONFIG

lint:
	verilator --lint-only -Wall rv32/*.sv

synth:
	@mkdir -p dump
	yosys -c scripts/synth.tcl

librelane_sta:
	librelane --to OpenROAD.STAPrePNR $(LIBRELANE_CONFIG)

clean:
	rm -rf obj_dir obj_dir_gls dump runs
	rm -rf __pycache__ tb/__pycache__ sim_build
	rm -rf *.jou *.log *.vcd *.fst .Xil wave.vcd
	rm -rf tb/*.csv
