// Instruction Memory - 16 x 32-bit ROM
// Stores program instructions
module InstructionMemory(
  input [31:0] pc,
  output [31:0] instruction
);
  reg [31:0] mem [0:15];
  initial begin
    mem[0]=32'b0000_00001_00010_00011_0000000000000; // ADD R3=R1+R2
    mem[1]=32'b0001_00001_00010_00100_0000000000000; // SUB R4=R1-R2
    mem[2]=32'b0010_00001_00010_00101_0000000000000; // AND R5=R1&R2
    mem[3]=32'b0011_00001_00010_00110_0000000000000; // OR  R6=R1|R2
    mem[4]=32'b0100_00001_00010_00111_0000000000000; // XOR R7=R1^R2
  end
  assign instruction=mem[pc>>2];
endmodule
