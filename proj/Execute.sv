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
	input [63:0] EX_valD_in,
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
	output [63:0] EX_valD_out,
	input mem_ready, 
	output annul_out,
	input EX_regWrite_in,
	output EX_regWrite_out,
	input EX_regWriteDouble_in,
	output EX_regWriteDouble_out,
	output [4:0] EX_p_regD_out,
	output EX_p_regWrite_out,
	output EX_p_regWriteDouble_out,
	input EX_icc_n_in,
	input EX_icc_z_in,
	input EX_icc_v_in,
	input EX_icc_c_in,
	output EX_icc_n_out,
	output EX_icc_z_out,
	output EX_icc_v_out,
	output EX_icc_c_out
);

	logic annul_in;
enum { STATEA=2'b00, STATEB=2'b01 } p_state, n_state;
logic n_ex_ready, p_ex_ready;
logic [INST_SIZE-1:0] n_valA, p_valA, n_valB, p_valB;
logic [63:0]  n_valD, p_valD; 
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
logic [31:0] p_res_out, n_res_out;
logic [63:0] n_pc, p_pc;
logic [31:0] n_target_out, p_target_out;
logic n_mux_sel, p_mux_sel;
logic n_annul, p_annul;
logic n_regWrite, p_regWrite;
logic n_regWriteDouble, p_regWriteDouble;
logic [31:0] alu_res_out;
logic [63:0]  alu_target_out, alu_mux_sel;
logic n_n, p_n, p_z, n_z, p_v, n_v, p_c, n_c;

ALU alu (.ALU_valA_in(EX_valA_in), .ALU_valB_in(EX_valB_in), .ALU_op_in(EX_op_in), .ALU_op2_in(EX_op2_in), .ALU_imm22_in(EX_disp22_in), .ALU_op3_in(EX_op3_in), .ALU_i_in(EX_i_in), .ALU_simm13_in(EX_imm13_in), .ALU_res_out(alu_res_out), .ALU_PC_in(EX_PC_in), .ALU_a_in(ALU_a_in), .ALU_cond_in(ALU_cond_in), .ALU_rd_in(EX_rd_in), .ALU_disp30_in(EX_disp30_in), .ALU_target_address_out(alu_target_out), .ALU_mux_sel_out(alu_mux_sel), .clk(clk), .reset(reset));

// add logic for bubble from decode
always_comb begin
	n_annul = p_annul;	
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
			n_valD = EX_valD_in;
			n_regWrite = EX_regWrite_in;
			n_regWriteDouble = EX_regWriteDouble_in;
			n_res_out = alu_res_out;
			n_target_out = alu_target_out;
			n_mux_sel = alu_mux_sel;
			n_n = EX_icc_n_in;
			n_z = EX_icc_z_in;
			n_v = EX_icc_v_in;
			n_c = EX_icc_c_in;
			if (EX_op_in  == 2'b00 && EX_op2_in == 3'b100 && EX_rd_in == 5'b00000) begin
				n_state = STATEA;
				n_ex_ready = 1;
				annul_out = annul_in;
			end
			else begin
				if (mem_ready == 0) begin
					n_state = STATEB;
					n_ex_ready = 0;
					annul_out = 0;
				end
				else begin
					// annul 
					if (EX_op_in == 2'b00 && EX_op2_in == 3'b010)
						annul_out = EX_a_in;
					else 
						annul_out = 0;
					n_state = STATEA;
					n_ex_ready = 1;
				end
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
			n_valD = p_valD;
			n_regWrite = p_regWrite;
			n_regWriteDouble = p_regWriteDouble;
			n_res_out = p_res_out;
			n_target_out = p_target_out;
			n_mux_sel = p_mux_sel;
			n_n = p_n;
			n_z = p_z;
			n_v = p_v;
			n_c = p_c;
			if (mem_ready == 0) begin
				annul_out = 0;
				n_state = STATEB;
				n_ex_ready = 0;
			end
			else begin
				// annul 
				if (p_op == 2'b00 && p_op2 == 3'b010) 
					annul_out = p_a;
				else 
					annul_out = 0;
				n_state = STATEA;
				n_ex_ready = 1;
			end
			end
	endcase


end
/*
assign ex_ready = p_ex_ready; 
assign EX_alures_out = p_alu_out;
assign EX_target_out = p_target_out;
assign EX_mux_sel_out = p_mux_sel;
assign EX_regD_out = p_rd; 
assign EX_op_out = p_op;
assign EX_op2_out = p_op2;
assign EX_op3_out = p_op3;
assign EX_valD_out = p_valD;
*/
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
		p_valD <= 0;
		p_annul <= 0;
		p_regWrite <= 0;
		p_regWriteDouble <= 0;
		p_res_out <= 0;
		p_target_out <= 0;
		p_mux_sel <= 0;
		p_n <= 0;
		p_z <= 0;
		p_v <= 0;
		p_c <= 0;
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
		p_valD <= n_valD;
		p_regWrite <= n_regWrite;
		p_regWriteDouble <= n_regWriteDouble;
		p_annul <= n_annul;
		p_res_out <= n_res_out;
		p_target_out <= n_target_out;
		p_mux_sel <= n_mux_sel;
		p_n <= n_n;
		p_z <= n_z;
		p_v <= n_v;
		p_c <= n_c;
	end

end

always_comb begin
	if (annul_in) begin
		EX_alures_out = p_res_out;//0;
		EX_target_out = p_target_out;
		EX_mux_sel_out = 0;
		EX_regD_out = 5'b00000;
		EX_op_out = 2'b00;
		EX_op2_out = 3'b100;
		EX_op3_out = 6'b100000;
		EX_valD_out = p_valD;//0;
		EX_regWrite_out = 0;
		EX_regWriteDouble_out = 0;
		EX_p_regD_out = 0;
		EX_p_regWrite_out = 0;
		EX_p_regWriteDouble_out = 0;
		EX_icc_n_out = 0;
		EX_icc_z_out = 0;
		EX_icc_v_out = 0;
		EX_icc_c_out = 0;
	end
	else begin
		EX_p_regD_out = n_rd; 
		EX_p_regWrite_out = n_regWrite;
		EX_p_regWriteDouble_out = n_regWriteDouble;
		EX_icc_n_out = n_n;
		EX_icc_z_out = n_z;
		EX_icc_v_out = n_v;
		EX_icc_c_out = n_c;
	case (p_state) 
		STATEA: begin
			EX_alures_out = alu_res_out;
			EX_target_out = alu_target_out;
			EX_mux_sel_out = alu_mux_sel;
			EX_regD_out = EX_rd_in; 
			EX_op_out = EX_op_in;
			EX_op2_out = EX_op2_in;
			EX_op3_out = EX_op3_in;
			EX_valD_out = EX_valD_in;
			EX_regWrite_out = EX_regWrite_in;
			EX_regWriteDouble_out = EX_regWriteDouble_in;
			ex_ready = 1;
		end
		default: begin 
			EX_alures_out = p_res_out;
			EX_target_out = p_target_out;
			EX_mux_sel_out = p_mux_sel;
			EX_regD_out = p_rd; 
			EX_op_out = p_op;
			EX_op2_out = p_op2;
			EX_op3_out = p_op3;
			EX_valD_out = p_valD;
			EX_regWrite_out = p_regWrite;
			EX_regWriteDouble_out = p_regWriteDouble;
			ex_ready = 0;
		end
	endcase
	end
end

always_ff @(posedge clk) begin
	if (reset)
		annul_in <= 0;
	else 
		annul_in <= annul_out;
end

/*
always_comb begin
	case (p_state) 
		STATEA: begin
ex_ready = 1;//p_ex_ready; 
EX_alures_out = p_alu_out;
EX_target_out = p_target_out;
EX_mux_sel_out = p_mux_sel;
EX_regD_out = p_rd; 
EX_op_out = p_op;
EX_op2_out = p_op2;
EX_op3_out = p_op3;
EX_valD_out = p_valD;
		end
		default: begin
ex_ready = 0; 
EX_alures_out = p_alu_out;//0;
EX_target_out = p_target_out;
EX_mux_sel_out = p_mux_sel;//0;
EX_regD_out = p_rd; //5'b00000
EX_op_out = p_op;//2'b00
EX_op2_out = p_op2;//3;b100
EX_op3_out = p_op3;//0;
EX_valD_out = p_valD;//0;
		end
	endcase
end
*/


endmodule 
