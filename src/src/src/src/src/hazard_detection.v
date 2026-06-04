// Hazard Detection Unit
// Detects RAW (Read After Write) data hazards
// Inserts NOP bubbles to stall pipeline
module HazardDetection(
  input [4:0] id_rs1, id_rs2,
  input [4:0] ex_rd, mem_rd,
  input       ex_we, mem_we,
  output reg  stall
);
  always @(*) begin
    stall = 0;
    // EX stage hazard
    if(ex_we && ex_rd != 0) begin
      if(ex_rd == id_rs1 || ex_rd == id_rs2)
        stall = 1;
    end
    // MEM stage hazard
    if(mem_we && mem_rd != 0) begin
      if(mem_rd == id_rs1 || mem_rd == id_rs2)
        stall = 1;
    end
  end
endmodule
