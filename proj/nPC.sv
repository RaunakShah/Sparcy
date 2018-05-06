module nPC
#(
	PC_SIZE = 64
)
(
	input clk,
	input reset,
	input [PC_SIZE-1:0] target,
	input mux_en,
	input [PC_SIZE-1:0] entry,
	input if_ready,
	output [PC_SIZE-1:0] nPC_out,
	input [PC_SIZE-1:0] nPC_in
);
logic [63:0] nPC_current;

always_comb begin
	nPC_out = nPC_current;
end

always_ff @(posedge clk) begin
	if (reset)
		nPC_current <= entry;
	else begin
		if (mux_en)
			nPC_current <= target;
		else begin
			if (if_ready)
				nPC_current <= nPC_out + 4;
		end
	end
end



endmodule
