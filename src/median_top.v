`timescale 1ns/1ns
`define A_WIDTH 8
`define D_WIDTH 8
`define R_WIDTH 3

module MEDIAN_Top(Go_t, Done_t, Rst_Core, MA_di32, MA_di8,
					MA_do32, MA_Addr6, MA_enb, MA_web, 
					MO_di8b, MO_do8b, MO_do8, MO_Addr5b, MO_enb, MO_web, Rst_M, Clk);

	//MEDIAN_Core interface
	input Go_t;
	output Done_t;
	input Rst_Core;
	
	//Dual-port input SRAM Interface
	input [31:0] MA_di32;
	input [7:0] MA_di8;
	output [31:0] MA_do32;
	input [5:0] MA_Addr6;
	input MA_enb, MA_web;
	
	//Dual-port output SRAM Interface
	input [7:0] MO_di8b;
	output [7:0] MO_do8b;
	output [7:0] MO_do8;
	input [4:0] MO_Addr5b;
	input MO_enb, MO_web;

	input Rst_M;
	
	//interface between MEDIAN_Core and Dual_port input SRAM
	wire [(`D_WIDTH-1):0] MA_do8;
	wire [(`A_WIDTH-1):0] MA_Addr8;
	wire A_ena, A_wea;

	//interface between MEDIAN_Core and Dual_port output SRAM
	wire [(`D_WIDTH-1):0] MO_di8;
	wire [(`A_WIDTH-`R_WIDTH-1):0]MO_Addr5;
	wire O_ena, O_wea;

	//Common Interface
	input Clk;
	
	MEDIAN MEDIAN_Core(Go_t, MA_Addr8, MA_do8, MO_Addr5, MO_di8,
							A_wea, A_ena, O_wea, O_ena, Done_t, Clk, Rst_Core);

	dp_sram_input MemA(
	MA_Addr8,//addra,
	MA_Addr6,//addrb,
	Clk,//clka,
	Clk,//clkb,
	MA_di8,//dina,
	MA_di32,//dinb,
	MA_do8,//douta,
	MA_do32,//doutb,
	A_ena,//ena,
	MA_enb,//enb,
	Rst_M,//sinita,
	Rst_M,//sinitb,
	A_wea,//wea,
	MA_web);//web);

	dp_sram_output MemO(
	MO_Addr5,//addra,
	MO_Addr5b,//addrb,
	Clk,//clka,
	Clk,//clkb,
	MO_di8,//dina,
	MO_di8b,//dinb,
	MO_do8,//douta,
	MO_do8b,//doutb,
	O_ena,//ena,
	MO_enb,//enb,
	Rst_M,//sinita,
	Rst_M,//sinitb,
	O_wea,//wea,
	MO_web);//web);

endmodule
