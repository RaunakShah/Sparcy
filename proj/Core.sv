`include "Sysbus.defs"

module Core
#(
  BUS_DATA_WIDTH = 64,
  BUS_TAG_WIDTH = 13
)
(
  input 		      clk,
			      reset,

  // address of the program entry point
  input [31:0] 		      entry,
  
  // interface to connect to the bus
  output 		      bus_reqcyc,
  output 		      bus_respack,
  output [BUS_DATA_WIDTH-1:0] bus_req,
  output [BUS_TAG_WIDTH-1:0]  bus_reqtag,
  input 		      bus_respcyc,
  input 		      bus_reqack,
  input [BUS_DATA_WIDTH-1:0]  bus_resp,
  input [BUS_TAG_WIDTH-1:0]   bus_resptag
);

  // function to be called to execute a system call
  import "DPI-C" function int
  syscall_cse502(input int g1, input int o0, input int o1, input int o2, input int o3, input int o4, input int o5);

  // implement your processor here...
  
endmodule
