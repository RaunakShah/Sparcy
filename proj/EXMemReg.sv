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
	input [63:0] EXMem_alures_in,
	input [1:0] EXMem_op_in,
	input [2:0] EXMem_op2_in,
	input [5:0] EXMem_op3_in,
	output [63:0] EXMem_target_out,
	output EXMem_mux_sel_out,
	output [4:0] EXMem_regD_out,
	output [63:0] EXMem_alures_out,
	output [1:0] EXMem_op_out,
	output [2:0] EXMem_op2_out,
	output [5:0] EXMem_op3_out,
	input [63:0] EXMem_valD_in,
	output [63:0] EXMem_valD_out,
	input EXMem_regWrite_in,
	output EXMem_regWrite_out,
	input EXMem_regWriteDouble_in,
	output EXMem_regWriteDouble_out,
	input mem_ready,
	input [3:0] EXMem_icc_in,
	output [3:0] EXMem_icc_out,
	input EXMem_icc_write_in, EXMem_Y_write_in,
	output EXMem_icc_write_out, EXMem_Y_write_out,
	input [31:0] EXMem_Y_in,
	output [31:0] EXMem_Y_out
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
		EXMem_valD_out <= 0;
		EXMem_regWrite_out <= 0;
		EXMem_regWriteDouble_out <= 0;
		EXMem_icc_out <= 0;
		EXMem_icc_write_out <= 0;
		EXMem_Y_out <= 0;
		EXMem_Y_write_out <= 0;
	end
	else begin
		if (mem_ready) begin
			EXMem_target_out <= EXMem_target_in;
			EXMem_mux_sel_out <= EXMem_mux_sel_in; // change to input later
			EXMem_regD_out <= EXMem_regD_in; 
			EXMem_alures_out <= EXMem_alures_in;
			EXMem_op_out <= EXMem_op_in;
			EXMem_op2_out <= EXMem_op2_in;
			EXMem_op3_out <= EXMem_op3_in;
			EXMem_valD_out <= EXMem_valD_in;
			EXMem_regWrite_out <= EXMem_regWrite_in;
			EXMem_regWriteDouble_out <= EXMem_regWriteDouble_in;
			EXMem_icc_out <= EXMem_icc_in;
			EXMem_icc_write_out <= EXMem_icc_write_in;
			EXMem_Y_out <= EXMem_Y_in;
			EXMem_Y_write_out <= EXMem_Y_write_in;
		end
	end
end


endmodule
