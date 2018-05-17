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
	output [2:0] dc_word_select,
	output [2:0] dc_byte_offset,
	output [63:0] dc_data_to_cache, // 63 because of load/store double words
	output dc_read_write_n,
	input dc_ack,
	input [63:0] dc_data_from_cache,
	input [63:0] Mem_valD_in,
	input Mem_regWrite_in,
	output Mem_regWrite_out,
	input Mem_regWriteDouble_in,
	output Mem_regWriteDouble_out,
	output [1:0] store_type,
	output [1:0] load_type,
	output [4:0] Mem_p_regD_out,
	output Mem_p_regWrite_out,
	output Mem_p_regWriteDouble_out,
	input [3:0] Mem_icc_in,
	output [3:0] Mem_icc_out,
	input Mem_icc_write_in, Mem_Y_write_in,
	output Mem_icc_write_out, Mem_p_iccWrite_out, Mem_Y_write_out, Mem_p_yWrite_out,
	input [31:0] Mem_Y_in,
	output [31:0] Mem_Y_out
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
logic [2:0] n_dc_word_select, p_dc_word_select;
logic n_dc_read_write_n, p_dc_read_write_n;
logic n_mem_ready, p_mem_ready;
logic [63:0] n_alures, p_alures;
logic [63:0] n_load_data, p_load_data;
logic [1:0] n_op, p_op;
logic [2:0] n_op2, p_op2;
logic [5:0] n_op3, p_op3; 
logic [63:0] n_dc_data_to_cache, p_dc_data_to_cache;
logic [4:0] n_regd, p_regd;
logic n_regWrite, p_regWrite;
logic n_regWriteDouble, p_regWriteDouble;
logic [2:0] n_byte_offset, p_byte_offset;
logic [1:0] n_store_type, p_store_type;
logic [1:0] n_load_type, p_load_type;
logic [3:0] n_icc, p_icc;
logic n_icc_write, p_icc_write, n_y_write, p_y_write;
logic [31:0] n_y, p_y;
always_comb begin
	n_dc_line_addr = p_dc_line_addr;//Mem_alures_in[63:6];
	n_dc_word_select = p_dc_word_select;//Mem_alures_in[:2];
	n_dc_data_to_cache = p_dc_data_to_cache;//5'b11111;// rd value  
	n_dc_read_write_n = p_dc_read_write_n;//0;// if store
	n_mem_ready = p_mem_ready;//0;
	n_byte_offset = p_byte_offset;
	n_store_type = p_store_type;
	n_load_type = p_load_type;
	n_icc_write = p_icc_write;
	n_y = p_y;
	n_y_write = p_y_write;
	case (p_state) // NOTE: only needs to go to b if load or store.
		STATEA: begin
			n_dc_line_addr = {44'h00000000000, Mem_alures_in[19:6]};//Mem_alures_in[63:6];
			n_dc_word_select = Mem_alures_in[5:3];
			n_byte_offset = Mem_alures_in[2:0];
			n_dc_data_to_cache = Mem_valD_in;// rd value  
			n_store_type = store_t(Mem_op3_in);
			n_load_type = load_t(Mem_op3_in);
			n_op = Mem_op_in;
			n_op2 = Mem_op2_in;
			n_op3 = Mem_op3_in;
			n_regd = Mem_regD_in;
			n_regWrite = Mem_regWrite_in;
			n_regWriteDouble = Mem_regWriteDouble_in;
			n_icc = Mem_icc_in;
			n_icc_write = Mem_icc_write_in;
			n_y_write = Mem_Y_write_in;
			n_alures = Mem_alures_in;
			n_load_data = 0;
			n_y = Mem_Y_in;
			if (load_op(Mem_op_in, Mem_op3_in) || store_op(Mem_op_in, Mem_op3_in)) begin 
				// load/store op
				n_state = STATEB;
				n_dc_req = 1;
				if (store_op(Mem_op_in, Mem_op3_in)) begin
					n_dc_read_write_n = 0;// if store or swap, 0
				end
				else
					n_dc_read_write_n = 1;	
				dc_req = 1;
				dc_line_addr = {44'h00000000000, Mem_alures_in[19:6]};//Mem_alures_in[63:6];
				dc_word_select = Mem_alures_in[5:3];
				dc_byte_offset = Mem_alures_in[2:0];
				dc_data_to_cache = Mem_valD_in;// rd value  
				if (Mem_op3_in == `LDSTUB)
					dc_data_to_cache = 64'h1111111111111111;
				store_type = store_t(Mem_op3_in);
				load_type = load_t(Mem_op3_in);
				dc_read_write_n = n_dc_read_write_n;
				Mem_p_regD_out = Mem_regD_in;
				Mem_p_regWrite_out = Mem_regWrite_in;
				Mem_p_regWriteDouble_out = Mem_regWriteDouble_in;
				Mem_p_iccWrite_out = Mem_icc_write_in;
				Mem_p_yWrite_out = Mem_Y_write_in;
				Mem_regWrite_out = Mem_regWrite_in;
				Mem_regWriteDouble_out = Mem_regWriteDouble_in;
				Mem_alures_out = Mem_alures_in;
				Mem_load_data_out = 0;
				Mem_icc_out = Mem_icc_in;
				Mem_icc_write_out = Mem_icc_write_in;
				Mem_Y_out = Mem_Y_in;
				Mem_Y_write_out = Mem_Y_write_in;
				Mem_regD_out = 5'b00000;
				Mem_op_out = 2'b00;
				Mem_op2_out = 3'b100;
				Mem_op3_out = 6'b100000;
				n_mem_ready = 0;
			end
			else begin
				n_state = STATEA;
				//$display("mem: state a to a");
				n_dc_req = 0;
				n_mem_ready = 1;
				n_dc_read_write_n = 1;	
				dc_req = 0;
				dc_line_addr = {44'h00000000000, Mem_alures_in[19:6]};//Mem_alures_in[63:6];
				dc_word_select = Mem_alures_in[5:3];
				dc_byte_offset = Mem_alures_in[2:0];
				dc_data_to_cache = Mem_valD_in;// rd value  
				store_type = store_t(Mem_op3_in);
				load_type = load_t(Mem_op3_in);
				dc_read_write_n = n_dc_read_write_n;
				Mem_p_regD_out = Mem_regD_in;
				Mem_p_regWrite_out = Mem_regWrite_in;
				Mem_p_regWriteDouble_out = Mem_regWriteDouble_in;
				Mem_p_iccWrite_out = Mem_icc_write_in;
				Mem_p_yWrite_out = Mem_Y_write_in;
				Mem_regWrite_out = Mem_regWrite_in;
				Mem_regWriteDouble_out = Mem_regWriteDouble_in;
				Mem_alures_out = Mem_alures_in;
				Mem_load_data_out = 0;
				Mem_icc_out = Mem_icc_in;
				Mem_icc_write_out = Mem_icc_write_in;
				Mem_Y_out = Mem_Y_in;
				Mem_Y_write_out = Mem_Y_write_in;
				Mem_regD_out = Mem_regD_in;
				Mem_op_out = Mem_op_in;
				Mem_op2_out = Mem_op2_in;
				Mem_op3_out = Mem_op3_in;
			end
			end
		STATEB: begin
			n_alures = p_alures; //Mem_alures_in;
			n_load_data = p_load_data;
			n_regd = p_regd; //Mem_regD_in;
			n_op = p_op; //Mem_op_in;
			n_op2 = p_op2;//Mem_op2_in;
			n_op3 = p_op3;//Mem_op3_in;
			n_regWrite = p_regWrite;
			n_regWriteDouble = p_regWriteDouble;
			n_icc = p_icc;
			n_icc_write = p_icc_write;
			n_y_write = p_y_write;
			n_y = p_y;
			Mem_p_regD_out = n_regd;
			Mem_p_regWrite_out = n_regWrite;
			Mem_p_regWriteDouble_out = n_regWriteDouble;
			Mem_p_iccWrite_out = n_icc_write;
			Mem_p_yWrite_out = n_y;
			dc_line_addr = p_dc_line_addr;
			dc_word_select = p_dc_word_select;
			dc_byte_offset = p_byte_offset;
			dc_read_write_n = p_dc_read_write_n;
			store_type = p_store_type;
			load_type = p_load_type;
			Mem_regWrite_out = p_regWrite;
			Mem_regWriteDouble_out = p_regWriteDouble;
			Mem_alures_out = p_alures;
			Mem_load_data_out = dc_data_from_cache;
			Mem_icc_out = p_icc;
			Mem_icc_write_out = p_icc_write;
			Mem_Y_out = p_y;
			Mem_Y_write_out = p_y_write;
			dc_data_to_cache = p_dc_data_to_cache;
			if (dc_ack) begin
				n_dc_req = 0;
				n_load_data = dc_data_from_cache;
				n_mem_ready = 1;
				n_state = STATEA;
				dc_req = 0;
				Mem_regD_out = p_regd;
				Mem_op_out = p_op;
				Mem_op2_out = p_op2;
				Mem_op3_out = p_op3;
				//$display("mem: state b to a");
			end
			else begin
				n_dc_req = 1;
				n_mem_ready = 0;
				n_state = STATEB;
				Mem_regD_out = 5'b00000;
				Mem_op_out = 2'b00;
				Mem_op2_out = 3'b100;
				Mem_op3_out = 6'b100000;
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
		p_op3 <= 6'b100000;//n_op3;
		p_dc_line_addr <= 0;//n_dc_line_addr ;
		p_dc_word_select <= 0;//n_dc_word_select; 
		p_byte_offset <= 0;
		p_dc_data_to_cache <= 0;//n_dc_data_to_cache; 
		p_dc_read_write_n <= 1;//n_dc_read_write_n; 
		p_mem_ready <= 1;//n_mem_ready;
		p_dc_req <= 0;
		p_regWrite <= 0;
		p_regWriteDouble <= 0;
		p_store_type <= 0;
		p_load_type <= 0;
		p_icc <= 0;
		p_icc_write <= 0;
		p_y <= 0;
		p_y_write <= 0;
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
		p_byte_offset <= n_byte_offset; 
		p_dc_data_to_cache <= n_dc_data_to_cache; 
		p_dc_read_write_n <= n_dc_read_write_n; 
		p_mem_ready <= n_mem_ready;
		p_dc_req <= n_dc_req;
		p_regWrite <= n_regWrite;
		p_regWriteDouble <= n_regWriteDouble;
		p_store_type <= n_store_type;
		p_load_type <= n_load_type;
		p_icc <= n_icc;
		p_icc_write <= n_icc_write;
		p_y <= n_y;
		p_y_write <= n_y_write;
		end
	end
end



always_comb begin
	case (p_state)
		STATEA: begin
			mem_ready = 1;
			end
		STATEB: begin
			mem_ready = 0;
			end
	endcase

end
function bit store_op(bit [1:0] op, bit [5:0] op3);
	if (op == 2'b11) begin
		// store instructions
		if (op3 == `STB || op3 == `STH || op3 == `ST || op3 == `STD || op3 == `SWAP) begin
			return 1;
		end
	end
	return 0;
endfunction

function bit load_op(bit [1:0] op, bit [5:0] op3);
	if (op == 2'b11) begin
		// load instructions
		if (op3 == `LDSB || op3 == `LDSH || op3 == `LDUB || op3 == `LDUH || op3 == `LD || op3 == `LDD) begin
			return 1;
		end
	end
	return 0;
endfunction

function bit [1:0]  store_t(bit [5:0] op3);
	if (op3 == `STB || op3 == `LDSTUB)
		return 2'b00;
	if (op3 == `STH)
		return 2'b01;
	if (op3 == `ST || op3 == `SWAP)
		return 2'b10;
	if (op3 == `STD)
		return 2'b11;
	return 2'b10;
endfunction
function bit [1:0]  load_t(bit [5:0] op3);
	if (op3 == `LDSB || op3 == `LDUB || op3 == `LDSTUB)
		return 2'b00;
	if (op3 == `LDSH || op3 == `LDUH)
		return 2'b01;
	if (op3 == `LD || op3 == `SWAP)
		return 2'b10;
	if (op3 == `LDD)
		return 2'b11;
	return 2'b10;
endfunction



endmodule		
