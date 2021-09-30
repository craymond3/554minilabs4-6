// fifo.sv
// Implements delay buffer (fifo)
// On reset all entries are set to 0
// Shift causes fifo to shift out oldest entry to q, shift in d

module fifo
  #(
  parameter DEPTH=8,
  parameter BITS=64
  )
  (
  input clk,rst_n,en,
  input [BITS-1:0] d,
  output [BITS-1:0] q
  );
  // your RTL code here
  
  localparam size = DEPTH * BITS;
  
  logic [ size-1 :0] data;
  
  assign q = data[(size - 1) -: BITS];
  
  always@(posedge clk, negedge rst_n)
	begin
		if(~rst_n)
			begin
				data <= 'b0;
			end
		else
			begin
				if(en)
					begin
						data <= (data << BITS) + d;
					end
			end
	end
endmodule // fifo
