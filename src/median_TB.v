`timescale 1ns/1ns
`define A_WIDTH 8
`define D_WIDTH 8
`define R_WIDTH 3
`define ITR 32

module Testbench();
	reg Go_t_s;
	wire Done_t_s;
	reg Rst_Core_s;
	reg [31:0] MA_di32_s;
	wire [(`D_WIDTH-1):0] MA_di8_s; // dummy port, not used!
	wire [31:0] MA_do32_s; // dummy port, not used!
	reg [(`A_WIDTH-3):0] MA_Addr6_s;
	reg MA_enb_s;
	reg MA_web_s;
	wire [(`D_WIDTH-1):0] MO_di8b_s; // dummy port, not used!
	wire [(`D_WIDTH-1):0] MO_do8b_s;
	wire [(`D_WIDTH-1):0] MO_do8_s; // dummy port, not used!
	reg [(`A_WIDTH-`R_WIDTH-1):0] MO_Addr5b_s;
	reg MO_enb_s;
	reg MO_web_s;
	reg Rst_M_s;
	reg Clk_s;
	
	reg [31:0] A[0:(2**(`A_WIDTH-2)-1)];
	reg [7:0] Ref[0:(`ITR-1)];
	integer Index;
	parameter ClkPeriod = 20;

	MEDIAN_Top CompToTest(
			Go_t_s,
			Done_t_s,
			Rst_Core_s,
			MA_di32_s,
			MA_di8_s,
			MA_do32_s,
			MA_Addr6_s,
			MA_enb_s,
			MA_web_s,
			MO_di8b_s,
			MO_do8b_s,
			MO_do8_s,
			MO_Addr5b_s,
			MO_enb_s,
			MO_web_s,
			Rst_M_s,
			Clk_s);

	// Clock Procedure
	always begin
		Clk_s <= 0; #(ClkPeriod/2);
		Clk_s <= 1; #(ClkPeriod/2);
	end

	// Initialize Arrays
	initial $readmemh("../sw/MemA.txt", A);
	initial $readmemh("../sw/sw_result.txt", Ref);
	
	initial begin
		Rst_M_s <= 1'b1; Rst_Core_s <= 1'b1; Go_t_s <= 1'b0;
		MA_enb_s <= 1'b0; MA_web_s <= 1'b0;
		MO_enb_s <= 1'b0; MO_web_s <= 1'b0;
		@(posedge Clk_s);
		
		Rst_M_s <= 1'b0;
		@(posedge Clk_s);
		
		for(Index=0;Index<(2**(`A_WIDTH-2));Index=Index+1) begin
			MA_enb_s <= 1'b1;
			MA_web_s <= 1'b1;
			MA_Addr6_s <= Index;
			MA_di32_s <= A[Index];
			@(posedge Clk_s);
		end	
		
		MA_enb_s <= 1'b0;
		MA_web_s <= 1'b0;
		@(posedge Clk_s);
		
		//Running MEDIAN_Core
		Rst_Core_s <= 1'b0; Go_t_s <= 1'b1;
		@(posedge Clk_s);
		
		Go_t_s <= 1'b0;
		@(posedge Clk_s);

		while(Done_t_s != 1'b1)
				@(posedge Clk_s);

		for(Index=0;Index<`ITR;Index=Index+1) begin
			MO_enb_s <= 1'b1;
			MO_web_s <= 1'b0;
			MO_Addr5b_s <= Index;
			@(posedge Clk_s);
			@(posedge Clk_s);
			
			if(MO_do8b_s != Ref[Index])
				$display("MEDIAN failed with %x -- should be equal to %x", MO_do8b_s, Ref[Index]);
			else
				$display("MEDIAN is %x that is equal to %x", MO_do8b_s, Ref[Index]);
		end
		
		$stop;
	end

endmodule
