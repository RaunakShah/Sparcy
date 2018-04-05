/**
 * This is just a timing model of a pipelined multiplier to let
 * you design the control logic of your processor pipeline. A Verilog
 * implementation of an actual pipelined multiplier would look very
 * differently.
 */ 

module PipelinedMult (clk, is_signed, op1, op2, res);
    parameter SIGNED = 1;
    parameter WIDTH = 32;
    parameter PIPE_DEPTH = 3;
    
    input  clk;
    input  is_signed;
    input  [WIDTH-1:0] op1, op2;
    output [2*WIDTH-1:0] res;
    
    logic [WIDTH-1:0] op1_pipe_regs [PIPE_DEPTH-1:0];
    logic [WIDTH-1:0] op2_pipe_regs [PIPE_DEPTH-1:0];

	// move the operands down the pipeline
    integer i;
    
    always_ff @(posedge clk) begin
        // first stage inputs
        op1_pipe_regs[0] <= op1;
        op2_pipe_regs[0] <= op2;
        
        // intermediate stages inputs
        for (i=1; i < PIPE_DEPTH; ++i) begin
            op1_pipe_regs[i] <= op1_pipe_regs[i-1];
            op2_pipe_regs[i] <= op2_pipe_regs[i-1];
        end            
    end

    always_comb begin
        if (is_signed)
            res = $signed(op1_pipe_regs[PIPE_DEPTH-1]) * $signed(op2_pipe_regs[PIPE_DEPTH-1]);
        else
            res = op1_pipe_regs[PIPE_DEPTH-1] * op2_pipe_regs[PIPE_DEPTH-1];
    end

endmodule
