/**
 * Instruction fetch phase
 */

// NOTE: changing stall state of stateb
// add ready state from decode to fetch
// in state b1 - resetting cache_req on stall. stall goes back to state a and restarts same request. will have to see if thats acceptable long term -- does the cache bring it in from memory?
// need to add a ready output going backwards to mux, to stall fetching of instruction if ifstage is not in state a

module InstructionFetch
#(
  // bus parameters
  BUS_DATA_WIDTH = 64,
  BUS_TAG_WIDTH = 13
)
(
	// inputs to mux
	input clk, reset,
	input [63:0] target,
	input id_read,
	input id_stall,	
	//logic [63:0] PCplus4_to_mux,
	//input mux_sel,
	// output of mux -- used within the module -- input to PC
	output [63:0] inst,
	output [63:0] IF_PCplus4_out,
	input logic ic_ack,
	input [63:0] ic_data_out,
	output logic ic_req, 
	output [57:0] ic_line_addr,
	output [3:0] ic_word_select,
	output if_write
  /*output ic_bus_reqcyc,
  output ic_bus_respack,
  output [BUS_DATA_WIDTH-1:0] ic_bus_req,
  output [BUS_TAG_WIDTH-1:0] ic_bus_reqtag,
  input  ic_bus_respcyc,
  input  ic_bus_reqack,
  input  [BUS_DATA_WIDTH-1:0] ic_bus_resp,
  input  [BUS_TAG_WIDTH-1:0] ic_bus_resptag
*/	

);
	logic [63:0] n_pc4, p_pc4;
	logic [63:0] n_pc, p_pc;//_from_mux, p_pc_from_mux, // also pc into PC
	logic n_ic_req, p_ic_req;
	logic [3:0] n_counter, p_counter;
	logic n_write, p_write;
	logic [63:0] p_inst, n_inst;
  enum { STATEA=2'b00, STATEB=2'b01, STATEC=2'b10, STATED=2'b11} n_state, p_state; 
// instruction cache
// IF/ID pipeline register

// next state logic
always_comb begin
	n_ic_req = p_ic_req;
	n_counter = p_counter + 1;
//	PCplus4 = 63'b1000;
	n_pc4 = p_pc4;
	n_inst = p_inst;
	n_write = p_write;
	if (id_read == 0)
		n_write = 0;
	
//	$display("bitches ack = %d", ic_ack);
	case (p_state)
		STATEA: begin
//			n_pc = p_pc4; // need to change to pc4 || target
			n_pc = target;
			if (n_pc == p_pc && n_pc != 0) begin
				//$display("zero");
				n_state = STATEA;
				n_ic_req = 0;
			end
//			PCplus4 = 63'b1111; 
//			$display("state a to b");
		/*	if (mux_sel) begin
				n_pc_from_mux = target;
			end
			else begin
				n_pc_from_mux = p_pc_from_mux + 4;
			end*/
//			if (id_stall) begin
//				n_state = STATES;
//				n_ic_req = 0;
//			end
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
				n_pc4 = p_pc + 4;
				if (id_read == 0) begin
					n_state = STATEC;
				end
				else begin
				n_write = 1;
					n_state = STATED;	
				end
			end
			else begin
				n_state = STATEB;
			end
			end
		STATEC: begin
			n_pc = p_pc;
			if (id_read == 0) begin
				n_state = STATEC;
			end
			else begin
					n_write = 1;
				n_state = STATED;
			end
			end
		STATED: begin
			n_pc = p_pc;
			if (id_read == 0)
				n_write = 0;
			n_state = STATEA;
			end
	endcase
end  

// register
always_ff @(posedge clk, negedge clk) begin
	if (reset) begin
		p_pc <= 0;
		p_state <= STATEA;
		p_ic_req <= 0;
		p_counter <= 0;
		p_pc4 <= 0;
		p_inst <= 0;
		p_write <= 0;
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
			p_counter <= n_counter;
			p_pc4 <= n_pc4;
			p_inst <= n_inst;
			p_write <= n_write;
		end
	end
end

//assign inst = (ic_ack)?ic_data_out:0;
//assign PCplus4 = (ic_ack)?p_pc_from_mux:0;
//assign PCplus4 = (ic_ack || p_state == STATES)?(p_pc + 4):64'hffffffff;
assign IF_PCplus4_out = p_pc;
assign if_write = p_write;
assign inst = p_inst;
assign ic_req = p_ic_req;
assign ic_line_addr = p_pc[63:6];
assign ic_word_select = p_pc[5:2];
endmodule    
    
    
