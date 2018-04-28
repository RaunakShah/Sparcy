module ALU

(
	input [31:0] ALU_valA_in,
	input [31:0] ALU_valB_in,
	input [1:0] ALU_op_in,
	input [2:0] ALU_op2_in,
	input [21:0] ALU_imm22_in,
	input [5:0] ALU_op3_in,
	input ALU_i_in,
	input [12:0] ALU_simm13_in,
	output [31:0] ALU_res_out,
	input [31:0] ALU_PC_in,
	input ALU_a_in,
	input [3:0] ALU_cond_in,
	input [4:0] ALU_rd_in,
	input [29:0] ALU_disp30_in,
	output [31:0] ALU_target_address_out,
	output ALU_mux_sel_out

);
logic [31:0] valB;
// mux to select between valb and imm based on i
// alu takes val a and mux out
// alu operation based on op and op3
// default, pass dummy
always_comb begin
	// if no op => sethi 000000 in rd == 00000. pass output to mem which will do nothing
	ALU_mux_sel_out = 0;
	ALU_target_address_out = 1;

	if (ALU_i_in)
		valB = ALU_simm_13;
	else
		valB = ALU_valB_in;

	if (ALU_op_in == 2'b10) begin // format 3 instructions
		if (ALU_op3_in == `ADD) begin  // ADD
			ALU_res_out = ALU_valA_in + valB;
		end // ADD
		if (ALU_op3_in == `SUB) begin // sub
		  ALU_res_out = ALU_valA_in - valB;
		end // sub
		if(ALU_op3_in == `AND) begin
			ALU_res_out = ALU_valA_in & valB;
		end
		if(ALU_op3_in == `OR) begin
			ALU_res_out = ALU_valA_in | valB;
		end
		if(ALU_op3_in == `XOR) begin
			ALU_res_out = ALU_valA_in ^ valB;
		end
		if(ALU_op3_in == `XNOR) begin
			ALU_res_out = ALU_valA_in ~^ valB;
		end
		if(ALU_op3_in == `UMUL || ALU_op3_in == `SMUL) begin
			ALU_res_out = ALU_valA_in * valB;
		end
		if(ALU_op3_in == `UDIV || ALU_op3_in == `SDIV) begin
			ALU_res_out = ALU_valA_in / valB;
		end
		if(ALU_op3_in == `JMPL || ALU_op3_in == `RETT) begin
			ALU_target_address_out = ALU_valA_in + valB;
			ALU_mux_sel_out = 1;
		end
		if(ALU_op3_in == `CALL) begin
			ALU_mux_sel_out = 1;
			ALU_target_address_out = ALU_PC_in + ((ALU_imm22_in << 9) >> 2);
	end
	//for Load/Store
	ALU_target_address_out = ALU_valA_in + valB;


end




endmodule
