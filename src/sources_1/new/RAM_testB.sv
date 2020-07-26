// (Block / LUTRAM) module for Xilinx Device
// Dwidth is bit length per 1WORD
// Dword is WORD length
// AWidth is data in-out bus bit length  

module RAM_testB #(
    parameter Dword = 16384,
    parameter Dwidth = 12, 
    parameter Awidth = $clog2(Dword+1),
    parameter style = "BLOCK", // BLOCK or distributed
    parameter initfile = "Meminit.txt"
)(
    input   logic   clk, we,
    input   logic   [Awidth-1:0]     addr,
    input   logic   [Dwidth-1:0]     din,
    output  logic   [Dwidth-1:0]     dout
);
    (*RAM_STYLE=style*) logic   [Dwidth-1:0]    bram    [0:Dword-1];
    initial $readmemb(initfile, bram);
    always_ff @(posedge clk)begin
        if(we) bram[addr] <= din;
        dout <= bram[addr];
    end

endmodule