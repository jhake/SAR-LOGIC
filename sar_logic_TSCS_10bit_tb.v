`timescale 1ns/100ps

module sar_logic_TSCS_10bit_tb;
	reg clk;
	reg rst;
	reg cnvst;
	reg cmp_out;
	wire [9:0] sar;
	wire eoc;
	wire cmp_clk;
	wire s_clk;

	wire [12:0] fine_sca1_top;
	wire [12:0] fine_sca1_btm;
	wire [12:0] fine_sca2_top;
	wire [12:0] fine_sca2_btm;
	wire fine_switch_S;

	wire s_clk_not;
	wire [12:0] fine_sca1_top_not;
	wire [12:0] fine_sca1_btm_not;
	wire [12:0] fine_sca2_top_not;
	wire [12:0] fine_sca2_btm_not;
	wire fine_switch_S_not;


	sar_logic_TSCS_10bit test(clk, rst, cnvst, cmp_out, sar, eoc, cmp_clk, s_clk, fine_sca1_top, fine_sca1_btm, fine_sca2_top, fine_sca2_btm, fine_switch_S, fine_switch_drain, s_clk_not, fine_sca1_top_not,
		fine_sca1_btm_not, fine_sca2_top_not, fine_sca2_btm_not, fine_switch_S_not, fine_switch_drain_not);

	always #5 clk = !clk;

	initial begin

		$dumpfile("sar_logic_TSCS_10bit.vcd");
		$dumpvars(0, sar_logic_TSCS_10bit_tb);

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