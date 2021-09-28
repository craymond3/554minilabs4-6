
module memA  #(
    parameter BITS_AB=8,
    parameter DIM=8    
	)   (    
	input                      clk,rst_n,en,WrEn,    
	input signed [BITS_AB-1:0] Ain [DIM-1:0],    
	input [$clog2(DIM)-1:0] Arow,    
	output signed [BITS_AB-1:0] Aout [DIM-1:0]   
	);
	
	logic [BITS_AB-1:0] zeros;
	genvar i;
	
	assign zeros = 'b0;
	
	generate
		begin
			for(i = 0; i < DIM; i++)
				begin
					if(i == 0)
						begin
						
							transpose_fifo
							#(
								.DEPTH(DIM),
								.BITS(BITS_AB)
							)
							t_fifo
							(
								.clk(clk),
								.rst_n(rst_n),
								.en(en & !WrEn),
								.WrEn((Arow == i) & WrEn),
								.WrData(Ain),
								.d(zeros),
								.q(Aout[i])
							);
						end
					else
						begin
							logic signed [BITS_AB-1:0] t_fifo_out;
							fifo
							#(
								.DEPTH(i),
								.BITS(BITS_AB)
							)
							pre_fifo
							(
								.clk(clk),
								.rst_n(rst_n),
								.en(en & ~WrEn),
								.d(t_fifo_out),
								.q(Aout[i])
							);
						
							transpose_fifo
							#(
								.DEPTH(DIM),
								.BITS(BITS_AB)
							)
							t_fifo
							(
								.clk(clk),
								.rst_n(rst_n),
								.en(en & ~WrEn),
								.WrEn((Arow == i) & WrEn),
								.WrData(Ain),
								.d(zeros),
								.q(t_fifo_out)
							);
						end
				end
		end
	endgenerate
	
	
	
endmodule