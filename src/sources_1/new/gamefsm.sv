`include "BRAM_test.sv"
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
    input   logic   [7:0]   ps_numT, ps_numU
);

/*
invader table align (word: 0: canon, 1-49 invader)
invader exist(1/0 : 2bit) | ID (6bit) | start vpos(0-480 12bit) | start hpos(0-640 12bit) | color (0x000-0xfff 12bit)

laser
laser table align (word 0 cannon, 1-40 laser)
laser exist (1/0 : 2bit)| ID (2bit) | retu(0-14 (4bit)) | gyo(0-640 12bit) | color (0x000-0xfff 12bit)
*/

logic   [51:0]   invader_table     [0:62];
logic   [51:0]   invader_tableTEMP [0:62];
logic   [7:0]    invT_pV           [0:62];
logic   [7:0]    invT_pH           [0:62];

logic   [6:0]   invMS;
logic           invMSEN;

logic   [7:0]   invT_pVs;
logic   [7:0]   invT_pHs;

logic   [62:0]  rrom_ren;
logic   [5:0]   rrom_rens;
logic   [62:0]  rrom_EN;
logic   [11:0]  rrom_vpos  [62:0];
logic   [11:0]  rrom_hpos  [62:0];
logic   [7:0]   rrom_size  [62:0];
logic   [62:0]  rrom_whpos;
logic   [62:0]  rrom_wvpos;
logic   [62:0]  rrom_clear;
logic   [11:0]  colorpallet;

logic   [39:0]  laser_table   [0:39];
logic   [39:0]  lase_ren;
logic   [5:0]   lase_rens;
logic   [39:0]  lase_EN;
logic   [11:0]  lase_vpos  [0:39];
logic   [11:0]  lase_hpos  [0:39];
logic   [39:0]  lase_wvpos;
logic   [39:0]  lase_whpos;
logic   [11:0]  lase_color [0:39];

//logic   [3:0]   rrom_colorM  [62:0];
logic   [2:0]   rrom_ID [62:0];

logic   [1:0]   movearg; // 0^ 1> 2v 3<
logic   [1:0]   moveNext;
logic   [4:0]   umoveC;
logic           movelock; // 1 .. locked

logic   [15:0]  invT_p12;
logic   [2:0]   table_upS;

logic   [11:0]  lase_chpos; // canon
logic   [11:0]  lase_cepos; // enemy
logic   [4:0]   short_PS;

// Collision Detection
logic   lase_hCD;
logic   lase_vCD;

assign  lase_hCD = lase_whpos[invMS] & lase_whpos[0];
assign  lase_vCD = lase_wvpos[invMS] & lase_wvpos[0];

// Output
logic   [11:0]  dinA0, dinA1, dinA2, dinA3, dinA4, dinA5, dinA6, dinA7, dinA8;
logic   [7:0]   csA;
logic   [18:0]  write_vramB;
logic           write_ENB;


assign short_PS = ps_numU[4:0];

assign invT_pVs = invT_pV[rrom_rens];
assign invT_pHs = invT_pH[rrom_rens];
assign invT_p12 = invT_pV[rrom_rens] * rrom_size[rrom_rens] + invT_pH[rrom_rens];

assign lase_cepos = rrom_hpos[short_PS] + (rrom_size[short_PS]/2);
assign lase_chpos = rrom_hpos[62]+17;

BRAM_test #(.Dword(1024),  .Dwidth(1), .initfile("picture/parrot12.txt")) BRAM_00 (
    clk25M, 1'b0, invT_p12, 12'h000, dinA0
);
BRAM_test #(.Dword(1024),  .Dwidth(1), .initfile("picture/space.txt")) BRAM_01 (
    clk25M, 1'b0, invT_p12, 12'h000, dinA1
);
BRAM_test #(.Dword(1024),  .Dwidth(12), .initfile("picture/space12.txt")) BRAM_02 (
    clk25M, 1'b0, invT_p12, 12'h000, dinA2
);
BRAM_test #(.Dword(1024),  .Dwidth(12), .initfile("picture/space12.txt")) BRAM_03 (
    clk25M, 1'b0, invT_p12, 12'h000, dinA3
);
BRAM_test #(.Dword(1024),  .Dwidth(12), .initfile("picture/space12.txt")) BRAM_04 (
    clk25M, 1'b0, invT_p12, 12'h000, dinA4
);
BRAM_test #(.Dword(1024),  .Dwidth(12), .initfile("picture/space12.txt")) BRAM_05 (
    clk25M, 1'b0, invT_p12, 12'h000, dinA5
);
BRAM_test #(.Dword(16384), .Dwidth(12), .initfile("picture/unarist_N.txt")) BRAM_06 (
    clk25M, 1'b0, invT_p12, 12'h000, dinA6
);
BRAM_test #(.Dword(16384), .Dwidth(12), .initfile("picture/unarist_L.txt")) BRAM_07 (
    clk25M, 1'b0, invT_p12, 12'h000, dinA7
);

always_ff @(posedge clk25M) begin
        if(reset)begin
            invader_table[0]     <= 52'h8_000_000_20_0_ff0;
            invader_table[1]     <= 52'h8_000_020_20_0_ff0;
            invader_table[2]     <= 52'h8_000_040_20_0_ff0;
            invader_table[3]     <= 52'h8_000_060_20_0_ff0;
            invader_table[4]     <= 52'h8_000_0a0_20_0_ff0;
            invader_table[5]     <= 52'h8_000_0c0_20_0_ff0;
            invader_table[6]     <= 52'h8_000_0e0_20_0_ff0;
            invader_table[7]     <= 52'h8_000_100_20_0_ff0;
            invader_table[8]     <= 52'h8_030_000_20_0_0ff;
            invader_table[9]     <= 52'h8_030_020_20_0_0ff;
            invader_table[10]    <= 52'h8_030_040_20_0_0ff;
            invader_table[11]    <= 52'h8_030_060_20_0_0ff;
            invader_table[12]    <= 52'h8_030_0a0_20_0_0ff;
            invader_table[13]    <= 52'h8_030_0c0_20_0_0ff;
            invader_table[14]    <= 52'h8_030_0e0_20_0_0ff;
            invader_table[15]    <= 52'h8_030_100_20_0_0ff;
            invader_table[16]    <= 52'h8_060_000_20_0_f0f;
            invader_table[17]    <= 52'h8_060_020_20_0_f0f;
            invader_table[18]    <= 52'h8_060_040_20_0_f0f;
            invader_table[19]    <= 52'h8_060_060_20_0_f0f;
            invader_table[20]    <= 52'h8_060_0a0_20_0_f0f;
            invader_table[21]    <= 52'h8_060_0c0_20_0_f0f;
            invader_table[22]    <= 52'h8_060_0e0_20_0_f0f;
            invader_table[23]    <= 52'h8_060_100_20_0_f0f;
            invader_table[24]    <= 52'h8_090_000_20_0_fff;
            invader_table[25]    <= 52'h8_090_020_20_0_fff;
            invader_table[26]    <= 52'h8_090_040_20_0_fff;
            invader_table[27]    <= 52'h8_090_060_20_0_fff;
            invader_table[28]    <= 52'h8_090_0a0_20_0_fff;
            invader_table[29]    <= 52'h8_090_0c0_20_0_fff;
            invader_table[30]    <= 52'h8_090_0e0_20_0_fff;
            invader_table[31]    <= 52'h8_090_100_20_0_fff;
            invader_table[32]    <= 52'h0_020_1a0_20_0_fff;
            invader_table[33]    <= 52'h0_020_1c0_20_0_fff;
            invader_table[34]    <= 52'h0_020_1e0_20_0_fff;
            invader_table[35]    <= 52'h0_020_200_20_0_fff;
            invader_table[36]    <= 52'h0_020_220_20_0_fff;
            invader_table[37]    <= 52'h0_020_240_20_0_fff;
            invader_table[38]    <= 52'h0_020_260_20_0_fff;
            invader_table[39]    <= 52'h0_000_000_20_0_000;
            invader_table[40]    <= 52'h0_000_000_20_0_000;
            invader_table[41]    <= 52'h0_000_000_20_0_000;
            invader_table[42]    <= 52'h0_000_000_20_0_000;
            invader_table[43]    <= 52'h0_000_000_20_0_000;
            invader_table[44]    <= 52'h0_000_000_20_0_000;
            invader_table[45]    <= 52'h0_000_000_20_0_000;
            invader_table[46]    <= 52'h0_000_000_20_0_000;
            invader_table[47]    <= 52'h0_000_000_20_0_000;
            invader_table[48]    <= 52'h0_000_000_20_0_000;
            invader_table[50]    <= 52'h0_1c0_000_20_1_fff;
            invader_table[51]    <= 52'h0_000_000_20_0_000;
            invader_table[52]    <= 52'h0_000_000_20_0_000;
            invader_table[53]    <= 52'h0_000_000_20_0_000;
            invader_table[54]    <= 52'h0_000_000_20_0_000;
            invader_table[55]    <= 52'h0_000_000_20_0_000;
            invader_table[56]    <= 52'h0_000_000_20_0_000;
            invader_table[57]    <= 52'h0_000_000_20_0_000;
            invader_table[58]    <= 52'h0_000_000_20_0_000;
            invader_table[59]    <= 52'h0_000_000_20_0_000;
            invader_table[60]    <= 52'h0_000_000_20_0_000;
            invader_table[61]    <= 52'h0_1a0_000_20_1_000;
            invader_table[62]    <= 52'h8_1c0_000_20_1_ff0;

            invader_tableTEMP[0]     <= 52'h0_000_000_20_0_000;
            invader_tableTEMP[1]     <= 52'h0_000_000_20_0_000;
            invader_tableTEMP[2]     <= 52'h0_000_000_20_0_000;
            invader_tableTEMP[3]     <= 52'h0_000_000_20_0_000;
            invader_tableTEMP[4]     <= 52'h0_000_000_20_0_000;
            invader_tableTEMP[5]     <= 52'h0_000_000_20_0_000;
            invader_tableTEMP[6]     <= 52'h0_000_000_20_0_000;
            invader_tableTEMP[7]     <= 52'h0_000_000_20_0_000;
            invader_tableTEMP[8]     <= 52'h0_000_000_20_0_000;
            invader_tableTEMP[9]     <= 52'h0_000_000_20_0_000;
            invader_tableTEMP[10]    <= 52'h0_000_000_20_0_000;
            invader_tableTEMP[11]    <= 52'h0_000_000_20_0_000;
            invader_tableTEMP[12]    <= 52'h0_000_000_20_0_000;
            invader_tableTEMP[13]    <= 52'h0_000_000_20_0_000;
            invader_tableTEMP[14]    <= 52'h0_000_000_20_0_000;
            invader_tableTEMP[15]    <= 52'h0_000_000_20_0_000;
            invader_tableTEMP[16]    <= 52'h0_000_000_20_0_000;
            invader_tableTEMP[17]    <= 52'h0_000_000_20_0_000;
            invader_tableTEMP[18]    <= 52'h0_000_000_20_0_000;
            invader_tableTEMP[19]    <= 52'h0_000_000_20_0_000;
            invader_tableTEMP[20]    <= 52'h0_000_000_20_0_000;
            invader_tableTEMP[21]    <= 52'h0_000_000_20_0_000;
            invader_tableTEMP[22]    <= 52'h0_000_000_20_0_000;
            invader_tableTEMP[23]    <= 52'h0_000_000_20_0_000;
            invader_tableTEMP[24]    <= 52'h0_000_000_20_0_000;
            invader_tableTEMP[25]    <= 52'h0_000_000_20_0_000;
            invader_tableTEMP[26]    <= 52'h0_000_000_20_0_000;
            invader_tableTEMP[27]    <= 52'h0_000_000_20_0_000;
            invader_tableTEMP[28]    <= 52'h0_000_000_20_0_000;
            invader_tableTEMP[29]    <= 52'h0_000_000_20_0_000;
            invader_tableTEMP[30]    <= 52'h0_000_000_20_0_000;
            invader_tableTEMP[31]    <= 52'h0_000_000_20_0_000;
            invader_tableTEMP[32]    <= 52'h0_000_000_20_0_000;
            invader_tableTEMP[33]    <= 52'h0_000_000_20_0_000;
            invader_tableTEMP[34]    <= 52'h0_000_000_20_0_000;
            invader_tableTEMP[35]    <= 52'h0_000_000_20_0_000;
            invader_tableTEMP[36]    <= 52'h0_000_000_20_0_000;
            invader_tableTEMP[37]    <= 52'h0_000_000_20_0_000;
            invader_tableTEMP[38]    <= 52'h0_000_000_20_0_000;
            invader_tableTEMP[39]    <= 52'h0_000_000_20_0_000;
            invader_tableTEMP[40]    <= 52'h0_000_000_20_0_000;
            invader_tableTEMP[41]    <= 52'h0_000_000_20_0_000;
            invader_tableTEMP[42]    <= 52'h0_000_000_20_0_000;
            invader_tableTEMP[43]    <= 52'h0_000_000_20_0_000;
            invader_tableTEMP[44]    <= 52'h0_000_000_20_0_000;
            invader_tableTEMP[45]    <= 52'h0_000_000_20_0_000;
            invader_tableTEMP[46]    <= 52'h0_000_000_20_0_000;
            invader_tableTEMP[47]    <= 52'h0_000_000_20_0_000;
            invader_tableTEMP[48]    <= 52'h0_000_000_20_0_000;
            invader_tableTEMP[49]    <= 52'h0_000_000_20_0_000;
            invader_tableTEMP[50]    <= 52'h0_000_000_20_0_000;
            invader_tableTEMP[51]    <= 52'h0_000_000_20_0_000;
            invader_tableTEMP[52]    <= 52'h0_000_000_20_0_000;
            invader_tableTEMP[53]    <= 52'h0_000_000_20_0_000;
            invader_tableTEMP[54]    <= 52'h0_000_000_20_0_000;
            invader_tableTEMP[55]    <= 52'h0_000_000_20_0_000;
            invader_tableTEMP[56]    <= 52'h0_000_000_20_0_000;
            invader_tableTEMP[57]    <= 52'h0_000_000_20_0_000;
            invader_tableTEMP[58]    <= 52'h0_000_000_20_0_000;
            invader_tableTEMP[59]    <= 52'h0_000_000_20_0_000;
            invader_tableTEMP[60]    <= 52'h0_000_000_20_0_000;
            invader_tableTEMP[61]    <= 52'h0_000_000_20_0_000;
            invader_tableTEMP[62]    <= 52'h0_000_000_20_0_000;

            laser_table[0]  <= 40'h0_000_001_fff;
            laser_table[1]  <= 40'h0_000_010_ff0;
            laser_table[2]  <= 40'h0_000_000_000;
            laser_table[3]  <= 40'h0_000_000_000;
            laser_table[4]  <= 40'h0_000_000_000;
            laser_table[5]  <= 40'h0_000_000_000;
            laser_table[6]  <= 40'h0_000_000_000;
            laser_table[7]  <= 40'h0_000_000_000;
            laser_table[8]  <= 40'h0_000_000_000;
            laser_table[9]  <= 40'h0_000_020_ff0;
            laser_table[10] <= 40'h0_000_000_000;
            laser_table[11]  <= 40'h0_000_000_000;
            laser_table[12]  <= 40'h0_000_000_000;
            laser_table[13]  <= 40'h0_000_030_ff0;
            laser_table[14]  <= 40'h0_000_000_000;
            laser_table[15]  <= 40'h0_000_000_000;
            laser_table[16]  <= 40'h0_000_000_000;
            laser_table[17]  <= 40'h0_000_000_000;
            laser_table[18]  <= 40'h0_000_000_000;
            laser_table[19]  <= 40'h0_000_040_ff0;
            laser_table[20]  <= 40'h0_000_000_000;
            laser_table[21]  <= 40'h0_000_000_000;
            laser_table[22]  <= 40'h0_000_000_000;
            laser_table[23]  <= 40'h0_000_000_000;
            laser_table[24]  <= 40'h0_000_000_000;
            laser_table[25]  <= 40'h0_000_050_ff0;
            laser_table[26]  <= 40'h0_000_000_000;
            laser_table[27]  <= 40'h0_000_000_000;
            laser_table[28]  <= 40'h0_000_000_000;
            laser_table[29]  <= 40'h0_000_000_000;
            laser_table[30]  <= 40'h0_000_060_ff0;
            laser_table[31]  <= 40'h0_000_000_000;
            laser_table[32]  <= 40'h0_000_000_000;
            laser_table[33]  <= 40'h0_000_000_000;
            laser_table[34]  <= 40'h0_000_000_000;
            laser_table[35]  <= 40'h0_000_000_000;
            laser_table[36]  <= 40'h0_000_070_ff0;
            laser_table[37]  <= 40'h0_000_000_000;
            laser_table[38]  <= 40'h0_000_000_000;
            laser_table[39]  <= 40'h0_000_080_ff0;
            //laser_table[40]  <= 40'h0_000_000_000;
            
            //pixeladdrH <= 1'b0;
            invMS <= 7'd0;
            invMSEN <= 1'b0;
            movearg <= 1'b1;
            moveNext <= 1'b1;
            movelock <= 1'b0;
            umoveC <= 0;
            dinA8 <= 12'h000;
            rrom_clear <= 62'h0;
        end else begin
            if(clk60&(invMSEN == 0))begin
                invMSEN <= 1'b1;
                movearg <= moveNext;
                movelock <= 0;
                table_upS <= 3'b000;
                rrom_clear <= 62'h0;
            end else if(invMSEN)begin
                if(table_upS == 3'b000)begin
                    if(((invader_table[invMS]&52'h8_000_000_00_0_000) == 52'h8_000_000_00_0_000)&swf0) begin
                        if(invMS!=62)begin
                            case(movearg)
                                2'd0:begin
                                    if((invader_table[invMS]&52'h0_fff_000_00_0_000)>= 52'h0_010_000_00_0_000)begin
                                        invader_tableTEMP[invMS] <= ((invader_table[invMS]&52'hf_000_fff_ff_f_fff) + {(invader_table[invMS]&52'h0_fff_000_00_0_000) - {12'h0, speed, 36'h000000}});
                                    end else begin
                                        invader_tableTEMP[invMS] <= invader_table[invMS];
                                        moveNext <= 1;
                                        movelock <= 1;
                                    end
                                end
                                2'd1:begin
                                    if((invader_table[invMS]&52'h0_000_fff_00_0_000)< (52'h0_000_280_00_0_000 - {16'h0_000, rrom_size[invMS], 24'h00_0_000} - {16'h0_000, speed, 24'h00_0_000}))begin
                                        invader_tableTEMP[invMS] <= ((invader_table[invMS]&52'hf_fff_000_ff_f_fff) + {(invader_table[invMS]&52'h0_000_fff_00_0_000) + {24'h0, speed, 24'h000}});
                                    end else begin
                                        invader_tableTEMP[invMS] <= invader_table[invMS];
                                        moveNext <= 2;
                                        movelock <= 1;
                                    end
                                end
                                2'd2:begin
                                    if(((invader_table[invMS]&52'h0_fff_000_00_0_000)< 52'h0_1c0_000_00_0_000))begin
                                        invader_tableTEMP[invMS] <= ((invader_table[invMS]&52'hf_000_fff_ff_f_fff) + {(invader_table[invMS]&52'h0_fff_000_00_0_000) + 52'h0_001_000_00_0_000});
                                        //umoveC <= umoveC + 1;
                                        moveNext <= (umoveC == 31) ?3:2;
                                        //moveNext <= 3;
                                    end else begin
                                        invader_tableTEMP[invMS] <= invader_table[invMS];
                                        moveNext <=3;
                                        movelock <= 1;
                                    end
                                end
                                2'd3:begin
                                    if((invader_table[invMS]&52'h0_000_fff_00_0_000)>= 52'h0_000_010_00_0_000)begin
                                        invader_tableTEMP[invMS] <= ((invader_table[invMS]&52'hf_fff_000_ff_f_fff) + {(invader_table[invMS]&52'h0_000_fff_00_0_000) - {24'h0, speed, 24'h000}});
                                    end else begin
                                        invader_tableTEMP[invMS] <= invader_table[invMS];
                                        moveNext <= 1;
                                        movelock <= 1;
                                    end
                                end
                            endcase
                        end
                    end begin
                        invT_pV[invMS] <= 8'h00;
                        invT_pH[invMS] <= 8'h00; 
                        invMS <= (invMS == 62) ? 0 : invMS + 1;
                        //invMSEN <= (invMS == 100) ? 0 : 1;
                        table_upS <= (invMS == 62) ? 3'b001 : 3'b000;
                    end
                end else if(table_upS == 3'b001)begin
                    if(invMS != 62)invader_table[invMS] <= (movelock) ? invader_table[invMS] : invader_tableTEMP[invMS];
                    else if(((invader_table[62]&52'h8_000_fff_00_0_000)>= 52'h8_000_002_00_0_000)&btnL)invader_table[62] <= (invader_table[62]- {16'h0, 12'h002, 24'h000});
                    else if(((invader_table[62]&52'h8_000_fff_00_0_000)<  52'h8_000_25f_00_0_000)&btnR)invader_table[62] <= (invader_table[62]+ {16'h0, 12'h002, 24'h000});
                    invMS <= (invMS == 62) ? 0 : invMS + 1;
                    //invMSEN <= (invMS == 62) ? 0 : 1;
                    table_upS <= (invMS == 62) ? 3'b010 : 3'b001;
                    umoveC <= (umoveC == 31) ? ((invMS == 62)? 0 : umoveC) : ((invMS == 62)? umoveC + 1 : umoveC);
                    movelock <= (invMS != 62) ? movelock : 0;
                end else if(table_upS ==3'b010)begin
                    if(invMS == 0)begin
                        if(lase_EN[0]) laser_table[0] <= (lase_vpos[0] >= 4) ? {laser_table[0] - 40'h0_004_000_000} : 40'h0; 
                        else if((!lase_EN[0]) & btnC) laser_table[0] <= {4'h8, 12'h1bf, lase_chpos, 12'hfff};
                        else laser_table[0] <= laser_table[0];
                        // rrom_hpos[62] + 17が上手くいかないので配線をassignする
                    end else begin
                        //if(lase_EN[invMS]) laser_table[invMS] <= (lase_vpos[invMSEN] < 460) ? {laser_table[invMS] + 40'h0_004_000_000} : {laser_table[invMS]&40'hf_000_fff_fff};
                        //else laser_table[invMS] <= laser_table[invMS];
                        if(lase_EN[invMS]) laser_table[invMS] <= (lase_vpos[invMSEN] < 460) ? {laser_table[invMS] + 40'h0_004_000_000} : 40'h0;
                        else laser_table[invMS] <= laser_table[invMS];
                    end begin
                        invMS <= (invMS ==39) ? 0 : invMS + 1;
                        //invMSEN <= (invMS == 39) ? 0 : 1;
                        table_upS <= (invMS == 39) ? 3'b011 : 3'b010;
                        umoveC <= umoveC;
                    end
                
                end else if(table_upS ==3'b011) begin
                    if(invMS != 0)begin
                        if(!lase_EN[invMS] && (short_PS <= 61)) laser_table[invMS] <= {4'h8, rrom_vpos[short_PS], lase_cepos, 12'hff0};
                        else laser_table[invMS] <= laser_table[invMS];
                    end begin
                        invMS <= (invMS ==39) ? 0 : invMS + 1;
                        //invMSEN <= (invMS == 39) ? 0 : 1;
                        table_upS <= (invMS == 39) ? 3'b100 : 3'b011;
                        umoveC <= umoveC;                                        
                    end
                end else if(table_upS ==3'b100) begin
                    /*
                    if((lase_EN[0])&(lase_EN[invMS])&((lase_vpos[invMS]-lase_vpos[0])<30)&(((lase_hpos[invMS]-lase_hpos[0])<10)|((lase_hpos[0]-lase_hpos[invMS])<10)))begin
                        laser_table[0] <= 40'h0_000_000_000;
                        laser_table[invMS] <= 40'h0_000_000_000;    
                    end else begin
                        laser_table[0] <= laser_table[0];
                        laser_table[invMS] <= laser_table[invMS];
                    end begin
                        invMS <= (invMS ==39) ? 0 : invMS + 1;
                        invMSEN <= (invMS == 39) ? 0 : 1;
                        table_upS <= (invMS == 39) ? 3'b000 : 3'b100;
                        umoveC <= umoveC;                
                    end
                    */
                    if(invMS==62) begin
                        invader_tableTEMP[invMS] <= invader_table[invMS];
                    end else if((lase_EN[0])&(rrom_EN[invMS])&((rrom_vpos[invMS]-lase_vpos[0])<=32)&((lase_hpos[0]-rrom_hpos[invMS])<=32)) begin
                        invader_tableTEMP[invMS] <= 52'h0_000_000_00_0_000;
                        laser_table[0] <= 40'h0_000_000_000;
                    //invader_tableTEMP[erasesel] <= (eraseen) ? (invader_table[erasesel]|52'h8_000_000_00_0_000) : (invader_table[erasesel]&52'h0_fff_fff_ff_f_fff);
                    end else begin
                        invader_tableTEMP[invMS] <= invader_table[invMS];
                        laser_table[0] <= laser_table[0];
                    end begin
                        invMS <= (invMS == 62) ? 0 : invMS + 1;
                        //invMSEN <= (invMS == 61) ? 0 : 1;
                        table_upS <= (invMS == 62) ? 3'b101 : 3'b100;
                        umoveC <= umoveC;                
                    end
                end else if(table_upS == 3'b101)begin
                //invader_table[invMS]は動かない
                //invader_table[8]は動かない
                //invader_table[62]は動いた
                    //if((invMS<=61)& rrom_clear[invMS])begin
                    //    invader_table[invMS] <= invader_table[invMS]&52'b0000_000000000000_000000000000_00000000_0000_000000000000;
                    //    laser_table[0] <= 40'h0_000_000_000;
                    //if(invMS<62)begin
                    //    invader_table[invMS] <= 0;
                    //end else begin
                    //    invader_table[invMS] <= invader_table[invMS];
                    //    laser_table[0] <= laser_table[0];
                    //end begin
                        invader_table[invMS] <= invader_tableTEMP[invMS];
                        invMS <= (invMS == 62) ? 0 : invMS + 1;
                        invMSEN <= (invMS == 62) ? 0 : 1;
                        table_upS <= (invMS == 62) ? 3'b000 : 3'b101;
                        umoveC <= umoveC;                      
                    //end
                end
            end else begin
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
                3'd0 : csA <= 1;
                3'd1 : csA <= 1<<1;
                3'd2 : csA <= 1<<2;
                3'd3 : csA <= 1<<3;
                3'd4 : csA <= 1<<4;
                3'd5 : csA <= 1<<5;
                3'd6 : csA <= 1<<6;
                3'd7 : csA <= 1<<7;
            endcase
            dinA8 <= 12'h000;
        end else if(lase_rens < 40)begin
            csA <= 0;
            dinA8 <= lase_color[lase_rens];
        end else begin
            csA <= 0;
            dinA8 <= 12'h000;
        end    
end

always_ff @(posedge clk25M)begin
    case(csA)
        8'b00000001 : dinB <= dinA0 * colorpallet;
        8'b00000010 : dinB <= dinA1 * colorpallet;
        8'b00000100 : dinB <= dinA2;
        8'b00001000 : dinB <= dinA3;
        8'b00010000 : dinB <= dinA4;
        8'b00100000 : dinB <= dinA5;
        8'b01000000 : dinB <= dinA6;
        8'b10000000 : dinB <= dinA7;
        default : dinB <= dinA8;
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

assign  rrom_rens = rrom_ren[0] ? 6'd0 :
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