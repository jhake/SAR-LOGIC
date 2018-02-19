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
	output reg [8:0] fine_sca2_btm,
	output reg fine_switch_S
	);
	
	parameter S_wait		= 3'd0;
	parameter S_comprst	= 3'd1;
	parameter S_coarse	= 3'd2;
	parameter S_bndset	= 3'd3;
	parameter S_fine		= 3'd4;

	reg [3:0] state;
	reg [3:0] b_coarse;
	reg [3:0] b_fine;
	reg bndset;

	reg fine_up; // 1 if SCA2 has upper bound voltage

	always @(posedge clk) begin //state transitions
		if (rst) 
			state <= S_wait;
		else
			case(state)
				S_wait:
					if(cnvst)
						state <= S_comprst;
					else 
						state <= S_wait;
				S_comprst:
					if(b_coarse)
						state <= S_coarse;
					else if(bndset)
						state <= S_bndset;
					else
						state <= S_fine;
				S_coarse:
					if(b_coarse==0)
						state <= S_bndset;
					else
						state <= S_comprst;
				S_bndset:
					if(bndset)
						state <= S_bndset;
					else
						state <= S_comprst;
				S_fine:
					if(b_fine==0)
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
			if (b_fine == 0 && state == S_fine) 
				eoc <= 1;
			else
				eoc <= 0;
	end

	always @(posedge clk) begin //bndset
		if (rst)
			// reset
			bndset <= 1;
		else 
			case(state)
				S_wait:
					bndset <= 1;
				S_bndset:
					bndset <= 0;
			endcase
	end

	always @(posedge clk) begin //b_coarse
		if (rst)
			// reset
			b_coarse <= 0;
		else 
			case(state)
				S_wait:
					b_coarse <= 4'd3;
				S_coarse:
					if(b_coarse)
						b_coarse <= b_coarse - 1;
			endcase
	end

	always @(posedge clk) begin //b_fine
		if (rst)
			// reset
			b_fine <= 0;
		else 
			case(state)
				S_wait:
					b_fine <= 4'd3;
				S_fine:
					if(b_fine)
						b_fine <= b_fine - 1;
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

	always @(posedge clk) begin //fine_up
		if (rst) 
			// reset
			fine_up <= 0;
		else 
			if (state == S_bndset && bndset && cmp_out) 
				fine_up <= 1;
	end

	always @(posedge clk) begin //sar
		if (rst) begin
			// reset
			sar <= 0;
		end
		else
			case(state)
				S_wait:
					sar[4'd7] <= 1;
				S_coarse: begin
					if(cmp_out == 0)
						sar[b_coarse+4'd4] <= 0;
					if(b_coarse)
						sar[b_coarse+4'd3] <= 1;
				end
				S_bndset:
					sar[4'd3] <= 1;
				S_fine: begin
					if(cmp_out == 0)
						sar[b_fine] <= 0;
					if(b_fine)
						sar[b_fine-1] <= 1;
				end
			endcase
	end

	always @(posedge clk) begin //DAC_switch_control
		if (rst) begin
			// reset
			fine_sca1_top <= 9'b111111111;
			fine_sca1_btm <= 9'b111100000;
			fine_sca2_top <= 9'b111111111;
			fine_sca2_btm <= 9'b111100000;
			fine_switch_S <= 0;
		end
		else
			case(state)
				S_wait: begin
					fine_sca1_top <= 9'b111111111;
					fine_sca1_btm <= 9'b111100000;
					fine_sca2_top <= 9'b111111111;
					fine_sca2_btm <= 9'b000000000;
					fine_switch_S <= 0;
				end
				S_coarse:
					case(b_coarse)
						4'd3:
							if(cmp_out) begin
								fine_sca1_btm[4:3] <= 2'b11;
							end		

							else begin
								fine_sca1_btm[8] <= 0;
							end
						4'd2:
							if(cmp_out) begin
								fine_sca1_btm[2] <= 1;
							end		
											
							else begin
								fine_sca1_btm[7] <= 0;
							end
						4'd1:
							if(cmp_out) begin
								fine_sca1_btm[1] <= 1;
							end		
											
							else begin
								fine_sca1_btm[6] <= 0;
							end
						4'd0:
							if(cmp_out) begin
								fine_sca1_btm[4:3] <= 2'b11;
							end		
											
							else begin
								fine_sca1_btm[4:3] <= 2'b11;
							end
					endcase

				S_bndset:
					case(bndset)
						1:
							if(cmp_out) begin
								fine_sca2_btm[8:1] <= fine_sca1_btm[8:1];
								fine_sca2_btm[0] <= 1;
							end		
											
							else begin
								fine_sca2_btm[8:6] <= fine_sca1_btm[8:6];
								fine_sca2_btm[5] <= 0;
								fine_sca2_btm[4:0] <= fine_sca1_btm[4:0];
							end
						0: begin
							fine_sca1_top <= 9'b000000010;
							fine_sca2_top <= 9'b000000010;
							fine_switch_S <= 1;
						end
					endcase

				S_fine:
					case(b_fine)
						4'd3:
							if( (cmp_out && fine_up == 0) || (cmp_out == 0 && fine_up) ) begin
								fine_sca1_top[6:5] <= 2'b11;
								fine_sca1_top[0] <= 1;
							end		
											
							else begin
								fine_sca2_top[6:5] <= 2'b11;
								fine_sca2_top[0] <= 1;
							end
						4'd2:
							if( (cmp_out && fine_up == 0) || (cmp_out == 0 && fine_up) ) begin
								fine_sca1_top[4] <= 1;
								fine_sca1_top[1] <= 1;
							end		
											
							else begin
								fine_sca2_top[4] <= 1;
								fine_sca2_top[1] <= 1;
							end
						4'd1:
							if( (cmp_out && fine_up == 0) || (cmp_out == 0 && fine_up) ) begin
								fine_sca1_top[3:2] <= 2'b11;
							end		
											
							else begin
								fine_sca2_top[3:2] <= 2'b11;
							end
						4'd0:
							if( (cmp_out && fine_up == 0) || (cmp_out == 0 && fine_up) ) begin
								fine_sca1_top[6:5] <= 2'b11;
								fine_sca1_top[0] <= 1;
							end		
											
							else begin
								fine_sca2_top[6:5] <= 2'b11;
								fine_sca2_top[0] <= 1;
							end

					endcase				
			endcase
		
	end

endmodule