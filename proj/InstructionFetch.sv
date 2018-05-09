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
	output if_ready
);
	logic [63:0] n_pc, p_pc;//_from_mux, p_pc_from_mux, // also pc into PC
	logic n_ic_req, p_ic_req;
	logic [31:0] p_inst, n_inst;
logic n_b, p_b;
logic [2:0] n_counter, p_counter;
  enum { STATEA=2'b00, STATEB=2'b01, STATEC=2'b10, STATES=2'b11} n_state, p_state; 
// instruction cache
// IF/ID pipeline register
// to stall for branches: in predecode, if branch, stall in state a for 6 cycles before accepting input 

// stall on branch algorithm:
// before going to A, if branch, goto S
// in first cycle, output, then bubble
// maybe need to change output logic to 


// next state logic
always_comb begin
	n_ic_req = p_ic_req;
	n_inst = p_inst;
	n_counter = 0;
	n_b = p_b;
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
			//$display("next instruction to cache: %ld", n_pc);
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
					// check if branch/call/jump
					if ((p_inst[31:30] == 2'b00  && p_inst[24:22] == 3'b010) || (p_inst[31:30] == 2'b01) || (p_inst[31:30] == 2'b10 && p_inst[24:19] == 6'b111000))
						n_b = 1;
					else
						n_b = 0;
					if (p_b == 1)
						n_state = STATES;
					//	n_state = STATEA;
					else begin
						n_state = STATEA;	
					end
					//n_state = STATES;	
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
			else begin
				// check if branch/call/jump
				if ((p_inst[31:30] == 2'b00  && p_inst[24:22] == 3'b010) || (p_inst[31:30] == 2'b01) || (p_inst[31:30] == 2'b10 && p_inst[24:19] == 6'b111000)) 
					n_b = 1;
				else
					n_b = 0;
				if (p_b == 1)
					n_state = STATES;
					//n_state = STATEA;
				else begin
					n_state = STATEA;
				end
			
			end
			end
		STATES: begin
			// stall for one cycle before going to A
			n_pc = p_pc;
			n_counter = p_counter + 1;
		//	if (p_counter == 0) begin
		//		n_inst = 32'h01000000;
		//		n_state = STATES;
		//	end
		//	else begin
				n_state = STATEA;
		//	end
			end
	endcase
end  

// register
always_ff @(posedge clk, negedge clk) begin
	if (reset) begin
		p_pc <= 0;
		p_state <= STATEA;
		p_ic_req <= 0;
		p_inst <= 32'h01000000;
		p_counter <= 0;
		p_b <= 0;
	end
	else begin
		if (!clk) begin
			if (/*n_ic_req &&*/ ic_ack) begin
				p_ic_req <= 0;
			end
			else begin 
				p_ic_req <= n_ic_req;
			end
		end
		else begin
			p_counter <= n_counter;
			p_ic_req <= n_ic_req;
			p_pc <= n_pc;
			p_state <= n_state;
			p_inst <= n_inst;
			p_b <= n_b;
		end
	end
end

always_comb begin
	ic_req = p_ic_req;
	ic_line_addr = {44'h00000000000, n_pc[19:6]};//n_pc[63:6];
	ic_word_select = n_pc[5:2];	
	case (p_state)
		STATEA: begin
			IF_PCplus4_out = p_pc;
			inst = p_inst;
			$display("PC: %h", p_pc);
			$display("inst: %h", p_inst);
			if_ready = 1;
			end
		STATES: begin
			IF_PCplus4_out = p_pc;//0;
			inst = 32'h01000000;//p_inst;
			if_ready = 0;
			end
		default: begin
			IF_PCplus4_out = p_pc;
			inst = 32'h01000000;
			if_ready = 0;
			end
	endcase
end
endmodule    
    
    
