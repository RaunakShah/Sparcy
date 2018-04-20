module RegFile
// register file
// for now, only implementing 32 general purpose registers
// need to add special purpose registers and register windows
#(
	REG_BITS_SIZE = 5,
	NO_OF_REG = 32,
	WINDOW_SIZE = 32,
	NO_OF_REG_WINDOWS = 1,
	INST_SIZE = 32
)
(
	input clk,
	input reset,
	input [REG_BITS_SIZE-1:0] rs1,
	input [REG_BITS_SIZE-1:0] rs2,
	output [INST_SIZE-1:0] val1,
	output [INST_SIZE-1:0] val2
);
localparam NUM_ROWS = (WINDOW_SIZE*NO_OF_REG_WINDOWS);
logic [NUM_ROWS-1:0] GeneralRegister [(2**REG_BITS_SIZE)-1:0];
logic [NUM_ROWS-1:0] PSR[(2**5)-1:0];
logic [NUM_ROWS-1:0] WIM[(2**5)-1:0];
logic [NUM_ROWS-1:0] TBR[(2**5)-1:0];
integer i;
always_ff @(posedge clk, negedge clk) begin
        if (reset) begin
            for (i = 0; i < NUM_ROWS; i += 1)
                GeneralRegister[i] = 32'hffffffff;
	    			GeneralRegister[0] = 0;
        end
        else begin
		// if (clk) write to reg
		if (!clk) begin
			val1 <= GeneralRegister[rs1];
			val2 <= GeneralRegister[rs2];
		end
	end
end


endmodule
