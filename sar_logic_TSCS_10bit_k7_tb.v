`timescale 1ns/100ps

module sar_logic_TSCS_10bit_k7_tb;
	reg clk;
	reg rst;
	reg cnvst;
	reg coarse_cmp_out;
	reg fine_cmp_out;
	wire [9:0] sar; // digital wire
	wire eoc; // end of conversion
	wire coarse_cmp_clk; // comparator clock
	wire fine_cmp_clk;

	wire s_clk; // bootstrap switch clock

	wire [8:0] coarse_sca1_top;
	wire [8:0] coarse_sca1_btm;
	wire [8:0] coarse_sca2_top;
	wire [8:0] coarse_sca2_btm;
	wire coarse_switch_S;
	wire coarse_switch_drain;

	wire [12:0] fine_sca1_top;
	wire [12:0] fine_sca1_btm;
	wire [12:0] fine_sca2_top;
	wire [12:0] fine_sca2_btm;
	wire fine_switch_S;
	wire fine_switch_drain;

	//INVERTED OUTPUTS
	wire s_clk_not;
	wire [8:0] coarse_sca1_top_not;
	wire [8:0] coarse_sca1_btm_not;
	wire [8:0] coarse_sca2_top_not;
	wire [8:0] coarse_sca2_btm_not;
	wire coarse_switch_S_not;
	wire coarse_switch_drain_not;

	wire [12:0] fine_sca1_top_not;
	wire [12:0] fine_sca1_btm_not;
	wire [12:0] fine_sca2_top_not;
	wire [12:0] fine_sca2_btm_not;
	wire fine_switch_S_not;
	wire fine_switch_drain_not;

	sar_logic_TSCS_10bit_k7 test(	
		clk,
		rst,
		cnvst,
		coarse_cmp_out,
		fine_cmp_out,
		sar, // digital wire
		eoc, // end of conversion
		coarse_cmp_clk, // comparator clock
		fine_cmp_clk,

		s_clk, // bootstrap switch clock

		coarse_sca1_top,
		coarse_sca1_btm,
		coarse_sca2_top,
		coarse_sca2_btm,
		coarse_switch_S,
		coarse_switch_drain,

		fine_sca1_top,
		fine_sca1_btm,
		fine_sca2_top,
		fine_sca2_btm,
		fine_switch_S,
		fine_switch_drain,

		//INVERTED OUTPUTS
		s_clk_not,
		coarse_sca1_top_not,
		coarse_sca1_btm_not,
		coarse_sca2_top_not,
		coarse_sca2_btm_not,
		coarse_switch_S_not,
		coarse_switch_drain_not,

		fine_sca1_top_not,
		fine_sca1_btm_not,
		fine_sca2_top_not,
		fine_sca2_btm_not,
		fine_switch_S_not,
		fine_switch_drain_not
	);

	always #5 clk = !clk;

	initial begin

		$dumpfile("sar_logic_TSCS_10bit_k7.vcd");
		$dumpvars(0, sar_logic_TSCS_10bit_k7_tb);

		clk = 0;
		rst = 1;
		cnvst = 0;
		coarse_cmp_out = 0;
		fine_cmp_out = 0;

		#30

		rst = 0;
		cnvst = 1;

		#20

		cnvst = 1;

		#400

		

		$finish;

	end
endmodule