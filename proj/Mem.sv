module Mem

(
	input clk, reset,
	input [4:0] Mem_regD_in,
	input [63:0] Mem_alures_in,
	input [1:0] Mem_op_in,
	input [2:0] Mem_op2_in,
	input [5:0] Mem_op3_in,
	output [63:0] Mem_alures_out,
	output [63:0] Mem_load_data_out,
	output [4:0] Mem_regD_out,
	output [1:0] Mem_op_out,
	output [2:0] Mem_op2_out,
	output [5:0] Mem_op3_out,
	output mem_ready,
	output dc_req,
	output [57:0] dc_line_addr,
	output [3:0] dc_word_select,
	output [63:0] dc_data_to_cache, // 63 because of load/store double words
	output dc_read_write_n,
	input dc_ack,
	input [63:0] dc_data_from_cache,
	input [31:0] Mem_valD_in
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
logic n_dc_req, p_dc_req;
logic [57:0] n_dc_line_addr, p_dc_line_addr;
logic [3:0] n_dc_word_select, p_dc_word_select;
logic n_dc_read_write_n, p_dc_read_write_n;
logic n_mem_ready, p_mem_ready;
logic [63:0] n_alures, p_alures;
logic [63:0] n_load_data, p_load_data;
logic [1:0] n_op, p_op;
logic [2:0] n_op2, p_op2;
logic [5:0] n_op3, p_op3; 
logic [63:0] n_dc_data_to_cache, p_dc_data_to_cache;
logic [4:0] n_regd, p_regd;


always_comb begin
	n_dc_line_addr = p_dc_line_addr;//Mem_alures_in[63:6];
	n_dc_word_select = p_dc_word_select;//Mem_alures_in[:2];
	n_dc_data_to_cache = p_dc_data_to_cache;//5'b11111;// rd value  
	n_dc_read_write_n = p_dc_read_write_n;//0;// if store
	n_mem_ready = p_mem_ready;//0;
	case (p_state) // NOTE: only needs to go to b if load or store.
		STATEA: begin
			if (Mem_op_in == 2'b01) begin // NOTE: change to load only later
				//$display("request for %d", Mem_alures_in);
				//$display("mem: state a to b");
				// load/store op
				n_state = STATEB;
				n_dc_req = 1;
				n_dc_line_addr = Mem_alures_in[63:6];
				n_dc_word_select = Mem_alures_in[5:2];
				n_dc_data_to_cache = Mem_valD_in;// rd value  
				n_dc_read_write_n = 1;// if store, 0
				n_mem_ready = 0;
				n_alures = Mem_alures_in;
				n_load_data = 0;
				n_op = Mem_op_in;
				n_op2 = Mem_op2_in;
				n_op3 = Mem_op3_in;
				n_regd = Mem_regD_in;
			end
			else begin
				n_state = STATEA;
				//$display("mem: state a to a");
				n_dc_req = 0;
				n_dc_line_addr = Mem_alures_in[63:6];
				n_dc_word_select = Mem_alures_in[5:2];
				n_dc_data_to_cache = 5'b11111;// rd value  
				n_dc_read_write_n = 1;// if store
				n_mem_ready = 1;
				n_alures = Mem_alures_in;
				n_load_data = 0;
				n_regd = Mem_regD_in;
				n_op = Mem_op_in;
				n_op2 = Mem_op2_in;
				n_op3 = Mem_op3_in;
			end
			end
		STATEB: begin
			n_alures = p_alures; //Mem_alures_in;
			n_load_data = p_load_data;
			n_regd = p_regd; //Mem_regD_in;
			n_op = p_op; //Mem_op_in;
			n_op2 = p_op2;//Mem_op2_in;
			n_op3 = p_op3;//Mem_op3_in;
			if (dc_ack) begin
				n_dc_req = 0;
				n_load_data = dc_data_from_cache;
				n_mem_ready = 1;
				n_state = STATEA;
				//$display("mem: state b to a");
			end
			else begin
				n_dc_req = 1;
				n_mem_ready = 0;
				n_state = STATEB;
				//$display("mem: state b to b");
			end
			end
	endcase
end

always_ff @(posedge clk, negedge clk) begin
	if (reset) begin
		p_state <= STATEA;
		p_load_data <= 0;//n_load_data; 
		p_alures <= 0;//n_alures; 
		p_regd <= 5'b00000;//n_regd ;
		p_op <= 2'b00;//n_op ;
		p_op2 <= 3'b100;//n_op2; 
		p_op3 <= 0;//n_op3;
		p_dc_line_addr <= 0;//n_dc_line_addr ;
		p_dc_word_select <= 0;//n_dc_word_select; 
		p_dc_data_to_cache <= 0;//n_dc_data_to_cache; 
		p_dc_read_write_n <= 1;//n_dc_read_write_n; 
		p_mem_ready <= 1;//n_mem_ready;
		p_dc_req <= 0;
	end
	else begin
		if (!clk) begin
			if (n_dc_req && dc_ack) begin
				p_dc_req <= 0;
			end
			else begin 
				p_dc_req <= n_dc_req;
			end
		end
		else begin
		p_state <= n_state;
		p_load_data <= n_load_data; 
		p_alures <= n_alures; 
		p_regd <= n_regd ;
		p_op <= n_op ;
		p_op2 <= n_op2; 
		p_op3 <= n_op3;
		p_dc_line_addr <= n_dc_line_addr ;
		p_dc_word_select <= n_dc_word_select; 
		p_dc_data_to_cache <= n_dc_data_to_cache; 
		p_dc_read_write_n <= n_dc_read_write_n; 
		p_mem_ready <= n_mem_ready;
		p_dc_req <= n_dc_req;
		end
	end
end



always_comb begin
	dc_req = p_dc_req;
	dc_line_addr = p_dc_line_addr;
	dc_word_select = p_dc_word_select;
	dc_data_to_cache = p_dc_data_to_cache;
	dc_read_write_n = p_dc_read_write_n;
	case (p_state)
		STATEA: begin
			Mem_alures_out = p_alures;
			Mem_load_data_out = p_load_data;
			Mem_regD_out = p_regd;
	 		Mem_op_out = p_op;
	 		Mem_op2_out = p_op2;
 			Mem_op3_out = p_op3;
			mem_ready = p_mem_ready;
			end
		STATEB: begin
			Mem_alures_out = p_alures;
			Mem_load_data_out = p_load_data;
			Mem_regD_out = 5'b00000;
	 		Mem_op_out = 2'b00;
	 		Mem_op2_out = 3'b100;
 			Mem_op3_out = p_op3;
			mem_ready = p_mem_ready;
			end
	endcase

end
endmodule		
