// Register File - 32 x 32-bit Registers
// R0 hardwired to zero (RISC rule)
module RegisterFile(
  input clk, we,
  input [4:0]  rs1, rs2, rd,
  input [31:0] wdata,
  output [31:0] rdata1, rdata2
);
  reg [31:0] regs [0:31];
  integer i;
  initial begin
    for(i=0;i<32;i=i+1) regs[i]=0;
    regs[1]=10; regs[2]=5;
  end
  always @(posedge clk)
    if(we && rd!=0) regs[rd]<=wdata;
  assign rdata1=regs[rs1];
  assign rdata2=regs[rs2];
endmodule
