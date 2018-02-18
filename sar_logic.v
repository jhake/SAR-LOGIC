module sar_logic(
	input clk,
	input rst,
	input cnvst,
	input cmp_out,
	output reg [7:0] sar, // digital output
	output reg eoc, // end of conversion
	output reg cmp_clk, // comparator clock

	output reg s_clk, // bootstrap switch clock

	output reg [8:0] fine_sca1_top,
	output reg [8:0] fine_sca1_btm,
	output reg [8:0] fine_sca2_top,
	output reg [8:0] fine_sca2_btm
	);
	
	parameter S_start 	= 3'd0;
	parameter S_sample	= 3'd1;
	parameter S_compare	= 3'd2;
	parameter S_decide	= 3'd3;

	reg [3:0] state;
	reg [3:0] b;

	always @(posedge clk) begin //state transitions
		if (rst) 
			state <= S_start;
		else
			case(state)
				S_start:
					if(cnvst)
						state <= S_sample;
					else 
						state <= S_start;
				S_sample:
					state <= S_compare;
				S_compare:
					state <= S_decide;
				S_decide:
					if(b==0)
						state <= S_start;
					else
						state <= S_compare;
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
				S_sample:
					b <= 4'd7;
				S_decide:
					if(b)
						b <= b - 1; 
			endcase
	end

	always @(posedge clk) begin //s_clk
		if (rst) 
			// reset
			s_clk <= 0;
		else 
			if (state == S_sample) 
				s_clk <= 1;
			else
				s_clk <= 0;
	end

	always @(posedge clk) begin //cmp_clk
		if (rst) 
			// reset
			cmp_clk <= 0;
		else 
			if (state == S_compare) 
				cmp_clk <= 1;
			else
				cmp_clk <= 0;
	end

	always @(posedge clk) begin //sar
		if (rst) begin
			// reset
			sar <= 0;
		end
		else
			case(state)
				S_start:
					sar[4'd7] <= 1;
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
			fine_sca1_top[8:0] <= 9'b111111111;
			fine_sca1_btm[8:0] <= 0;
			fine_sca2_top[8:0] <= 9'b111111111;
			fine_sca2_btm[8:0] <= 0;
		end
		else
			case(state)
				S_start: begin
					fine_sca1_top[8:0] <= 9'b111111111;
					fine_sca1_btm[8:0] <= 0;
					fine_sca2_top[8:0] <= 9'b111111111;
					fine_sca2_btm[8:0] <= 0;
				end
				/*S_decide: begin
					if(cmp_out == 0)
						case(b)
						endcase
					else
						case(b)
						endcase
				end*/
			endcase
		
	end

endmodule