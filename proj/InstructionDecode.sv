/**
 * Instruction decode phase
 */

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
	output [BUS_INST_WIDTH-1:0] valA, valB, valD,
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
	input MemWB_regWrite

);
  enum { STATEA=2'b00, STATEB=2'b01, STATES=2'b10} n_state, p_state; 
//	logic [4:0] rs1, rs2;
//	logic [BUS_DATA_WIDTH-1:0] n_pc4, p_pc4;
logic [4:0] n_rs1, p_rs1, n_rs2, p_rs2, n_rd, p_rd;
logic [31:0] n_inst, p_inst;
logic [63:0] n_pc, p_pc;
logic [31:0] val1, val2, val3;
logic n_id_read, p_id_read;
logic n_id_write, p_id_write;


RegFile regis (.clk(clk), .reset(reset), .rs1(p_rs1), .rs2(p_rs2), .val1(val1), .val2(val2), .val3(val3), .rd(p_rd), .reg_write_en(WB_reg_en), .data(WB_data_out), .wr_reg(WB_regD_out));

// next state logic
always_comb begin
	n_rs1 = p_rs1;
	n_rs2 = p_rs2;
	n_rd = p_rd;
	n_inst = p_inst;
	n_pc = p_pc;
	case (p_state)	
		STATEA: begin
			// need to check for stall from next stage
			// need to check for instruction dependencies
			// check for dependencies. if present, go to states
			if (inst == 32'h01000000) begin
				n_inst = 32'h01000000;
				n_state = STATEA;	
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
				if ((p_rd == IDEX_rd_out || p_rs2 == IDEX_rd_out) && (IDEX_rd_out != 5'b00000) && (IDEX_regWrite == 1)) begin
					n_state = STATEB;	
					//$display("stall ONE");
				end
				else begin 
					if ((p_rd == EXMem_regD_out || p_rs2 == EXMem_regD_out) && (EXMem_regD_out != 5'b00000) && (EXMem_regWrite == 1)) begin
						n_state = STATEB;
						//$display("stall TWO");
					end
					else begin 
						if ((p_rd == MemWB_regD_out || p_rs2 == MemWB_regD_out) && (MemWB_regD_out != 5'b00000) && (MemWB_regWrite == 1)) begin
							n_state = STATEB;
							//$display("stall THREE");
	
						end
						else begin
							//$display("NO stall");
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
	end
	else begin
		p_pc <= n_pc;
		p_state <= n_state;
		p_rs1 <= n_rs1;
		p_rs2 <= n_rs2;
		p_rd <= n_rd;
		p_inst <= n_inst;
		
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
			end
		default: begin
			id_ready = 0; 
			ID_PCplus4_out = 0;
			valA = 0;
			valB = 0;
			valD = 0;
			a = 0;//p_inst[29];
			op3 = 0;//;p_inst[24:19];
			i = 0;//p_inst[13];
			imm13 = 0;//p_inst[12:0];
			disp22 = 0;//p_inst[21:0];
			op = 0;//p_inst[31:30];
			cond = 0;//p_inst[28:25];
			op2 = 3'b100;//p_inst[24:22];
			rd = 0;//p_inst[29:25];
			disp30 = 0;//p_inst[29:0];
		end
	endcase
end

endmodule    
    
    
