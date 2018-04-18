module EXMemReg
#(
	PC_SIZE = 32,
	INST_SIZE = 32
)
(
	input clk,
	input reset,
	input [63:0] EXMem_target_in,
	input EXMem_mux_sel_in,
	input [4:0] EXMem_regD_in,
	input [31:0] EXMem_alures_in,
	input [1:0] EXMem_op_in,
	input [2:0] EXMem_op2_in,
	input [5:0] EXMem_op3_in,
	output [63:0] EXMem_target_out,
	output EXMem_mux_sel_out,
	output [4:0] EXMem_regD_out,
	output [31:0] EXMem_alures_out,
	output [1:0] EXMem_op_out,
	output [2:0] EXMem_op2_out,
	output [5:0] EXMem_op3_out
);
// DUMMY
always_ff @(posedge clk) begin
	if (reset) begin
		// change to no ops
		EXMem_target_out <= 0;
		EXMem_mux_sel_out <= 0;
		EXMem_regD_out <= 0; 
		EXMem_alures_out <= 0;
		EXMem_op_out <= 0;
		EXMem_op2_out <= 0;
		EXMem_op3_out <= 0;
	end
	else begin
		EXMem_target_out <= EXMem_target_in;
		EXMem_mux_sel_out <= 0; // change to input later
		EXMem_regD_out <= EXMem_regD_in; 
		EXMem_alures_out <= EXMem_alures_in;
		EXMem_op_out <= EXMem_op_in;
		EXMem_op2_out <= EXMem_op2_in;
		EXMem_op3_out <= EXMem_op3_in;
	end
end


endmodule
