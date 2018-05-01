/**
 * Instruction decode phase
 */
`include "ALUops.sv"
// TODO data in, dest reg and enable for write to reg file
// TODO default case statement should latch old values rather than 0's
module InstructionDecode
#(
  // bus parameters
  BUS_DATA_WIDTH = 64,
  BUS_INST_WIDTH = 32
)
(
	input clk, reset,
	input [BUS_DATA_WIDTH-1:0] ID_PCplus4_in,
	input [BUS_INST_WIDTH-1:0] inst,
	output id_ready,
	output [BUS_DATA_WIDTH-1:0] ID_PCplus4_out,
	output [BUS_INST_WIDTH-1:0] valA, valB, 
	output [63:0] valD,
	output a,
	output [5:0] op3,
	output i,
	output [12:0] imm13,
	output [21:0] disp22,
	output [1:0] op,
	output [3:0] cond,
	output [2:0] op2,
	output [4:0] rd,
	output [29:0] disp30,
	input ex_ready,
	input WB_reg_en,
	input [31:0] WB_data_out,
	input [4:0] WB_regD_out,
	input [4:0] IDEX_rd_out,
	input [4:0] EXMem_regD_out,
	input [4:0] MemWB_regD_out,
	input IDEX_regWrite,
	input EXMem_regWrite,
	input MemWB_regWrite,
	input IDEX_regWriteDouble,
	input EXMem_regWriteDouble,
	input MemWB_regWriteDouble,
	output ID_regWrite_out,
	output ID_regWriteDouble_out,
	// special register
	output ID_icc_n_out,
	output ID_icc_z_out,
	output ID_icc_v_out,
	output ID_icc_c_out,
	output [4:0] cwp_out,
	output [31:0] wim_out,
	output [31:0] Y_out,
	input ID_icc_n_in,
	input ID_icc_z_in,
	input ID_icc_c_in,
	input ID_icc_v_in,
	input ID_icc_n_en,
	input ID_icc_z_en,
	input ID_icc_c_en,
	input ID_icc_v_en,
	input cwp_inc,
	input cwp_dec,
	input et_inc,
	input et_dec,
	input [31:0] Y_in,
	input Y_en,
	output ID_icc_n_write,
	output ID_icc_z_write,
	output ID_icc_c_write,
	output ID_icc_v_write


);
  enum { STATEA=2'b00, STATEB=2'b01, STATES=2'b10} n_state, p_state; 
//	logic [4:0] rs1, rs2;
//	logic [BUS_DATA_WIDTH-1:0] n_pc4, p_pc4;
logic [4:0] n_rs1, p_rs1, n_rs2, p_rs2, n_rd, p_rd;
logic [31:0] n_inst, p_inst;
logic [63:0] n_pc, p_pc;
logic [31:0] val1, val2;
logic [63:0] val3;
logic n_id_read, p_id_read;
logic n_id_write, p_id_write;
logic p_regWrite, n_regWrite, n_regWriteDouble, p_regWriteDouble;


RegFile regis (.clk(clk), .reset(reset), .rs1(inst[18:14]), .rs2(inst[4:0]), .val1(valA), .val2(valB), .val3(valD), .rd(inst[29:25]), .reg_write_en(WB_reg_en), .data(WB_data_out), .wr_reg(WB_regD_out), .icc_n_in(ID_icc_n_in), .icc_z_in(ID_icc_z_in), .icc_v_in(ID_icc_v_in), .icc_c_in(ID_icc_c_in), .icc_n_en(ID_icc_n_en), .icc_z_en(ID_icc_z_en) , .icc_v_en(ID_icc_v_en), .icc_c_en(ID_icc_c_en), .cwp_inc(cwp_inc), .cwp_dec(cwp_dec), .et_inc(et_inc), .et_dec(et_dec), .Y_in(Y_in), .Y_en(Y_en), .icc_n_out(ID_icc_n_out), .icc_z_out(ID_icc_z_out), .icc_v_out(ID_icc_v_out), .icc_c_out(ID_icc_c_out), .cwp_out(cwp_out), .wim_out(wim_out), .Y_out(Y_out));





always_comb begin
	n_pc = p_pc;
	n_inst = p_inst;
	n_regWrite = p_regWrite;
	n_regWriteDouble = p_regWriteDouble;
	case (p_state)
		STATEA: begin
			n_inst = inst;
			n_regWrite = reg_write(inst[31:30], inst[24:19]);
			n_regWriteDouble = reg_write_double(inst[31:30], inst[24:19]);
			n_pc = ID_PCplus4_in;
			if (inst == 32'h01000000) begin
				ID_PCplus4_out = ID_PCplus4_in;
				a = inst[29];
				op3 = inst[24:19];
				i = inst[13];
				imm13 = inst[12:0];
				disp22 = inst[21:0];
				op = inst[31:30];
				cond = inst[28:25];
				op2 = inst[24:22];
				rd = inst[29:25];
				disp30 = inst[29:0];
				ID_regWrite_out = 0;//reg_write(inst[31:30], inst[24:19]);
				ID_regWriteDouble_out = 0;//reg_write_double(inst[31:30], inst[24:19]);
				//valA = 0;
				//valB = 0;
				//valD = 0;
				n_state = STATEA;
			end
			else begin 	
			// check for dependancies
			if (instruction_dependancy(inst[18:14], inst[4:0], IDEX_rd_out, IDEX_regWrite, IDEX_regWriteDouble) || instruction_dependancy(inst[18:14], inst[4:0], EXMem_regD_out, EXMem_regWrite, EXMem_regWriteDouble)) begin
				ID_PCplus4_out = 0;
				//valA = 0;
				//valB = 0;
				//valD = 0;
				a = 0;
				op3 = 6'b100000;
				i = 0;
				imm13 = 0;
				disp22 = 0;
				op = 2'b00;
				cond = 0;
				op2 = 3'b100;
				rd = 0;
				disp30 = 0;
				ID_regWrite_out = 0;
				ID_regWriteDouble_out = 0;
				n_state = STATES;
			end
			else begin
				ID_PCplus4_out = ID_PCplus4_in;
				a = inst[29];
				op3 = inst[24:19];
				i = inst[13];
				imm13 = inst[12:0];
				disp22 = inst[21:0];
				op = inst[31:30];
				cond = inst[28:25];
				op2 = inst[24:22];
				if (inst[31:30] == 2'b01)
					rd = 5'b01111;
				else
					rd = inst[29:25];
				disp30 = inst[29:0];
				ID_regWrite_out = reg_write(inst[31:30], inst[24:19]);
				ID_regWriteDouble_out = reg_write_double(inst[31:30], inst[24:19]);
				if (ex_ready) begin
					//valA = val1;
					//valB = val2;
					//valD = val3;
					n_state = STATEA;
				end
				else begin 
					//valA = 0;
					//valB = 0;//val2;
					//valD = 0;//val3;
					n_state = STATEB;
				end
			end
			end
			end
		STATEB: begin
			ID_PCplus4_out = p_pc;
			a = p_inst[29];
			op3 = p_inst[24:19];
			i = p_inst[13];
			imm13 = p_inst[12:0];
			disp22 = p_inst[21:0];
			op = p_inst[31:30];
			cond = p_inst[28:25];
			op2 = p_inst[24:22];
			rd = p_inst[29:25];
			disp30 = p_inst[29:0];
			ID_regWrite_out = p_regWrite;
			ID_regWriteDouble_out = p_regWriteDouble;
			if (ex_ready) begin
				//valA = val1;
				//valB = val2;
				//valD = val3;
				n_state = STATEA;
			end
			else begin
				//valA = 0;
				//valB = 0;//val2;
				//valD = 0;//val3;
				n_state = STATEB;	
			end
			end
		STATES: begin
			if (instruction_dependancy(p_inst[18:14], p_inst[4:0], IDEX_rd_out, IDEX_regWrite, IDEX_regWriteDouble) || instruction_dependancy(p_inst[18:14], p_inst[4:0], EXMem_regD_out, EXMem_regWrite, EXMem_regWriteDouble)) begin
				ID_PCplus4_out = 0;
				//valA = 0;
				//valB = 0;
				//valD = 0;
				a = 0;
				op3 = 6'b100000;
				i = 0;
				imm13 = 0;
				disp22 = 0;
				op = 2'b00;
				cond = 0;
				op2 = 3'b100;
				rd = 0;
				disp30 = 0;
				ID_regWrite_out = 0;
				ID_regWriteDouble_out = 0;
				n_state = STATES;
				n_state = STATES;
			end
			else begin
				ID_PCplus4_out = p_pc;
				a = inst[29];
				op3 = inst[24:19];
				i = inst[13];
				imm13 = inst[12:0];
				disp22 = inst[21:0];
				op = inst[31:30];
				cond = inst[28:25];
				op2 = inst[24:22];
				rd = inst[29:25];
				disp30 = inst[29:0];
				ID_regWrite_out = reg_write(inst[31:30], inst[24:19]);
				ID_regWriteDouble_out = reg_write_double(inst[31:30], inst[24:19]);
				if (ex_ready) begin
					n_state = STATEA;
					//valA = val1;
					//valB = val2;
					//valD = val3;
				end
				else begin 
					n_state = STATEB;
					//valA = val1;
					//valB = val2;
					//valD = val3;
				end
			end
			end
	endcase
end	

always_ff @(posedge clk) begin
	if (reset) begin 
		p_pc <= 0;
		p_inst <= 0;
		p_regWrite <= 0;
		p_regWriteDouble <= 0;
		p_state <= STATEA;
	end
	else begin
		p_pc <= n_pc;
		p_inst <= n_inst;
		p_regWrite <= n_regWrite;
		p_regWriteDouble <= n_regWriteDouble;
		p_state <= n_state;
	end
end

// outputs
assign id_ready = (p_state == STATEA)?1:0;
				
function bit reg_write(bit [1:0] op, bit [5:0] op3);
	if (op == 2'b11) begin
		// store instructions
		if (op3 == `STB|| op3 == `STH || op3 == `ST || op3 == `STD) begin
			return 0;
		end
	end
	if (op == 2'b00) begin
		// branch instructions
		return 0;
	end
	if (op == 2'b01) begin
		// call instructions
		return 0;
	end
	return 1;

endfunction
function bit reg_write_double(bit [1:0] op, bit [5:0] op3);
	if (op == 2'b11) begin
		// store instructions
		if (op3 == `LDD)
			return 1;
	end
	return 0;

endfunction

function bit instruction_dependancy(bit [4:0] rs1, bit [4:0] rs2, bit [4:0] rd, bit regwrite, bit regwritedouble);
	if ( ((rs1 == rd || rs2 == rd) && (rd != 5'b00000) && (regwrite)) || ((rs1 == rd+1 || rs2 == rd+1) && regwritedouble)) begin
		return 1;
	end
	return 0;
endfunction

function bit cc_dep(bit [4:0] rs1, bit [4:0] rs2, bit [4:0] rd, bit regwrite, bit regwritedouble);
	if ( ((rs1 == rd || rs2 == rd) && (rd != 5'b00000) && (regwrite)) || ((rs1 == rd+1 || rs2 == rd+1) && regwritedouble)) begin
		return 1;
	end
	return 0;
endfunction
function bit cc_write(bit [1:0] op, bit [5:0] op3);
	if (op == 2'b01) begin
		if (op3 == `ANDcc || op3 == `ANDNcc || op3 == `ORcc || op3 == `ORNcc || op3 == `XORcc || op3 == `XNORcc || op3 == `ADDcc || op3 == `ADDXcc || op3 == `TADDcc || op3 == `TADDccTV || op3 == `SUBcc || op3 == `SUBXcc || op3 == `TSUBcc || op3 == `TSUBccTV || op3 == `MULScc || op3 == `UMULcc || op3 == `SMULcc || op3 == `UDIVcc || op3 ==`SDIVcc) 
		return 1;
	return 0;  
	end

endfunction

endmodule    
		

/*
// next state logic
always_comb begin
	n_rs1 = p_rs1;
	n_rs2 = p_rs2;
	n_rd = p_rd;
	n_inst = p_inst;
	n_pc = p_pc;
	n_regWrite = p_regWrite;
	n_regWriteDouble = p_regWriteDouble;
	case (p_state)	
		STATEA: begin
			// need to check for stall from next stage
			// need to check for instruction dependencies
			// check for dependencies. if present, go to states
			if (inst == 32'h01000000) begin
				n_inst = 32'h01000000;
				n_state = STATEA;	
				n_regWrite = 0;
				n_regWriteDouble = 0;
			end
			else begin
				n_state = STATEB;
				n_rs1 = inst[18:14];
				n_rs2 = inst[4:0];
				n_rd = inst[29:25];
				n_inst = inst;
				n_pc = ID_PCplus4_in;
			end
			end
		STATEB: begin
			if (ex_ready == 0)
				n_state = STATEB;
			else begin
				// if rs's == rd of older instruction, stay
				if (instruction_dependancy(p_rs1, p_rs2, IDEX_rd_out, IDEX_regWrite, IDEX_regWriteDouble)) begin
					n_state = STATEB;	
				end
				else begin 
					if (instruction_dependancy(p_rs1, p_rs2, EXMem_regD_out, EXMem_regWrite, EXMem_regWriteDouble)) begin
						n_state = STATEB;
					end
					else begin 
						if (instruction_dependancy(p_rs1, p_rs2, MemWB_regD_out, MemWB_regWrite, MemWB_regWriteDouble)) begin
							n_state = STATEB;
	
						end
						else begin
							n_regWrite = reg_write(p_inst[31:30], p_inst[24:19]);
							n_regWriteDouble = reg_write_double(p_inst[31:30], p_inst[24:19]);
							n_state = STATEA;
						end	
					end
				end
			end
			end
	endcase
end  

// register
always_ff @(posedge clk) begin
	if (reset) begin
		p_pc <= 0;
		p_state <= STATEA;
		p_rs1 <= 0;
		p_rs2 <= 0;
		p_rd <= 0;
		p_inst <= 32'h01000000;
		p_regWrite <= 0;
		p_regWriteDouble <= 1;
	end
	else begin
		p_pc <= n_pc;
		p_state <= n_state;
		p_rs1 <= n_rs1;
		p_rs2 <= n_rs2;
		p_rd <= n_rd;
		p_inst <= n_inst;
		p_regWrite <= n_regWrite;
		p_regWriteDouble <= n_regWriteDouble;
		
	end

end
always_comb begin
	case (p_state)
		STATEA: begin 
			ID_PCplus4_out = p_pc;
			valA = val1;
			valB = val2;
			valD = val3;
			a = p_inst[29];
			op3 = p_inst[24:19];
			i = p_inst[13];
			imm13 = p_inst[12:0];
			disp22 = p_inst[21:0];
			op = p_inst[31:30];
			cond = p_inst[28:25];
			op2 = p_inst[24:22];
			rd = p_inst[29:25];
			disp30 = p_inst[29:0];
			id_ready = 1;
			ID_regWrite_out = p_regWrite;
			ID_regWriteDouble_out = p_regWriteDouble;
			end
		default: begin
			id_ready = 0; 
			ID_PCplus4_out = 0;
			valA = 0;
			valB = 0;
			valD = 0;
			a = 0;//p_inst[29];
			op3 = 6'b100000;//;p_inst[24:19];
			i = 0;//p_inst[13];
			imm13 = 0;//p_inst[12:0];
			disp22 = 0;//p_inst[21:0];
			op = 0;//p_inst[31:30];
			cond = 0;//p_inst[28:25];
			op2 = 3'b100;//p_inst[24:22];
			rd = 0;//p_inst[29:25];
			disp30 = 0;//p_inst[29:0];
			ID_regWrite_out = 0;
			ID_regWriteDouble_out = 0;
		end
	endcase
end

function bit reg_write(bit [1:0] op, bit [5:0] op3);
	if (op == 2'b11) begin
		// store instructions
		if (op3 == `STB|| op3 == `STH || op3 == `ST || op3 == `STD) begin
			return 0;
		end
	end
	if (op == 2'b00) begin
		// branch instructions
		return 0;
	end
	if (op == 2'b01) begin
		// call instructions
		return 0;
	end
	return 1;

endfunction
function bit reg_write_double(bit [1:0] op, bit [5:0] op3);
	if (op == 2'b11) begin
		// store instructions
		if (op3 == `LDD)
			return 1;
	end
	return 0;

endfunction

function bit instruction_dependancy(bit [4:0] rs1, bit [4:0] rs2, bit [4:0] rd, bit regwrite, bit regwritedouble);
	if ( ((rs1 == rd || rs2 == rd) && (rd != 5'b00000) && (regwrite)) || ((rs1 == rd+1 || rs2 == rd+1) && regwritedouble)) begin
		return 1;
	end
	return 0;
endfunction

endmodule    
    
  */ 
