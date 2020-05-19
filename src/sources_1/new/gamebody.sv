if(clk60&(invMSEN == 0))begin // フレーム間処理の開始
    invMSEN <= 1'b1;
    movearg <= moveNext;
    movelock <= 0;
    //table_upS <= 3'b000;
    rrom_clear <= 62'h0;
end else if(invMSEN)begin
    if(table_upS == 3'b000)begin // 敵機の移動
        if(((invader_table[invMS]&52'h8_000_000_00_0_000) == 52'h8_000_000_00_0_000)&swf0) begin // exist ?
            if(invMS!=62)begin
                case(movearg)
                    2'd0:begin // 上移動
                        if((invader_table[invMS]&52'h0_fff_000_00_0_000)>= 52'h0_010_000_00_0_000)begin 
                            invader_tableTEMP[invMS] <= ((invader_table[invMS]&52'hf_000_fff_ff_f_fff) + {(invader_table[invMS]&52'h0_fff_000_00_0_000) - {12'h0, speed, 36'h000000}});
                        end else begin
                            invader_tableTEMP[invMS] <= invader_table[invMS];
                            moveNext <= 1;
                            movelock <= 1;
                        end
                    end
                    2'd1:begin // 左移動
                        if((invader_table[invMS]&52'h0_000_fff_00_0_000)< (52'h0_000_280_00_0_000 - {16'h0_000, rrom_size[invMS], 24'h00_0_000} - {16'h0_000, speed, 24'h00_0_000}))begin
                            invader_tableTEMP[invMS] <= ((invader_table[invMS]&52'hf_fff_000_ff_f_fff) + {(invader_table[invMS]&52'h0_000_fff_00_0_000) + {24'h0, speed, 24'h000}});
                        end else begin
                            invader_tableTEMP[invMS] <= invader_table[invMS];
                            moveNext <= 2;
                            movelock <= 1;
                        end
                    end
                    2'd2:begin //下移動
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
                    2'd3:begin // 右移動
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
    end else if(table_upS == 3'b001)begin // 敵機移動の反映と自機の移動
        if(invMS != 62)invader_table[invMS] <= (movelock) ? invader_table[invMS] : invader_tableTEMP[invMS];
        else if(((invader_table[62]&52'h8_000_fff_00_0_000)>= 52'h8_000_002_00_0_000)&btnL)invader_table[62] <= (invader_table[62]- {16'h0, 12'h002, 24'h000});
        else if(((invader_table[62]&52'h8_000_fff_00_0_000)<  52'h8_000_25f_00_0_000)&btnR)invader_table[62] <= (invader_table[62]+ {16'h0, 12'h002, 24'h000});
        invMS <= (invMS == 62) ? 0 : invMS + 1;
        table_upS <= (invMS == 62) ? 3'b010 : 3'b001;
        umoveC <= (umoveC == 31) ? ((invMS == 62)? 0 : umoveC) : ((invMS == 62)? umoveC + 1 : umoveC);
        movelock <= (invMS != 62) ? movelock : 0;
    end else if(table_upS ==3'b010)begin // 自機レーザーの生成及び全レーザーの移動
        if(invMS == 0)begin
            if(lase_EN[0]) laser_table[0] <= (lase_vpos[0] >= 4) ? {laser_table[0] - 40'h0_004_000_000} : 40'h0; 
            else if((!lase_EN[0]) & btnC) laser_table[0] <= {4'h8, 12'h1bf, lase_chpos, 12'hfff};
            else laser_table[0] <= laser_table[0];
        end else begin
            if(lase_EN[invMS]) laser_table[invMS] <= (lase_vpos[invMSEN] < 460) ? {laser_table[invMS] + 40'h0_004_000_000} : 40'h0;
            else laser_table[invMS] <= laser_table[invMS];
        end begin
            invMS <= (invMS ==39) ? 0 : invMS + 1;
            table_upS <= (invMS == 39) ? 3'b011 : 3'b010;
            umoveC <= umoveC;
        end
    
    end else if(table_upS ==3'b011) begin // 敵レーザーの生成
        if(invMS != 0)begin
            if(!lase_EN[invMS] && (short_PS <= 61)) laser_table[invMS] <= {4'h8, rrom_vpos[short_PS], lase_cepos, 12'hff0};
            else laser_table[invMS] <= laser_table[invMS];
        end begin
            invMS <= (invMS ==39) ? 1 : invMS + 1;
            table_upS <= (invMS == 39) ? 3'b100 : 3'b011;
            umoveC <= umoveC;                                        
        end
    end else if(table_upS == 3'b100) begin // 当たり判定(レーザーxレーザー)
        if((lase_EN[0])&(lase_EN[invMS])&((lase_vpos[invMS]-lase_vpos[0])<30)&(((lase_hpos[invMS]-lase_hpos[0])<10)|((lase_hpos[0]-lase_hpos[invMS])<10)))begin
            laser_table[0] <= 40'h0_000_000_000;
            laser_table[invMS] <= 40'h0_000_000_000;    
        end else begin
            laser_table[0] <= laser_table[0];
            laser_table[invMS] <= laser_table[invMS];
        end begin
            invMS <= (invMS ==39) ? 0 : invMS + 1;
            //invMSEN <= (invMS == 39) ? 0 : 1;
            table_upS <= (invMS == 39) ? 3'b101 : 3'b100;
            umoveC <= umoveC;                
        end
    end else if(table_upS ==3'b101) begin // 当たり判定(レーザーx敵機本体)
        if(invMS==62) begin
            invader_tableTEMP[invMS] <= invader_table[invMS];
        end else if((lase_EN[0])&(rrom_EN[invMS])&((rrom_vpos[invMS]-lase_vpos[0])<=32)&((lase_hpos[0]-rrom_hpos[invMS])<=32)) begin
            invader_tableTEMP[invMS] <= 52'h0_000_000_00_0_000;
            laser_table[0] <= 40'h0_000_000_000;
        end else begin
            invader_tableTEMP[invMS] <= invader_table[invMS];
            laser_table[0] <= laser_table[0];
        end begin
            invMS <= (invMS == 62) ? 1 : invMS + 1;
            table_upS <= (invMS == 62) ? 3'b110 : 3'b101;
            umoveC <= umoveC;                
        end
    end else if(table_upS == 3'b110)begin // 自機への当たり判定
        if((lase_EN[invMS])&((rrom_vpos[62]-lase_vpos[invMS])<=32)&((lase_hpos[invMS]-rrom_hpos[62])<=32))begin
            invader_tableTEMP[62] <= 52'h0_000_000_00_0_000;
            laser_table[invMS] <= 40'h0_000_000_000;
        end begin    
            invMS <= (invMS == 39) ? 0 : invMS + 1;
            //invMSEN <= (invMS == 62) ? 0 : 1;
            table_upS <= (invMS == 39) ? 3'b111 : 3'b110;
            umoveC <= umoveC;                      
        end   
    end else if(table_upS == 3'b111)begin // 敵機本体の反映
            invader_table[invMS] <= invader_tableTEMP[invMS];
            invMS <= (invMS == 62) ? 0 : invMS + 1;
            invMSEN <= (invMS == 62) ? 0 : 1;
            table_upS <= (invMS == 62) ? 3'b000 : 3'b111;
            umoveC <= umoveC;                      
        //end
    end
end