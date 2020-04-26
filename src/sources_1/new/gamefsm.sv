module gamefsm #(
    parameter rad = 8,
    parameter intable = "intable.txt",
    parameter latable = "latable.txt",
    parameter invader01 = "invader01.txt"
)(
    input   logic           clk, reset, clk25M, clk60,
    input   logic           swL, swR, swW,
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
invader exist(1/0 : 2bit) | ID (2bit) | retu(0-14 4bit) | gyo(0-640 12bit) | color (0x000-0xfff 12bit)

laser
laser table align (word 0 cannon, 1-40 laser)
laser exist (1/0 : 2bit)| ID (2bit) | retu(0-14 (4bit)) | gyo(0-640 12bit) | color (0x000-0xfff 12bit)
*/

logic   [39:0]    invader_table [0:49];
logic   [27:0]    laser_table   [0:39];
logic   [31:0]    inv01A        [0:31];

initial begin
    //$readmemh(intable, invader_table);
    $readmemh(latable, laser_table);
    $readmemb(invader01, inv01A);
end

logic   [7:0]   invWEI;
logic   [11:0]  invWCO;
logic   [11:0]  invWXPa,invWXPb;

logic   [18:0]  pixeladdrH, pixeladdrV;
logic   [11:0]  colorpallet;
//assign  pixeladdrH = (whpos%32);
assign  pixeladdrV = (wvpos%32);

logic   [5:0]   invMS;
logic           invMSEN;

always_ff @(posedge clk25M) begin
        if(reset)begin
            invader_table[0]     <= 40'h8_000_000_fff;
            invader_table[1]     <= 40'h8_001_140_fff;
            invader_table[2]     <= 40'h8_002_000_fff;
            invader_table[3]     <= 40'h8_003_140_fff;
            invader_table[4]     <= 40'h8_004_000_fff;
            invader_table[5]     <= 40'h8_005_140_fff;
            invader_table[6]     <= 40'h8_006_000_fff;
            invader_table[7]     <= 40'h8_007_140_fff;
            invader_table[8]     <= 40'h8_008_000_fff;
            invader_table[9]     <= 40'h8_009_140_fff;
            invader_table[10]    <= 40'h8_00a_000_fff;
            invader_table[11]    <= 40'h8_00b_140_fff;
            invader_table[12]    <= 40'h8_00c_000_fff;
            invader_table[13]    <= 40'h8_00d_140_fff;
            invader_table[14]    <= 40'h8_00e_000_fff;
            invader_table[15]    <= 40'h0_000_000_000;
            invader_table[16]    <= 40'h0_000_000_000;
            invader_table[17]    <= 40'h0_000_000_000;
            invader_table[18]    <= 40'h0_000_000_000;
            invader_table[19]    <= 40'h0_000_000_000;
            invader_table[20]    <= 40'h0_000_000_000;
            invader_table[21]    <= 40'h0_000_000_000;
            invader_table[22]    <= 40'h0_000_000_000;
            invader_table[23]    <= 40'h0_000_000_000;
            invader_table[24]    <= 40'h0_000_000_000;
            invader_table[25]    <= 40'h0_000_000_000;
            invader_table[26]    <= 40'h0_000_000_000;
            invader_table[27]    <= 40'h0_000_000_000;
            invader_table[28]    <= 40'h0_000_000_000;
            invader_table[29]    <= 40'h0_000_000_000;
            invader_table[30]    <= 40'h0_000_000_000;
            invader_table[31]    <= 40'h0_000_000_000;
            invader_table[32]    <= 40'h0_000_000_000;
            invader_table[33]    <= 40'h0_000_000_000;
            invader_table[34]    <= 40'h0_000_000_000;
            invader_table[35]    <= 40'h0_000_000_000;
            invader_table[36]    <= 40'h0_000_000_000;
            invader_table[37]    <= 40'h0_000_000_000;
            invader_table[38]    <= 40'h0_000_000_000;
            invader_table[39]    <= 40'h0_000_000_000;
            invader_table[40]    <= 40'h0_000_000_000;
            invader_table[41]    <= 40'h0_000_000_000;
            invader_table[42]    <= 40'h0_000_000_000;
            invader_table[43]    <= 40'h0_000_000_000;
            invader_table[44]    <= 40'h0_000_000_000;
            invader_table[45]    <= 40'h0_000_000_000;
            invader_table[46]    <= 40'h0_000_000_000;
            invader_table[47]    <= 40'h0_000_000_000;
            invader_table[48]    <= 40'h0_000_000_000;
            invader_table[49]    <= 40'h0_000_000_000;
            
            pixeladdrH <= 1'b0;
            invMS <= 6'd0;
            invMSEN <= 1'b0;
        end else begin
            if(clk60&swW&(invMSEN == 0))begin
                invMSEN <= 1'b1;
            end else if(invMSEN)begin
                if((invader_table[invMS]&40'h8_000_000_000) == 40'h8_000_000_000) begin
                    if ((invader_table[invMS]&40'h0_000_fff_000)<= 40'h0_000_25f_000) begin
                        invader_table[invMS] <= ((invader_table[invMS]&40'hf_fff_000_000) + {(invader_table[invMS]&40'h0_000_fff_000) + 40'h0_000_003_000} + {invader_table[invMS]&40'h0_000_000_fff});
                    end else begin
                        invader_table[invMS] <= ((invader_table[invMS]&40'hf_fff_000_000) + {invader_table[invMS]&40'h0_000_000_000                      } + {invader_table[invMS]&40'h0_000_000_fff});
                    end 
                end
                invMS <= (invMS == 14) ? 0 : invMS + 1;
                invMSEN <= (invMS == 14) ? 0 : 1;
            end else begin
                pixeladdrH <= (whpos==rrom_hpos[rrom_rens]) ? 0 : (whpos==rrom_hpos[rrom_rens]+32) ? 0 : pixeladdrH + 1; 
                colorpallet <= invader_table[rrom_rens];
                vdin <= (rrom_rens != 50)? inv01A[pixeladdrV][pixeladdrH] * colorpallet : 12'h000; 
            end
        end    
end

typedef enum logic [1:0] {
    blankS, romS
} rrom_stateT;
rrom_stateT rrom_state;

logic   [49:0]  rrom_ren;
logic   [49:0]  rrom_EN;
logic   [3:0]   rrom_vpos  [49:0];
logic   [11:0]   rrom_hpos  [49:0];
logic   [49:0]  rrom_whpos;
logic   [49:0]  rrom_wvpos;

genvar k;
generate 
    for(k=0;k<50;k=k+1) begin : RromReadEN
        assign rrom_EN[k]   = (invader_table[k]&40'hf_000_000_000)>>39;
        assign rrom_vpos[k] = (invader_table[k]&40'h0_fff_000_000)>>24;
        assign rrom_hpos[k] = (invader_table[k]&40'h0_000_fff_000)>>12;
        assign rrom_whpos[k] = (rrom_EN[k]==1'b1) & (rrom_hpos[k]<=whpos) & (whpos < rrom_hpos[k]+32);
        assign rrom_wvpos[k] = (rrom_EN[k]==1'b1) & (rrom_vpos[k]*32<=wvpos) & (wvpos < (rrom_vpos[k]+1)*32);
        assign rrom_ren[k] = (rrom_EN[k]==1'b1) & (rrom_hpos[k]<=whpos) & (whpos < rrom_hpos[k]+32) & (rrom_vpos[k]*32<=wvpos) & (wvpos < (rrom_vpos[k]+1)*32);                                                     
    end
endgenerate

logic   [5:0]   rrom_rens;
always_comb begin
    case(rrom_ren)
        50'b00000000000000000000000000000000000000000000000000 : rrom_rens <= 6'd50;
        50'b00000000000000000000000000000000000000000000000001 : rrom_rens <= 6'd0;
        50'b00000000000000000000000000000000000000000000000010 : rrom_rens <= 6'd1;
        50'b00000000000000000000000000000000000000000000000100 : rrom_rens <= 6'd2;
        50'b00000000000000000000000000000000000000000000001000 : rrom_rens <= 6'd3;
        50'b00000000000000000000000000000000000000000000010000 : rrom_rens <= 6'd4;
        50'b00000000000000000000000000000000000000000000100000 : rrom_rens <= 6'd5;
        50'b00000000000000000000000000000000000000000001000000 : rrom_rens <= 6'd6;
        50'b00000000000000000000000000000000000000000010000000 : rrom_rens <= 6'd7;
        50'b00000000000000000000000000000000000000000100000000 : rrom_rens <= 6'd8;
        50'b00000000000000000000000000000000000000001000000000 : rrom_rens <= 6'd9;
        50'b00000000000000000000000000000000000000010000000000 : rrom_rens <= 6'd10;
        50'b00000000000000000000000000000000000000100000000000 : rrom_rens <= 6'd11;
        50'b00000000000000000000000000000000000001000000000000 : rrom_rens <= 6'd12;
        50'b00000000000000000000000000000000000010000000000000 : rrom_rens <= 6'd13;
        50'b00000000000000000000000000000000000100000000000000 : rrom_rens <= 6'd14;
        50'b00000000000000000000000000000000001000000000000000 : rrom_rens <= 6'd15;
        50'b00000000000000000000000000000000010000000000000000 : rrom_rens <= 6'd16;
        50'b00000000000000000000000000000000100000000000000000 : rrom_rens <= 6'd17;
        50'b00000000000000000000000000000001000000000000000000 : rrom_rens <= 6'd18;
        50'b00000000000000000000000000000010000000000000000000 : rrom_rens <= 6'd19;
        50'b00000000000000000000000000000100000000000000000000 : rrom_rens <= 6'd20;
        50'b00000000000000000000000000001000000000000000000000 : rrom_rens <= 6'd21;
        50'b00000000000000000000000000010000000000000000000000 : rrom_rens <= 6'd22;
        50'b00000000000000000000000000100000000000000000000000 : rrom_rens <= 6'd23;
        50'b00000000000000000000000001000000000000000000000000 : rrom_rens <= 6'd24;
        50'b00000000000000000000000010000000000000000000000000 : rrom_rens <= 6'd25;
        50'b00000000000000000000000100000000000000000000000000 : rrom_rens <= 6'd26;
        50'b00000000000000000000001000000000000000000000000000 : rrom_rens <= 6'd27;
        50'b00000000000000000000010000000000000000000000000000 : rrom_rens <= 6'd28;
        50'b00000000000000000000100000000000000000000000000000 : rrom_rens <= 6'd29;
        50'b00000000000000000001000000000000000000000000000000 : rrom_rens <= 6'd30;
        50'b00000000000000000010000000000000000000000000000000 : rrom_rens <= 6'd31;
        50'b00000000000000000100000000000000000000000000000000 : rrom_rens <= 6'd32;
        50'b00000000000000001000000000000000000000000000000000 : rrom_rens <= 6'd33;
        50'b00000000000000010000000000000000000000000000000000 : rrom_rens <= 6'd34;
        50'b00000000000000100000000000000000000000000000000000 : rrom_rens <= 6'd35;
        50'b00000000000001000000000000000000000000000000000000 : rrom_rens <= 6'd36;
        50'b00000000000010000000000000000000000000000000000000 : rrom_rens <= 6'd37;
        50'b00000000000100000000000000000000000000000000000000 : rrom_rens <= 6'd38;
        50'b00000000001000000000000000000000000000000000000000 : rrom_rens <= 6'd39;
        50'b00000000010000000000000000000000000000000000000000 : rrom_rens <= 6'd40;
        50'b00000000100000000000000000000000000000000000000000 : rrom_rens <= 6'd41;
        50'b00000001000000000000000000000000000000000000000000 : rrom_rens <= 6'd42;
        50'b00000010000000000000000000000000000000000000000000 : rrom_rens <= 6'd43;
        50'b00000100000000000000000000000000000000000000000000 : rrom_rens <= 6'd44;
        50'b00001000000000000000000000000000000000000000000000 : rrom_rens <= 6'd45;
        50'b00010000000000000000000000000000000000000000000000 : rrom_rens <= 6'd46;
        50'b00100000000000000000000000000000000000000000000000 : rrom_rens <= 6'd47;
        50'b01000000000000000000000000000000000000000000000000 : rrom_rens <= 6'd48;
        50'b10000000000000000000000000000000000000000000000000 : rrom_rens <= 6'd49;
    default: rrom_rens <= 6'd50;
    endcase
end


always_ff @(posedge clk25M)begin
    write_vramB <= write_vramA;
    write_ENB <= write_ENA;
end

/*
always_ff @(posedge clk60) begin
    if(reset) begin
        game_state <= game_start;
        invader_state <= inv_stop;
    end else if(schange) begin
        case(game_state)
            game_state : begin
                if(swW) begin
                    game_state <= game_play;
                    invader_state <= left;
                end
            end
            game_play : begin
                // cannon turn
                if(swL & (vtable[19:12][840] == laser_cannon_L))// cannon NOT moves left
                else if(swL & (vtable[19:12][840] != laser_cannon_L))// cannon moves left
                if(swR & (vtable[19:12][899] == laser_cannon_R))// cannon NOT moves right
                else if(swR & (vtable[19:12][899] == laser_cannon_R))// cannon moves right
                if(swW) // cannon launch laser
                
                // invader (laser)
                
                //  invader (move)                
                case(invader_state)
                    inv_left: begin
                        if(leftedges)begin
                            invader_state <= inv_right;
                        end else begin
                         // invader moves left
                        end
                    end
                    inv_right : begin
                        if(rightedges & rightedge[14]==1'b0)begin
                    
                        //invader moves under
                        end else if(rightedges & rightedge[14]==1'b1)// gameover
                    end
                    inv_under : begin
                        //moves under and status left
                        invader_state <= inv_left;
                    end
                    default: begin
                        game_state <= game_over;
                        invader_state <= inv_stop;
                    end
            end
            game_result : begin
            end
            game_over : begin
            end
            game_romu : begin
            end
    end
end
//角�??????��?��??��?��???��?��??��?��????��?��??��?��???��?��??��?��場合�??????��?��??��?��???��?��??��?��????��?��??��?��???��?��??��?��ス?????��?��??��?��???��?��??��?��????��?��??��?��???��?��??��?��?ート�??り替えした�??????��?��??��?��???��?��??��?��????��?��??��?��???��?��??��?��ちに移?????��?��??��?��???��?��??��?��????��?��??��?��???��?��??��?��?
*/
endmodule