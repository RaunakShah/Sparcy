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
	output [63:0] ALU_res_out,
	input [31:0] ALU_PC_in,
	input ALU_a_in,
	input [3:0] ALU_cond_in,
	input [4:0] ALU_rd_in,
	input [29:0] ALU_disp30_in,
	output [31:0] ALU_target_address_out,
	output ALU_mux_sel_out,
	input clk, 
	input reset,
	input [3:0] ALU_icc_in,
	output [3:0] ALU_icc_out,
	input [31:0] ALU_Y_in,
	output [31:0] ALU_Y_out,
	output ALU_a_out

);
logic [31:0] valB;
logic c, z, n, v;
// mux to select between valb and imm based on i
// alu takes val a and mux out
// alu operation based on op and op3
// default, pass dummy
always_comb begin
	// if no op => sethi 000000 in rd == 00000. pass output to mem which will do nothing
	ALU_mux_sel_out = 0;
	ALU_target_address_out = 0;
	ALU_icc_out = ALU_icc_in;
	ALU_Y_out = ALU_Y_in;
	ALU_a_out = ALU_a_in;
	if (ALU_i_in)
		valB = 32'(signed'(ALU_simm13_in));
	//	valB = {{32{ALU_simm13_in[12]}},ALU_simm13_in};
	else
		valB = ALU_valB_in;
	ALU_res_out = ALU_valA_in + valB;

	if (ALU_op_in == 2'b01) begin // CALL
		ALU_target_address_out = ALU_PC_in + (4*ALU_disp30_in);
		ALU_mux_sel_out = 1;
		ALU_res_out = ALU_PC_in;
		ALU_a_out = 0;
	end
	if (ALU_op_in == 2'b11) begin // format 3 instructions
	// Load; Store; Atomic; Swap
			ALU_res_out = ALU_valA_in + valB;
	end
	if (ALU_op_in == 2'b00) begin
		if (ALU_op2_in == `SETHI)
			ALU_res_out = {ALU_imm22_in, 10'b0000000000};
		if (ALU_op2_in == 3'b010) begin
			c = ALU_icc_in[0];
			v = ALU_icc_in[1];
			z = ALU_icc_in[2];
			n = ALU_icc_in[3];
			ALU_target_address_out = ALU_PC_in + (4*(32'(signed'(ALU_imm22_in))));
			if (ALU_cond_in == `BA) begin
				ALU_mux_sel_out = 1;
			end
			if (ALU_cond_in == `BN) begin
				ALU_mux_sel_out = 0;
			end
			if (ALU_cond_in == `BNE) begin
				if (!z)	begin
					ALU_mux_sel_out = 1;
					ALU_a_out = 0;
				end
			end
			if (ALU_cond_in == `BE) begin
				if (z) begin	
					ALU_mux_sel_out = 1;
					ALU_a_out = 0;
				end
			end
			if (ALU_cond_in == `BG) begin
				if (!(z || (n ^ v))) begin
					ALU_mux_sel_out = 1;
					ALU_a_out = 0;
				end
			end
			if (ALU_cond_in == `BLE) begin
				if (z || (n ^ v)) begin		
					ALU_mux_sel_out = 1;
					ALU_a_out = 0;
				end
			end
			if (ALU_cond_in == `BGE) begin
				if (!(n ^ v)) begin		
					ALU_mux_sel_out = 1;
					ALU_a_out = 0;
				end
			end
			if (ALU_cond_in == `BL) begin
				if (n ^ v) begin		
					ALU_mux_sel_out = 1;
					ALU_a_out = 0;
				end
			end
			if (ALU_cond_in == `BGU) begin
				if (!(c || z)) begin		
					ALU_mux_sel_out = 1;
					ALU_a_out = 0;
				end
			end
			if (ALU_cond_in == `BLEU) begin
				if (c || z) begin		
					ALU_mux_sel_out = 1;
					ALU_a_out = 0;
				end
			end
			if (ALU_cond_in == `BCC) begin
				if (!c) begin		
					ALU_mux_sel_out = 1;
					ALU_a_out = 0;
				end
			end
			if (ALU_cond_in == `BCS) begin
				if (c) begin		
					ALU_mux_sel_out = 1;
					ALU_a_out = 0;
				end
			end
			if (ALU_cond_in == `BPOS) begin
				if (!n) begin		
					ALU_mux_sel_out = 1;
					ALU_a_out = 0;
				end
			end
			if (ALU_cond_in == `BNEG) begin
				if (n) begin		
					ALU_mux_sel_out = 1;
					ALU_a_out = 0;
				end
			end
			if (ALU_cond_in == `BVC) begin
				if (!v)	begin
					ALU_mux_sel_out = 1;
					ALU_a_out = 0;
				end
			end
			if (ALU_cond_in == `BVS) begin
				if (v) begin		
					ALU_mux_sel_out = 1;
					ALU_a_out = 0;
				end
			end
		end
	end
	if (ALU_op_in == 2'b10) begin // format 2 instructions
		// Shift
		if (ALU_op3_in == `SLL) 
			ALU_res_out = ALU_valA_in << valB[4:0];			
		if (ALU_op3_in == `SRL)
			ALU_res_out = ALU_valA_in >> valB[4:0];
		if (ALU_op3_in == `SRA)
			ALU_res_out = 32'(signed'(ALU_valA_in)) >>> valB[4:0];
		if (ALU_op3_in == `AND)
			ALU_res_out = ALU_valA_in & valB;
		if (ALU_op3_in == `ANDcc) begin
			ALU_res_out = ALU_valA_in & valB;
			z = ALU_res_out?0:1;
			ALU_icc_out = ALU_icc_in;
			ALU_icc_out[2] = z;
		end
		if (ALU_op3_in == `ANDN	)
			ALU_res_out = ALU_valA_in & (~valB);
		if (ALU_op3_in == `ANDNcc) begin
			ALU_res_out = ALU_valA_in & (~valB);
			z = ALU_res_out?0:1;
			ALU_icc_out = ALU_icc_in;
			ALU_icc_out[2] = z;
		end
		if (ALU_op3_in == `OR)
			ALU_res_out = ALU_valA_in | valB;
		if (ALU_op3_in == `ORcc) begin
			ALU_res_out = ALU_valA_in | valB;
			z = ALU_res_out?0:1;
			ALU_icc_out = ALU_icc_in;
			ALU_icc_out[2] = z;
		end
		if (ALU_op3_in == `ORN)
			ALU_res_out = ALU_valA_in | (~valB);
		if (ALU_op3_in == `ORNcc) begin
			ALU_res_out = ALU_valA_in | (~valB);
			z = ALU_res_out?0:1;
			ALU_icc_out = ALU_icc_in;
			ALU_icc_out[2] = z;
		end
		if (ALU_op3_in == `XOR)
			ALU_res_out = ALU_valA_in ^ valB;
		if (ALU_op3_in == `XORcc) begin
			ALU_res_out = ALU_valA_in ^ valB;
			z = ALU_res_out?0:1;
			ALU_icc_out = ALU_icc_in;
			ALU_icc_out[2] = z;
		end
		if (ALU_op3_in == `XNOR)
			ALU_res_out = ALU_valA_in ^ (~valB);
		if (ALU_op3_in == `XNORcc) begin
			ALU_res_out = ALU_valA_in ^ (~valB);
			z = ALU_res_out?0:1;
			ALU_icc_out = ALU_icc_in;
			ALU_icc_out[2] = z;
		end
		if (ALU_op3_in == `ADD || ALU_op3_in == `SAVE || ALU_op3_in == `RESTORE)
			ALU_res_out = ALU_valA_in + valB;
		if (ALU_op3_in == `ADDcc) begin
			ALU_res_out = ALU_valA_in + valB;
			c = ALU_res_out[32];
			z = ALU_res_out?0:1;
			n = ALU_res_out[31]?1:0;
			v = 0;
			if ((ALU_valA_in[31] == valB[31]) && (ALU_valA_in[31] != ALU_res_out[31]))
				v = 1;
			ALU_icc_out = {n,z,v,c};
		end
		if (ALU_op3_in == `ADDX)
			ALU_res_out = ALU_valA_in + valB + ALU_icc_in[0];
		if (ALU_op3_in == `ADDXcc) begin
			ALU_res_out = ALU_valA_in + valB + ALU_icc_in[0];
			c = ALU_res_out[32];
			z = ALU_res_out?0:1;
			n = ALU_res_out[31]?1:0;
			v = 0;
			if ((ALU_valA_in[31] == valB[31]) && (ALU_valA_in[31] != ALU_res_out[31]))
				v = 1;
			ALU_icc_out = {n,z,v,c};

		end
		if (ALU_op3_in == `SUB)
			ALU_res_out = ALU_valA_in - valB;
		if (ALU_op3_in == `SUBcc) begin
			ALU_res_out = ALU_valA_in - valB;
			c = ALU_res_out[32];
			z = ALU_res_out?0:1;
			n = ALU_res_out[31]?1:0;
			v = 0;
			if ((ALU_valA_in[31] != valB[31]) && (ALU_valA_in[31] != ALU_res_out[31]))
				v = 1;
			ALU_icc_out = {n,z,v,c};
		end
		if (ALU_op3_in == `SUBX)
			ALU_res_out = ALU_valA_in - valB - ALU_icc_in[0];
		if (ALU_op3_in == `SUBXcc) begin
			ALU_res_out = ALU_valA_in - valB - ALU_icc_in[0];
			c = ALU_res_out[32];
			z = ALU_res_out?0:1;
			n = ALU_res_out[31]?1:0;
			v = 0;
			if ((ALU_valA_in[31] != valB[31]) && (ALU_valA_in[31] != ALU_res_out[31]))
				v = 1;
			ALU_icc_out = {n,z,v,c};
		end
		if (ALU_op3_in == `MULScc) begin
			logic [31:0] step2;
			step2 = {(ALU_icc_in[3] ^ ALU_icc_in[1]), (ALU_valA_in>>1)};
			if (ALU_Y_in[0])
				ALU_res_out = valB + step2;
			else
				ALU_res_out = 0 + step2;
			c = ALU_res_out[32];
			z = ALU_res_out?0:1;
			n = ALU_res_out[31]?1:0;
			v = 0;
			if ((ALU_valA_in[31] == valB[31]) && (ALU_valA_in[31] != ALU_res_out[31]))
				v = 1;
			ALU_icc_out = {n,z,v,c};
			ALU_Y_out = {ALU_valA_in[0], ALU_Y_in[31:1]};
		end
		if (ALU_op3_in == `UMUL) 
			ALU_res_out = ALU_valA_in * valB;
		if (ALU_op3_in == `SMUL) 
			ALU_res_out = ALU_valA_in * valB;
		if (ALU_op3_in == `UMULcc) begin 
			ALU_res_out = ALU_valA_in * valB;
			n = ALU_res_out[31]?1:0;
			z = (ALU_res_out[31:0] == 0)?1:0;
			v = 0;
			c = 0;
			ALU_icc_out = {n,z,v,c};
		end
		if (ALU_op3_in == `SMULcc) begin 
			ALU_res_out = ALU_valA_in * valB;
			n = ALU_res_out[31]?1:0;
			z = (ALU_res_out[31:0] == 0)?1:0;
			v = 0;
			c = 0;
			ALU_icc_out = {n,z,v,c};
		end
		if (ALU_op3_in == `UDIV)  begin
			logic [31:0] quotient, remainder;
			logic [32:0] result;
			quotient = {ALU_Y_in,ALU_valA_in} / valB;
			remainder = {ALU_Y_in,ALU_valA_in} % valB;
			result = remainder + quotient;
			if ((result>(2**32)-1) && (remainder == valB-1)) 
				ALU_res_out = 32'hffffffff;
			else
				ALU_res_out = quotient;			
		end
		if (ALU_op3_in == `UDIVcc)  begin
			logic [31:0] quotient, remainder;
			logic [32:0] result;
			quotient = {ALU_Y_in,ALU_valA_in} / valB;
			remainder = {ALU_Y_in,ALU_valA_in} % valB;
			result = remainder + quotient;
			if ((result>(2**32)-1) && (remainder == valB-1)) begin
				ALU_res_out = 32'hffffffff;
				v = 1;
			end
			else begin
				ALU_res_out = quotient;			
				v = 0;
			end
			n = ALU_res_out[31]?1:0;
			z = (ALU_res_out[31:0] == 0)?1:0;
			c = 0;
			ALU_icc_out = {n,z,v,c};
		end
		if (ALU_op3_in == `SDIV) begin
			logic [31:0] quotient;
			logic [30:0] remainder;
			logic [31:0] result;
			quotient = {ALU_Y_in,ALU_valA_in} / valB;
			remainder = {ALU_Y_in,ALU_valA_in} % valB;
			result = remainder + quotient;
			if (result[31]) begin // negative result
				if ((result < (-2**31)) && remainder == 0)
					ALU_res_out = 32'h80000000;
				else 	
					ALU_res_out = quotient;			
			end
			else begin
				if ((result > (2**31)-1) && (remainder == valB[30:0]-1)) 
					ALU_res_out = 32'h7fffffff;
				else
					ALU_res_out = quotient;			
			end
		end
		if (ALU_op3_in == `SDIVcc)  begin
			logic [31:0] quotient;
			logic [30:0] remainder;
			logic [31:0] result;
			quotient = {ALU_Y_in,ALU_valA_in} / valB;
			remainder = {ALU_Y_in,ALU_valA_in} % valB;
			result = remainder + quotient;
			if (result[31]) begin // negative result
				if ((result < (-2**31)) && remainder == 0) begin
					v = 1;
					ALU_res_out = 32'h80000000;
				end 
				else begin 	
					ALU_res_out = quotient;			
					v = 0;
				end
			end
			else begin
				if ((result > (2**31)-1) && (remainder == valB[30:0]-1)) begin
					ALU_res_out = 32'h7fffffff;
					v = 1;
				end
				else begin
					v = 0;
					ALU_res_out = quotient;			
				end
			end
			n = ALU_res_out[31]?1:0;
			z = (ALU_res_out[31:0] == 0)?1:0;
			c = 0;
			ALU_icc_out = {n,z,v,c};
		end
		if (ALU_op3_in == `JMPL) begin
			ALU_target_address_out = ALU_valA_in + valB;
			ALU_res_out = ALU_PC_in;
			ALU_mux_sel_out = 1;
		end
	end
end		
		




endmodule
		



