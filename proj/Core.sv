//`include "Sysbus.defs"

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

logic [63:0] IFID_PCplus4_out; // pc + 4
logic [63:0] ID_PCplus4_out; // pc + 4
logic [63:0] IDEX_PCplus4_out; // pc + 4
logic [31:0] inst_decode;
	logic [63:0] in_PCplus4;
	logic id_stall;
	logic id_read;
	logic if_write;
	logic [64-1:0] out_PCplus4;
	logic [32-1:0] valA, valB;
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



assign target = reset?0:entry;
NextInstruction #(64) nextinst (.clk(clk), .reset(reset), .ni_PCplus4_in(next_inst), .entry(entry), .NI_PC_out(inst), .target(EXMem_target_out), .mux_en(EXMem_mux_sel_out));
//$display("target = %d", target);
InstructionFetch ifstage (.clk(clk), .reset(reset), .target(inst), .IF_PCplus4_out(next_inst), .ic_ack(ic_ack), .ic_req(ic_req), .ic_line_addr(ic_line_addr), .ic_word_select(ic_word_select), .if_write (if_write), .id_read(id_read), .ic_data_out(ic_data_out)); 

  // implement your processor here...
  // IF stage - Instantiate the IF stage

ICacheDirectMap #(64, 13, 4, 4, 58, 4) i_cache (.clk(clk), .reset(reset), .proc_ack(ic_ack), .proc_data_out(ic_data_out), .proc_req(ic_req), .proc_line_addr(ic_line_addr), .proc_word_select(ic_word_select), .bus_reqcyc(Core.bus_reqcyc), .bus_respack(Core.bus_respack), .bus_req(Core.bus_req), .bus_reqtag(Core.bus_reqtag), .bus_respcyc(Core.bus_respcyc), .bus_reqack(Core.bus_reqack), .bus_resp(Core.bus_resp), .bus_resptag(Core.bus_resptag));

IFIDReg #(64, 32) ifidpipeline (.clk(clk), .reset(reset), .IFID_PCplus4_in(next_inst), .inst(ic_data_out), .IFID_PCplus4_out(IFID_PCplus4_out), .inst_decode(inst_decode));

InstructionDecode #(64, 32) idstage (.clk(clk), .reset(reset), .ID_PCplus4_in(IFID_PCplus4_out), .inst(inst_decode), .if_write(if_write), .id_read(id_read), .ID_PCplus4_out(ID_PCplus4_out), .valA(valA), .valB(valB), .a(a), .op3(op3), .i(i), .imm13(imm13), .disp22(disp22), .op(op), .cond(cond), .op2(op2), .rd(rd), .disp30(disp30));

IDEXReg #(64, 32) idexpipeline (.clk(clk), .reset(reset), .IDEX_PCplus4_in(ID_PCplus4_out), .IDEX_valA_in(valA), .IDEX_valB_in(valB), .IDEX_a_in(a), .IDEX_op3_in(op3), .IDEX_i_in(i), .IDEX_imm13_in(imm13), .IDEX_disp22_in(disp22), .IDEX_op_in(op), .IDEX_cond_in(cond), .IDEX_op2_in(op2), .IDEX_rd_in(rd), .IDEX_disp30_in(disp30), .IDEX_PCplus4_out(IDEX_PC_out), .IDEX_valA_out(IDEX_valA_out), .IDEX_valB_out(IDEX_valB_out), .IDEX_a_out(IDEX_a_out), .IDEX_op3_out(IDEX_op3_out), .IDEX_i_out(IDEX_i_out), .IDEX_imm13_out(IDEX_imm13_out), .IDEX_disp22_out(IDEX_disp22_out), .IDEX_op_out(IDEX_op_out), .IDEX_cond_out(IDEX_cond_out), .IDEX_op2_out(IDEX_op2_out), .IDEX_rd_out(IDEX_rd_out), .IDEX_disp30_out(IDEX_disp30_out)); 

Execute execute (.clk(clk), .reset(reset), .EX_PC_in(IDEX_PC_out), .EX_valA_in(IDEX_valA_out), .EX_valB_in(IDEX_valB_out), .EX_a_in(IDEX_a_out), .EX_op3_in(IDEX_op3_out), .EX_i_in(IDEX_i_out), .EX_imm13_in(IDEX_imm13_out), .EX_disp22_in(IDEX_disp22_out), .EX_op_in(IDEX_op_out), .EX_cond_in(IDEX_cond_out), .EX_op2_in(IDEX_op2_out), .EX_rd_in(IDEX_rd_out), .EX_disp30_in(IDEX_disp30_out), .EX_target_out(EX_target_out), .EX_mux_sel_out(EX_mux_sel_out));

EXMemReg exmempipeline (.clk(clk), .reset(reset), .EXMem_target_in(EX_target_out), .EXMem_mux_sel_in(EX_mux_sel_out), .EXMem_target_out(EXMem_target_out), .EXMem_mux_sel_out(EXMem_mux_sel_out));

endmodule
