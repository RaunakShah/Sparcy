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
	input [REG_BITS_SIZE-1:0] rd,
	output [INST_SIZE-1:0] val1,
	output [INST_SIZE-1:0] val2,
	output [63:0] val3,
	input reg_write_en,
	input [63:0] data,
	input [4:0] wr_reg,
	input reg_writeDouble_en
);
localparam NUM_ROWS = (WINDOW_SIZE*NO_OF_REG_WINDOWS);
logic [NUM_ROWS-1:0] GeneralRegister [(2**REG_BITS_SIZE)-1:0];
integer i;
always_ff @(posedge clk, negedge clk) begin
        if (reset) begin
            for (i = 0; i < NUM_ROWS; i += 1)
                GeneralRegister[i] = 32'h88888888;
        end
        else begin
		// if (clk) write to reg
		if (clk) begin
			if (reg_write_en) begin
				GeneralRegister[wr_reg] <= data[31:0];
				if (reg_writeDouble_en)
					GeneralRegister[wr_reg+1] <= data[63:32];
			end
		end
		if (!clk) begin
			val1 <= GeneralRegister[rs1];
			val2 <= GeneralRegister[rs2];
			val3 <= {GeneralRegister[rd+1], GeneralRegister[rd]};
		end
	end
end


endmodule
