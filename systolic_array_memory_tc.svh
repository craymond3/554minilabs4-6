`include "systolic_array_tc.svh"

class systolic_array_memory_tc #(
	BITS_AB=8,
	BITS_C=16,
	DIM=8
	) extends systolic_array_tc #(
	BITS_AB,
	BITS_C,
	DIM
	);

	function bit signed [BITS_AB-1:0] get_A(int row, int col);
		return A[row][col];
	endfunction: get_A
	
	
	function bit signed [BITS_AB-1:0] get_B(int row, int col);
		return B[row][col];
	endfunction: get_B



endclass
