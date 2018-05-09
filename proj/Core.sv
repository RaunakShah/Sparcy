
`include "Sysbus.defs"

module Core
#(
  BUS_DATA_WIDTH = 64,
  BUS_TAG_WIDTH = 13
)
(
  input 		      clk,
			      reset,

  // address of the program entry point
  input [31:0] 		      entry,
  
  // interface to connect to the bus
  output 		      bus_reqcyc,
  output 		      bus_respack,
  output [BUS_DATA_WIDTH-1:0] bus_req,
  output [BUS_TAG_WIDTH-1:0]  bus_reqtag,
  input 		      bus_respcyc,
  input 		      bus_reqack,
  input [BUS_DATA_WIDTH-1:0]  bus_resp,
  input [BUS_TAG_WIDTH-1:0]   bus_resptag
);

  // function to be called to execute a system call
//  import "DPI-C" function int
  //syscall_cse502(input int g1, input int o0, input int o1, input int o2, input int o3, input int o4, input int o5);
logic [63:0] target;
logic [63:0] next_inst; // pc + 4A
logic [63:0] inst;
logic ic_req; //
logic [57:0] ic_line_addr;//
logic [3:0] ic_word_select; //
logic [31:0] ic_data_out;
logic ic_ack; //
logic if_ready;
logic [31:0] nPC_out;
logic [31:0] nPC_in;

logic ID_regWrite_out;
logic ID_regWriteDouble_out;
logic [63:0] IFID_PCplus4_out; // pc + 4
logic [63:0] ID_PCplus4_out; // pc + 4
logic [63:0] IDEX_PCplus4_out; // pc + 4
logic [31:0] inst_decode;
	logic [63:0] in_PCplus4;
	logic id_stall;
	logic id_ready;
	logic if_write;
	logic [64-1:0] out_PCplus4;
	logic [32-1:0] valA, valB;
	logic [63:0] valD;
	logic a;
	logic [5:0] op3;
	logic i;
	logic [12:0] imm13;
	logic [21:0] disp22;
	logic [1:0] op;
	logic [3:0] cond;
	logic [2:0] op2;
	logic [4:0] rd;
	logic [29:0] disp30;
	logic [63:0] IDEX_PC_out;
	logic [31:0] IDEX_valA_out;
	logic [31:0] IDEX_valB_out;
	logic [63:0] IDEX_valD_out;
	logic [63:0] EX_valD_out;
	logic IDEX_a_out;
	logic [5:0] IDEX_op3_out;
	logic IDEX_i_out;
	logic [12:0] IDEX_imm13_out;
	logic [21:0] IDEX_disp22_out; 
	logic [1:0] IDEX_op_out;
	logic [3:0] IDEX_cond_out; 
	logic [2:0] IDEX_op2_out; 
	logic [4:0] IDEX_rd_out;
	logic [29:0] IDEX_disp30_out;
	logic [63:0] EX_target_out;
	logic EX_mux_sel_out;
	logic [63:0] EXMem_target_out;
	logic EXMem_mux_sel_out;

logic id_write;
logic ex_ready;
logic exc_out;
logic c_out;
logic [31:0] if_inst_out;
logic [10:0] res;
logic [63:0] EX_alures_out, EXMem_alures_out;
assign target = reset?0:entry;
logic ic_reqcyc_out;
logic [63:0] ic_req_out;
logic [12:0] ic_reqtag_out;
logic ic_reqack_in;
logic ic_respack_out;
logic [4:0] EX_regD_out;
logic [1:0] EX_op_out;
logic [2:0] EX_op2_out;
logic [5:0] EX_op3_out;
logic [4:0] EXMem_regD_out;
logic [1:0] EXMem_op_out;
logic [2:0] EXMem_op2_out;
logic [5:0] EXMem_op3_out;
logic [63:0] EXMem_valD_out;
logic [63:0] Mem_alures_out;
logic [31:0] Mem_load_data_out;
logic [4:0] Mem_regD_out;
logic [1:0] Mem_op_out;
logic [2:0] Mem_op2_out;
logic [5:0] Mem_op3_out;
logic mem_ready;
logic dc_req;
logic [2:0] dc_word_select;
logic [2:0] dc_byte_offset;
logic [1:0] store_type;
logic [57:0] dc_line_addr;	
logic [63:0] dc_data_to_cache;
logic dc_read_write_n;
logic dc_ack;
logic [63:0] dc_data_from_cache;
logic dc_reqcyc_out;
logic [63:0] dc_req_out;
logic [12:0] dc_reqtag_out;
logic dc_reqack_in;
logic dc_respack_out;
logic annul;

logic [63:0] MemWB_alures_out;
logic [63:0] MemWB_load_data_out;
logic [4:0] MemWB_regD_out;
logic [1:0] MemWB_op_out;
logic [2:0] MemWB_op2_out;
logic [5:0] MemWB_op3_out;
logic WB_reg_en;
logic [31:0] WB_data_out;
logic [4:0] WB_regD_out;

//NextInstruction #(64) nextinst (.clk(clk), .reset(reset), .ni_PCplus4_in(next_inst), .entry(entry), .NI_PC_out(inst), .target(EXMem_target_out), .mux_en(EXMem_mux_sel_out), .if_ready(if_ready), .nPC_out(nPC_out), .nPC_in(nPC_out));
//$display("target = %d", target);
nPC npc (.clk(clk), .reset(reset), .target(EX_target_out), .mux_en(EX_mux_sel_out), .entry(entry), .if_ready(if_ready), .nPC_out(nPC_out), .nPC_in(nPC_out));

PC pc (.clk(clk), .reset(reset), .PC_in(nPC_out), .PC_out(inst), .if_ready(if_ready));

InstructionFetch ifstage (.clk(clk), .reset(reset), .target(inst), .IF_PCplus4_out(next_inst), .ic_ack(ic_ack), .ic_req(ic_req), .ic_line_addr(ic_line_addr), .ic_word_select(ic_word_select), .id_ready(id_ready), .ic_data_out(ic_data_out), .inst(if_inst_out), .entry(entry), .if_ready(if_ready)); 

  // implement your processor here...
  // IF stage - Instantiate the IF stage

//ICacheDirectMap #(64, 13, 4, 4, 58, 4) i_cache (.clk(clk), .reset(reset), .proc_ack(ic_ack), .proc_data_out(ic_data_out), .proc_req(ic_req), .proc_line_addr(ic_line_addr), .proc_word_select(ic_word_select), .bus_reqcyc(Core.bus_reqcyc), .bus_respack(Core.bus_respack), .bus_req(Core.bus_req), .bus_reqtag(Core.bus_reqtag), .bus_respcyc(Core.bus_respcyc), .bus_reqack(Core.bus_reqack), .bus_resp(Core.bus_resp), .bus_resptag(Core.bus_resptag));
ICacheDirectMap #(64, 13, 4, 4, 58, 4) i_cache (.clk(clk), .reset(reset), .proc_ack(ic_ack), .proc_data_out(ic_data_out), .proc_req(ic_req), .proc_line_addr(ic_line_addr), .proc_word_select(ic_word_select), .bus_reqcyc(ic_reqcyc_out), .bus_respack(ic_respack_out), .bus_req(ic_req_out), .bus_reqtag(ic_reqtag_out), .bus_respcyc(Core.bus_respcyc), .bus_reqack(ic_reqack_in), .bus_resp(Core.bus_resp), .bus_resptag(Core.bus_resptag));

IFIDReg #(64, 32) ifidpipeline (.clk(clk), .reset(reset), .IFID_PCplus4_in(next_inst), .inst(if_inst_out), .IFID_PCplus4_out(IFID_PCplus4_out), .inst_decode(inst_decode), .id_ready(id_ready));

logic [3:0] ID_icc_out;
logic ID_icc_write_out, ID_Y_write_out;
logic [31:0] ID_Y_out;
InstructionDecode #(64, 32) idstage (.clk(clk), .reset(reset), .ID_PCplus4_in(IFID_PCplus4_out), .inst(inst_decode), .id_ready(id_ready), .ID_PCplus4_out(ID_PCplus4_out), .valA(valA), .valB(valB), .a(a), .op3(op3), .i(i), .imm13(imm13), .disp22(disp22), .op(op), .cond(cond), .op2(op2), .rd(rd), .disp30(disp30), .ex_ready(ex_ready), .valD(valD), .WB_reg_en(WB_reg_en), .WB_data_out(WB_data_out), .WB_regD_out(WB_regD_out), .IDEX_rd_out(EX_p_regD_out), .EXMem_regD_out(Mem_p_regD_out), .MemWB_regD_out(WB_regD_out), .IDEX_regWrite(EX_p_regWrite_out), .EXMem_regWrite(Mem_p_regWrite_out), .MemWB_regWrite(WB_reg_en), .ID_regWrite_out(ID_regWrite_out), .ID_regWriteDouble_out(ID_regWriteDouble_out), .IDEX_regWriteDouble(EX_p_regWriteDouble_out), .EXMem_regWriteDouble(Mem_p_regWriteDouble_out), .MemWB_regWriteDouble(MemWB_regWriteDouble_out), .ID_icc_out(ID_icc_out), .ID_icc_write_out(ID_icc_write_out), .IDEX_icc_write(EX_p_iccWrite_out), .EXMem_icc_write(Mem_p_iccWrite_out), .Y_out(ID_Y_out), .ID_Y_write_out(ID_Y_write_out), .IDEX_Y_write(EX_p_yWrite_out), .EXMem_Y_write(Mem_p_yWrite_out), .ID_icc_in(WB_icc_out), .ID_icc_en(WB_icc_en), .Y_en(WB_Y_en), .WB_regDouble_en(WB_regDouble_en));
/*	input cwp_inc,
	input cwp_dec,
	input et_inc,
	input et_dec,
*/

logic IDEX_regWrite_out;
logic IDEX_regWriteDouble_out;
logic [3:0] IDEX_icc_out;
logic IDEX_icc_write_out, IDEX_Y_write_out;
logic [31:0] IDEX_Y_out;
IDEXReg #(64, 32) idexpipeline (.clk(clk), .reset(reset), .IDEX_PCplus4_in(ID_PCplus4_out), .IDEX_valA_in(valA), .IDEX_valB_in(valB), .IDEX_a_in(a), .IDEX_op3_in(op3), .IDEX_i_in(i), .IDEX_imm13_in(imm13), .IDEX_disp22_in(disp22), .IDEX_op_in(op), .IDEX_cond_in(cond), .IDEX_op2_in(op2), .IDEX_rd_in(rd), .IDEX_disp30_in(disp30), .IDEX_PCplus4_out(IDEX_PC_out), .IDEX_valA_out(IDEX_valA_out), .IDEX_valB_out(IDEX_valB_out), .IDEX_a_out(IDEX_a_out), .IDEX_op3_out(IDEX_op3_out), .IDEX_i_out(IDEX_i_out), .IDEX_imm13_out(IDEX_imm13_out), .IDEX_disp22_out(IDEX_disp22_out), .IDEX_op_out(IDEX_op_out), .IDEX_cond_out(IDEX_cond_out), .IDEX_op2_out(IDEX_op2_out), .IDEX_rd_out(IDEX_rd_out), .IDEX_disp30_out(IDEX_disp30_out), .IDEX_valD_in(valD), .IDEX_valD_out(IDEX_valD_out), .IDEX_regWrite_in(ID_regWrite_out), .IDEX_regWrite_out(IDEX_regWrite_out), .IDEX_regWriteDouble_in(ID_regWriteDouble_out), .IDEX_regWriteDouble_out(IDEX_regWriteDouble_out), .ex_ready(ex_ready), .IDEX_icc_in(ID_icc_out), .IDEX_icc_out(IDEX_icc_out), .IDEX_icc_write_in(ID_icc_write_out), .IDEX_icc_write_out(IDEX_icc_write_out), .IDEX_Y_in(ID_Y_out), .IDEX_Y_out(IDEX_Y_out), .IDEX_Y_write_in(ID_Y_write_out), .IDEX_Y_write_out(IDEX_Y_write_out));


logic EX_regWrite_out;
logic EX_regWriteDouble_out;
logic [3:0] EX_icc_out;
logic EX_icc_write_out, EX_p_iccWrite_out, EX_Y_write_out, EX_p_yWrite_out;
logic [31:0] EX_Y_out;
Execute execute (.clk(clk), .reset(reset), .EX_PC_in(IDEX_PC_out), .EX_valA_in(IDEX_valA_out), .EX_valB_in(IDEX_valB_out), .EX_a_in(IDEX_a_out), .EX_op3_in(IDEX_op3_out), .EX_i_in(IDEX_i_out), .EX_imm13_in(IDEX_imm13_out), .EX_disp22_in(IDEX_disp22_out), .EX_op_in(IDEX_op_out), .EX_cond_in(IDEX_cond_out), .EX_op2_in(IDEX_op2_out), .EX_rd_in(IDEX_rd_out), .EX_disp30_in(IDEX_disp30_out), .EX_target_out(EX_target_out), .EX_mux_sel_out(EX_mux_sel_out), .ex_ready(ex_ready), .mem_ready(mem_ready), .EX_alures_out(EX_alures_out), .EX_regD_out(EX_regD_out), .EX_op_out(EX_op_out), .EX_op2_out(EX_op2_out), .EX_op3_out(EX_op3_out), .EX_valD_in(IDEX_valD_out), .EX_valD_out(EX_valD_out), .annul_out(annul), .EX_regWrite_in(IDEX_regWrite_out), .EX_regWrite_out(EX_regWrite_out), .EX_regWriteDouble_in(IDEX_regWriteDouble_out), .EX_regWriteDouble_out(EX_regWriteDouble_out), .EX_p_regD_out(EX_p_regD_out), .EX_p_regWrite_out(EX_p_regWrite_out), .EX_p_regWriteDouble_out(EX_p_regWriteDouble_out), .EX_icc_in(IDEX_icc_out), .EX_icc_out(EX_icc_out), .EX_icc_write_in(IDEX_icc_write_out), .EX_icc_write_out(EX_icc_write_out), .EX_p_iccWrite_out(EX_p_iccWrite_out), .EX_Y_in(IDEX_Y_out), .EX_Y_out(EX_Y_out), .EX_Y_write_in(IDEX_Y_write_out), .EX_Y_write_out(EX_Y_write_out), .EX_p_yWrite_out(EX_p_yWrite_out)); 

	logic [4:0] EX_p_regD_out;
	logic  EX_p_regWrite_out;
	logic EX_p_regWriteDouble_out, EX_p_icc_write;
logic EXMem_regWrite_out;
logic EXMem_regWriteDouble_out;
logic [3:0] EXMem_icc_out;
logic EXMem_icc_write_out, EXMem_Y_write_out;
logic [31:0] EXMem_Y_out;
EXMemReg exmempipeline (.clk(clk), .reset(reset), .EXMem_target_in(EX_target_out), .EXMem_mux_sel_in(EX_mux_sel_out), .EXMem_target_out(EXMem_target_out), .EXMem_mux_sel_out(EXMem_mux_sel_out), .EXMem_alures_in(EX_alures_out), .EXMem_alures_out(EXMem_alures_out), .EXMem_regD_in(EX_regD_out), .EXMem_op_in(EX_op_out), .EXMem_op2_in(EX_op2_out), .EXMem_op3_in(EX_op3_out), .EXMem_regD_out(EXMem_regD_out), .EXMem_op_out(EXMem_op_out), .EXMem_op2_out(EXMem_op2_out), .EXMem_op3_out(EXMem_op3_out), .EXMem_valD_in(EX_valD_out), .EXMem_valD_out(EXMem_valD_out), .EXMem_regWrite_in(EX_regWrite_out), .EXMem_regWrite_out(EXMem_regWrite_out), .EXMem_regWriteDouble_in(EX_regWriteDouble_out), .EXMem_regWriteDouble_out(EXMem_regWriteDouble_out), .mem_ready(mem_ready), .EXMem_icc_in(EX_icc_out), .EXMem_icc_out(EXMem_icc_out), .EXMem_icc_write_in(EX_icc_write_out), .EXMem_icc_write_out(EXMem_icc_write_out), .EXMem_Y_in(EX_Y_out), .EXMem_Y_out(EXMem_Y_out), .EXMem_Y_write_in(EX_Y_write_out), .EXMem_Y_write_out(EXMem_Y_write_out));
/*
*/
Arbiter arbiter (.clk(clk), .reset(reset), .ic_reqcyc(ic_reqcyc_out), .ic_req(ic_req_out), .ic_reqtag(ic_reqtag_out), .bus_reqcyc(Core.bus_reqcyc), .bus_req(Core.bus_req), .bus_reqtag(Core.bus_reqtag), .bus_reqack(Core.bus_reqack), .ic_reqack(ic_reqack_in), .ic_respack(ic_respack_out), .bus_respack(Core.bus_respack), .dc_reqcyc(dc_reqcyc_out), .dc_req(dc_req_out), .dc_reqtag(dc_reqtag_out), .dc_reqack(dc_reqack_in), .dc_respack(dc_respack_out));


logic Mem_regWrite_out;
logic Mem_regWriteDouble_out;
logic [4:0] Mem_p_regD_out;
logic  Mem_p_regWrite_out;
logic Mem_p_regWriteDouble_out;
logic [3:0] Mem_icc_out;
logic Mem_icc_write_out, Mem_p_iccWrite_out, Mem_Y_write_out, Mem_p_yWrite_out;
logic [31:0] Mem_Y_out, MemWB_Y_out;
Mem mem ( .clk(clk), .reset(reset), .mem_ready(mem_ready), .Mem_regD_in(EXMem_regD_out), .Mem_alures_in(EXMem_alures_out), .Mem_op_in(EXMem_op_out), .Mem_op2_in(EXMem_op2_out), .Mem_op3_in(EXMem_op3_out), .Mem_alures_out(Mem_alures_out), .Mem_load_data_out(Mem_load_data_out), .Mem_regD_out(Mem_regD_out), .Mem_op_out(Mem_op_out), .Mem_op2_out(Mem_op2_out), .Mem_op3_out(Mem_op3_out), .Mem_valD_in(EXMem_valD_out), .dc_req(dc_req), .dc_line_addr(dc_line_addr), .dc_word_select(dc_word_select), .dc_data_to_cache(dc_data_to_cache), .dc_read_write_n(dc_read_write_n), .dc_ack(dc_ack), .dc_data_from_cache(dc_data_from_cache), .Mem_regWrite_in(EXMem_regWrite_out), .Mem_regWrite_out(Mem_regWrite_out), .dc_byte_offset(dc_byte_offset), .store_type(store_type), .Mem_regWriteDouble_in(EXMem_regWriteDouble_out), .Mem_regWriteDouble_out(Mem_regWriteDouble_out), .Mem_p_regD_out(Mem_p_regD_out), .Mem_p_regWrite_out(Mem_p_regWrite_out), .Mem_p_regWriteDouble_out(Mem_p_regWriteDouble_out), .Mem_icc_in(EXMem_icc_out), .Mem_icc_out(Mem_icc_out), .Mem_icc_write_in(EXMem_icc_write_out), .Mem_icc_write_out(Mem_icc_write_out), .Mem_p_iccWrite_out(Mem_p_iccWrite_out), .Mem_Y_in(EXMem_Y_out), .Mem_Y_out(Mem_Y_out), .Mem_Y_write_in(EXMem_Y_write_out), .Mem_Y_write_out(Mem_Y_write_out), .Mem_p_yWrite_out(Mem_p_yWrite_out));


DCacheDirectMap #(64, 13, 8, 3, 58, 4) dcache ( .clk(clk), .reset(reset), .proc_ack(dc_ack), .proc_data_out(dc_data_from_cache), .proc_req(dc_req), .proc_line_addr(dc_line_addr), .proc_word_select(dc_word_select), .proc_read_write_n(dc_read_write_n), .proc_data_in(dc_data_to_cache), .bus_reqcyc(dc_reqcyc_out), .bus_respack(dc_respack_out), .bus_req(dc_req_out), .bus_reqtag(dc_reqtag_out), .bus_respcyc(Core.bus_respcyc), .bus_reqack(dc_reqack_in), .bus_resp(Core.bus_resp), .bus_resptag(Core.bus_resptag), .proc_byte_offset(dc_byte_offset), .store_type(store_type));


logic MemWB_regWrite_out;
logic MemWB_regWriteDouble_out;
logic MemWB_icc_n_out, MemWB_icc_z_out, MemWB_icc_v_out, MemWB_icc_c_out;
logic [3:0] MemWB_icc_out;
logic MemWB_icc_write_out, MemWB_Y_write_out;
MemWBReg memwbreg ( .clk(clk), .reset(reset), .MemWB_alures_in(Mem_alures_out), .MemWB_load_data_in(Mem_load_data_out), .MemWB_regD_in(Mem_regD_out), .MemWB_op_in(Mem_op_out), .MemWB_op2_in(Mem_op2_out), .MemWB_op3_in(Mem_op3_out), .MemWB_alures_out(MemWB_alures_out), .MemWB_load_data_out(MemWB_load_data_out), .MemWB_regD_out(MemWB_regD_out), .MemWB_op_out(MemWB_op_out), .MemWB_op2_out(MemWB_op2_out), .MemWB_op3_out(MemWB_op3_out), .MemWB_regWrite_in(Mem_regWrite_out), .MemWB_regWrite_out(MemWB_regWrite_out), .MemWB_regWriteDouble_in(Mem_regWriteDouble_out), .MemWB_regWriteDouble_out(MemWB_regWriteDouble_out), .MemWB_icc_in(Mem_icc_out), .MemWB_icc_out(MemWB_icc_out), .MemWB_icc_write_in(Mem_icc_write_out), .MemWB_icc_write_out(MemWB_icc_write_out), .MemWB_Y_in(Mem_Y_out), .MemWB_Y_out(MemWB_Y_out), .MemWB_Y_write_in(Mem_Y_write_out), .MemWB_Y_write_out(MemWB_Y_write_out));

logic WB_Y_en, WB_icc_en, WB_regDouble_en;  
logic [3:0] WB_icc_out;
WB wb ( .clk(clk), .reset(reset), .WB_alures_in(MemWB_alures_out), .WB_load_data_in(MemWB_load_data_out), .WB_regD_in(MemWB_regD_out), .WB_op_in(MemWB_op_out), .WB_op2_in(MemWB_op2_out), .WB_op3_in(MemWB_op3_out), .WB_data_out(WB_data_out), .WB_regD_out(WB_regD_out), .WB_reg_en(WB_reg_en), .WB_regWrite_in(MemWB_regWrite_out), .WB_regWriteDouble_in(MemWB_regWriteDouble_out), .WB_icc_in(MemWB_icc_out), .WB_icc_out(WB_icc_out), .WB_icc_write_in(MemWB_icc_write_out), .WB_icc_en(WB_icc_en), .WB_Y_write_in(MemWB_Y_write_out), .WB_Y_en(WB_Y_en), .WB_regDouble_en(WB_regDouble_en));	

endmodule
