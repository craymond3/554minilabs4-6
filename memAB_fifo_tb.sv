`include "systolic_array_memory_tc.svh"
module memAB_fifo_tb();
	localparam BITS_AB = 8;
	localparam BITS_C = 16;
	localparam DIM = 8;
	localparam tests = 10;
	
	logic clk;
	logic rst_n;
	logic enA;
	logic enB;
	logic WrEn;
	logic signed [BITS_AB-1:0] Ain [DIM-1:0];
	logic [$clog2(DIM)-1:0] Arow;
	logic [BITS_AB-1:0] Aout [DIM-1:0];
	logic signed [BITS_AB-1:0] Bin [DIM-1:0];
	logic [BITS_AB-1:0] Bout [DIM-1:0];
	
	
	logic signed [BITS_AB-1:0] realDataA;
	logic signed [BITS_AB-1:0] realDataB;
	
	int i;
	int j;
	int ff_it;

	memA #(
		.BITS_AB(BITS_AB),
		.DIM(DIM)
		) memA_dut (
		.clk(clk),
		.rst_n(rst_n),
		.en(enA),
		.WrEn(WrEn),
		.Ain(Ain),
		.Arow(Arow),
		.Aout(Aout)
		);
		
	memB #(
		.BITS_AB(BITS_AB),
		.DIM(DIM)
		) memB_dut (
		.clk(clk),
		.rst_n(rst_n),
		.en(enB),
		.Bin(Bin),
		.Bout(Bout)
		);
	
	systolic_array_memory_tc #(
		.BITS_AB(BITS_AB),
		.BITS_C(BITS_C),
		.DIM(DIM)
		) satc;
		
		
	always #5 clk = ~clk;
		
	initial begin
		clk = 'b0;
		rst_n = 'b0;
		enA = 'b0;
		enB = 'b0;
		WrEn = 'b0;
		Arow = 'b0;
		for(int ab_0_init = 0; ab_0_init < DIM; ab_0_init++)
			begin
				Ain[ab_0_init] = 'b0;
				Bin[ab_0_init] = 'b0;
			end
		
		
		
		i = 0;
		j = 0;
		realDataA = 'b0;
		realDataB = 'b0;
		
		@(posedge clk);
		rst_n = 'b1;
		@(posedge clk);
		// Feed values into fifos to check reset
		satc = new();			
		WrEn = 'b1;
		enA = 'b0;
		enB = 'b1;
		for(int major = 0; major < DIM; major++)
			begin
				for(int minor = 0; minor < DIM; minor++)
					begin
						Ain[minor] = satc.get_A(major,minor);
						Bin[minor] = satc.get_B(major,minor);
					end
				@(posedge clk);
				Arow++;
			end
		enB = 'b0;
		enA = 'b0;
		WrEn = 'b0;
		rst_n = 'b0;
		@(posedge clk);
		rst_n = 'b1;
		WrEn ='b0;
		enA = 1'b1;
		enB = 1'b1;
		for(int inc = 0; inc < DIM; inc++)
			begin
				Bin[inc] = 'b0;
			end
			
		// This will hold enable high for (2*DIM) - 1 cycles, 
		// checking that the outputs of both A and B are 0
		for(i = 0; i < (2*DIM) - 1; i++)
			begin
				@(posedge clk);
				#1 for(j = 0; j < DIM; j++)
					begin
						if(Aout[j] != 'b0)
							begin
								$display("ERROR: Faulty Reset. Expected: 0, Got: %d for memA at Row: %d, Column: %d", Aout[j], i, j);
								$stop;
							end
						if(Bout[j] != 'b0)
							begin
								$display("ERROR: Faulty Reset. Expected: 0, Got: %d for memB at Row: %d, Column: %d", Bout[j], j, i);
								$stop;
							end
					end
				
			end
		// Feed in values into the arrays
		for (int test_num = 0; test_num < tests; test_num++)
			begin
				satc = new();			
				WrEn = 'b1;
				enA = 'b0;
				for(int major = 0; major < DIM; major++)
					begin
						for(int minor = 0; minor < DIM; minor++)
							begin
								Ain[minor] = satc.get_A(major,minor);
								Bin[minor] = satc.get_B(major,minor);
							end
						@(posedge clk);
						Arow++;
					end
				
				WrEn ='b0;
				enA = 1'b1;
				for(int inc = 0; inc < DIM; inc++)
					begin
						Bin[inc] = 'b0;
					end
				// Check that the arrays feed out correctly
				for (int major = 0; major < (2*DIM) - 1; major++)
					begin
						#1 for(int minor = 0; minor < DIM; minor++)
							begin
								realDataA = satc.get_next_A(minor);
								realDataB = satc.get_next_B(minor);
								 if(Aout[minor] != realDataA)
									begin
										$display("ERROR: Bad output. Expected: %d, Got: %d for memA at Row: %d, Column: %d", realDataA, Aout[minor], major, minor);
										$stop;
									end
								 if(Bout[minor] != realDataB)
									begin
										$display("ERROR: Bad output. Expected: %d, Got: %d for memB at Row: %d, Column: %d", realDataB, Bout[minor], minor, major);
										$stop;
									end
							end
							@(posedge clk);
							satc.next_cycle();
					end
			end
		$display("HOORAY! All tests pass!");
		$stop;
	end
endmodule

