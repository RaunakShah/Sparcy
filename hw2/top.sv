/**
 * To plumb your cache into the reset of verilator
 */

module top(
  input  reset, 
         clk,

  // interface to connect to the processor
  output c_ack,
  output [31:0] c_data_out,
  input  c_req,
  input  c_read_write_n,
  input  [57:0] c_line_addr,
  input  [31:0] c_data_in,
  input  [3:0] c_word_select,
  
  // interface to connect to the bus
  output bus_reqcyc,
  output bus_respack,
  output [63:0] bus_req,
  output [12:0] bus_reqtag,
  input  bus_respcyc,
  input  bus_reqack,
  input  [63:0] bus_resp,
  input  [12:0] bus_resptag
);

    // instantiate the cache
    // it has 16 words of 4 bytes each per line (each line = 64B)
    // The cache only has 2**4=16 sets to make sure block replacement happens
    DirectMap
    #(
      .BUS_DATA_WIDTH(64),
      .BUS_TAG_WIDTH(13),
      .WORD_SIZE(4),
      .LOG_WORDS_PER_LINE(4),
      .ADDR_WIDTH(64-6),
      .LOG_NUM_SETS(4)
    )
    cache
    (
      clk, reset,
      c_ack, c_data_out, c_req, c_read_write_n, c_line_addr, c_word_select, c_data_in,
      bus_reqcyc, bus_respack, bus_req, bus_reqtag, bus_respcyc, bus_reqack, bus_resp, bus_resptag
    );
    
endmodule // top


