module PC
#(
	PC_SIZE = 64
)
(
	input clk,
	input reset,
	input [PC_SIZE-1:0] PC_in,
	output [PC_SIZE-1:0] PC_out,
	input if_ready

);

logic [PC_SIZE-1:0] PC_current;

always_comb begin
	if (if_ready)
		PC_out = PC_in;
	else
		PC_out = PC_current;
end

always_ff @(posedge clk) begin
	if (reset)
		PC_current <= 0;
	if (if_ready)
		PC_current <= PC_in;
end

endmodule
