`timescale 1ns/100ps

module sar_logic_CS_tb;
	reg clk;
	reg rst;
	reg cnvst;
	reg cmp_out;
	wire [7:0] sar; // digital output
	wire eoc; // end of conversion
	wire cmp_clk; // comparator clock

	wire s_clk; // bootstrap switch clock
	wire [15:0] fine_btm;
	wire fine_switch_drain;

	//INVERTED OUTPUTS
	wire s_clk_not;
	wire [15:0] fine_btm_not;
	wire fine_switch_drain_not;


	sar_logic_CS test(clk, rst, cnvst, cmp_out, sar, eoc, cmp_clk, s_clk, fine_btm, fine_switch_drain, s_clk_not, fine_btm_not, fine_switch_drain_not);

	always #5 clk = !clk;

	initial begin

		$dumpfile("sar_logic_CS.vcd");
		$dumpvars(0, sar_logic_CS_tb);

		clk = 0;
		rst = 1;
		cnvst = 0;
		cmp_out = 1;

		#30

		rst = 0;
		cmp_out = 1;
		cnvst = 1;

		#20

		cnvst = 1;

		#300

		

		$finish;

	end
endmodule