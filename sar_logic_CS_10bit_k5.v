module sar_logic_CS_10bit_k5(
	input clk,
	input rst,
	input cnvst,
	input cmp_out,
	input cmp_out_coarse,
	output reg [9:0] sar, // digital output
	output reg eoc, // end of conversion
	output reg cmp_clk, // comparator clock
	output reg cmp_clk_coarse,

	output reg s_clk, // bootstrap switch clock
	output reg [19:0] fine_btm,
	output reg [9:0] coarse_btm,
	output reg fine_switch_drain,
	output reg coarse_switch_drain,

	//INVERTED OUTPUTS
	output s_clk_not,
	output [19:0] fine_btm_not,
	output [9:0] coarse_btm_not,
	output fine_switch_drain_not,
	output coarse_switch_drain_not
	);
	
	// 256 128 64 32 16 8  4  2  1  1  256 128 64 32 16 8 4 2 1 1
	//  19  18 17 16 15 14 13 12 11 10   9   8  7  6  5 4 3 2 1 0 
	parameter S_wait						= 4'd0;
	parameter S_drain 					= 4'd1;
	parameter S_comprst					= 4'd2;
	parameter S_ds							= 4'd3;
	parameter S_comprst_coarse 	= 4'd4;
	parameter S_decide					= 4'd5;

	assign s_clk_not = ~s_clk;
	assign fine_btm_not = ~fine_btm;
	assign fine_switch_drain_not = ~fine_switch_drain;
	assign coarse_btm_not = ~coarse_btm;
	assign coarse_switch_drain_not = ~coarse_switch_drain;

	reg [3:0] state;
	reg drain;
	reg [3:0] b;
	reg [2:0] b_coarse;
	reg ds;

	reg fine_up; // 1 if SCA2 has upper bound voltage

	always @(posedge clk) begin //state transitions
		if (rst) 
			state <= S_wait;
		else
			case(state)
				S_wait:
					if(cnvst)
						state <= S_drain;
					else 
						state <= S_wait;
				S_drain:
					if(drain)
						state <= S_drain;
					else
						state <= S_comprst_coarse;
				S_comprst:
					state <= S_decide;
				S_comprst_coarse:
					state <= S_decide;
				S_ds:
					if(ds==0)
						state <= S_comprst;
				S_decide:
					if(b==0)
						state <= S_wait;
					else
						if(b_coarse)
							state <= S_comprst_coarse;
						else if(ds)
							state <= S_ds;
						else 
							state <= S_comprst;

			endcase
	end


	always @(posedge clk) begin //eoc
		if (rst) 
			// reset
			eoc <= 0;
		else 
			if (b == 0 && state == S_decide) 
				eoc <= 1;
			else
				eoc <= 0;
	end


	always @(posedge clk) begin //b
		if (rst)
			// reset
			b <= 0;
		else 
			case(state)
				S_wait:
					b <= 4'd9;
				S_decide:
					if(b)
						b <= b - 1;
			endcase
	end

	always @(posedge clk) begin //b_coarse
		if (rst)
			// reset
			b_coarse <= 3'd4;
		else 
			case(state)
				S_wait:
					b_coarse <= 3'd4;
				S_decide:
					if(b_coarse)
						b_coarse <= b_coarse - 1;
			endcase
	end

	always @(*) begin //s_clk
		if (rst) 
			// reset
			s_clk <= 1;
		else 
			if (state == S_wait) 
				s_clk <= 1;
			else
				s_clk <= 0;
	end

	always @(posedge clk) begin //cmp_clk
		if (rst) 
			// reset
			cmp_clk <= 0;
		else 
			if (state == S_comprst) 
				cmp_clk <= 1;
			else
				cmp_clk <= 0;
	end

	always @(posedge clk) begin //cmp_clk_coarse
		if (rst) 
			// reset
			cmp_clk_coarse <= 0;
		else 
			if (state == S_comprst_coarse) 
				cmp_clk_coarse <= 1;
			else
				cmp_clk_coarse <= 0;
	end

	always @(posedge clk) begin //drain
		if (rst) 
			// reset
			drain <= 1;
		else 
			if (state == S_drain)
				drain <= 0;
			else if (state == S_wait)
				drain <= 1;
	end

	always @(posedge clk) begin //ds
		if (rst) 
			// reset
			ds <= 1;
		else 
			if (state == S_ds)
				ds <= 0;
			else if (state == S_wait)
				ds <= 1;
	end

	always @(posedge clk) begin //sar
		if (rst) begin
			// reset
			sar <= 0;
		end
		else
			case(state)
				S_wait:
					sar <= 10'b1000000000;
				S_decide: begin
					if(cmp_clk_coarse) begin
						if(cmp_out_coarse == 0)
							sar[b] <= 0;
						if(b)
						 sar[b-1] <= 1;
					end
					else begin
						if(cmp_out == 0)
							sar[b] <= 0;
						if(b)
							sar[b-1] <= 1;
					end
				end
				
			endcase
	end


	always @(posedge clk) begin //DAC_switch_control
		if (rst) begin
			// reset
			fine_btm <= 20'd0;
			fine_switch_drain <= 1;
			coarse_switch_drain <= 1;
			coarse_btm <= 10'd0;
		end
		else
			case(state)
				S_wait: begin
					fine_btm <= 20'd0;
					coarse_btm <= 10'd0;
					fine_switch_drain <= 1;
					coarse_switch_drain <= 1;
				end
				S_drain:
					case(drain)
						1:
							coarse_switch_drain <= 0;
						0: begin
							coarse_btm <= 10'b1111100000;
							end
						endcase
				S_ds:
					case(ds)
						1:
							fine_switch_drain <= 0;
						0: begin
							if(sar[9] == 1) begin
								fine_btm[19] <= 1;
								fine_btm[9] <= 1;
							end
							if(sar[8] == 1) begin
								fine_btm[18] <= 1;
								fine_btm[8] <= 1;
							end
							if(sar[7] == 1) begin
								fine_btm[17] <= 1;
								fine_btm[7] <= 1;
							end
							if(sar[6] == 1) begin
								fine_btm[16] <= 1;
								fine_btm[6] <= 1;
							end
							if(sar[5] == 1) begin
								fine_btm[15] <= 1;
								fine_btm[5] <= 1;
							end
							fine_btm[14:10] <= 5'b11111;
						end

					endcase
				S_decide:
					if(cmp_clk_coarse) 
						if(cmp_out_coarse) begin
							coarse_btm[b_coarse] <= 1;
						end		

						else begin
							coarse_btm[b_coarse+5] <= 0;
						end

					else
						if(cmp_out) begin
							fine_btm[b] <= 1;
						end		

						else begin
							fine_btm[b+10] <= 0;
						end

			endcase
		
	end

endmodule