module IDEXReg
#(
	PC_SIZE = 32,
	INST_SIZE = 32
)
(
	input clk,
	input reset,
	input [PC_SIZE-1:0] IDEX_PCplus4_in,
	input [INST_SIZE-1:0] IDEX_valA_in,
	input [INST_SIZE-1:0] IDEX_valB_in,
	input [63:0] IDEX_valD_in,
	input [INST_SIZE-1:0] IDEX_valDdouble_in,
	input IDEX_a_in,
	input [5:0] IDEX_op3_in,
	input IDEX_i_in,
	input [12:0] IDEX_imm13_in,
	input [21:0] IDEX_disp22_in, 
	input [1:0] IDEX_op_in, 
	input [3:0] IDEX_cond_in, 
	input [2:0] IDEX_op2_in, 
	input [4:0] IDEX_rd_in,
	input [29:0] IDEX_disp30_in, 
	output [PC_SIZE-1:0] IDEX_PCplus4_out,
	output [INST_SIZE-1:0] IDEX_valA_out,
	output [INST_SIZE-1:0] IDEX_valB_out,
	output [63:0] IDEX_valD_out,
	output IDEX_a_out,
	output [5:0] IDEX_op3_out,
	output IDEX_i_out,
	output [12:0] IDEX_imm13_out,
	output [21:0] IDEX_disp22_out, 
	output [1:0] IDEX_op_out, 
	output [3:0] IDEX_cond_out, 
	output [2:0] IDEX_op2_out, 
	output [4:0] IDEX_rd_out,
	output [29:0] IDEX_disp30_out,
	input IDEX_regWrite_in,
	output IDEX_regWrite_out,
	input IDEX_regWriteDouble_in,
	output IDEX_regWriteDouble_out,
	input ex_ready,
	input [3:0] IDEX_icc_in,
	input [4:0] IDEX_cwp_in,
	input [31:0] IDEX_wim_in,
	input [31:0] IDEX_Y_in,
	output [3:0] IDEX_icc_out,
	output [4:0] IDEX_cwp_out,
	output [31:0] IDEX_wim_out,
	output [31:0] IDEX_Y_out,
	input IDEX_icc_write_in, IDEX_Y_write_in,
	output IDEX_icc_write_out, IDEX_Y_write_out
);

always_ff @(posedge clk) begin
	if (reset) begin
		IDEX_PCplus4_out <= 0;
		IDEX_valA_out <= 0;
		IDEX_valB_out <= 0;
		IDEX_valD_out <= 0;
		IDEX_a_out <= 0;
		IDEX_op_out <= 0;
		IDEX_i_out <= 0;
		IDEX_imm13_out <= 0;
		IDEX_disp22_out <= 0;
		IDEX_op3_out <= 0;
		IDEX_cond_out <= 0;
		IDEX_op2_out <= 0;
		IDEX_rd_out <= 0;
		IDEX_disp30_out <= 0;
		IDEX_regWrite_out <= 0;
		IDEX_regWriteDouble_out <= 0;
		IDEX_icc_out <= 0;
		IDEX_cwp_out <= 0;
		IDEX_wim_out <= 0;
		IDEX_Y_out <= 0;
		IDEX_icc_write_out <= 0;
		IDEX_Y_write_out <= 0;
	end
	else begin
		if (ex_ready) begin
			IDEX_PCplus4_out <= IDEX_PCplus4_in;
			IDEX_valA_out <= IDEX_valA_in; 
			IDEX_valB_out <= IDEX_valB_in;
			IDEX_valD_out <= IDEX_valD_in;
			IDEX_a_out <= IDEX_a_in ;
			IDEX_op_out <= IDEX_op_in ;
			IDEX_i_out <= IDEX_i_in ;
			IDEX_imm13_out <= IDEX_imm13_in ;
			IDEX_disp22_out <= IDEX_disp22_in ;
			IDEX_op3_out <= IDEX_op3_in ;
			IDEX_cond_out <= IDEX_cond_in ;
			IDEX_op2_out <= IDEX_op2_in ;
			IDEX_rd_out <= IDEX_rd_in ;
			IDEX_disp30_out <= IDEX_disp30_in ;
			IDEX_regWrite_out <= IDEX_regWrite_in;
			IDEX_regWriteDouble_out <= IDEX_regWriteDouble_in;
			IDEX_icc_out <= IDEX_icc_in;
			IDEX_cwp_out <= IDEX_cwp_in;
			IDEX_wim_out <= IDEX_wim_in;
			IDEX_Y_out <= IDEX_Y_in;
			IDEX_icc_write_out <= IDEX_icc_write_in;
			IDEX_Y_write_out <= IDEX_Y_write_in;
		end
	end
end


endmodule
