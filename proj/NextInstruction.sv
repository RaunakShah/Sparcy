module NextInstruction
#(
	PC_SIZE = 32
)
(
	input clk,
	input reset,
	input [PC_SIZE-1:0] ni_PCplus4_in,
// TODO add input lines for ex/mem register
	input [PC_SIZE-1:0] target,
	input mux_en,
//	input pc_en,
	input [PC_SIZE-1:0] entry,
	output [PC_SIZE-1:0] NI_PC_out,
	input if_ready,
	output [PC_SIZE-1:0] nPC_out,
	input [PC_SIZE-1:0] nPC_in
);

logic [PC_SIZE-1:0] next_inst;
logic [PC_SIZE-1:0] ni;

// mux
always_comb begin
	if (mux_en)
		next_inst = target;
	else
	//	next_inst = ni_PCplus4_in + 4;
		next_inst = nPC_in+4;
end	

// pc
always_ff @(posedge clk) begin
	if (reset) begin
		NI_PC_out <= entry;
		nPC_out <= entry+4;
	end
	else begin
		if (if_ready) begin
			//if (ni_PCplus4_in != 64'hffffffffffffffff);
			NI_PC_out <= nPC_in;
			nPC_out <= next_inst;
		end
	end
end

endmodule
