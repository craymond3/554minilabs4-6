
module systolic_array
#(
   parameter BITS_AB=8,
   parameter BITS_C=16,
   parameter DIM=8
   )
  (
   input                      clk,rst_n,WrEn,en,
   input signed [BITS_AB-1:0] A [DIM-1:0],
   input signed [BITS_AB-1:0] B [DIM-1:0],
   input signed [BITS_C-1:0]  Cin [DIM-1:0],
   input [$clog2(DIM)-1:0]    Crow,
   output signed [BITS_C-1:0] Cout [DIM-1:0]
   );
   
   integer inc;
   // ROWS x COLS
   logic signed [BITS_AB-1:0] Bouts [DIM:0][DIM-1:0];
   logic signed [BITS_AB-1:0] Aouts [DIM-1:0][DIM:0];
   wire signed [BITS_C-1:0] Couts [DIM-1:0][DIM-1:0];
   
   always_comb
		begin
			for(inc = 0; inc < DIM; inc++)
				begin
					Aouts[inc][0] = A[inc];
					Bouts[0][inc] = B[inc];
				end
		end
   
   genvar row;
   genvar col;
   
   generate
		for(col = 0; col < DIM; col++)
			begin
				for(row = 0; row < DIM; row++)
					begin
						tpumac 
						#(
							.BITS_AB(BITS_AB),
							.BITS_C(BITS_C)
						)
						mac
						(
						.clk	(clk),
						.rst_n	(rst_n),
						.WrEn	(WrEn & (Crow == row)),
						.en		(en),
						.Ain	(Aouts[row][col]),
						.Bin	(Bouts[row][col]),
						.Cin	(Cin[col]),
						.Aout	(Aouts[row][col + 1]),
						.Bout	(Bouts[row + 1][col]),
						.Cout	(Couts[row][col])
						);
						
					end
				assign Cout[col] = Couts[Crow][col];
			end
   endgenerate
   
   
endmodule