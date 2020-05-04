module gamefsm #(
    parameter rad = 8,
    parameter intable = "intable.txt",
    parameter latable = "latable.txt",
    parameter invader00 = "picture/invader00.txt"
)(
    input   logic           clk, reset, clk25M, clk60,
    input   logic           swf2, swf1, swf0,
    //input   logic           btnC, btnU, btnL, btnR, btnD,
    input   logic   [3:0]   speed,
    input   logic   [9:0]   whpos, wvpos,
    input   logic   [18:0]  write_vramA,
    input   logic           write_ENA,
    output  logic   [18:0]  write_vramB,
    output  logic           write_ENB,
    output  logic   [11:0]  vdin

    // for rom override
    /*
    input   logic   [rad-1:0]   romsec,
    input   logic   [5:0]       romwA,
    input   logic   [11:0]      romwdata
    */
);
/*
0x00    none
0x01    invader  (CRAB)_L
0x02    invader  (CRAB)_C
0x03    invader  (CRAB)_R
0x04    invader' (CRAB)_L
0x05    invader' (CRAB)_C
0x06    invader' (CRAB)_R
0x07    laser_invader
0x08    cannon_L
0x09    cannon_C
0x0a    cannon_R
0x0b    laser_cannon_L
0x0c    laser_cannon_C
0x0d    laser_cannon_R
0x0e    "g"
0x0f    "a"
0x10    "m"
0x11    "e"
0x12    "s"
0x13    "t"
0x14    "r"
0x15    "o"
0x16    "v"
*/
/*
typedef enum logic [2:0] {
    game_start, game_play, game_result, game_over, game_romu
} game_stateT;
typedef enum logic [1:0] {
    inv_stop, inv_left, inv_right, inv_under
} invader_stateT;

game_stateT game_state;
invader_stateT invader_state;
*/
/*
invader table align (word: 0: canon, 1-49 invader)
invader exist(1/0 : 2bit) | ID (6bit) | start vpos(0-480 12bit) | start hpos(0-640 12bit) | color (0x000-0xfff 12bit)

laser
laser table align (word 0 cannon, 1-40 laser)
laser exist (1/0 : 2bit)| ID (2bit) | retu(0-14 (4bit)) | gyo(0-640 12bit) | color (0x000-0xfff 12bit)
*/

logic   [51:0]    invader_table [0:62];
logic   [51:0]    invader_tableTEMP [0:62];
logic   [7:0]     invT_pV       [0:62];
logic   [7:0]     invT_pH       [0:62];

logic   [31:0]    inv00A        [0:31];
logic   [31:0]    inv01A        [0:31];
logic   [31:0]    inv02A        [0:31];
logic   [31:0]    inv03A        [0:31];
logic   [31:0]    inv04A        [0:31];
logic   [31:0]    inv05A        [0:31];
logic   [11:0]    inv00B        [0:16383];
logic   [11:0]    inv01B        [0:16383];

logic   [27:0]    laser_table   [0:39];

initial begin
    //$readmemh(intable, invader_table);
    $readmemh(latable, laser_table);
    $readmemh("invTs.txt", invT_pV);
    $readmemh("invTs.txt", invT_pH);
    $readmemb(invader00, inv00A);
    $readmemb("picture/space.txt", inv01A);
    $readmemb("picture/space.txt", inv02A);
    $readmemb("picture/space.txt", inv03A);
    $readmemb("picture/space.txt", inv04A);
    $readmemb("picture/space.txt", inv05A);
    $readmemh("picture/karubabu.txt", inv00B);
    $readmemh("picture/fire.txt", inv01B);
end

logic   [6:0]   invMS;
logic           invMSEN;

logic   [7:0]   invT_pVs;
logic   [7:0]   invT_pHs;

logic   [63:0]  rrom_ren;
logic   [5:0]   rrom_rens;
logic   [63:0]  rrom_EN;
logic   [11:0]  rrom_vpos  [62:0];
logic   [11:0]  rrom_hpos  [62:0];
logic   [7:0]   rrom_size  [62:0];
logic   [63:0]  rrom_whpos;
logic   [63:0]  rrom_wvpos;
logic   [11:0]  colorpallet;
//logic   [3:0]   rrom_colorM  [62:0];
logic   [2:0]   rrom_ID [62:0];

logic   [1:0]   movearg; // 0^ 1> 2v 3<
logic   [1:0]   moveNext;
logic   [4:0]   umoveC;
logic           movelock; // 1 .. locked

logic   [15:0]  invT_p12;
logic   [1:0]   table_upS;

assign invT_pVs = invT_pV[rrom_rens];
assign invT_pHs = invT_pH[rrom_rens];
assign invT_p12 = invT_pV[rrom_rens] * rrom_size[rrom_rens] + invT_pH[rrom_rens];
genvar i;

always_ff @(posedge clk25M) begin
        if(reset)begin
            invader_table[0]     <= 52'h8_000_000_20_0_fff;
            invader_table[1]     <= 52'h8_020_020_80_6_fff;
            invader_table[2]     <= 52'h8_080_030_80_7_fff;
            invader_table[3]     <= 52'h0_000_080_20_0_fff;
            invader_table[4]     <= 52'h0_000_0a0_20_0_fff;
            invader_table[5]     <= 52'h0_000_0c0_20_0_fff;
            invader_table[6]     <= 52'h0_000_0e0_20_0_fff;
            invader_table[7]     <= 52'h0_000_100_20_0_fff;
            invader_table[8]     <= 52'h0_000_120_20_0_fff;
            invader_table[9]     <= 52'h0_000_140_20_0_fff;
            invader_table[10]    <= 52'h0_000_160_20_0_fff;
            invader_table[11]    <= 52'h0_000_180_20_0_fff;
            invader_table[12]    <= 52'h0_000_1a0_20_0_fff;
            invader_table[13]    <= 52'h0_000_1c0_20_0_fff;
            invader_table[14]    <= 52'h0_000_1e0_20_0_fff;
            invader_table[15]    <= 52'h0_000_200_20_0_fff;
            invader_table[16]    <= 52'h0_000_220_20_0_fff;
            invader_table[17]    <= 52'h0_000_240_20_0_fff;
            invader_table[18]    <= 52'h0_000_260_20_0_fff;
            invader_table[19]    <= 52'h0_020_000_20_0_fff;
            invader_table[20]    <= 52'h0_020_020_20_0_fff;
            invader_table[21]    <= 52'h0_020_040_20_0_fff;
            invader_table[22]    <= 52'h0_020_060_20_0_fff;
            invader_table[23]    <= 52'h0_020_080_20_0_fff;
            invader_table[24]    <= 52'h0_020_0a0_20_0_fff;
            invader_table[25]    <= 52'h0_020_0c0_20_0_fff;
            invader_table[26]    <= 52'h0_020_0e0_20_0_fff;
            invader_table[27]    <= 52'h0_020_100_20_0_fff;
            invader_table[28]    <= 52'h0_020_120_20_0_fff;
            invader_table[29]    <= 52'h0_020_140_20_0_fff;
            invader_table[30]    <= 52'h0_020_160_20_0_fff;
            invader_table[31]    <= 52'h0_020_180_20_0_fff;
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
            invader_table[50]    <= 52'h0_000_000_20_0_000;
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
            invader_table[61]    <= 52'h0_000_000_20_0_000;
            invader_table[62]    <= 52'h0_000_000_20_0_000;

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

            //pixeladdrH <= 1'b0;
            invMS <= 7'd0;
            invMSEN <= 1'b0;
            movearg <= 1'b1;
            moveNext <= 1'b1;
            movelock <= 1'b0;
            umoveC <= 0;
        end else begin
            if(clk60&(invMSEN == 0))begin
                invMSEN <= 1'b1;
                movearg <= moveNext;
                movelock <= 0;
                table_upS <= 2'b00;
            end else if(invMSEN)begin
                if(table_upS == 2'b00)begin
                    if(((invader_table[invMS]&52'h8_000_000_00_0_000) == 52'h8_000_000_00_0_000)&swf0) begin
                        if(invMS<62)begin
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
                                if((invader_table[invMS]&52'h0_000_fff_00_0_000)< 52'h0_000_280_00_0_000 - {16'h0_000, rrom_size[invMS], 24'h00_0_000})begin
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
                        table_upS <= (invMS == 62) ? 2'b01 : 2'b00;
                    end
                end else if(table_upS == 2'b01)begin
                        invader_table[invMS] <= (movelock) ? invader_table[invMS] : invader_tableTEMP[invMS];
                        invMS <= (invMS == 62) ? 0 : invMS + 1;
                        invMSEN <= (invMS == 62) ? 0 : 1;
                        table_upS <= (invMS == 62) ? 2'b00 : 2'b01;
                        umoveC <= (umoveC == 31) ? ((invMS == 62)? 0 : umoveC) : ((invMS == 62)? umoveC + 1 : umoveC);
                end    
            end else begin
                if(rrom_rens != 63)begin
                    if(rrom_ren[rrom_rens] & write_ENA)begin
                        invT_pH[rrom_rens] <= (whpos==rrom_hpos[rrom_rens]) ? 0 : (whpos==rrom_hpos[rrom_rens]+rrom_size[rrom_rens]-1) ? 0 : invT_pH[rrom_rens] + 1;
                        invT_pV[rrom_rens] <= (whpos==rrom_hpos[rrom_rens]+rrom_size[rrom_rens]-1) ? invT_pV[rrom_rens] + 1 : invT_pV[rrom_rens];
                    end begin
                        colorpallet <= invader_table[rrom_rens];
                    end
                end
            end
        end 
        if(rrom_rens != 63)begin
            case(rrom_ID[rrom_rens])
                3'd0 : vdin <= inv00A[invT_pVs][invT_pHs] * colorpallet;
                3'd1 : vdin <= inv01A[invT_pVs][invT_pHs] * colorpallet;
                3'd2 : vdin <= inv02A[invT_pVs][invT_pHs] * colorpallet;
                3'd3 : vdin <= inv03A[invT_pVs][invT_pHs] * colorpallet;
                3'd4 : vdin <= inv04A[invT_pVs][invT_pHs] * colorpallet;
                3'd5 : vdin <= inv05A[invT_pVs][invT_pHs] * colorpallet;
                3'd6 : vdin <= inv00B[invT_p12];
                3'd7 : vdin <= inv01B[invT_p12];
            endcase
        end else begin
            vdin <= 12'h000;
        end    
end

typedef enum logic [1:0] {
    blankS, romS
} rrom_stateT;
rrom_stateT rrom_state;


genvar k;
generate 
    for(k=0;k<63;k=k+1) begin : RromReadEN
        assign rrom_EN[k]   = (invader_table[k]&52'hf_000_000_00_0_000)>>51;
        assign rrom_vpos[k] = (invader_table[k]&52'h0_fff_000_00_0_000)>>36;
        assign rrom_hpos[k] = (invader_table[k]&52'h0_000_fff_00_0_000)>>24;
        assign rrom_size[k] = (invader_table[k]&52'h0_000_000_ff_0_000)>>16;
        assign rrom_ID[k]   = (invader_table[k]&52'h0_000_000_00_f_000)>>12;
        //assign rrom_ID[k]    =(invader_table[k]&52'hf_000_000_00_0_000)>>48;
        assign rrom_whpos[k] = (rrom_EN[k]==1'b1) & (rrom_hpos[k]<=whpos) & (whpos < rrom_hpos[k]+rrom_size[k]);
        assign rrom_wvpos[k] = (rrom_EN[k]==1'b1) & (rrom_vpos[k]<=wvpos) & (wvpos < rrom_vpos[k]+rrom_size[k]);
        assign rrom_ren[k] = (rrom_EN[k]==1'b1) & (rrom_hpos[k]<=whpos) & (whpos < rrom_hpos[k]+rrom_size[k]) & (rrom_vpos[k]<=wvpos) & (wvpos < rrom_vpos[k]+rrom_size[k]);                                                     
    end
endgenerate

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
    write_ENB <= write_ENA;
end

endmodule