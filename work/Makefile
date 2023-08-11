i2s_lint: ../rtl/i2s.v 
	verilator --lint-only ../rtl/i2s.v 

i2s_tb: ../rtl/i2s.v ../tb/i2s_tb.sv 
	rm -rfv i2s_tb.vcd
	iverilog ../rtl/i2s.v ../tb/i2s_tb.sv 
	./a.out
	gtkwave ./i2s_tb.vcd
