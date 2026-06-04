// ALU Module - 32-bit Arithmetic Logic Unit
module ALU(
  input [31:0] A, B,
  input [3:0]  opcode,
  output reg [31:0] result,
  output reg zero
);
  always @(*) begin
    case(opcode)
      4'b0000: begin result=A+B; zero=(A+B==0); end
      4'b0001: begin result=A-B; zero=(A==B);   end
      4'b0010: begin result=A&B; zero=(A&B)==0; end
      4'b0011: begin result=A|B; zero=(A|B)==0; end
      4'b0100: begin result=A^B; zero=(A==B);   end
      4'b0101: begin result=(A<B)?1:0; zero=(A>=B); end
      4'b0110: begin result=A-B; zero=(A==B);   end
      4'b0111: begin result=A-B; zero=(A!=B);   end
      default: begin result=0;   zero=1;        end
    endcase
  end
endmodule
