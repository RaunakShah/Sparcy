/**
 * Execute
 */

// TODO alu, alu for pc, mux for alu inputs
`include "ALUops.sv"
/*
algorithm:
inputs - pc, valA, valB, opcodes etc, regD
outputs - new pc, mux enable, alu result, regD, controls?
mux and alu - always comb
new pc - always comb
send inputs to both, move to state b
takes one cycle to execute, move to state a
outputs when moving from b to a

*/
module Execute
#(
  // bus parameters
  BUS_DATA_WIDTH = 64,
  PC_SIZE = 64, 
  INST_SIZE = 32,
  BUS_INST_WIDTH = 32
)
(
	input clk, reset,
	input [PC_SIZE-1:0] EX_PC_in,
	input [INST_SIZE-1:0] EX_valA_in,
	input [INST_SIZE-1:0] EX_valB_in,
	input EX_a_in,
	input [5:0] EX_op3_in,
	input EX_i_in,
	input [12:0] EX_imm13_in,
	input [21:0] EX_disp22_in, 
	input [1:0] EX_op_in, 
	input [3:0] EX_cond_in, 
	input [2:0] EX_op2_in, 
	input [4:0] EX_rd_in,
	input [29:0] EX_disp30_in,
	output [63:0] EX_target_out,
	output EX_mux_sel_out, 
	output ex_ready,
	output [4:0] EX_regD_out,
	output [31:0] EX_alures_out,
	output [1:0] EX_op_out,
	output [2:0] EX_op2_out,
	output [5:0] EX_op3_out,
	input mem_ready
);

enum { STATEA=2'b00, STATEB=2'b01 } p_state, n_state;
logic n_ex_ready, p_ex_ready;
logic [INST_SIZE-1:0] n_valA, p_valA, n_valB, p_valB; 
logic n_a, p_a;
logic [5:0] n_op3, p_op3;
logic n_i, p_i;
logic [12:0] n_imm13, p_imm13;
logic [21:0] n_disp22, p_disp22;
logic [21:0] n_imm22, p_imm22;
logic [1:0] n_op, p_op;
logic [3:0] n_cond, p_cond;
logic [2:0] n_op2, p_op2;
logic [4:0] n_rd, p_rd;
logic [29:0] n_disp30, p_disp30;
logic [31:0] p_alu_out, n_alu_out;
logic [31:0] n_pc, p_pc;
logic [31:0] p_target_out;
logic p_mux_sel;

//TargetPCCalc target ();
ALU alu (.ALU_valA_in(p_valA), .ALU_valB_in(p_valB), .ALU_op_in(p_op), .ALU_op2_in(p_op2), .ALU_imm22_in(p_imm22), .ALU_op3_in(p_op3), .ALU_i_in(p_i), .ALU_simm13_in(p_imm13), .ALU_res_out(p_alu_out), .ALU_PC_in(p_pc), .ALU_a_in(p_a), .ALU_cond_in(p_cond), .ALU_rd_in(p_rd), .ALU_disp30_in(p_disp30), .ALU_target_address_out(p_target_out), .ALU_mux_sel_out(p_mux_sel));

// add logic for bubble from decode
always_comb begin	
	case (p_state)
		STATEA: begin
			n_valA = EX_valA_in;
			n_valB = EX_valB_in;
			n_op = EX_op_in;
			n_op2 = EX_op2_in;
			n_imm22 = EX_disp22_in;
			n_op3 = EX_op3_in;
			n_i = EX_i_in;
			n_imm13 = EX_imm13_in;
			n_a = EX_a_in;
			n_pc = EX_PC_in;
			n_cond = EX_cond_in;
			n_rd = EX_rd_in;
			n_disp30 = EX_disp30_in;
			if (mem_ready == 0) begin
				n_state = STATEB;
				n_ex_ready = 0;
			end
			else begin
				n_state = STATEA;
				n_ex_ready = 1;
			end
			end
		STATEB: begin
			n_valA = p_valA;
			n_valB = p_valB;
			n_op = p_op;
			n_op2 = p_op2;
			n_imm22 = p_imm22;
			n_op3 = p_op3;
			n_i = p_i;
			n_imm13 = p_imm13;
			n_a = p_a;//EX_a_in;
			n_pc = p_pc;//EX_PC_in;
			n_cond = p_cond;//EX_cond_in;
			n_rd = p_rd;//EX_rd_in;
			n_disp30 = p_disp30;//EX_disp30_in;
			if (mem_ready == 0) begin
				n_state = STATEB;
				n_ex_ready = 0;
			end
			else begin
				n_state = STATEA;
				n_ex_ready = 1;
			end
			end
	endcase


end

assign ex_ready = p_ex_ready; 
assign EX_alures_out = p_alu_out;
assign EX_target_out = p_target_out;
assign EX_mux_sel_out = p_mux_sel;
// register
always_ff @(posedge clk) begin
	if (reset) begin
		p_state <= STATEA;
		p_ex_ready <= 1;
		p_valA <= 0;
		p_valB <= 0;//n_valB;
		p_op <= 0;//n_op;
		p_op2 <= 0;//n_op2;
		p_imm22 <= 0;//n_imm22;
		p_op3 <= 0;//n_op3;
		p_i <= 0;//n_i;
		p_imm13 <= 0;//n_imm13;
		p_a <= 0;
		p_pc <= 0;//n_pc;
		p_cond <= 0;//n_cond;
		p_rd <= 0;//n_rd;
		p_disp30 <= 0;//n_disp30;
	end
	else begin
		p_state <= n_state;
		p_ex_ready <= n_ex_ready;
		p_valA <= n_valA;
		p_valB <= n_valB;
		p_op <= n_op;
		p_op2 <= n_op2;
		p_imm22 <= n_imm22;
		p_op3 <= n_op3;
		p_i <= n_i;
		p_imm13 <= n_imm13;
		p_state <= n_state;//STATEA;
		p_a <= n_a;
		p_pc <= n_pc;
		p_cond <= n_cond;
		p_rd <= n_rd;
		p_disp30 <= n_disp30;
	end

end


endmodule 
