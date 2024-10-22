`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/13/2020 06:32:15 PM
// Design Name: 
// Module Name: vga215test
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module vga215test;
    logic            clk;
    logic   [15:0]   sw;
    logic            btnC, btnU, btnL, btnR, btnD;
    logic   [6:0]    seg;
    logic            dp;
    logic   [3:0]    an;
    logic   [7:0]    JA;
    logic   [3:0]    vgaRed, vgaBlue, vgaGreen;
    logic            Hsync, Vsync;

    initial begin
        sw[15:0] <= 2'b00;
        clk <= 1'b0;
        {btnC, btnU, btnL, btnR, btnD} <= 5'b10000;
        #10
        sw[1:0] <= 2'b01;
        #50
        sw[1:0] <= 2'b11;
        sw[3] <=1'b1;
    end
    always #5 clk <= ~clk;
    basys3_vga #(
    .ramdamize("ramdamize.sv")
    )basys3_vga(.*);
endmodule
