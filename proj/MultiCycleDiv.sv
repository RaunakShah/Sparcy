/**
 * This is just a timing model of a multi-cycle divider to let
 * you design the control logic of your processor pipeline. A Verilog
 * implementation of an actual multi-cycle divider would look very
 * differently.
 */ 

module MultiCycleDiv (clk, reset, is_signed, start, dividend, divisor, qoutient);
    parameter SIGNED = 1;
    parameter WIDTH = 32;
    parameter DELAY = 8;
    
    input  clk;
	  input  reset;
    input  is_signed;
    input  start;
    input  [2*WIDTH-1:0] dividend;
    input  [WIDTH-1:0] divisor;    
    output [WIDTH-1:0] qoutient;
    
	// calculate the result and update the delay counter
    integer i;
    logic [WIDTH-1:0] qoutient_latch;
    
    always_ff @(posedge clk) begin
		if (reset) begin
			i <= 0;
			qoutient_latch <= 0;
		end
		else if (0 == i && start) begin
			i <= DELAY;
			
			if (is_signed)
				qoutient_latch <= $signed(dividend) / $signed(divisor);
			else
				qoutient_latch <= dividend / divisor;
		end
		else if (0 != i)
			i <= i - 1;			
	end
	
	// output the result
	assign qoutient = (0 == i) ? qoutient_latch : 0;
	
endmodule
