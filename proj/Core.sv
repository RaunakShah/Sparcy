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
logic [63:0] next_inst; // pc + 4
logic ic_req; //
logic [57:0] ic_line_addr;//
logic [3:0] ic_word_select; //
logic [31:0] ic_data_out;
logic ic_ack; //

logic [63:0] PCplus4_decode; // pc + 4
logic [31:0] inst_decode;
	logic [63:0] in_PCplus4;
	logic [31:0] inst;
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


InstructionDecode #(64, 32) idstage (.clk(clk), .reset(reset), .in_PCplus4(PCplus4_decode), .inst(inst_decode), .if_write(if_write), .id_read(id_read), .out_PCplus4(PCplus4_exe), .valA(valA), .valB(valB), .a(a), .op3(op3), .i(i), .imm13(imm13), .disp22(disp22), .op(op), .cond(cond), .op2(op2), .rd(rd), .disp30(disp30));

assign target = reset?0:entry;
//$display("target = %d", target);
InstructionFetch ifstage (.clk(clk), .reset(reset), .target(target), .PCplus4(next_inst), .ic_ack(ic_ack), .ic_req(ic_req), .ic_line_addr(ic_line_addr), .ic_word_select(ic_word_select), .if_write (if_write), .id_read(id_read), .ic_data_out(ic_data_out)); 

  // implement your processor here...
  // IF stage - Instantiate the IF stage

ICacheDirectMap #(64, 13, 4, 4, 58, 4) i_cache (.clk(clk), .reset(reset), .proc_ack(ic_ack), .proc_data_out(ic_data_out), .proc_req(ic_req), .proc_line_addr(ic_line_addr), .proc_word_select(ic_word_select), .bus_reqcyc(Core.bus_reqcyc), .bus_respack(Core.bus_respack), .bus_req(Core.bus_req), .bus_reqtag(Core.bus_reqtag), .bus_respcyc(Core.bus_respcyc), .bus_reqack(Core.bus_reqack), .bus_resp(Core.bus_resp), .bus_resptag(Core.bus_resptag));


IFIDReg #(64, 32) ifidpipeline (.clk(clk), .reset(reset), .PCplus4(next_inst), .inst(ic_data_out), .PCplus4_decode(PCplus4_decode), .inst_decode(inst_decode));

endmodule
