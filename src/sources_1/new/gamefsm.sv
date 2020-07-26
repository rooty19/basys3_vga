`include "RAM_test.sv"
`include "RAM_testB.sv"

module gamefsm (
    input   logic           clk, reset, clk25M, clk60,
    input   logic           swf2, swf1, swf0,
    input   logic   [3:0]   speed,
    input   logic           eraseen,
    input   logic   [5:0]   erasesel,
    input   logic           btnC, btnU, btnL, btnR, btnD,
    input   logic   [9:0]   whpos, wvpos,
    input   logic   [18:0]  write_vramA,
    input   logic           write_ENA,
    output  logic   [18:0]  write_vramC,
    output  logic           write_ENC,
    output  logic   [11:0]  dinB,
    input   logic   [7:0]   ps_numT, ps_numU,
    output  logic   [1:0]   gcount,
    output  logic   [8:0]   score,
    output  logic   [4:0]   table_upS
);

/*
invader table align (word: 0 null, 1-61 invader, 62 cannon)
invader exist(1/0 : 4bit) | start vpos(0-480 12bit) | start hpos(0-640 12bit) | size(8bit)| ID(4bit) | color (0x000-0xfff 12bit)

laser table align (word 0 cannon, 1-40 laser)
laser exist (1/0 : 4bit)| start vpos(0-480 12bit) | start hpos(0-640 12bit) | color (0x000-0xfff 12bit)
*/

// Invader Table RAM
logic   [51:0]   invader_table     [0:62];
logic   [51:0]   invader_tableTEMP [0:62];

// ステートとフラグ
//logic   [4:0]   table_upS;
logic   [6:0]   invMS;
logic           invMSEN;
logic   [1:0]   movearg; // 0^ 1> 2v 3<
logic   [1:0]   moveNext;
logic   [4:0]   umoveC;
logic           movelock; // 1 .. locked

logic          goverF;
logic          clearF;
//logic   [1:0]  gcount;
//logic   [8:0]  score;

logic   [51:0] GT00, GT01, GT02, GT03; 
logic   [51:0] GTOV, GTCO, GTCC;


// 描写座標用
logic   [7:0]    invT_pV           [0:62];
logic   [7:0]    invT_pH           [0:62];
logic   [7:0]   invT_pVs;
logic   [7:0]   invT_pHs;
logic   [15:0]  invT_p12;

// インベーダー用
logic   [62:0]  rrom_ren;
logic   [5:0]   rrom_rens;
logic   [62:0]  rrom_EN;
logic   [11:0]  rrom_vpos  [62:0];
logic   [11:0]  rrom_hpos  [62:0];
logic   [7:0]   rrom_size  [62:0];
logic   [62:0]  rrom_whpos;
logic   [62:0]  rrom_wvpos;
logic   [62:0]  rrom_clear;
logic   [3:0]   rrom_ID [62:0];

logic   [11:0]  colorpallet;
logic   [3:0]   speeds;
assign speeds = (swf0) ? speed : gcount + 1;

// レーザー用
logic   [39:0]  laser_table   [0:39];
logic   [39:0]  laser_tableTEMP   [0:39];
logic   [39:0]  lase_ren;
logic   [5:0]   lase_rens;
logic   [39:0]  lase_EN;
logic   [11:0]  lase_vpos  [0:39];
logic   [11:0]  lase_hpos  [0:39];
logic   [39:0]  lase_wvpos;
logic   [39:0]  lase_whpos;
logic   [11:0]  lase_color [0:39];

logic   [11:0]  lase_chpos; // canon
logic   [11:0]  lase_cepos; // enemy
logic   [4:0]   short_PS;

// Collision Detection
logic   lase_hCD;
logic   lase_vCD;

assign  clearF = (rrom_EN == {1'b1, 62'b0}) ? 1'b1 : 1'b0;

assign  lase_hCD = lase_whpos[invMS] & lase_whpos[0];
assign  lase_vCD = lase_wvpos[invMS] & lase_wvpos[0];

// Output
logic   [11:0]  dinA0, dinA1, dinA2, dinA3, dinA4, dinA5, dinA6, dinA7, dinA8, dinA9;
logic   [11:0]  dinAa, dinAb, dinAc, dinAd, dinAe, dinAf, dinAx;
logic   [15:0]   csA;
logic   [18:0]  write_vramB;
logic           write_ENB;

assign short_PS = ps_numU[4:0];

assign invT_pVs = invT_pV[rrom_rens];
assign invT_pHs = invT_pH[rrom_rens];
assign invT_p12 = invT_pV[rrom_rens] * rrom_size[rrom_rens] + invT_pH[rrom_rens];

assign lase_cepos = rrom_hpos[short_PS] + (rrom_size[short_PS]>>1);
assign lase_chpos = rrom_hpos[62]+17;

// Table
RAM_test #(.Dword(63),  .Dwidth(52), .style("distributed"), .initfile("tables/gametable00.txt")) BRAM_GT00 (
    clk25M, 1'b0, invMS, 52'h0, GT00
);
RAM_test #(.Dword(63),  .Dwidth(52), .style("distributed"), .initfile("tables/gametable01.txt")) BRAM_GT01 (
    clk25M, 1'b0, invMS, 52'h0, GT01
);
RAM_test #(.Dword(63),  .Dwidth(52), .style("distributed"), .initfile("tables/gametable02.txt")) BRAM_GT02 (
    clk25M, 1'b0, invMS, 52'h0, GT02
);
RAM_test #(.Dword(63),  .Dwidth(52), .style("distributed"), .initfile("tables/gametable03.txt")) BRAM_GT03 (
    clk25M, 1'b0, invMS, 52'h0, GT03
);
RAM_test #(.Dword(63),  .Dwidth(52), .style("distributed"), .initfile("gameover.txt")) BRAM_GTOV (
    clk25M, 1'b0, invMS, 52'h0, GTOV
);
RAM_test #(.Dword(63),  .Dwidth(52), .style("distributed"), .initfile("tables/continue.txt")) BRAM_GTCO (
    clk25M, 1'b0, invMS, 52'h0, GTCO
);
RAM_test #(.Dword(63),  .Dwidth(52), .style("distributed"), .initfile("tables/clear.txt")) BRAM_GTCC (
    clk25M, 1'b0, invMS, 52'h0, GTCC
);


// Texture
RAM_testB #(.Dword(1024),  .Dwidth(1), .style("distributed"), .initfile("picture_git/canon.txt")) BRAM_00 (
    clk25M, 1'b0, invT_p12, 12'h000, dinA0
);
RAM_testB #(.Dword(1024),  .Dwidth(12), .style("distributed"), .initfile("picture_git/tux32.txt")) BRAM_01 (
    clk25M, 1'b0, invT_p12, 12'h000, dinA1
);
RAM_testB #(.Dword(1024),  .Dwidth(12), .style("distributed"), .initfile("picture_git/yuka_yappari.txt")) BRAM_02 (
    clk25M, 1'b0, invT_p12, 12'h000, dinA2
);
RAM_testB #(.Dword(1024),  .Dwidth(12), .style("distributed"), .initfile("picture_git/unarist.txt")) BRAM_03 (
    clk25M, 1'b0, invT_p12, 12'h000, dinA3
);
RAM_testB #(.Dword(16384),  .Dwidth(4), .style("BLOCK"), .initfile("picture_git/credit_git.txt")) BRAM_04 (
    clk25M, 1'b0, invT_p12, 12'h000, dinA4
);
RAM_testB #(.Dword(4096),  .Dwidth(12), .style("distributed"), .initfile("picture_git/tux64.txt")) BRAM_05 (
    clk25M, 1'b0, invT_p12, 12'h000, dinA5
);
RAM_testB #(.Dword(16384), .Dwidth(12), .style("BLOCK"), .initfile("picture_git/continue.txt")) BRAM_06 (
    clk25M, 1'b0, invT_p12, 12'h000, dinA6
);
RAM_testB #(.Dword(1024), .Dwidth(1), .style("distributed"), .initfile("picture_git/space32.txt")) BRAM_07 (
    clk25M, 1'b0, invT_p12, 12'h000, dinA7
);
RAM_testB #(.Dword(4096),  .Dwidth(12), .style("distributed"), .initfile("picture_git/yuka_gue64.txt")) BRAM_08 (
    clk25M, 1'b0, invT_p12, 12'h000, dinA8
);
RAM_testB #(.Dword(16384),  .Dwidth(12), .style("BLOCK"), .initfile("picture_git/ai.txt")) BRAM_09 (
    clk25M, 1'b0, invT_p12, 12'h000, dinA9
);
RAM_testB #(.Dword(4096),  .Dwidth(12), .style("BLOCK"), .initfile("picture_git/ion1.txt")) BRAM_0A (
    clk25M, 1'b0, invT_p12, 12'h000, dinAa
);
RAM_testB #(.Dword(4096),  .Dwidth(12), .style("BLOCK"), .initfile("picture_git/ion2.txt")) BRAM_0B (
    clk25M, 1'b0, invT_p12, 12'h000, dinAb
);
RAM_testB #(.Dword(4096),  .Dwidth(12), .style("BLOCK"), .initfile("picture_git/ion3.txt")) BRAM_0C (
    clk25M, 1'b0, invT_p12, 12'h000, dinAc
);
RAM_testB #(.Dword(4096),  .Dwidth(12), .style("BLOCK"), .initfile("picture_git/ion4.txt")) BRAM_0D (
    clk25M, 1'b0, invT_p12, 12'h000, dinAd
);
RAM_testB #(.Dword(16384),  .Dwidth(12), .style("BLOCK"), .initfile("picture_git/initial.txt")) BRAM_0E (
    clk25M, 1'b0, invT_p12, 12'h000, dinAe
);
RAM_testB #(.Dword(16384),  .Dwidth(4), .style("BLOCK"), .initfile("picture_git/gameover.txt")) BRAM_0F (
    clk25M, 1'b0, invT_p12, 12'h000, dinAf
);

always_ff @(posedge clk25M) begin
        if(reset)begin
            `include "tables/inv_table62_Z.sv"
            `include "tables/inv_tableTEMP62.sv"
            `include "tables/laser_table39.sv"
            
            //pixeladdrH <= 1'b0;
            invMS <= 7'd0;
            invMSEN <= 1'b0;
            movearg <= 1'b1;
            moveNext <= 1'b1;
            movelock <= 1'b0;
            umoveC <= 0;
            dinAx <= 12'h000;
            rrom_clear <= 62'h0;
            table_upS <= 5'b00000;
            score <= 9'd0;
            gcount <= 0;
        end else begin
            if(clk60&(invMSEN == 0))begin // フレーム間処理の開始
                invMSEN <= 1'b1;
                movearg <= moveNext;
                movelock <= 0;
                //table_upS <= 3'b000;
                rrom_clear <= 62'h0;
                `include "tables/invT_init.sv"
            end else if(invMSEN)begin
                if(table_upS == 5'b00000)begin
                    if(btnU) begin
                        table_upS <= 5'b00001;
                        score <= (goverF) ? 0 : score;
                        goverF <= 0;
                        invMSEN <= 0;
                    end else begin
                        table_upS <= 5'b00000;
                        goverF <= goverF;
                        invMSEN <= 0;
                    end    
                end else if(table_upS == 5'b00001)begin
                    case(gcount)
                        2'b00 : invader_table[invMS] <= GT00;
                        2'b01 : invader_table[invMS] <= GT01;
                        2'b10 : invader_table[invMS] <= GT02;
                        2'b11 : invader_table[invMS] <= GT03;
                    endcase    
                    invader_tableTEMP[invMS] <= 56'h0;
                    invMS <= (invMS == 62) ? 0 : invMS + 1;
                    invMSEN <= (invMS == 62) ? 0 : 1;
                    table_upS <= (invMS == 62) ? 5'b00010 : 5'b00001;
                end
                `include "gamebody.sv"
                else if(table_upS == 5'b01100)begin
                    if(invMS < 40) laser_table[invMS] <= 40'h0;
                    invader_table[invMS] <= GTOV;
                    invMS <= (invMS == 62) ? 0 : invMS + 1;
                    invMSEN <= (invMS == 62) ? 0 : 1;
                    table_upS <= (invMS == 62) ? 5'b00000 : 5'b01100;
                    gcount <= 0;
                end else if(table_upS == 5'b01101) begin
                    if(invMS < 40) laser_table[invMS] <= 40'h0;
                    invader_table[invMS] <= (gcount != 3) ? GTCO : GTCC;
                    invMS <= (invMS == 62) ? 0 : invMS + 1;
                    invMSEN <= (invMS == 62) ? 0 : 1;
                    table_upS <= (invMS == 62) ? 5'b00000 : 5'b01101;
                    if (invMS == 62) gcount <= gcount + 1;
                end
            end begin
            //else begin
                if((rrom_rens < 63) & (rrom_ren[rrom_rens]) & (write_ENA))begin
                    invT_pH[rrom_rens] <= (whpos==rrom_hpos[rrom_rens]) ? 0 : (whpos==rrom_hpos[rrom_rens]+rrom_size[rrom_rens]-1) ? 0 : invT_pH[rrom_rens] + 1;
                    invT_pV[rrom_rens] <= (whpos==rrom_hpos[rrom_rens]+rrom_size[rrom_rens]-1) ? invT_pV[rrom_rens] + 1 : invT_pV[rrom_rens];
                    colorpallet <= invader_table[rrom_rens];
                end else if((lase_rens < 40) & (lase_ren[lase_rens]) & (write_ENA))begin
                    colorpallet <= lase_color[lase_rens]; 
                end else begin
                    colorpallet <= 12'h000;
                end
            end
        end 
        if(rrom_rens < 63)begin
            case(rrom_ID[rrom_rens])
                4'h0 : csA <= 1;
                4'h1 : csA <= 1<<1;
                4'h2 : csA <= 1<<2;
                4'h3 : csA <= 1<<3;
                4'h4 : csA <= 1<<4;
                4'h5 : csA <= 1<<5;
                4'h6 : csA <= 1<<6;
                4'h7 : csA <= 1<<7;
                4'h8 : csA <= 1<<8;
                4'h9 : csA <= 1<<9;
                4'ha : csA <= 1<<10;
                4'hb : csA <= 1<<11;
                4'hc : csA <= 1<<12;
                4'hd : csA <= 1<<13;    
                4'he : csA <= 1<<14;    
                4'hf : csA <= 1<<15;                                
            endcase
            dinAx <= 12'h000;
        end else if(lase_rens < 40)begin
            csA <= 0;
            dinAx <= lase_color[lase_rens];
        end else begin
            csA <= 0;
            dinAx <= 12'h000;
        end    
end

always_ff @(posedge clk25M)begin
    case(csA)
        16'b0000000000000001 : dinB <= dinA0 * colorpallet;
        16'b0000000000000010 : dinB <= dinA1;
        16'b0000000000000100 : dinB <= dinA2;
        16'b0000000000001000 : dinB <= dinA3 * colorpallet;
        16'b0000000000010000 : dinB <= {dinA4[3:0], dinA4[3:0], dinA4[3:0]};
        16'b0000000000100000 : dinB <= dinA5;
        16'b0000000001000000 : dinB <= dinA6;
        16'b0000000010000000 : dinB <= dinA7 * colorpallet;
        16'b0000000100000000 : dinB <= dinA8;
        16'b0000001000000000 : dinB <= dinA9;
        16'b0000010000000000 : dinB <= dinAa;
        16'b0000100000000000 : dinB <= dinAb;
        16'b0001000000000000 : dinB <= dinAc;
        16'b0010000000000000 : dinB <= dinAd;
        16'b0100000000000000 : dinB <= dinAe;  
        16'b1000000000000000 : dinB <= {dinAf[3:0], dinAf[3:0], dinAf[3:0]}; 
        default : dinB <= dinAx;
    endcase    
end

genvar k,l;
generate 
    for(k=0;k<63;k=k+1) begin : Rrom
        assign rrom_EN[k]   = (invader_table[k]&52'hf_000_000_00_0_000)>>51;
        assign rrom_vpos[k] = (invader_table[k]&52'h0_fff_000_00_0_000)>>36;
        assign rrom_hpos[k] = (invader_table[k]&52'h0_000_fff_00_0_000)>>24;
        assign rrom_size[k] = (invader_table[k]&52'h0_000_000_ff_0_000)>>16;
        assign rrom_ID[k]   = (invader_table[k]&52'h0_000_000_00_f_000)>>12;
        assign rrom_whpos[k] = (rrom_EN[k]==1'b1) & (rrom_hpos[k]<=whpos) & (whpos < rrom_hpos[k]+rrom_size[k]);
        assign rrom_wvpos[k] = (rrom_EN[k]==1'b1) & (rrom_vpos[k]<=wvpos) & (wvpos < rrom_vpos[k]+rrom_size[k]);
        assign rrom_ren[k]   = (rrom_whpos[k]) & (rrom_wvpos[k]);                                                      
    end

    for(l=0;l<40;l=l+1) begin : laser
        assign lase_EN[l]       = (laser_table[l]&40'hf_000_000_000)>>39;
        assign lase_vpos[l]     = (laser_table[l]&40'h0_fff_000_000)>>24;
        assign lase_hpos[l]     = (laser_table[l]&40'h0_000_fff_000)>>12;
        assign lase_color[l]    = (laser_table[l]&40'h0_000_000_fff);
        assign lase_wvpos[l]    = (lase_EN[l]==1'b1) & (lase_hpos[l]-1<=whpos) & (whpos<=lase_hpos[l]+1);
        assign lase_whpos[l]    = (lase_EN[l]==1'b1) & (lase_vpos[l]<=wvpos) & (wvpos<lase_vpos[l]+20);
        assign lase_ren[l]      = (lase_whpos[l]) & (lase_wvpos[l]);
    end
endgenerate

assign  lase_rens = lase_ren[0] ? 6'd0 :
                    lase_ren[1] ? 6'd1:
                    lase_ren[2] ? 6'd2:
                    lase_ren[3] ? 6'd3:
                    lase_ren[4] ? 6'd4:
                    lase_ren[5] ? 6'd5:
                    lase_ren[6] ? 6'd6:
                    lase_ren[7] ? 6'd7:
                    lase_ren[8] ? 6'd8:
                    lase_ren[9] ? 6'd9:
                    lase_ren[10]? 6'd10:
                    lase_ren[11] ? 6'd11:
                    lase_ren[12] ? 6'd12:
                    lase_ren[13] ? 6'd13:
                    lase_ren[14] ? 6'd14:
                    lase_ren[15] ? 6'd15:
                    lase_ren[16] ? 6'd16:
                    lase_ren[17] ? 6'd17:
                    lase_ren[18] ? 6'd18:
                    lase_ren[19] ? 6'd19:
                    lase_ren[20] ? 6'd20:
                    lase_ren[21] ? 6'd21:
                    lase_ren[22] ? 6'd22:
                    lase_ren[23] ? 6'd23:
                    lase_ren[24] ? 6'd24:
                    lase_ren[25] ? 6'd25:
                    lase_ren[26] ? 6'd26:
                    lase_ren[27] ? 6'd27:
                    lase_ren[28] ? 6'd28:
                    lase_ren[29] ? 6'd29:
                    lase_ren[30] ? 6'd30:
                    lase_ren[31] ? 6'd31:
                    lase_ren[32] ? 6'd32:
                    lase_ren[33] ? 6'd33:
                    lase_ren[34] ? 6'd34:
                    lase_ren[35] ? 6'd35:
                    lase_ren[36] ? 6'd36:
                    lase_ren[37] ? 6'd37:
                    lase_ren[38] ? 6'd38:
                    lase_ren[39] ? 6'd39:
                    6'd40;

assign  rrom_rens = rrom_ren[0] ? 6'd0:
                    rrom_ren[1] ? 6'd1:
                    rrom_ren[2] ? 6'd2:
                    rrom_ren[3] ? 6'd3:
                    rrom_ren[4] ? 6'd4:
                    rrom_ren[5] ? 6'd5:
                    rrom_ren[6] ? 6'd6:
                    rrom_ren[7] ? 6'd7:
                    rrom_ren[8] ? 6'd8:
                    rrom_ren[9] ? 6'd9:
                    rrom_ren[10]? 6'd10:
                    rrom_ren[11] ? 6'd11:
                    rrom_ren[12] ? 6'd12:
                    rrom_ren[13] ? 6'd13:
                    rrom_ren[14] ? 6'd14:
                    rrom_ren[15] ? 6'd15:
                    rrom_ren[16] ? 6'd16:
                    rrom_ren[17] ? 6'd17:
                    rrom_ren[18] ? 6'd18:
                    rrom_ren[19] ? 6'd19:
                    rrom_ren[20] ? 6'd20:
                    rrom_ren[21] ? 6'd21:
                    rrom_ren[22] ? 6'd22:
                    rrom_ren[23] ? 6'd23:
                    rrom_ren[24] ? 6'd24:
                    rrom_ren[25] ? 6'd25:
                    rrom_ren[26] ? 6'd26:
                    rrom_ren[27] ? 6'd27:
                    rrom_ren[28] ? 6'd28:
                    rrom_ren[29] ? 6'd29:
                    rrom_ren[30] ? 6'd30:
                    rrom_ren[31] ? 6'd31:
                    rrom_ren[32] ? 6'd32:
                    rrom_ren[33] ? 6'd33:
                    rrom_ren[34] ? 6'd34:
                    rrom_ren[35] ? 6'd35:
                    rrom_ren[36] ? 6'd36:
                    rrom_ren[37] ? 6'd37:
                    rrom_ren[38] ? 6'd38:
                    rrom_ren[39] ? 6'd39:
                    rrom_ren[40] ? 6'd40:
                    rrom_ren[41] ? 6'd41:
                    rrom_ren[42] ? 6'd42:
                    rrom_ren[43] ? 6'd43:
                    rrom_ren[44] ? 6'd44:
                    rrom_ren[45] ? 6'd45:
                    rrom_ren[46] ? 6'd46:
                    rrom_ren[47] ? 6'd47:
                    rrom_ren[48] ? 6'd48:
                    rrom_ren[49] ? 6'd49:
                    rrom_ren[50] ? 6'd50:
                    rrom_ren[51] ? 6'd51:
                    rrom_ren[52] ? 6'd52:
                    rrom_ren[53] ? 6'd53:
                    rrom_ren[54] ? 6'd54:
                    rrom_ren[55] ? 6'd55:
                    rrom_ren[56] ? 6'd56:
                    rrom_ren[57] ? 6'd57:
                    rrom_ren[58] ? 6'd58:
                    rrom_ren[59] ? 6'd59:
                    rrom_ren[60] ? 6'd60:
                    rrom_ren[61] ? 6'd61:
                    rrom_ren[62] ? 6'd62:                    
                    6'd63;

always_ff @(posedge clk25M)begin
    write_vramB <= write_vramA;
    write_vramC <= write_vramB;
    write_ENB <= write_ENA;
    write_ENC <= write_ENB;
end 
endmodule