`timescale 1ns/1ns
`define A_WIDTH 8
`define D_WIDTH 8
`define R_WIDTH 3

module MEDIAN(Go, A_Addr, A_Data, Out_Addr, Out_Data,
							A_RW, A_EN, Out_RW, Out_EN, Done, Clk, Rst);
	input Go;
	input [(`D_WIDTH-1):0] A_Data;
	output reg [(`A_WIDTH-1):0] A_Addr;
	output reg [(`A_WIDTH-`R_WIDTH-1):0] Out_Addr;
	output reg [(`D_WIDTH-1):0] Out_Data;
	output reg A_RW, A_EN, Out_RW, Out_EN, Done;
	input Rst, Clk;
	
	reg [3:0] State;
	reg [(`D_WIDTH-1):0] Arr[0: (2**`R_WIDTH-1)];
	integer I, J, K, L, M;
	integer Index;

	parameter S0 = 4'b0000, S1 = 4'b0001, S2 = 4'b0010, S3a = 4'b0011, S3 = 4'b0100,
						S4 = 4'b0101, S5 = 4'b0110, S6 = 4'b0111, S7 = 4'b1000, S8 = 4'b1001,
						S9 = 4'b1010, S10 = 4'b1011, S11 = 4'b1100;

	always @(posedge Clk) begin
		if (Rst==1'b1) begin
			A_Addr <= {`A_WIDTH{1'b0}};
			Out_Addr <= {(`A_WIDTH-`R_WIDTH){1'b0}};
			Out_Data <= {`D_WIDTH{1'b0}};
			A_RW <= 1'b0; A_EN <= 1'b0; Out_RW <= 1'b0; Out_EN <= 1'b0;
			Done <= 1'b0;
			State <= S0;
			I <= 0; J <= 0; K <= 0; L <= 0; M <= 0;
			for(Index=0;Index<(2**`R_WIDTH);Index=Index+1)
				Arr[Index] <= {`D_WIDTH{1'b0}};
		end
		else begin
			A_Addr <= {`A_WIDTH{1'b0}};
			Out_Addr <= {(`A_WIDTH-`R_WIDTH){1'b0}};
			Out_Data <= {`D_WIDTH{1'b0}};
			A_RW <= 1'b0; A_EN <= 1'b0; Out_RW <= 1'b0; Out_EN <= 1'b0;
			Done <= 1'b0;

			case (State)
				S0: begin
					I <= 0; J <= 0;
					if (Go==1'b1) State <= S1;
					else State <= S0;
				end
				S1: begin
					M <= 0;
					State <= S2;
				end
				S2: begin
					if (M<8) begin
						A_Addr <= I;
						A_RW <= 1'b0;
						A_EN <= 1'b1;
						State <= S3a;
					end
					else State <= S4;
				end
				S3a:
					State <= S3;
				S3: begin
					Arr[M] <= A_Data;
					M <= M + 1;
					I <= I + 1;
					State <= S2;
				end
				S4: begin
					L <= 0;
					State <= S5;
				end
				S5: begin
					K <= L + 1;
					if (L<8) State <= S6;
					else State <= S11;
				end
				S6: begin
					if (K<8) State <= S7;
					else State <= S10;
				end
				S7: begin
					if (Arr[L]>Arr[K]) State <= S8;
					else State <= S9;
				end
				S8: begin
					Arr[L] <= Arr[K];
					Arr[K] <= Arr[L];
					State <= S9;
				end
				S9: begin
					K <= K + 1;
					State <= S6;
				end
				S10: begin
					L <= L + 1;
					State <= S5;
				end
				S11: begin
					Out_Addr <= J;
					Out_Data <= (Arr[(2**`R_WIDTH)/2-1]+Arr[(2**`R_WIDTH)/2])/2;
					Out_RW <= 1'b1;
					Out_EN <= 1'b1;
					J <= J + 1;
					if (I<2**`A_WIDTH) State <= S1;
					else begin
						State <= S0;
						Done <= 1'b1;
					end
				end
			endcase
		end
	end
endmodule
