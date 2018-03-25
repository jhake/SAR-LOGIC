module sar_logic_TSCS_10bit_k7(
	input clk,
	input rst,
	input cnvst,
	input coarse_cmp_out,
	input fine_cmp_out,
	output reg [9:0] sar, // digital output
	output reg eoc, // end of conversion
	output reg coarse_cmp_clk, // comparator clock
	output reg fine_cmp_clk,

	output reg s_clk, // bootstrap switch clock

	output reg [8:0] coarse_sca1_top,
	output reg [8:0] coarse_sca1_btm,
	output reg [8:0] coarse_sca2_top,
	output reg [8:0] coarse_sca2_btm,
	output reg coarse_switch_S,
	output reg coarse_switch_drain,

	output reg [12:0] fine_sca1_top,
	output reg [12:0] fine_sca1_btm,
	output reg [12:0] fine_sca2_top,
	output reg [12:0] fine_sca2_btm,
	output reg fine_switch_S,
	output reg fine_switch_drain,

	//INVERTED OUTPUTS
	output s_clk_not,
	output [8:0] coarse_sca1_top_not,
	output [8:0] coarse_sca1_btm_not,
	output [8:0] coarse_sca2_top_not,
	output [8:0] coarse_sca2_btm_not,
	output coarse_switch_S_not,
	output coarse_switch_drain_not,

	output [12:0] fine_sca1_top_not,
	output [12:0] fine_sca1_btm_not,
	output [12:0] fine_sca2_top_not,
	output [12:0] fine_sca2_btm_not,
	output fine_switch_S_not,
	output fine_switch_drain_not
	);
	
	parameter S_wait						= 4'd0;
	parameter S_coarse_drain 		= 4'd1;
	parameter S_coarse_comprst	= 4'd2;
	parameter S_coarse_c				= 4'd3;
	parameter S_coarse_bndset		= 4'd4;
	parameter S_coarse_swtop		= 4'd5;
	parameter S_coarse_f				= 4'd6;
	parameter S_detskip					= 4'd7;
	parameter S_fine_comprst		= 4'd8;
	parameter S_fine_c					= 4'd9;
	parameter S_fine_swtop			= 4'd10;
	parameter S_fine_f					= 4'd11;

	assign s_clk_not = ~s_clk;
	assign coarse_sca1_top_not = ~coarse_sca1_top;
	assign coarse_sca1_btm_not = ~coarse_sca1_btm;
	assign coarse_sca2_top_not = ~coarse_sca2_top;
	assign coarse_sca2_btm_not = ~coarse_sca2_btm;
	assign coarse_switch_S_not = ~coarse_switch_S;
	assign coarse_switch_drain_not = ~coarse_switch_drain;
	assign fine_sca1_top_not = ~fine_sca1_top;
	assign fine_sca1_btm_not = ~fine_sca1_btm;
	assign fine_sca2_top_not = ~fine_sca2_top;
	assign fine_sca2_btm_not = ~fine_sca2_btm;
	assign fine_switch_S_not = ~fine_switch_S;
	assign fine_switch_drain_not = ~fine_switch_drain;


	reg [8:0] coarse_sca1_top_wait;
	reg [8:0] coarse_sca2_top_wait;
	reg [12:0] fine_sca1_top_wait;
	reg [12:0] fine_sca2_top_wait;

	reg [4:0] state;
	reg [3:0] coarse_b_c;
	reg [3:0] coarse_b_f;
	reg [1:0] coarse_bndset;
	reg [1:0] coarse_drain;
	reg coarse_swtop;
	reg [3:0] fine_b_c;
	reg [3:0] fine_b_f;
	reg [1:0] fine_bndset;
	reg [1:0] fine_drain;
	reg fine_swtop;

	reg [1:0] detskip;

	reg coarse_f_up; // 1 if SCA2 has upper bound voltage
	reg fine_f_up;
	always @(posedge clk) begin //state transitions
		if (rst) 
			state <= S_wait;
		else
			case(state)
				S_wait:
					if(cnvst)
						state <= S_coarse_drain;
					else 
						state <= S_wait;
				S_coarse_drain:
					if(coarse_drain)
						state <= S_coarse_drain;
					else
						state <= S_coarse_comprst;
				S_coarse_comprst:
					if(coarse_b_c)
						state <= S_coarse_c;
					else if(coarse_bndset)
						state <= S_coarse_bndset;
					else
						state <= S_coarse_f;
				S_coarse_c:
					if(coarse_b_c==0)
						state <= S_coarse_bndset;
					else
						state <= S_coarse_comprst;
				S_coarse_bndset:
					if(coarse_bndset)
						state <= S_coarse_bndset;
					else
						state <= S_coarse_swtop;
				S_coarse_swtop:
					if(coarse_swtop)
						state <= S_coarse_swtop;
					else
						state <= S_coarse_comprst;	
				S_coarse_f:
					if(coarse_b_f<=1)
						state <= S_detskip;
					else
						state <= S_coarse_comprst;
				S_detskip:
					if(detskip)
						state <= S_detskip;
					else
						state <= S_fine_f;
				S_fine_comprst:
					state <= S_fine_f;
				S_fine_f:
					if(fine_b_f == 0)
						state <= S_wait;
					else
						state <= S_fine_comprst;

			endcase
	end


	always @(posedge clk) begin //eoc
		if (rst) 
			// reset
			eoc <= 0;
		else 
			if (fine_b_f == 0 && state == S_fine_f) 
				eoc <= 1;
			else
				eoc <= 0;
	end

	always @(posedge clk) begin //coarse_bndset
		if (rst)
			// reset
			coarse_bndset <= 2;
		else 
			case(state)
				S_wait:
					coarse_bndset <= 2;
				S_coarse_bndset:
					if(coarse_bndset)
						coarse_bndset <= coarse_bndset - 1;
			endcase
	end

	always @(posedge clk) begin //coarse_b_c
		if (rst)
			// reset
			coarse_b_c <= 0;
		else 
			case(state)
				S_wait:
					coarse_b_c <= 4'd3;
				S_coarse_c:
					if(coarse_b_c)
						coarse_b_c <= coarse_b_c - 1;
			endcase
	end

	always @(posedge clk) begin //coarse_b_f
		if (rst)
			// reset
			coarse_b_f <= 0;
		else 
			case(state)
				S_wait:
					coarse_b_f <= 4'd3;
				S_coarse_f:
					if(coarse_b_f)
						coarse_b_f <= coarse_b_f - 1;
			endcase
	end

	always @(posedge clk) begin //fine_b_f
		if (rst)
			// reset
			fine_b_f <= 0;
		else 
			case(state)
				S_wait:
					fine_b_f <= 4'd2;
				S_fine_f:
					if(fine_b_f)
						fine_b_f <= fine_b_f - 1;
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

	always @(posedge clk) begin //coarse_cmp_clk
		if (rst) 
			// reset
			coarse_cmp_clk <= 0;
		else 
			if (state == S_coarse_comprst) 
				coarse_cmp_clk <= 1;
			else
				coarse_cmp_clk <= 0;
	end

	always @(posedge clk) begin //fine_cmp_clk
		if (rst) 
			// reset
			fine_cmp_clk <= 0;
		else 
			if (state == S_fine_comprst) 
				fine_cmp_clk <= 1;
			else
				fine_cmp_clk <= 0;
	end

	always @(posedge clk) begin //coarse_f_up
		if (rst) 
			// reset
			coarse_f_up <= 0;
		else 
			if (state == S_coarse_bndset == 1 && coarse_bndset == 1 && coarse_cmp_out) 
				coarse_f_up <= 1;
	end

	always @(posedge clk) begin //coarse_drain
		if (rst) 
			// reset
			coarse_drain <= 1;
		else 
			if (state == S_coarse_drain && coarse_drain)
				coarse_drain <= coarse_drain - 1;
			else if (state == S_wait)
				coarse_drain <= 2;
	end

	always @(posedge clk) begin //detskip
		if (rst) 
			// reset
			detskip <= 2'd3;
		else 
			if (state == S_detskip)
				detskip <= detskip - 1;
			else if (state == S_wait)
				detskip <= 2'd3;
	end

	always @(posedge clk) begin //coarse_swtop
		if (rst) 
			// reset
			coarse_swtop <= 1;
		else 
			if (state == S_coarse_swtop) 
				coarse_swtop <= 0;
			else if (state == S_wait)
				coarse_swtop <= 1;
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
				S_coarse_c: begin
					if(coarse_cmp_out == 0)
						sar[coarse_b_c+4'd6] <= 0;
					if(coarse_b_c)
						sar[coarse_b_c+4'd5] <= 1;
				end
				S_coarse_bndset: begin
					if(coarse_cmp_out == 0)
						sar[4'd6] <= 0;
					sar[4'd5] <= 1;
				end
				S_coarse_f: begin
					if(coarse_cmp_out == 0)
						sar[coarse_b_f+4'd2] <= 0;
					if(coarse_b_f)
						sar[coarse_b_f+1] <= 1;
				end
				S_fine_f: begin
					if(fine_cmp_out == 0)
						sar[fine_b_f] <= 0;
					if(fine_b_f)
						sar[fine_b_f-1] <= 1;
				end
			endcase
	end


	always @(posedge clk) begin //DAC_switch_control
		if (rst) begin
			// reset
			coarse_sca1_top <= 9'b111111111;
			coarse_sca1_btm <= 9'b000000000;
			coarse_sca2_top <= 9'b111111111;
			coarse_sca2_btm <= 9'b000000000;
			coarse_switch_S <= 1;
			coarse_switch_drain <= 0;
		end
		else
			case(state)
				S_wait: begin
					coarse_sca1_top <= 9'b111111111;
					coarse_sca1_btm <= 9'b000000000;
					coarse_sca2_top <= 9'b111111111;
					coarse_sca2_btm <= 9'b000000000;
					coarse_switch_S <= 1;
					coarse_sca1_top_wait <= 9'b000000000;
					coarse_sca2_top_wait <= 9'b000000000;
					coarse_switch_drain <= 0;

					fine_sca1_btm <= 13'd0;
					fine_sca2_btm <= 13'd0;
					fine_switch_S <= 1;
					fine_switch_drain <= 1;
					fine_sca1_top <= 13'b1111111111111;
					fine_sca2_top <= 13'b1111111111111;
					fine_sca1_top_wait <= 13'd0;
					fine_sca2_top_wait <= 13'd0;
				end
				S_coarse_drain:
					case(coarse_drain)
						2'd2:
							coarse_switch_drain <= 1;
						2'd1:
							coarse_switch_drain <= 0;
						2'd0: begin
							coarse_switch_drain <= 0;
							coarse_sca1_btm <= 9'b111100000;
							coarse_sca2_btm <= 9'b111100000;
							end
						endcase
				S_coarse_c:
					case(coarse_b_c)
						4'd3:
							if(coarse_cmp_out) begin
								coarse_sca1_btm[4:3] <= 2'b11;
								coarse_sca2_btm[4:3] <= 2'b11;
							end		

							else begin
								coarse_sca1_btm[8] <= 0;
								coarse_sca2_btm[8] <= 0;
							end
						4'd2:
							if(coarse_cmp_out) begin
								coarse_sca1_btm[2] <= 1;
								coarse_sca2_btm[2] <= 1;
							end		
											
							else begin
								coarse_sca1_btm[7] <= 0;
								coarse_sca2_btm[7] <= 0;
							end
						4'd1:
							if(coarse_cmp_out) begin
								coarse_sca1_btm[1] <= 1;
								coarse_sca2_btm[1] <= 1;
							end		
											
							else begin
								coarse_sca1_btm[6] <= 0;
								coarse_sca2_btm[6] <= 0;
							end

					endcase

				S_coarse_bndset:
					case(coarse_bndset)
						2:
							coarse_switch_S <= 0;
						1:
							if(coarse_cmp_out) begin
								coarse_sca2_btm[0] <= 1;
							end		
											
							else begin
								coarse_sca2_btm[5] <= 0;
							end
						0: begin
							coarse_sca1_top_wait <= 9'b000000010;
							coarse_sca2_top_wait <= 9'b000000010;
							coarse_sca1_top <= 9'b000000000;
							coarse_sca2_top <= 9'b000000000;
						end
							

					endcase

				S_coarse_swtop: 
					if(coarse_swtop)
						coarse_switch_S <= 1;
					else begin
						coarse_sca2_top <= 9'b000000010;
						coarse_sca1_top <= 9'b000000010;
					end

				S_coarse_f:
					case(coarse_b_f)
						4'd3:
							if( (coarse_cmp_out && coarse_f_up == 0) || (coarse_cmp_out == 0 && coarse_f_up) ) begin
								coarse_sca1_top_wait[3:2] <= 2'b11;
								coarse_sca1_top_wait[8] <= 1;
								coarse_sca1_top[2] <= 1;
							end		
											
							else begin
								coarse_sca2_top_wait[3:2] <= 2'b11;
								coarse_sca2_top_wait[8] <= 1;
								coarse_sca2_top[2] <= 1;
							end
						4'd2:
							if( (coarse_cmp_out && coarse_f_up == 0) || (coarse_cmp_out == 0 && coarse_f_up) ) begin
								coarse_sca1_top_wait[7] <= 1;
								coarse_sca1_top_wait[4] <= 1;
								coarse_sca1_top[3] <= coarse_sca1_top_wait[3];
								coarse_sca2_top[3] <= coarse_sca2_top_wait[3];
								coarse_sca1_top[4] <= 1;
							end		
											
							else begin
								coarse_sca2_top_wait[7] <= 1;
								coarse_sca2_top_wait[4] <= 1;
								coarse_sca2_top[3] <= coarse_sca2_top_wait[3];
								coarse_sca1_top[3] <= coarse_sca1_top_wait[3];
								coarse_sca2_top[4] <= 1;							
							end
						4'd1: begin
							if( (coarse_cmp_out && coarse_f_up == 0) || (coarse_cmp_out == 0 && coarse_f_up) ) begin
								coarse_sca1_top_wait[6:5] <= 2'b11;
								coarse_sca1_top[8:7] <= coarse_sca1_top_wait[8:7];
								coarse_sca2_top[8:7] <= coarse_sca2_top_wait[8:7];
								coarse_sca1_top[6:5] <= 2'b11;
							end		
											
							else begin
								coarse_sca2_top_wait[6:5] <= 2'b11;
								coarse_sca2_top[8:7] <= coarse_sca2_top_wait[8:7];
								coarse_sca1_top[8:7] <= coarse_sca1_top_wait[8:7];
								coarse_sca2_top[6:5] <= 2'b11;
							end
							fine_switch_drain <= 0;
							fine_switch_S <= 0;
						end
						// 4'd0:
						// 	if( (coarse_cmp_out && coarse_f_up == 0) || (coarse_cmp_out == 0 && coarse_f_up) ) begin
						// 		coarse_sca1_top[6:5] <= 2'b11;
						// 		coarse_sca1_top[0] <= 1;
						// 	end		
											
						// 	else begin
						// 		coarse_sca2_top[6:5] <= 2'b11;
						// 		coarse_sca2_top[0] <= 1;
						// 	end

					endcase		

				S_detskip: 
					case(detskip)
						3: begin
							fine_sca1_btm[8] <= 1;
							if(sar[9] == 1) begin
								fine_sca1_btm[12] <= 1;
								fine_sca1_btm[7:5] <= 3'b111;
								fine_sca2_btm[12] <= 1;
								fine_sca2_btm[7:5] <= 3'b111;
							end
							if(sar[8] == 1) begin
								fine_sca1_btm[11] <= 1;
								fine_sca1_btm[4:3] <= 2'b11;
								fine_sca2_btm[11] <= 1;
								fine_sca2_btm[4:3] <= 2'b11;
							end
							if(sar[7] == 1) begin
								fine_sca1_btm[10] <= 1;
								fine_sca1_btm[2] <= 1;
								fine_sca2_btm[10] <= 1;
								fine_sca2_btm[2] <= 1;
							end
							if(sar[6] == 1) begin
								fine_sca1_btm[9] <= 1;
								fine_sca1_btm[1] <= 1;
								fine_sca2_btm[9] <= 1;
								fine_sca2_btm[1] <= 1;
							end
							if(sar[5] == 1) begin
								fine_sca2_btm[0] <= 1;
							end
						end
						2: begin //bndset
							fine_sca1_top <= 13'd0;
							fine_sca2_top <= 13'd0;
						end
						1:
							fine_switch_S <= 1;
						0: begin
							if( (sar[4] && fine_f_up == 0) || (sar[4] == 0 && fine_f_up) ) begin
								fine_sca1_top_wait[2] <= 1;
								fine_sca1_top_wait[4] <= 1;
								fine_sca1_top_wait[7] <= 1;
								fine_sca1_top_wait[12] <= 1;
								fine_sca1_top[4] <= 1;
								fine_sca2_top[4] <= 1;
								fine_sca1_top[2] <= 1;
							end
							else begin
								fine_sca2_top_wait[2] <= 1;
								fine_sca2_top_wait[4] <= 1;
								fine_sca2_top_wait[7] <= 1;
								fine_sca2_top_wait[12] <= 1;
								fine_sca1_top[4] <= 1;
								fine_sca2_top[4] <= 1;
								fine_sca2_top[2] <= 1;
							end
							if((sar[3] && fine_f_up == 0) || (sar[3] == 0 && fine_f_up)) begin
								fine_sca1_top_wait[3] <= 1;
								fine_sca1_top_wait[6] <= 1;
								fine_sca1_top_wait[11] <= 1;
								fine_sca1_top[3] <= 1;
							end
							else begin
								fine_sca2_top_wait[3] <= 1;
								fine_sca2_top_wait[6] <= 1;
								fine_sca2_top_wait[11] <= 1;
								fine_sca2_top[3] <= 1;		
							end
						end
					endcase

				
				S_fine_f:
					case(fine_b_f)
					4'd2:
						if( (fine_cmp_out && fine_f_up == 0) || (fine_cmp_out == 0 && fine_f_up) ) begin
							fine_sca1_top_wait[5] <= 1;
							fine_sca1_top_wait[10] <= 1;
							fine_sca1_top[7:6] <= fine_sca1_top_wait[7:6];
							fine_sca2_top[7:6] <= fine_sca2_top_wait[7:6];
							fine_sca1_top[5] <= 1;
						end		
										
						else begin
							fine_sca2_top_wait[5] <= 1;
							fine_sca2_top_wait[10] <= 1;
							fine_sca1_top[7:6] <= fine_sca1_top_wait[7:6];
							fine_sca2_top[7:6] <= fine_sca2_top_wait[7:6];
							fine_sca2_top[5] <= 1;
						end
					4'd1:
						if( (fine_cmp_out && fine_f_up == 0) || (fine_cmp_out == 0 && fine_f_up) ) begin
							fine_sca1_top_wait[9:8] <= 2'b11;
							fine_sca1_top[12:10] <= fine_sca1_top_wait[12:10];
							fine_sca2_top[12:10] <= fine_sca2_top_wait[12:10];
							fine_sca1_top[9:8] <= 2'b11;
						end		
										
						else begin
							fine_sca2_top_wait[9:8] <= 2'b11;
							fine_sca1_top[12:10] <= fine_sca1_top_wait[12:10];
							fine_sca2_top[12:10] <= fine_sca2_top_wait[12:10];
							fine_sca2_top[9:8] <= 2'b11;
							end
					endcase
			endcase
		
	end

endmodule