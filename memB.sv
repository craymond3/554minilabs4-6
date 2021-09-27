module memB
  #(
    parameter BITS_AB=8,
    parameter DIM=8
    )
   (
    input                      clk,rst_n,en,
    input signed [BITS_AB-1:0] Bin [DIM-1:0],
    output signed [BITS_AB-1:0] Bout [DIM-1:0]
    );
		
		logic signed [BITS_AB-1:0] d_in [DIM-1:0];
		logic signed [BITS_AB-1:0] q_out [DIM-1:0];
		
		genvar i;
		
		{3{r_VAL_1}});
		generate
		for (i = 0; i < DIM; i = i + 1) begin
			fifo #(.BITS(BITS_AB), .DEPTH(DIM * 2 - 1)) b_fifo(.clk(clk), .rst_n(rst_n), 
			.en(en), .d({DIM-1-i{1'b0}},Bin[i] >> i * BITS_AB, {i{1'b0}}), .q()); 
		end
	 endgenerate
		
endmodule
