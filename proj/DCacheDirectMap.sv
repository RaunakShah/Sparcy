/**
 * A write-allocate, write-back direct-mapped cache
 */
module DCacheDirectMap
#(
  // bus parameters
  BUS_DATA_WIDTH = 64,
  BUS_TAG_WIDTH = 13,

  // cache parameters
  WORD_SIZE = 4,          // # bytes in a word
  LOG_WORDS_PER_LINE = 4, // log2 of # of words in a cache line
  ADDR_WIDTH = 64-6,      // input address width, does not include block-offset bits
  LOG_NUM_SETS = 10       // log2 of # of sets in the cache (= # index bits)      
)
(
  // reset and clock
  input  clk, 
  input reset,
  
  // interface to connect to the processor
  output proc_ack,
  output [WORD_SIZE*8-1:0] proc_data_out,
  input  proc_req,
  input  proc_read_write_n,
  input  [ADDR_WIDTH-1:0] proc_line_addr,
  input  [LOG_WORDS_PER_LINE-1:0] proc_word_select,
  input  [WORD_SIZE*8-1:0] proc_data_in,
  
  // interface to connect to the bus
  output bus_reqcyc,
  output bus_respack,
  output [BUS_DATA_WIDTH-1:0] bus_req,
  output [BUS_TAG_WIDTH-1:0] bus_reqtag,
  input  bus_respcyc,
  input  bus_reqack,
  input  [BUS_DATA_WIDTH-1:0] bus_resp,
  input  [BUS_TAG_WIDTH-1:0] bus_resptag
);

  enum { STATEI=3'b000, STATEA=3'b001, STATEB=3'b010, STATEC=3'b011, STATED=3'b100, STATEE=3'b101 } n_state, p_state; 
  // local parameters
  localparam WORDS_PER_LINE = 2**LOG_WORDS_PER_LINE;
  localparam WORD_SIZE_BITS = WORD_SIZE * 8;
  localparam NUM_SETS = 2**LOG_NUM_SETS;
  localparam LINE_SIZE = WORD_SIZE * WORDS_PER_LINE;
  localparam LINE_SIZE_BITS = LINE_SIZE * 8;

  logic procline[53:0];	
  logic [511:0] write_data_sram, out_data_sram;
  logic [15:0] n_data_write;
  logic n_tag_write, n_dirty_write;
  logic [53:0] out_tag_sram, out_tag;
  logic out_dirty_sram;
  logic dirty_line;
  logic p_reqcyc, n_reqcyc;
  logic [63:0] p_req, n_req;// = {out_tag_sram + 6'b000000};
  logic [12:0] p_reqtag, n_reqtag;// = 13'b0000100000000;
  logic [4:0] p_counter, n_counter;
  logic n_ack, p_ack;
  logic n_respack, p_respack;
  logic [31:0] n_proc_data_out, p_proc_data_out;
  // FIXME: instantiate separate SRAMs for state, tag and data
  // ...
	dcache_SRAM #(.WIDTH(512), .LOG_NUM_ROWS(4), .WORD_SIZE(32)) dcache_dataSRAM (.clk(clk), .reset(reset), .readAddr(proc_line_addr[3:0]), .writeAddr(proc_line_addr[3:0]), .writeData(write_data_sram), .writeEnable(n_data_write), .readData(out_data_sram));

	dcache_SRAM #(.WIDTH(54), .LOG_NUM_ROWS(4), .WORD_SIZE(54)) dcache_tagSRAM (.clk(clk), .reset(reset), .readAddr(proc_line_addr[3:0]), .writeAddr(proc_line_addr[3:0]), .writeData(proc_line_addr[57:4]), .writeEnable(n_tag_write), .readData(out_tag_sram));

	dcache_SRAM #(.WIDTH(1), .LOG_NUM_ROWS(4), .WORD_SIZE(1)) dcache_dirtySRAM (.clk(clk), .reset(reset), .readAddr(proc_line_addr[3:0]), .writeAddr(proc_line_addr[3:0]), .writeData(dirty_line), .writeEnable(n_dirty_write), .readData(out_dirty_sram));
  // FIXME: implement the cache logic
  // ...

always_comb begin
	n_reqcyc = 0;
	n_req = 0;//{out_tag_sram + 6'b000000};
	n_reqtag = p_reqtag;//0;//13'b0000100000000;
	n_counter = p_counter;
	n_ack = 0;
	n_proc_data_out = p_proc_data_out;
	n_respack = 0;
	n_tag_write = 0;
	n_data_write = 0; n_dirty_write = 0; dirty_line = 0; write_data_sram = 0;
	case (p_state)
		STATEA:	begin
			if (proc_req == 1) begin
				//$display("cache: state a to b");
				n_state = STATEB;
			end
			else begin
				n_state = STATEA;
			end
			end
		STATEB: begin
			if (out_tag_sram == proc_line_addr[57:4]) begin // hit
				//$display("out tag sram %d proc line add %d", out_tag_sram, proc_line_addr[57:4]);
				//$display("data at location %h", out_data_sram);
				//$display("out data %h", out_data_sram[proc_word_select*32 +: 32]);
				//$display("proc word data %h",proc_word_select);
				//$display("cache: b to a");

				n_ack = 1;
				n_proc_data_out = out_data_sram[proc_word_select*32 +: 32];
				n_state = STATEA;
				if (proc_read_write_n == 0) begin
					//$display("writing %h", proc_data_in);
					write_data_sram = proc_data_in << (proc_word_select*32);
					n_data_write = 1 << (proc_word_select);
					n_dirty_write = 1;
					dirty_line = 1;
					//$display("data at location %h", out_data_sram);
				end
			end
			else begin // miss	
				if (out_dirty_sram == 1) begin // dirty
						$display("STATEB dirty miss at %h", {out_tag_sram, proc_line_addr[3:0], 6'b000000});
					//$display("data at location %h", out_data_sram);
					n_state = STATEC;
					//$display("cache: b to c");
					n_counter = 0;
				end
				else begin
					n_state = STATED;// TODO clean miss
					//$display("cache: b to d");
					//$display("clean miss sup");
				end
			end
			
			end
		STATEC: begin
			if (p_counter == 0) begin
				//$display("NEXT REQUEST %b", {out_tag_sram, proc_line_addr[3:0], 6'b000000});
				//	$display("STATEC dirty miss at %h", {out_tag_sram, proc_line_addr[3:0], 6'b000000});
				//$display("%d sending %h with tag %h",p_counter, n_req, n_reqtag);
				n_req = {out_tag_sram, proc_line_addr[3:0], 6'b000000};
				n_reqtag = 13'b0000100000011;
				n_reqcyc = 1;
				n_state = STATEC;
					//$display("cache: c to c 1");
				n_counter = p_counter + 1;
			end
			else begin
				if (bus_reqack == 1) begin
					if (p_counter < 9) begin
						n_req = out_data_sram[(p_counter-1)*64 +: 64];
						n_reqtag = p_reqtag;
						n_reqcyc = 1;
						n_state = STATEC;
					//$display("cache: c to c 2 n_req %d n_reqtag %d ", n_req, n_reqtag);
						n_counter = p_counter + 1;
						// $display("sending %h", n_req);
						// $display("data at location %h", out_data_sram);
					end
					else begin
						n_state = STATED;
					//$display("cache: c to d");
					end
				end
				else begin
					n_state = STATEC;
					//$display("cache: c to c 3");
					n_counter = p_counter;
					n_req = p_req;
					n_reqtag = p_reqtag;
					n_reqcyc = 1;
				end
			end
			end
		STATED: begin
			if (bus_reqack == 1) begin
				//$display("got reqack going to statee");
					//$display("cache: d to e");
				n_state = STATEE;
				n_counter = 0;
			end
			else begin
				n_tag_write = 1;
				n_dirty_write = 1;
				dirty_line = 0;
				n_reqcyc = 1;
				n_req = {proc_line_addr, 6'b000000};
				n_reqtag = 13'b1000100000011;
				
				n_state = STATED;
					//$display("cache: d to D");
				//$display("sending tag %h", n_reqtag);
				//$display("sending out addr %h to be added to line %h", proc_line_addr, proc_line_addr[3:0]);
			end
			end
		STATEE: begin
			if (bus_respcyc == 1 && bus_resptag == p_reqtag) begin
				//$display("got respcyc");
				n_counter = p_counter + 1;
				n_respack = 1;
				write_data_sram = bus_resp << (p_counter*64);
				n_data_write = 3 << (p_counter*2);
				//$display("pcounter %h writedata %h ndatawrite %h", p_counter, write_data_sram, n_data_write);
				if (p_counter < 7) begin
					//$display("cache: E to e");
					n_state = STATEE;
				end
				else begin
					//$display("cache: e to b");
					n_state = STATEB;
					n_reqtag = 0;
				end
			end	
			else begin 
					//$display("cache: e to e");
				n_state = STATEE;
			end
			end
	endcase
end

always_ff @(posedge clk) begin
	if (reset) begin
      	// reset logic: what happens on a reset
		p_reqcyc <= 0;
		p_reqtag <= 0;//n_reqtag;
		p_req <= 0;//n_req;
		p_state <= STATEA;//n_state;	
		p_counter <= 0;//n_counter;
		p_respack <= 0;
		p_proc_data_out <= 0;
		out_tag <= 0;
		p_ack <= 0;
	end
	else begin
      	// normal operation logic
	//	$display("next state: %d", n_state);
		out_tag <= out_tag_sram;
		p_ack <= n_ack;
		p_reqcyc <= n_reqcyc;
		p_reqtag <= n_reqtag;
		p_req <= n_req;
		p_state <= n_state;	
		p_counter <= n_counter;
		p_respack <= n_respack;
		p_proc_data_out <= n_proc_data_out;
  	end
end
  
  
  // FIXME: you should replace these with something meaningful

  assign proc_data_out = p_proc_data_out;
  assign proc_ack = p_ack;
  assign bus_req = p_req;
  assign bus_reqtag = p_reqtag;
  assign bus_reqcyc = p_reqcyc;
  assign bus_respack = p_respack;

endmodule    
    
    
