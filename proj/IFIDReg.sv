module IFIDReg
#(
	PC_SIZE = 32,
	INST_SIZE = 32
)
(
	input clk,
	input reset,
	input [PC_SIZE-1:0] PCplus4,
	input [INST_SIZE-1:0] inst,
	output [PC_SIZE-1:0] PCplus4_decode,
	output [INST_SIZE-1:0]inst_decode
);

always_ff @(posedge clk) begin
	if (reset) begin
		PCplus4_decode <= 0;
		inst_decode <= 0;
	end
	else begin
		PCplus4_decode <= PCplus4;
		inst_decode <= inst;
	end
end


endmodule
