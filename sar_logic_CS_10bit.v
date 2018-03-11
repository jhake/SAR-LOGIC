module sar_logic_CS(
	input clk,
	input rst,
	input cnvst,
	input cmp_out,
	output reg [9:0] sar, // digital output
	output reg eoc, // end of conversion
	output reg cmp_clk, // comparator clock

	output reg s_clk, // bootstrap switch clock
	output reg [19:0] fine_btm,
	output reg fine_switch_drain,

	//INVERTED OUTPUTS
	output s_clk_not,
	output [19:0] fine_btm_not,
	output fine_switch_drain_not
	);
	
	// 256 128 64 32 16 8  4  2  1  1  256 128 64 32 16 8 4 2 1 1
	//  19  18 17 16 15 14 13 12 11 10   9   8  7  6  5 4 3 2 1 0 
	parameter S_wait		= 3'd0;
	parameter S_drain 	= 3'd1;
	parameter S_comprst	= 3'd2;
	parameter S_decide	= 3'd3;

	assign s_clk_not = ~s_clk;
	assign fine_btm_not = ~fine_btm;
	assign fine_switch_drain_not = ~fine_switch_drain;

	reg [2:0] state;
	reg [1:0] drain;
	reg [3:0] b;

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
						state <= S_comprst;
				S_comprst:
					state <= S_decide;
				S_decide:
					if(b==0)
						state <= S_wait;
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


	always @(posedge clk) begin //drain
		if (rst) 
			// reset
			drain <= 1;
		else 
			if (state == S_drain && drain)
				drain <= drain - 1;
			else if (state == S_wait)
				drain <= 2;
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
					if(cmp_out == 0)
						sar[b] <= 0;
					if(b)
						sar[b-1] <= 1;
				end
				
			endcase
	end


	always @(posedge clk) begin //DAC_switch_control
		if (rst) begin
			// reset
			fine_btm <= 20'd0;
			fine_switch_drain <= 0;
		end
		else
			case(state)
				S_wait: begin
					fine_btm <= 20'd0;
					fine_switch_drain <= 0;
				end
				S_drain:
					case(drain)
						2'd2:
							fine_switch_drain <= 1;
						2'd1:
							fine_switch_drain <= 0;
						2'd0: begin
							fine_switch_drain <= 0;
							fine_btm <= 20'b11111111110000000000;
							end
						endcase
				S_decide:
					if(cmp_out) begin
						fine_btm[b] <= 1;
					end		

					else begin
						fine_btm[b+10] <= 0;
					end

			endcase
		
	end

endmodule