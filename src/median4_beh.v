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

	parameter S0 = 4'b0000, S1 = 4'b0001, S2 = 4'b0010, S3 = 4'b0011, S4 = 4'b0100,
						S5 = 4'b0101, S6 = 4'b0110, S7 = 4'b0111, S8 = 4'b1000, S9 = 4'b1001,
						S10 = 4'b1010, S11a = 4'b1011, S11 = 4'b1100;

	// Shared variables
	reg I_Clr, J_Clr, L_Clr, M_Clr;
	reg K_Ld, Arr_Ld;
	reg I_Inc, J_Inc, K_Inc, L_Inc, M_Inc;
	reg Arr_Swap;
	reg Out_Ld;
	reg L_Lt_8, K_Lt_8, I_Lt_256, M_Lt_8;
	reg Rev;
	// Controller variables 
	reg [3:0] State, StateNext;
	// Datapath variables
	reg [(`D_WIDTH-1):0] Arr[0: (2**`R_WIDTH-1)];
	integer I, J, K, L, M;
	integer Index;

	// -- Datapath Procedures -- //
	// DP CombLogic
	always @(I, J, K, L, M) begin
		A_Addr <= I;
		Out_Addr <= J;

		if (M<8) M_Lt_8 <= 1'b1;
		else M_Lt_8 <= 1'b0;

		if (K<8) K_Lt_8 <= 1'b1;
		else K_Lt_8 <= 1'b0;

		if (L<8) L_Lt_8 <= 1'b1;
		else L_Lt_8 <= 1'b0;

		if (Arr[L]>Arr[K]) Rev <= 1'b1;
		else Rev <= 1'b0;
	
		if (I<256) I_Lt_256 <= 1'b1;
		else I_Lt_256 <= 1'b0;

	end
	
	// DP regs
	always @(posedge Clk) begin
		if (Rst==1'b1) begin
			I <= 0; J <= 0; K <= 0; L <= 0; M <= 0;
			for(Index=0;Index<(2**`R_WIDTH);Index=Index+1)
				Arr[Index] <= {`D_WIDTH{1'b0}};
		end
		else if (I_Clr==1'b1 && J_Clr==1'b1) begin
			I <= 0;
			J <= 0;
		end
		else if (M_Clr==1'b1)
			M <= 0;
		else if (Arr_Ld==1'b1 && I_Inc==1'b1 && M_Inc==1'b1) begin
			Arr[M] <= A_Data;
			I <= I + 1;
			M <= M + 1;
		end
		else if (L_Clr==1'b1)
			L <= 0;	
		else if (K_Ld==1'b1)
			K <= L + 1;
		else if (Arr_Swap==1'b1) begin
			Arr[L] <= Arr[K];
			Arr[K] <= Arr[L];
		end
		else if (K_Inc==1'b1)
			K <= K + 1;
		else if (L_Inc==1'b1)
			L <= L + 1;
		else if (Out_Ld==1'b1)
			Out_Data <= (Arr[(2**`R_WIDTH)/2-1]+Arr[(2**`R_WIDTH)/2])/2;
		else if (J_Inc==1'b1)
			J <= J + 1;
	end

	// -- Controller Procedures -- //
	// Ctrl CombLogic
	always @(State, Go, M_Lt_8, L_Lt_8, K_Lt_8, I_Lt_256, Rev) begin
		A_RW <= 1'b0; A_EN <= 1'b0; Out_RW <= 1'b0; Out_EN <= 1'b0;
		Done <= 1'b0;
		I_Clr <= 1'b0; J_Clr <= 1'b0; L_Clr <= 1'b0; M_Clr <= 1'b0;
		K_Ld <= 1'b0; Arr_Ld <= 1'b0;
		I_Inc <= 1'b0; J_Inc <= 1'b0; K_Inc <= 1'b0; L_Inc <= 1'b0; M_Inc <= 1'b0;
		Arr_Swap <= 1'b0;
		Out_Ld <= 1'b0;

		case (State)
			S0: begin
				I_Clr <= 1'b1; J_Clr <= 1'b1;
				if (Go==1'b1) StateNext <= S1;
				else StateNext <= S0;
			end
			S1: begin
				M_Clr <= 1'b1;
				StateNext <= S2;
			end
			S2: begin
				if (M_Lt_8==1'b1) begin
					A_RW <= 1'b0;
					A_EN <= 1'b1;
					StateNext <= S3;
				end
				else StateNext <= S4;
			end
			S3: begin
				Arr_Ld <= 1'b1;
				I_Inc <= 1'b1;
				M_Inc <= 1'b1;
				StateNext <= S2;
			end
			S4: begin
				L_Clr <= 1'b1;
				StateNext <= S5;
			end
			S5: begin
				K_Ld <= 1'b1;
				if (L_Lt_8==1'b1) StateNext <= S6;
				else StateNext <= S11a;
			end
			S6: begin
				if (K_Lt_8==1'b1) StateNext <= S7;
				else StateNext <= S10;
			end
			S7: begin
				if (Rev==1'b1) StateNext <= S8;
				else StateNext <= S9;
			end
			S8: begin
				Arr_Swap <= 1'b1;
				StateNext <= S9;
			end
			S9: begin
				K_Inc <= 1'b1;
				StateNext <= S6;
			end
			S10: begin
				L_Inc <= 1'b1;
				StateNext <= S5;
			end
			S11a: begin
				Out_Ld <= 1'b1;
				StateNext <= S11;
			end
			S11: begin
				Out_RW <= 1'b1;
				Out_EN <= 1'b1;
				J_Inc <= 1'b1;
				if (I_Lt_256==1'b1) StateNext <= S1;
				else begin
					Done <= 1'b1;
					StateNext <= S0;
				end
			end
		endcase
	end
	
	// Ctrl State Regs
	always @(posedge Clk) begin
		if (Rst == 1'b1)
			State <= S0;
		else
			State <= StateNext;
	end
endmodule
