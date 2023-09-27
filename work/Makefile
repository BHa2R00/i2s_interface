i2s_lint: ../rtl/i2s.v 
	verilator --lint-only --top-module i2s ../rtl/i2s.v 

ahb_i2s_lint: ../rtl/i2s.v 
	verilator --lint-only --top-module ahb_i2s ../rtl/i2s.v 

i2s_tb: ../rtl/i2s.v ../tb/i2s_tb.sv 
	rm -rfv i2s_tb.fst
	${hdl_simulator} ../rtl/i2s.v ../tb/i2s_tb.sv 
	vvp ./a.out -fst
	gtkwave ./i2s_tb.fst
