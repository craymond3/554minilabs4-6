module transpose_fifo #(
  parameter DEPTH=8,
  parameter BITS=64
  )
  (
  input clk,rst_n,en,WrEn,
  input signed [BITS-1:0] WrData [DEPTH-1:0],
  input signed [BITS-1:0] d,
  output signed[BITS-1:0] q
  );
  // your RTL code here
  
  logic signed [BITS-1:0] data [DEPTH-1:0];
  assign q = data[0];
  integer i;
 
  
  always_ff@(posedge clk, negedge rst_n)
	begin
		if(~rst_n)
			begin
				for(i = 0; i < DEPTH;i++)
					begin
						data[i] <= 'b0;
					end
			end
		else
			begin
				if(WrEn)
					begin
						data <= WrData;
					end
				else if(en)
					begin
						for(i = 0; i < DEPTH; i++)
							begin
								if(i < DEPTH-1)
									begin
										data[i] <= data[i+1];
									end
								else
									begin
										data[i] <= d;
									end
							end
					end
			end
	end
endmodule // fifo
