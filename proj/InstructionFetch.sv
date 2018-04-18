/**
 * Instruction fetch phase
 */

// NOTE: changing stall state of stateb
// add ready state from decode to fetch
// need to add a ready output going backwards to mux, to stall fetching of instruction if ifstage is not in state a

module InstructionFetch
#(
  // bus parameters
  BUS_DATA_WIDTH = 64,
  BUS_TAG_WIDTH = 13
)
(
	input clk, reset,
	input [63:0] target,
	input id_ready,
	input id_stall,	
	input [63:0] entry,
	output [31:0] inst,
	output [63:0] IF_PCplus4_out,
	input logic ic_ack,
	input [31:0] ic_data_out,
	output logic ic_req, 
	output [57:0] ic_line_addr,
	output [3:0] ic_word_select,
	output if_write
);
	logic [63:0] n_pc, p_pc;//_from_mux, p_pc_from_mux, // also pc into PC
	logic n_ic_req, p_ic_req;
	logic [31:0] p_inst, n_inst;
  enum { STATEA=2'b00, STATEB=2'b01, STATEC=2'b10, STATED=2'b11} n_state, p_state; 
// instruction cache
// IF/ID pipeline register

// next state logic
always_comb begin
	n_ic_req = p_ic_req;
	n_inst = p_inst;
	case (p_state)
		STATEA: begin
//			n_pc = p_pc+4;
			n_pc = target;
			if (n_pc == p_pc && n_pc != 0) begin
				n_state = STATEA;
				n_ic_req = 0;
				n_inst = 32'h01000000;
			end
			else begin
				n_state = STATEB;
				n_ic_req = 1;
			end
			end
		STATEB: begin
			// create inputs for instruction cache
			// if ack from cache - set output data, goto statea
			//n_pc_from_mux = p_pc_from_mux;
			n_pc = p_pc;
			if (ic_ack) begin
				n_ic_req = 0;
				n_inst = ic_data_out;
				n_state = STATEA;

				if (id_ready == 0) begin
					n_state = STATEC;
				end
				else begin
					n_state = STATEA;	
				end
			end
			else begin
				n_state = STATEB;
			end
			end
		STATEC: begin
			n_pc = p_pc;
			if (id_ready == 0) 
				n_state = STATEC;
			else
				n_state = STATEA;
			end
	endcase
end  

// register
always_ff @(posedge clk, negedge clk) begin
	if (reset) begin
		p_pc <= entry;
		p_state <= STATEA;
		p_ic_req <= 0;
		p_inst <= 32'h01000000;
	end
	else begin
		if (!clk) begin
			if (n_ic_req && ic_ack) begin
				p_ic_req <= 0;
			end
			else begin 
				p_ic_req <= n_ic_req;
			end
		end
		else begin
			p_ic_req <= n_ic_req;
			p_pc <= n_pc;
			p_state <= n_state;
			p_inst <= n_inst;
		end
	end
end

always_comb begin
	ic_req = p_ic_req;
	ic_line_addr = p_pc[63:6];
	ic_word_select = p_pc[5:2];	
	IF_PCplus4_out = p_pc;
	case (p_state)
		STATEA: begin
			inst = p_inst;
			end
		default: begin
//			IF_PCplus4_out = 64'hffffffffffffffff;
			inst = 32'h01000000; // stall for now
			end
	endcase
end
//assign inst = (ic_ack)?ic_data_out:0;
//assign PCplus4 = (ic_ack)?p_pc_from_mux:0;
//assign PCplus4 = (ic_ack || p_state == STATES)?(p_pc + 4):64'hffffffff;
endmodule    
    
    
