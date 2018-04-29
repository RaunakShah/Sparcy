module RegFile
// register file
// for now, only implementing 32 general purpose registers
// need to add special purpose registers and register windows
// TODO!!!! TRAPS and TBR
#(
	REG_BITS_SIZE = 5,
	NO_OF_REG = 32,
	WINDOW_SIZE = 16,
	NO_OF_REG_WINDOWS = 2, // or 32
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
	input reg_writeDouble_en,
	// icc o/ps, i/ps and write enables
	output icc_n_out,
	output icc_z_out,
	output icc_v_out,
	output icc_c_out,
	input icc_n_in,
	input icc_z_in,
	input icc_c_in,
	input icc_v_in,
	input icc_n_en,
	input icc_z_en,
	input icc_c_en,
	input icc_v_en,
	output [4:0] cwp_out,
	input cwp_inc,
	input cwp_dec,
	input et_inc,
	input et_dec,
	output [31:0] wim_out,
	output [31:0] Y_out,
	input [31:0] Y_in,
	input Y_en
	
);
localparam NUM_ROWS = (WINDOW_SIZE*NO_OF_REG_WINDOWS);
logic [(2**REG_BITS_SIZE)-1:0] GeneralRegister [32]; // need to change later
logic [(2**REG_BITS_SIZE)-1:0] GlobalGeneralRegister [8];
// split PSR into components
// logic [(2**REG_BITS_SIZE)-1:0] PSR;
logic [3:0] PSR_impl;
logic [3:0] PSR_ver;
logic PSR_icc_n;
logic PSR_icc_z;
logic PSR_icc_v;
logic PSR_icc_c;
logic [5:0] PSR_reserved;
logic PSR_EC;
logic PSR_EF;
logic [3:0] PSR_PIL;
logic PSR_S;
logic PSR_PS;
logic PSR_ET;
logic [4:0] PSR_CWP;
logic [(2**REG_BITS_SIZE)-1:0] WIM;
logic [(2**REG_BITS_SIZE)-1:0] TBR;
logic [(2**REG_BITS_SIZE)-1:0] Y;
integer i;
always_ff @(posedge clk, negedge clk) begin
        if (reset) begin
            	for (i = 0; i < 512; i += 1)
                	GeneralRegister[i] = 10;
		for (i = 0; i < 512; i += 1)
			GlobalGeneralRegister[i] = 10;
	    	PSR_impl <= 4'b1111;
		PSR_ver <= 4'b1111;
		PSR_icc_n <= 1'b0;
		PSR_icc_z <= 1'b0;
		PSR_icc_v <= 1'b0;
		PSR_icc_c <= 1'b0;
 		PSR_reserved <= 6'b000000;
		PSR_EC <= 1'b0;
		PSR_EF <= 1'b0;
		PSR_PIL <= 4'b0000;
		PSR_S <= 1'b0;
		PSR_PS <= 1'b0;
		PSR_ET <= 0;
		PSR_CWP <= 5'b00000;
		WIM <= 0; 
		Y <= 0;
        end
        else begin
		// if (clk) write to reg
		if (clk) begin
			if (reg_write_en) begin
				GeneralRegister[wr_reg] <= data[31:0];
				if (reg_writeDouble_en)
					GeneralRegister[wr_reg+1] <= data[63:32];
			end
			val1 <= 0;
			val2 <= 0;
			val3 <= 0;
			if (icc_n_en)
				PSR_icc_n <= icc_n_in;
			if (icc_z_en)
				PSR_icc_z <= icc_z_in;
			if (icc_c_en)
				PSR_icc_c <= icc_c_in;
			if (icc_v_en)
				PSR_icc_v <= icc_v_in;
			if (cwp_inc)
				PSR_CWP <= PSR_CWP+1;
			if (cwp_dec)
				PSR_CWP <= PSR_CWP-1;
			if (et_inc)
				PSR_ET <= 1;
			if (et_dec)
				PSR_ET <= 0;
			if (Y_en)
				Y <= Y_in;
			val1 <= 0;
			val2 <= 0;
			val3 <= 0;
		end
		if (!clk) begin
			val1 <= GeneralRegister[rs1];
			val2 <= GeneralRegister[rs2];
			val3 <= {GeneralRegister[rd+1], GeneralRegister[rd]};
			icc_n_out <= PSR_icc_n; 
			icc_z_out <= PSR_icc_z;
			icc_v_out <= PSR_icc_v;
			icc_c_out <= PSR_icc_c;
			cwp_out <= PSR_CWP;
			wim_out <= WIM;
			Y_out <= Y;
		end
	end
end


endmodule
