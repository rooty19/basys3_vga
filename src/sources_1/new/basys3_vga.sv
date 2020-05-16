`include "vhclk_gen.v"
`include "ramdamize.sv"
//`include "gamefsm.sv"
module basys3_vga(
    input   logic            clk,
    input   logic   [15:0]   sw,
    output  logic   [6:0]    seg,
    output  logic            dp,
    output  logic   [3:0]    an,
    input   logic            btnC, btnU, btnL, btnR, btnD,
    output  logic   [7:0]    JA,
    output  logic   [3:0]    vgaRed, vgaBlue, vgaGreen,
    output  logic            Hsync, Vsync
);

logic   clk10, clk100, clk25M;
logic   display_en;
logic   [9:0]  hpos, vpos;
logic   Hsyncd, Vsyncd;
logic   vramCS;
divider #(.targetfreq(32'd16))  div10 (clk, !sw[0], clk10);
divider #(.targetfreq(32'd500))  div100 (clk, !sw[0], clk100);
divider #(.targetfreq(32'd25175000))  div25M (clk, !sw[0], clk25M);


logic   [7:0]   ps_numT, ps_numU;
logic   [19:0]  vaddr;
logic   [18:0]  read_grobalA, read_vramA, write_vramA, write_grobalA;
logic   [18:0]  write_vramB;

always_ff @(posedge clk25M) {Hsync, Vsync} <= {Hsyncd, Vsyncd};
always_ff @(posedge clk25M) display_en <= display_end;

logic   [9:0]  whpos, wvpos;
//write vpos/hpos
assign whpos = hpos;
assign wvpos = ((vpos<480-32) & hpos<640)? (vpos+32) : (492<=vpos & hpos < 640) ? (vpos-492) : 9'b0;
//read address
assign read_grobalA = ((hpos < 640) & (vpos < 480)) ? (vpos*640 + hpos) : 0;
assign read_vramA = ((hpos < 640) & (vpos < 480)) ? (read_grobalA%(32*640)) : 19'b0;
//write address
assign write_grobalA = ((vpos<480-32) & hpos<640)? ((vpos+32)*640 + hpos) : (492<=vpos & hpos < 640) ? ((vpos-492)*640 + hpos) : 19'b0;
assign write_vramA = write_grobalA%(32*640);
// write en
logic  write_ENA, write_ENB;
assign write_ENA = ((vpos<480-32) & hpos<640)? 1'b1 : (492<=vpos & hpos < 640) ? 1'b1 : 1'b0;
// data line and chip select
logic   [11:0]  vdin, vdoutA, vdoutB, vdout;
logic           RvramCS, WvramCS;
assign RvramCS = vramCS;
assign vdout = (!RvramCS)? vdoutA : vdoutB;

logic  clk60;
assign clk60 = ((vpos == 480) & (hpos == 0)) ? 1 : 0;

always_ff @(posedge clk25M) WvramCS <= RvramCS;
assign {vgaBlue, vgaGreen, vgaRed} = (display_en) ? vdout : 12'h000;

m_seq_test m_seq_test (
    clk10, !sw[0], ps_numT, ps_numU
);

//dynamic_led dynamic_led (clk100, !sw[1], count[15:12], count[11:8], count[7:4], count[3:0], an, {seg, dp});
dynamic_led dynamic_led (
    clk100,
    !sw[1],
    ps_numT[7:4],
    ps_numT[3:0],
    ps_numU[7:4],
    ps_numU[3:0],
    an,
    {seg, dp}
);

hvsync_generator hvsync_generator (clk25M, sw[1], Hsyncd, Vsyncd, display_end, hpos, vpos, vramCS);

gamefsm gamefsm(
    clk, !sw[1], clk25M, clk60,
    sw[5], sw[4], sw[3],
    sw[15:12],
    sw[11],
    sw[10:5],
    btnC, btnU, btnL, btnR, btnD,
    whpos, wvpos,
    write_vramA, write_ENA,
    write_vramB, write_ENB,
    vdin,
    ps_numT, ps_numU
);

// address converter
// HY/Sync #1
// barwriter #1
// Wvram #1
blk_mem_gen_0 vramA (
    clk25M,
    WvramCS, 
    write_ENB,
    write_vramB,
    vdin,
    clk25M,
    !RvramCS,
    read_vramA,
    vdoutA
);

blk_mem_gen_0 vramB (
    clk25M,
    !WvramCS, 
    write_ENB,
    write_vramB,
    vdin,
    clk25M,
    RvramCS,
    read_vramA,
    vdoutB
/*
  .clka(clka),    // input wire clka
  .ena(ena),      // input wire ena
  .wea(wea),      // input wire [0 : 0] wea
  .addra(addra),  // input wire [14 : 0] addra
  .dina(dina),    // input wire [11 : 0] dina
  .clkb(clkb),    // input wire clkb
  .enb(enb),      // input wire enb
  .addrb(addrb),  // input wire [14 : 0] addrb
  .doutb(doutb)  // output wire [11 : 0] doutb
*/
);


//assign JA[1:0] = {clk10, clk100};
//assign JA[2] = (count[3:0]==0)? 1'b1 : 1'b0;
logic   [15:0]  count;
always_ff @(posedge clk10)begin
    if(!sw[1]) begin
        count <= 32'b0;
    end else begin
        count <= count + 1;
    end
end

endmodule

module dynamic_led(
    input   logic           clk, reset, // clk is 1~16ms
    input   logic   [3:0]   seg3, seg2, seg1, seg0,
    output  logic   [3:0]   ANs, // AN3, AN2, AN1, AN0
    output  logic   [7:0]   seg
);
    logic   [4:0]   inseg;
    logic   [1:0]   state;

    always_ff @(posedge clk)begin
        if(reset) begin
            ANs <= 4'b1110;
        end else begin
            ANs   <= {ANs[2:0], ANs[3]};
        end 
    end

    always_comb begin
        case(ANs)
            4'b1110:  inseg <= seg0;
            4'b1101:  inseg <= seg1; 
            4'b1011:  inseg <= seg2;
            4'b0111:  inseg <= seg3;
            default : inseg <= 4'd8;
        endcase
    end
    logic   [7:0] se;
    //initial se <= 8'b11111111;
    always_comb begin
        case(inseg)
            4'h0:   se <= 8'b11111100; // CA -> DP
            4'h1:   se <= 8'b01100000;
            4'h2:   se <= 8'b11011010;
            4'h3:   se <= 8'b11110010;
            4'h4:   se <= 8'b01100110;
            4'h5:   se <= 8'b10110110;
            4'h6:   se <= 8'b10111110;
            4'h7:   se <= 8'b11100000;
            4'h8:   se <= 8'b11111110;
            4'h9:   se <= 8'b11110110;
            4'ha:   se <= 8'b11101110;
            4'hb:   se <= 8'b00111110;
            4'hc:   se <= 8'b10011100;
            4'hd:   se <= 8'b01111010;
            4'he:   se <= 8'b10011110;
            4'hf:   se <= 8'b10001110;
            default: se <= 8'b0;
        endcase
    end

    assign seg = {!se[1], !se[2], !se[3], !se[4], !se[5], !se[6], !se[7], !se[0]};
endmodule

module divider #(
    parameter basefreq = 32'd100000000,
    parameter targetfreq = 32'd10
)(
    input   logic   clk, reset,
    output  logic   dclk
);
localparam targetcount = (basefreq / targetfreq);
localparam harfpoint = targetcount / 2;
logic   [31:0]  counter;
always_ff @(posedge clk) begin
    if(reset) begin
        counter <= 32'd0;
        dclk <= 1'b0;
    end else begin
        counter <= (counter < harfpoint) ? counter + 32'b1 : 32'b0;
        dclk <= (counter == (harfpoint - 1'b1)) ? ~dclk : dclk; 
    end 
end
endmodule

// LEGACY CODE
module barwriter(
    input   logic          clk, reset, clk25M,
    input   logic   [9:0]  hpos, vpos,
    input   logic   [18:0] wvaddr,
    input   logic          vwen,       
    output  logic   [18:0] wvaddr_out,
    output  logic          vwen_out,
    output  logic   [11:0] vdin
);

    logic   [3:0] hpix;
    always_ff @(posedge clk25M)begin
        if(reset) begin
            vdin <= 1'b0;
            hpix <= 4'b0;
        end else begin
            if((hpos+1)%40==0) hpix <= (hpos < 640) ? ((hpos+1)==640)? 4'b0 : hpix+1 : 4'b0;
            else hpix <= (hpos < 640) ? hpix : 4'b0;
            if(0<=vpos && vpos<120)begin
                vdin <= {hpix, 8'b0};
            end else if(120<=vpos && vpos<240)begin
                vdin <= {4'b0, hpix, 4'b0};
            end else if(240<=vpos && vpos<360)begin
                vdin <= {8'b0, hpix};
            end else if(360<=vpos && vpos<480)begin
                vdin <= {hpix,hpix,hpix};
            end else vdin <= 12'b0;
            
        end   
    end

    always_ff @(posedge clk25M) {wvaddr_out, vwen_out} <= {wvaddr, vwen};
endmodule
