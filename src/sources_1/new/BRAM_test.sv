module BRAM_test #(
    parameter Dword = 16384,
    parameter Dwidth = 12, 
    parameter Awidth = $clog2(Dword+1),
    parameter initfile = "Meminit.txt"
)(
    input   logic   clk, we,
    input   logic   [Awidth-1:0]     addr,
    input   logic   [Dwidth-1:0]     din,
    output  logic   [Dwidth-1:0]     dout
);
    (* RAM_STYLE="BLOCK"*) logic   [Dwidth-1:0]    bram    [0:Dword-1];
    initial $readmemh(initfile, bram);
    always_ff @(posedge clk)begin
        if(we) bram[addr] <= din;
        dout <= bram[addr];
    end

endmodule