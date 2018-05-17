module RegFile
// register file
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
	output [3:0] icc_out,
	input [3:0] icc_in,
	input icc_en,
	output [4:0] cwp_out,
	input cwp_inc,
	input cwp_dec,
	input et_inc,
	input et_dec,
	output [31:0] wim_out,
	output [31:0] Y_out,
	input [31:0] Y_in,
	input Y_en,
	output [31:0] g1, o0, o1, o2, o3, o4, o5
	
);
localparam NUM_ROWS = (WINDOW_SIZE*NO_OF_REG_WINDOWS);
logic [(2**REG_BITS_SIZE)-1:0] GeneralRegister [512]; 
logic [(2**REG_BITS_SIZE)-1:0] GlobalGeneralRegister [8];
// split PSR into components
// logic [(2**REG_BITS_SIZE)-1:0] PSR;
logic [3:0] PSR_impl;
logic [3:0] PSR_ver;
logic [3:0] PSR_icc;
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
                	GeneralRegister[i] = 0;
		for (i = 0; i < 8; i += 1)
			GlobalGeneralRegister[i] = 0;
	    	PSR_impl <= 4'b1111;
		PSR_ver <= 4'b1111;
		PSR_icc <= 4'b0000;
 		PSR_reserved <= 6'b000000;
		PSR_EC <= 1'b0;
		PSR_EF <= 1'b0;
		PSR_PIL <= 4'b0000;
		PSR_S <= 1'b0;
		PSR_PS <= 1'b0;
		PSR_ET <= 0;
		PSR_CWP <= 5'b00001;
		WIM <= 0; 
		Y <= 0;
        end
        else begin
		// if (clk) write to reg
		if (clk) begin
			if (reg_write_en) begin
				// if 0-7, take from global
				// else take from ((wrreg-8) + 16*cwp) mod (16*32)
				if (wr_reg <= 7) begin
					if (wr_reg != 0)
						GlobalGeneralRegister[wr_reg] = data[31:0];
					if (reg_writeDouble_en) 
						GlobalGeneralRegister[wr_reg+1] = data[63:32];
				end
				else begin
					GeneralRegister[((wr_reg-8)+(16*PSR_CWP)) % (16*32)] = data[31:0];
					if (reg_writeDouble_en)
						GeneralRegister[((wr_reg+1-8)+(16*PSR_CWP)) % (16*32)] = data[63:32];
				//GeneralRegister[wr_reg] <= data[31:0];
				//if (reg_writeDouble_en)
				//	GeneralRegister[wr_reg+1] <= data[63:32];
				end
			end
			if (icc_en)
				PSR_icc <= icc_in;
			if (et_inc)
				PSR_ET <= 1;
			if (et_dec)
				PSR_ET <= 0;
			if (Y_en)
				Y <= data[63:32];
			if (cwp_inc) begin
				//$display("old registers");	
				PSR_CWP <= (PSR_CWP+1) % 32;
			end
			if (cwp_dec) begin
				//$display("new registers");
				PSR_CWP <= (PSR_CWP-1) % 32;
			end
		// remove later
			val1 <= 0;
			val2 <= 0;
			val3 <= 0;
			icc_out <= PSR_icc; 
			cwp_out <= PSR_CWP;
			wim_out <= WIM;
			Y_out <= Y;
			g1 <= 0;
			o0 <= 0;
			o1 <= 0;
			o2 <= 0;
			o3 <= 0;
			o4 <= 0;
			o5 <= 0;
		end
		if (!clk) begin
			if (rs1 <= 7)
				val1 <= GlobalGeneralRegister[rs1];
			else
				val1 <= GeneralRegister[((rs1-8)+(16*PSR_CWP))%(16*32)];
			if (rs2 <= 7)
				val2 <= GlobalGeneralRegister[rs2];
			else
				val2 <= GeneralRegister[((rs2-8)+(16*PSR_CWP))%(16*32)];
			if (rd <= 7)
				val3 <= {GlobalGeneralRegister[rd+1],GlobalGeneralRegister[rd]};
			else
				val3 <= {GeneralRegister[((rd+1-8)+(16*PSR_CWP))%(16*32)], GeneralRegister[((rd-8)+(16*PSR_CWP))%(16*32)]};
			g1 <= GlobalGeneralRegister[1];
			o0 <= GeneralRegister[((16*PSR_CWP))%(16*32)];			
			o1 <= GeneralRegister[(1+(16*PSR_CWP))%(16*32)];			
			o2 <= GeneralRegister[(2+(16*PSR_CWP))%(16*32)];			
			o3 <= GeneralRegister[(3+(16*PSR_CWP))%(16*32)];			
			o4 <= GeneralRegister[(4+(16*PSR_CWP))%(16*32)];			
			o5 <= GeneralRegister[(5+(16*PSR_CWP))%(16*32)];			
			

			//val1 <= GeneralRegister[rs1];
			//val2 <= GeneralRegister[rs2];
			//val3 <= {GeneralRegister[rd+1], GeneralRegister[rd]};
			icc_out <= PSR_icc; 
			cwp_out <= PSR_CWP;
			wim_out <= WIM;
			Y_out <= Y;
		end
	end
end


endmodule
