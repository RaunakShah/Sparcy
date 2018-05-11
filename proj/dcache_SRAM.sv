module dcache_SRAM(
    input  clk
,   input  reset        
,   input  [LOG_NUM_ROWS-1:0] readAddr
,   output [WIDTH-1:0] readData
,   input  [LOG_NUM_ROWS-1:0] writeAddr
,   input  [WIDTH-1:0] writeData
,   input  [WIDTH/WORD_SIZE-1:0] writeEnable
);
    parameter WIDTH = 512;
    parameter LOG_NUM_ROWS = 9;
    parameter WORD_SIZE = 64;
    localparam NUM_ROWS = 2**LOG_NUM_ROWS;
    
    logic[WIDTH-1:0] mem[NUM_ROWS-1:0];

    initial begin
        $display("Initializing %0dKB (%0dx%0d) memory", (WIDTH+7)/8 * NUM_ROWS/1024, WIDTH, NUM_ROWS);
    end

    integer i;
    integer j;
    always @ (posedge clk) begin
        if (reset) begin
            for (i = 0; i < NUM_ROWS; i += 1)
//                for (j = 0; j < WIDTH; j += 1)
			mem[i] = 32'h0000000f;//3;//512'hffffffff;
            for (i = 0; i < NUM_ROWS; i += 1)
			$display("initialized %d to %02x", i, mem[i]);// = 1;//512'hffffffff;
        end
        else begin
            // read
	//$display("write addr %d readAddr = %d read data %d", writeAddr, readAddr, mem[readAddr] );
            readData <= mem[readAddr];
            // write
            for (i = 0; i < WIDTH/WORD_SIZE; i += 1) begin
//		$display("SRAM %d at i %d ", writeData[i*WORD_SIZE +: WORD_SIZE], i);
                if (writeEnable[i]) begin
                    mem[writeAddr][i*WORD_SIZE +: WORD_SIZE] <= writeData[i*WORD_SIZE +: WORD_SIZE];
//			$display("writing in sram %d i = %d", writeData[i*WORD_SIZE +: WORD_SIZE], i);
                end
            end
        end
    end
endmodule
