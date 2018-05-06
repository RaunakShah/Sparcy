module MemWBReg
#(
	PC_SIZE = 32,
	INST_SIZE = 32
)
(
	input clk,
	input reset,
	input [63:0] MemWB_alures_in,
	input [63:0] MemWB_load_data_in,
	input [4:0] MemWB_regD_in,
	input [1:0] MemWB_op_in,
	input [2:0] MemWB_op2_in,
	input [5:0] MemWB_op3_in,
	output [63:0] MemWB_alures_out,
	output [63:0] MemWB_load_data_out,
	output [4:0] MemWB_regD_out,
	output [1:0] MemWB_op_out,
	output [2:0] MemWB_op2_out,
	output [5:0] MemWB_op3_out,
	input MemWB_regWrite_in,
	output MemWB_regWrite_out,
	input MemWB_regWriteDouble_in,
	output MemWB_regWriteDouble_out,
	input [3:0] MemWB_icc_in,
	output [3:0] MemWB_icc_out,
	input MemWB_icc_write_in, MemWB_Y_write_in,
	output MemWB_icc_write_out, MemWB_Y_write_out,
	input [31:0] MemWB_Y_in,
	output [31:0] MemWB_Y_out
);
// DUMMY
always_ff @(posedge clk) begin
	if (reset) begin
		// change to no ops
		MemWB_alures_out <= 0;
		MemWB_load_data_out <= 0;
		MemWB_op_out <= 00;
		MemWB_op2_out <= 100;
		MemWB_op3_out <= 0;
		MemWB_regD_out <= 0;
		MemWB_regWrite_out <= 0;
		MemWB_regWriteDouble_out <= 0;
		MemWB_icc_out <= 0;
		MemWB_icc_write_out <= 0;
		MemWB_Y_out <= 0;
		MemWB_Y_write_out <= 0;
	end
	else begin
		MemWB_regD_out <= MemWB_regD_in; 
		MemWB_alures_out <= MemWB_alures_in;
		MemWB_op_out <= MemWB_op_in;
		MemWB_op2_out <= MemWB_op2_in;
		MemWB_op3_out <= MemWB_op3_in;
		MemWB_load_data_out <= MemWB_load_data_in;
		MemWB_regWrite_out <= MemWB_regWrite_in;
		MemWB_regWriteDouble_out <= MemWB_regWriteDouble_in;
		MemWB_icc_out <= MemWB_icc_in;
		MemWB_icc_write_out <= MemWB_icc_write_in;
		MemWB_Y_out <= MemWB_Y_in;
		MemWB_Y_write_out <= MemWB_Y_write_in;
	end
end


endmodule
