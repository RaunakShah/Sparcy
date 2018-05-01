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
	input clk, 
	input reset,
	input ALU_icc_n_in, ALU_icc_z_in, ALU_icc_v_in, ALU_icc_c_in,
	input ALU_icc_n_out, ALU_icc_z_out, ALU_icc_v_out, ALU_icc_c_out

);
logic [31:0] valB;
// mux to select between valb and imm based on i
// alu takes val a and mux out
// alu operation based on op and op3
// default, pass dummy
always_comb begin
	// if no op => sethi 000000 in rd == 00000. pass output to mem which will do nothing
	ALU_mux_sel_out = 0;
	ALU_target_address_out = 0;

	if (ALU_i_in)
		valB = 32'(signed'(ALU_simm_13));
	else
		valB = ALU_valB_in;
	if (ALU_op_in == 2'b01) begin // CALL
		ALU_target_address_out = ALU_PC_in + (4*ALU_disp30_in);
		ALU_mux_sel_out = 1;
		ALU_res_out = ALU_PC_in;
	end
	if (ALU_op_in == 2'b11) begin // format 3 instructions
	// Load; Store; Atomic; Swap
			ALU_res_out = ALU_valA_in + valB;
	end
	if (ALU_op_in == 2'b00) begin
		if (ALU_op2_in == `SETHI)
			ALU_res_out = {ALU_imm22_in, 10'b0000000000};
		if (ALU_op2_in == `Bicc) begin
			if (cond == `BA) begin
				ALU_mux_sel_out = 1;
				ALU_target_address_out = ALU_PC_in + (4*(32'(signed'(ALU_imm_22)));
			end
			if (cond == `BN) begin
				ALU_mux_sel_out = 0;
				ALU_target_address_out = ALU_PC_in + (4*(32'(signed'(ALU_imm_22)));
			end
			// TODO Icc instructions
		end
	end
	if (ALU_op_in == 2'b10) begin // format 2 instructions
		if (ALU_op3_in == `AND)
			ALU_res_out = ALU_valA_in & valB;
		if (ALU_op3_in == `ANDcc) begin
			ALU_res_out = ALU_valA_in & valB;
			ALU_icc_z_out = ALU_res_out?0:1;
			ALU_icc_n_out = ALU_res_out[31]?1:0; 
			ALU_icc_c_out = 0;
			ALU_icc_v_out = 0;
		end
		if (ALU_op3_in == `ANDN	)
			ALU_res_out = ALU_valA_in & (~valB);
		if (ALU_op3_in == `ANDNcc) begin
			ALU_res_out = ALU_valA_in & (~valB);
			ALU_icc_z_out = ALU_res_out?0:1;
			ALU_icc_n_out = ALU_res_out[31]?1:0; 
			ALU_icc_c_out = 0;
			ALU_icc_v_out = 0;
		end
		if (ALU_op3_in == `OR)
			ALU_res_out = ALU_valA_in | valB;
		if (ALU_op3_in == `ORcc) begin
			ALU_res_out = ALU_valA_in | valB;
			ALU_icc_z_out = ALU_res_out?0:1;
			ALU_icc_n_out = ALU_res_out[31]?1:0; 
			ALU_icc_c_out = 0;
			ALU_icc_v_out = 0;
		end
		if (ALU_op3_in == `ORN)
			ALU_res_out = ALU_valA_in | (~valB);
		if (ALU_op3_in == `ORNcc) begin
			ALU_res_out = ALU_valA_in | (~valB);
			ALU_icc_z_out = ALU_res_out?0:1;
			ALU_icc_n_out = ALU_res_out[31]?1:0; 
			ALU_icc_c_out = 0;
			ALU_icc_v_out = 0;
		end
		if (ALU_op3_in == `XOR)
			ALU_res_out = ALU_valA_in ^ valB;
		if (ALU_op3_in == `XORcc) begin
			ALU_res_out = ALU_valA_in ^ valB;
			ALU_icc_z_out = ALU_res_out?0:1;
			ALU_icc_n_out = ALU_res_out[31]?1:0; 
			ALU_icc_c_out = 0;
			ALU_icc_v_out = 0;
		end
		if (ALU_op3_in == `XNOR)
			ALU_res_out = ALU_valA_in ^ (~valB);
		if (ALU_op3_in == `XNORcc) begin
			ALU_res_out = ALU_valA_in ^ (~valB);
			ALU_icc_z_out = ALU_res_out?0:1;
			ALU_icc_n_out = ALU_res_out[31]?1:0; 
			ALU_icc_c_out = 0;
			ALU_icc_v_out = 0;
		end
		if (ALU_op3_in == `ADD)
			ALU_res_out = ALU_valA_in + valB;
		if (ALU_op3_in == `ADDcc)
			// TODO
			ALU_res_out = ALU_valA_in + valB;
		if (ALU_op3_in == `ADDX)
			// TODO
			ALU_res_out = ALU_valA_in + valB;
		if (ALU_op3_in == `ADDXcc)
			// TODO
			ALU_res_out = ALU_valA_in + valB;
		if (ALU_op3_in == `SUB)
			ALU_res_out = ALU_valA_in - valB;
		if (ALU_op3_in == `SUBcc)
			// TODO
			ALU_res_out = ALU_valA_in - valB;
		if (ALU_op3_in == `SUBX)
			// TODO
			ALU_res_out = ALU_valA_in - valB;
		if (ALU_op3_in == `SUBXcc)
			// TODO
			ALU_res_out = ALU_valA_in - valB;
	end		
		



		/*if (ALU_op3_in == `ADD) begin  // ADD
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

*/
end




endmodule
		





		/*if (ALU_op3_in == `ADD) begin  // ADD
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

*/
end




endmodule
