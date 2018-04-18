module Mem

(
	input [4:0] Mem_regD_in,
	input [31:0] Mem_alures_in,
	input [1:0] Mem_op_in,
	input [2:0] Mem_op2_in,
	input [5:0] Mem_op3_in,
	output [31:0] Mem_alures_out,
	output [31:0] Mem_load_data_out,
	output [4:0] Mem_regD_out,
	output [1:0] Mem_op_out,
	output [2:0] Mem_op2_out,
	output [5:0] Mem_op3_out,
	output mem_ready,
	output id_req,
	output [57:0] id_line_addr,
	output [3:0] id_word_select,
	output [31:0] id_data_to_cache,
	output id_read_write_n,
	input logic ic_ack,
	input [31:0] ic_data_from_cache
);
	

// two states:
// state a: ready to receive next input
// state b: waiting on mem
// 	    should output bubble 
//	    should stall prev stages

// only when output from mem available, output whatever
// else output no op
// because write back is a combinational block. will output same again and again.
enum { STATEA=2'b00, STATEB=2'b01 } n_state, p_state;
logic n_id_req, p_id_req;
always_comb begin
	n_load_data = 00000; // no op
	n_alures = 00000; // no op
	n_regd = 000000; // no op
	n_op = 00000; // no op
	n_op2 = 0000; // no op
	n_op3 = 0000; // no op 
	case (p_state) // note: only needs to go to b if load or store.
		STATEA: begin
			n_state = STATEB;
			n_id_req = 1;
			n_id_line_addr = Mem_alures_in[63:6];
			n_id_word_select = Mem_alures_in[5:2];
			n_id_data_to_cache = // rd value  
			n_id_read_write_n = // if store
			n_mem_ready = 0;
			end
		STATEB: begin
			if (id_ack) begin
				n_id_req = 0;
				n_load_data = id_data_from_cache;
				n_mem_ready = 1;
				n_state = STATEA;
			end
			else begin
				n_id_req = p_id_req;
				n_mem_ready = 0;
				n_state = STATEB;
			end
			end
	endcase
end

always_ff @(posedge clk) begin
	if (reset)
		p_state <= STATEA;
	else
		p_state <= n_state;
end




		
