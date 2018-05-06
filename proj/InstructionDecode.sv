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
	input [63:0] WB_data_out,
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
	output [3:0] ID_icc_out,
	output [4:0] cwp_out,
	output [31:0] wim_out,
	output [31:0] Y_out,
	input [3:0] ID_icc_in,
	input ID_icc_en,
	//input cwp_inc,
	//input cwp_dec,
	input et_inc,
	input et_dec,
	input Y_en,
	output ID_Y_write_out,
	output ID_icc_write_out,
	input IDEX_icc_write,
	input EXMem_icc_write,
	input IDEX_Y_write,
	input EXMem_Y_write


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
logic p_regWrite, n_regWrite, n_regWriteDouble, p_regWriteDouble, p_icc_write, n_icc_write, p_y_write, n_y_write;
logic cwp_inc, cwp_dec;

RegFile regis (.clk(clk), .reset(reset), .rs1(inst[18:14]), .rs2(inst[4:0]), .val1(valA), .val2(valB), .val3(valD), .rd(inst[29:25]), .reg_write_en(WB_reg_en), .data(WB_data_out), .wr_reg(WB_regD_out), .icc_in(ID_icc_in), .icc_en(ID_icc_en), .cwp_inc(cwp_inc), .cwp_dec(cwp_dec), .et_inc(et_inc), .et_dec(et_dec), .Y_in(Y_in), .Y_en(Y_en), .icc_out(ID_icc_out),  .cwp_out(cwp_out), .wim_out(wim_out), .Y_out(Y_out));





always_comb begin
	n_pc = p_pc;
	n_inst = p_inst;
	n_regWrite = p_regWrite;
	n_regWriteDouble = p_regWriteDouble;
	n_icc_write = p_icc_write;
	n_y_write = p_y_write;
	cwp_inc = 0;
	cwp_dec = 0;
	case (p_state)
		STATEA: begin
			n_inst = inst;
			n_regWrite = reg_write(inst[31:30], inst[24:19], inst[24:22]);
			n_regWriteDouble = reg_write_double(inst[31:30], inst[24:19]);
			n_icc_write = cc_write(inst[31:0], inst[24:19]);
			n_y_write = Y_write(inst[31:0], inst[24:19]);
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
				ID_regWrite_out = 0;
				ID_regWriteDouble_out = 0;
				ID_icc_write_out = 0;
				ID_Y_write_out = 0;
				//valA = 0;
				//valB = 0;
				//valD = 0;
				n_state = STATEA;
			end
			else begin 	
			// check for dependancies
			if (instruction_dependancy(inst[18:14], inst[4:0], IDEX_rd_out, IDEX_regWrite, IDEX_regWriteDouble) || instruction_dependancy(inst[18:14], inst[4:0], EXMem_regD_out, EXMem_regWrite, EXMem_regWriteDouble) || cc_dep(inst[31:30], inst[24:22], inst[24:19], IDEX_icc_write) || cc_dep(inst[31:30], inst[24:22], inst[24:19], EXMem_icc_write) || Y_dep(inst[31:30], inst[24:19], IDEX_Y_write, EXMem_Y_write)) begin
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
				ID_icc_write_out = 0;
				ID_Y_write_out = 0;
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
				ID_regWrite_out = reg_write(inst[31:30], inst[24:19], inst[24:22]);
				ID_regWriteDouble_out = reg_write_double(inst[31:30], inst[24:19]);
				ID_icc_write_out = cc_write(inst[31:0], inst[24:19]);
				ID_Y_write_out = Y_write(inst[31:0], inst[24:19]);
				if (ex_ready) begin
					//valA = val1;
					//valB = val2;
					//valD = val3;
					if (inst[31:30] == 2'b10) begin
						if (inst[24:19] == `SAVE)
							cwp_dec = 1;
						if (inst[24:19] == `RESTORE)
							cwp_inc = 1;
					end
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
			ID_icc_write_out = p_icc_write;
			ID_Y_write_out = p_y_write;
			if (ex_ready) begin
				//valA = val1;
				//valB = val2;
				//valD = val3;
				if (p_inst[31:30] == 2'b10) begin
					if (p_inst[24:19] == `SAVE)
						cwp_dec = 1;
					if (p_inst[24:19] == `RESTORE)
						cwp_inc = 1;
				end
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
			if (instruction_dependancy(p_inst[18:14], p_inst[4:0], IDEX_rd_out, IDEX_regWrite, IDEX_regWriteDouble) || instruction_dependancy(p_inst[18:14], p_inst[4:0], EXMem_regD_out, EXMem_regWrite, EXMem_regWriteDouble) || cc_dep(p_inst[31:30], p_inst[24:22], p_inst[24:19], IDEX_icc_write) || cc_dep(p_inst[31:30], p_inst[24:22], p_inst[24:19], EXMem_icc_write) || Y_dep(p_inst[31:30], p_inst[24:19], IDEX_Y_write, EXMem_Y_write)) begin
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
				ID_icc_write_out = 0;
				ID_Y_write_out = 0;
				n_state = STATES;
				n_state = STATES;
			end
			else begin
				// CHANGIN inst to p_inst
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
				ID_regWrite_out = p_regWrite;//reg_write(inst[31:30], inst[24:19]);
				ID_regWriteDouble_out = p_regWriteDouble;//reg_write_double(inst[31:30], inst[24:19]);
				ID_icc_write_out = p_icc_write;
				ID_Y_write_out = p_y_write;
				if (ex_ready) begin
					n_state = STATEA;
					if (p_inst[31:30] == 2'b10) begin
						if (p_inst[24:19] == `SAVE)
							cwp_dec = 1;
						if (p_inst[24:19] == `RESTORE)
							cwp_inc = 1;
					end
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
		p_icc_write <= 0;
		p_y_write <= 0;
		p_state <= STATEA;
	end
	else begin
		p_pc <= n_pc;
		p_inst <= n_inst;
		p_regWrite <= n_regWrite;
		p_regWriteDouble <= n_regWriteDouble;
		p_icc_write <= n_icc_write;
		p_y_write <= n_y_write;
		p_state <= n_state;
	end
end

// outputs
assign id_ready = (p_state == STATEA)?1:0;
				
function bit reg_write(bit [1:0] op, bit [5:0] op3, bit [2:0] op2);
	if (op == 2'b11) begin
		// store instructions
		if (op3 == `STB|| op3 == `STH || op3 == `ST || op3 == `STD) begin
			return 0;
		end
	end
	if (op == 2'b00) begin
		// branch instructions
		if (op2 == 3'b010)
			return 0;
	end
	return 1;

endfunction

function bit reg_write_double(bit [1:0] op, bit [5:0] op3);
	// ADD FOR MUL AND DIV
	if (op == 2'b11) begin
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

function bit cc_dep(bit [1:0] op, bit [2:0] op2, bit [5:0] op3, bit write);
	if (write == 1) begin
		if (op == 2'b00) begin // BRANCH
			if (op2 == `BA || op2 == `BN || op2 == `BNE || op2 == `BE || op2 == `BG || op2 == `BLE || op2 == `BGE || op2 == `BL || op2 == `BGU || op2 == `BLEU || op2 == `BCC || op2 == `BCS || op2 == `BPOS || op2 == `BNEG || op2 == `BVC || op2 == `BVS)
				return 1;
		end	
		if (op == 2'b10) begin
			if (op3 == `TA || op3 == `TN || op3 == `TNE || op3 == `TE || op3 == `TG || op3 == `TLE || op3 == `TGE || op3 ==`TL || op3 == `TGU || op3 == `TLEU || op3 == `TCC || op3 == `TCS || op3 == `TPOS || op3 == `TNEG || op3 == `TVC || op3 == `TVS)
				return 1;
		end
		return 0;
	end
	return 0;

endfunction

function bit cc_write(bit [1:0] op, bit [5:0] op3);
	if (op == 2'b01) begin
		if (op3 == `ANDcc || op3 == `ANDNcc || op3 == `ORcc || op3 == `ORNcc || op3 == `XORcc || op3 == `XNORcc || op3 == `ADDcc || op3 == `ADDXcc || op3 == `TADDcc || op3 == `TADDccTV || op3 == `SUBcc || op3 == `SUBXcc || op3 == `TSUBcc || op3 == `TSUBccTV || op3 == `MULScc || op3 == `UMULcc || op3 == `SMULcc || op3 == `UDIVcc || op3 ==`SDIVcc || `MULScc) 
		return 1;
	end
	return 0;  
endfunction

function bit Y_write(bit [1:0] op, bit [5:0] op3);
//	return 1;
	if (op == 2'b01) begin
		if (op3 == `MULScc || op3 == `UMUL || op3 == `UMULcc || op3 == `SMUL || op3 == `SMULcc)
			return 1;
	end
	return 0;
endfunction

function bit Y_dep(bit [1:0] op, bit [5:0] op3, exwrite, memwrite);
	// if inst is divide and write == 1
	if ((op == 2'b10) && exwrite && memwrite) begin
		if (op3 == `UDIV || op3 == `SDIV || op3 == `UDIVcc || op3 == `SDIVcc) 
			return 1;
	end
	return 0;
endfunction

endmodule    
		

    
