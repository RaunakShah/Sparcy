module alu
#(
  BUS_DATA_WIDTH = 64,
  BUS_INST_WIDTH = 32
  )
  (
    input clk,reset,
    input [2:0] control,
    input first,
    input second,
    output [BUS_INST_WIDTH - 1:0] res,
    output stall,
    );

always @ ( control or first or second ) begin
  case (control)
    3'b000 : res = first & second;
    3'b001 : res = first | second;
    3'b010 : res = first + second;
    3'b110 : res = first - second;
  endcase
end
