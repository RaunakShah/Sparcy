module WB 

(
	input clk, reset,
	input [63:0] WB_alures_in,
	input [63:0] WB_load_data_in,
	input [4:0] WB_regD_in,
	input [1:0] WB_op_in,
	input [2:0] WB_op2_in,
	input [5:0] WB_op3_in,
	input WB_regWrite_in,
	input WB_regWriteDouble_in,
	output [63:0] WB_data_out,
	output [4:0] WB_regD_out,
	output WB_reg_en,
	output WB_regDouble_en, WB_Y_en, WB_icc_en,
	input WB_Y_write_in, WB_icc_write_in,
	input [3:0] WB_icc_in,
	output [3:0] WB_icc_out
);


always_comb begin
	if (WB_op_in == 2'b00 && WB_op2_in == 3'b100 && WB_regD_in == 5'b00000) begin
		WB_reg_en = 0;
		WB_regDouble_en = 0;
		WB_data_out = 0;
		WB_regD_out = 0;
		WB_Y_en = 0;
		WB_icc_out = 0;
		WB_icc_en = 0;
	end
	else begin
		// if load, data == load data in else data = alures in
		WB_reg_en = WB_regWrite_in;
		WB_regDouble_en = WB_regWriteDouble_in;
		WB_data_out = WB_alures_in;
		WB_icc_out = WB_icc_in;
		WB_icc_en = WB_icc_write_in;
		if (is_load_op(WB_op_in)) begin
			if (WB_op3_in == `LDSB)
				WB_data_out = 64'(signed'(WB_load_data_in[7:0]));	
			if (WB_op3_in == `LDSH)
				WB_data_out = 64'(signed'(WB_load_data_in[15:0]));	
			if (WB_op3_in == `LDUB)
				WB_data_out = WB_load_data_in[7:0];	
			if (WB_op3_in == `LDUH)
				WB_data_out = WB_load_data_in[15:0];	
			if (WB_op3_in == `LD)
				WB_data_out = WB_load_data_in[31:0];	
			if (WB_op3_in == `LDD)
				WB_data_out = WB_load_data_in;	
		end	
		WB_regD_out = WB_regD_in;
		WB_Y_en = WB_Y_write_in;
	end
end

function bit is_load_op(bit [1:0] op);
	if (op == 2'b11) begin
		return 1;
	end
	return 0;
endfunction
endmodule
		
