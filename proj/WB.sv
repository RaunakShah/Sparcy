module WB 

(
	input clk, reset,
	input [63:0] WB_alures_in,
	input [63:0] WB_load_data_in,
	input [4:0] WB_regD_in,
	input [1:0] WB_op_in,
	input [2:0] WB_op2_in,
	input [5:0] WB_op3_in,
	output [31:0] WB_data_out,
	output [4:0] WB_regD_out,
	output WB_reg_en
);


always_comb begin
	if (WB_op_in == 2'b00 && WB_op2_in == 3'b100) begin
		WB_reg_en = 0;
		WB_data_out = 0;
		WB_regD_out = 0;
	end
	else begin
		WB_reg_en = 1;
		WB_data_out = 32'h44444444;
		WB_regD_out = 5'b10010;
	end
end
endmodule
		
