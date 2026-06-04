// ========== ALU ==========
module ALU(
  input [31:0] A, B,
  input [3:0]  opcode,
  output reg [31:0] result,
  output zero
);
  assign zero = (result == 0);
  always @(*) begin
    case(opcode)
      4'b0000: result = A + B;
      4'b0001: result = A - B;
      4'b0010: result = A & B;
      4'b0011: result = A | B;
      4'b0100: result = A ^ B;
      4'b0101: result = (A < B) ? 1 : 0;
      default: result = 0;
    endcase
  end
endmodule

// ========== Register File ==========
module RegisterFile(
  input clk, we,
  input [4:0]  rs1, rs2, rd,
  input [31:0] wdata,
  output [31:0] rdata1, rdata2
);
  reg [31:0] regs [0:31];
  integer i;
  initial begin
    for(i = 0; i < 32; i = i+1) regs[i] = 0;
    regs[1] = 10;
    regs[2] = 5;
  end
  always @(posedge clk)
    if(we && rd != 0) regs[rd] <= wdata;
  assign rdata1 = regs[rs1];
  assign rdata2 = regs[rs2];
endmodule

// ========== Instruction Memory ==========
module InstructionMemory(
  input [31:0] pc,
  output [31:0] instruction
);
  reg [31:0] mem [0:15];
  initial begin
    mem[0] = 32'b0000_00001_00010_00011_0000000000000; // ADD R3=R1+R2
    mem[1] = 32'b0001_00001_00010_00100_0000000000000; // SUB R4=R1-R2
    mem[2] = 32'b0010_00001_00010_00101_0000000000000; // AND R5=R1&R2
    mem[3] = 32'b0011_00001_00010_00110_0000000000000; // OR  R6=R1|R2
    mem[4] = 32'b0100_00001_00010_00111_0000000000000; // XOR R7=R1^R2
  end
  assign instruction = mem[pc >> 2];
endmodule

// ========== 5-Stage Pipeline Processor ==========
module Pipeline(
  input clk, reset
);
  // ---- IF Stage ----
  reg [31:0] pc;
  wire [31:0] if_instruction;

  InstructionMemory IM(.pc(pc), .instruction(if_instruction));

  always @(posedge clk or posedge reset) begin
    if(reset) pc <= 0;
    else      pc <= pc + 4;
  end

  // ---- IF/ID Pipeline Register ----
  reg [31:0] id_instruction;
  reg [31:0] id_pc;
  always @(posedge clk or posedge reset) begin
    if(reset) begin id_instruction <= 0; id_pc <= 0; end
    else      begin id_instruction <= if_instruction; id_pc <= pc; end
  end

  // ---- ID Stage (Decode) ----
  wire [3:0]  id_opcode;
  wire [4:0]  id_rs1, id_rs2, id_rd;
  wire [31:0] id_rdata1, id_rdata2;

  assign id_opcode = id_instruction[31:28];
  assign id_rs1    = id_instruction[27:23];
  assign id_rs2    = id_instruction[22:18];
  assign id_rd     = id_instruction[17:13];

  // WB stage signals (forwarded back for writeback)
  wire        wb_we;
  wire [4:0]  wb_rd;
  wire [31:0] wb_result;

  RegisterFile RF(
    .clk(clk), .we(wb_we),
    .rs1(id_rs1), .rs2(id_rs2),
    .rd(wb_rd), .wdata(wb_result),
    .rdata1(id_rdata1), .rdata2(id_rdata2)
  );

  // ---- ID/EX Pipeline Register ----
  reg [3:0]  ex_opcode;
  reg [4:0]  ex_rd;
  reg [31:0] ex_A, ex_B, ex_pc;
  always @(posedge clk or posedge reset) begin
    if(reset) begin
      ex_opcode <= 0; ex_rd <= 0;
      ex_A <= 0; ex_B <= 0; ex_pc <= 0;
    end else begin
      ex_opcode <= id_opcode;
      ex_rd     <= id_rd;
      ex_A      <= id_rdata1;
      ex_B      <= id_rdata2;
      ex_pc     <= id_pc;
    end
  end

  // ---- EX Stage (Execute) ----
  wire [31:0] ex_result;
  wire        ex_zero;

  ALU alu(
    .A(ex_A), .B(ex_B),
    .opcode(ex_opcode),
    .result(ex_result),
    .zero(ex_zero)
  );

  // ---- EX/MEM Pipeline Register ----
  reg [4:0]  mem_rd;
  reg [31:0] mem_result, mem_pc;
  reg [3:0]  mem_opcode;
  always @(posedge clk or posedge reset) begin
    if(reset) begin
      mem_rd <= 0; mem_result <= 0;
      mem_pc <= 0; mem_opcode <= 0;
    end else begin
      mem_rd     <= ex_rd;
      mem_result <= ex_result;
      mem_pc     <= ex_pc;
      mem_opcode <= ex_opcode;
    end
  end

  // ---- MEM Stage (Memory — passthrough for now) ----
  // No data memory ops in this program, just pass through

  // ---- MEM/WB Pipeline Register ----
  reg [4:0]  wb_rd_r;
  reg [31:0] wb_result_r;
  reg        wb_we_r;
  reg [31:0] wb_pc;
  reg [3:0]  wb_opcode;
  always @(posedge clk or posedge reset) begin
    if(reset) begin
      wb_rd_r <= 0; wb_result_r <= 0;
      wb_we_r <= 0; wb_pc <= 0; wb_opcode <= 0;
    end else begin
      wb_rd_r    <= mem_rd;
      wb_result_r<= mem_result;
      wb_we_r    <= 1'b1;
      wb_pc      <= mem_pc;
      wb_opcode  <= mem_opcode;
    end
  end

  // ---- WB Stage ----
  assign wb_we     = wb_we_r;
  assign wb_rd     = wb_rd_r;
  assign wb_result = wb_result_r;

endmodule

// ========== Testbench ==========
module tb_Pipeline;
  reg clk, reset;

  Pipeline DUT(.clk(clk), .reset(reset));

  // Monitor writeback stage
  wire        wb_we     = DUT.wb_we_r;
  wire [4:0]  wb_rd     = DUT.wb_rd_r;
  wire [31:0] wb_result = DUT.wb_result_r;
  wire [3:0]  wb_opcode = DUT.wb_opcode;
  wire [31:0] wb_pc     = DUT.wb_pc;

  initial clk = 0;
  always #5 clk = ~clk;

  reg [23:0] op_name;

  initial begin
    $display("=== 5-Stage Pipeline Processor ===");
    $display("WB_PC\tOP\tRD\tResult\tWriteback");
    $display("--------------------------------------------------");
    reset = 1; #10;
    reset = 0;

    repeat(10) begin
      #10;
      if(wb_we && wb_rd != 0) begin
        case(wb_opcode)
          4'b0000: op_name = "ADD";
          4'b0001: op_name = "SUB";
          4'b0010: op_name = "AND";
          4'b0011: op_name = " OR";
          4'b0100: op_name = "XOR";
          default: op_name = "???";
        endcase
        $display("%0d\t%s\tR%0d\t%0d\tWRITE",
                 wb_pc, op_name, wb_rd, wb_result);
      end
    end

    $display("--------------------------------------------------");
    $display("Pipeline Complete!");
    $finish;
  end
endmodule
