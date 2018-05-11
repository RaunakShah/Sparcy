module Arbiter 

// inputs: from i cache and d cache; from ram
// outputs: to ram; forward to both caches
#(
  // bus parameters
  BUS_DATA_WIDTH = 64,
  BUS_TAG_WIDTH = 13

)

(
  // from caches to arbiter
  input clk, reset,
  input dc_reqcyc,
  input [BUS_DATA_WIDTH-1:0] dc_req,
  input [BUS_TAG_WIDTH-1:0] dc_reqtag,
  input ic_reqcyc,
  input [BUS_DATA_WIDTH-1:0] ic_req,
  input [BUS_TAG_WIDTH-1:0] ic_reqtag,
  output bus_reqcyc,
  output [BUS_DATA_WIDTH-1:0] bus_req,
  output [BUS_TAG_WIDTH-1:0] bus_reqtag,
  input bus_reqack,
  output dc_reqack,
  input dc_respack,
  output ic_reqack,
  input ic_respack,
  output bus_respack
);

enum { STATEI=2'b00, STATEA=2'b01, STATEB=2'b10 } n_state, p_state;
logic n_reqcyc, p_reqcyc;
logic [63:0] n_req, p_req;
logic [12:0] n_reqtag, p_reqtag;
logic n_reqack, p_reqack, n_respack, p_respack, p_dc_reqack, n_dc_reqack;


/*
state i: if ic, goto a
	else if id goto b
	else i
state a: if ic, stay
	else if id goto b
		else goto i
state b: if id, stay
	else if ic goto a
		else goto i


*/

always_comb begin
	bus_respack = ic_respack || dc_respack;
	case (p_state)
		STATEI: begin
			if (ic_reqcyc) begin
				//$display("CC0: making request for %h", ic_req);
				bus_reqcyc = ic_reqcyc;
				bus_req = ic_req;
				bus_reqtag = ic_reqtag;
				//bus_respack = ic_respack;
				dc_reqack = 0;
				ic_reqack = bus_reqack;
				n_state = STATEA;
			end
			else begin
				if (dc_reqcyc) begin
				//$display("DC0: making request for %ld going to B", dc_req);
					bus_reqcyc = dc_reqcyc;
					bus_req = dc_req;
					bus_reqtag = dc_reqtag;
					//bus_respack = dc_respack;
					dc_reqack = bus_reqack;
					ic_reqack = 0;
					n_state = STATEB;
				end
				else begin
				bus_reqcyc = 0;//dc_reqcyc;
				bus_req = 0;//dc_req;
				bus_reqtag = 0;//dc_reqtag;
				//bus_respack = 0;//dc_respack;
				dc_reqack = 0;
				ic_reqack = 0; //bus_reqack;
				n_state = STATEI;
				end
			end
			end	
		STATEA: begin
			if (ic_reqcyc) begin
				bus_reqcyc = ic_reqcyc;
				bus_req = ic_req;
				bus_reqtag = ic_reqtag;
				dc_reqack = 0; //bus_reqack;
				ic_reqack = bus_reqack;
				n_state = STATEA;
			end
			else begin
/*				if (dc_reqcyc) begin
				//$display("DC: making request for %h", dc_req);
					bus_reqcyc = dc_reqcyc;
					bus_req = dc_req;
					bus_reqtag = dc_reqtag;
					//bus_respack = ic_respack;
					ic_reqack = bus_reqack;
					dc_reqack = 0;
					n_state = STATEB;
				end
				else begin
*/					bus_reqcyc = 0;//dc_reqcyc;
					bus_req = 0;//dc_req;
					bus_reqtag = 0;//dc_reqtag;
					//bus_respack = ic_respack;
					dc_reqack = 0;//bus_reqack;
					ic_reqack = bus_reqack;
					n_state = STATEI;
//				end
			end
			end
		STATEB: begin
			if (dc_reqcyc) begin
				bus_reqcyc = dc_reqcyc;
				bus_req = dc_req;
				bus_reqtag = dc_reqtag;
				//bus_respack = dc_respack;
				dc_reqack = bus_reqack;
				ic_reqack = 0;
				n_state = STATEB;
			end
			else begin	
/*				if (ic_reqcyc) begin
				//$display("CC: making request for %h", ic_req);
					bus_reqcyc = ic_reqcyc;
					bus_req = ic_req;
					bus_reqtag = ic_reqtag;
					//bus_respack = dc_respack;
					dc_reqack = bus_reqack;
					ic_reqack = 0;
					n_state = STATEA;
				end
				else begin
*/					//$display("going to I");
					bus_reqcyc = 0;//ic_reqcyc;
					bus_req = 0;//ic_req;
					bus_reqtag = 0;//ic_reqtag;
					//bus_respack = dc_respack;
					dc_reqack = bus_reqack;
					ic_reqack = 0;
					n_state = STATEI;
//				end
			end
			end
		endcase
end

always_ff @(posedge clk) begin
	if (reset) 
		p_state <= STATEI;
	else
		p_state <= n_state;
end












/*
always_comb begin
	case (p_state)
		STATEI: begin
			if (dc_reqcyc) begin
					n_state = STATEB;
					n_reqcyc = 1;
					n_req = dc_req;
					n_reqtag = dc_reqtag;
					n_reqack = 0;
					n_respack = 0;
					n_dc_reqack = 0;
				//$display("arbiter: state i to b");
			end
			else begin
					n_state = STATEI;
					n_reqcyc = 0;
					n_req = 0;
					n_reqtag = 0;//ic_reqtag;
					n_reqack = 0;
					n_respack = 0;
					n_dc_reqack = 0;
				//$display("arbiter: state i to i");
			end
			end
		STATEB: begin
			if (bus_reqack) begin
					n_state = STATEI;
				//$display("arbiter: state b to i");
					n_reqcyc = 0;
					n_req = 0;
					n_reqtag = 0;//ic_reqtag;
					n_reqack = 0;
					n_respack = 0;
					n_dc_reqack = 1;
			end
			else begin
				n_state = STATEB;
				n_reqcyc = dc_reqcyc;
				n_req = dc_req;
				n_reqtag = dc_reqtag;
				n_dc_reqack = 0;
				//$display("arbiter: state b to b reqcyc %d req %d reqtag %d ", dc_reqcyc, dc_req, dc_reqtag);
			end
			end
	endcase
end

always_ff @(posedge clk) begin
	if (reset) begin
		p_state <= STATEI;
		p_reqcyc <= 0;
		p_req <= 0;
		p_reqtag <= 0;
		p_dc_reqack <= 0;
		p_respack <= 0;
	end
	else begin
		p_state <= n_state;
		p_reqcyc <= n_reqcyc;
		p_req <= n_req;
		p_reqtag <= n_reqtag;
		p_dc_reqack <= n_dc_reqack;
		p_respack <= n_respack;
	end
end

assign bus_reqcyc = p_reqcyc;
assign bus_req = p_req;
assign bus_reqtag = p_reqtag;
assign dc_reqack = bus_reqack;//((p_state == STATEB) && bus_reqack)?1:0;
assign bus_respack = dc_respack;
*/
endmodule
