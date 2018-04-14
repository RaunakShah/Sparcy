module IFIDReg
#(
	PC_SIZE = 32,
	INST_SIZE = 32
)
(
	input clk,
	input reset,
	input [PC_SIZE-1:0] IFID_PCplus4_in,
	input [INST_SIZE-1:0] inst,
	output [PC_SIZE-1:0] IFID_PCplus4_out,
	output [INST_SIZE-1:0]inst_decode
);

always_ff @(posedge clk) begin
	if (reset) begin
		IFID_PCplus4_out <= 0;
		inst_decode <= 0;
	end
	else begin
		IFID_PCplus4_out <= IFID_PCplus4_in;
		inst_decode <= inst;
	end
end


endmodule
