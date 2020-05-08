// copyed from https://marsee101.blog.fc2.com/blog-entry-2096.html
module m_seq_test(
    input    wire         clk,
    input    wire        reset,
    output    reg [7:0]    mseq8,
    output    wire [7:0]    mseq8_2
);

    reg    [15:0]    mseq16;
    
    function [7:0] mseqf8_0 (input [7:0] din);
        reg xor_result;
        begin
            xor_result = din[7] ^ din[3] ^ din[2] ^ din[1];
            mseqf8_0 = {din[6:0], xor_result};
        end
    endfunction
    
    function [7:0] mseqf8_1 (input [7:0] din);
        reg xor_result;
        begin
            xor_result = din[7] ^ din[4] ^ din[2] ^ din[0];
            mseqf8_1 = {din[6:0], xor_result};
        end
    endfunction
    
    function [15:0] mseqf16 (input [15:0] din);
        reg xor_result;
        begin
            xor_result = din[15] ^ din[12] ^ din[10] ^ din[8] ^ din[7] ^ din[6] ^ din[3] ^ din[2];
            mseqf16 = {din[14:0], xor_result};
        end
    endfunction        
    
    always @(posedge clk) begin
        if (reset) 
            mseq8 <= 8'd1;
        else
            mseq8 <= mseqf8_0(mseq8);
    end
    
    always @(posedge clk) begin
        if (reset) 
            mseq16 <= 16'd1;
        else
            mseq16 <= mseqf16(mseq16);
    end
    assign mseq8_2 = mseq16[7:0];
    
endmodule