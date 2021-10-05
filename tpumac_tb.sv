
module tpumac_tb();
	localparam BITS_AB=8;
    localparam BITS_C=16;
	logic clk;
	logic rst_n;
	logic en;
	logic WrEn;
	logic signed [BITS_AB-1:0] Ain;
	logic signed [BITS_AB-1:0] Bin;
	logic signed [BITS_C-1:0] Cin;
	logic signed [BITS_AB-1:0] Aout;
	logic signed [BITS_AB-1:0] Bout;
	logic signed [BITS_C-1:0] Cout;
	
	// Intermediate values for checking
	logic signed [BITS_C-1:0] mult_val;
	logic signed [BITS_C-1:0] accum_expected;
	logic signed [BITS_AB-1:0] ABrange [6:0];
	
	integer acount;
	integer bcount;
	integer ccount;
	
	tpumac mac (
		.clk(clk),
		.rst_n(rst_n), 
		.en(en), 
		.WrEn(WrEn), 
		.Ain(Ain), 
		.Bin(Bin), 
		.Cin(Cin), 
		.Aout(Aout), 
		.Bout(Bout), 
		.Cout(Cout)
		);
		
	// Set up clock
	always #5 clk = ~clk;
	
	

	
	
	/*
	Reset
		at start
		from a number
	en
		check that Aout and Bout can only be written when en is enabled
		
	WrEn
		Check that Cout can only be written when WrEn and en are high
		
	Multiplication
		Check that the multiply function properly multiplies on a range of positive and negative numbers
		Brute force is not terrible honestly
	
	Accumulation
		Check that the module can accumulate a range of positive and negative numbers, try to get overflow
	*/
	
	initial begin
		ABrange[0] = 8'b1000_0000;
		ABrange[1] = 8'b1111_0000;
		ABrange[2] = 8'b1111_1111;
		ABrange[3] = 8'b0000_0000;
		ABrange[4] = 8'b0000_0001;
		ABrange[5] = 8'b0001_0000;;
		ABrange[6] = 8'b0111_1111;
		
		mult_val = 0;
		accum_expected = 0;
		
		clk = 1'b0;
		
		Ain = 'b0;
		Bin = 'b0;
		Cin = 'b0;
		WrEn = 0;
		en = 0;
		rst_n = 0;
		
		@(posedge clk);
		rst_n = 1;
		
		//Check rst_n
		#1 if(Aout != 0)
			begin
				$display("Error! Reset was not conducted properly for Aout. Expected: 0. got: %d", Aout);
				$stop;
			end
		#1 if(Bout != 0)
			begin
				$display("Error! Reset was not conducted properly for Bout. Expected: 0. got: %d", Bout);
				$stop;
			end
		#1 if(Cout != 0)
			begin
				$display("Error! Reset was not conducted properly for Cout. Expected: 0. got: %d", Cout);
				$stop;
			end
		
		
		// Check that en allows writing to Aout and Cout
		@(posedge clk);
			Ain = 8'hAA;
			Bin = 8'hBB;
		@(posedge clk);
			#1 if(Aout != 0)
				begin
					$display("Error! Aout was written without en. Expected: 0. got: %d", Aout);
					$stop;
				end
			#1 if(Bout != 0)
				begin
					$display("Error! Bout was written without en. Expected: 0. got: %d", Bout);
					$stop;
				end
			en = 1'b1;
		@(posedge clk);
			#1 if(Aout != 8'hAA)
				begin
					$display("Error! Wrong value written to Aout. Expected: AB. got: %d", Aout);
					$stop;
				end
			#1 if(Bout != 8'hBB)
				begin
					$display("Error! Wrong value written to Bout. Expected: CD. got: %d", Bout);
					$stop;
				end
			Ain = 8'h00;
			Bin = 8'h00;
			en = 1'b0;
			
		// Reset
			rst_n = 1'b0;
		@(posedge clk);
			rst_n = 1'b1;
			
			Cin = 16'hCCCC;
		@(posedge clk);
		// Check en and WrEn for Cin
		// Check that nothing is written when en and WrEn are not enabled
			#1 if(Cout != 0)
				begin
					$display("Error! Wrong value written to Cout. Expected: 0. got: %d", Cout);
					$stop;
				end
			en = 1'b1;
		@(posedge clk);
		// Check that Cin is not written to Cout if only en is high
			#1 if(Cout != 0)
				begin
					$display("Error! Wrong value written to Cout. Expected: 0. got: %d", Cout);
					$stop;
				end
			en = 1'b0;
			WrEn = 1'b1;
		@(posedge clk);
		// Check that Cin is not written to Cout when only WrEn is high
			#1 if(Cout != 0)
				begin
					$display("Error! Wrong value written to Cout. Expected: 0. got: %d", Cout);
					$stop;
				end
			en = 1'b1;
			WrEn = 1'b1;
		@(posedge clk);
		// Check that Cin is written to Cout only when both en and WrEn are high
			#1 if(Cout != 16'hCCCC)
				begin
					$display("Error! Wrong value written to Cout. Expected: ABBA. got: %d", Cout);
					$stop;
				end
			Cin = 16'h0000;
			WrEn = 1'b0;
			// Check all possible multiplications (Only 255*255)
			for(acount = -128; acount < 128; acount++)
				begin
					for(bcount = -128; bcount < 128; bcount++)
						begin
							rst_n = 1'b0;
							@(posedge clk);
							rst_n = 1'b1;
							Ain = acount;
							Bin = bcount;
							@(posedge clk);
							mult_val = Ain * Bin;
							#1 if(Cout != mult_val)
								begin
									$display("Error! Bad multiplication. Expected: %d. got: %d", mult_val, Cout);
									$stop;
								end
						end
				end
		// Check accumulation
			for(ccount = -32768; ccount < 32767; ccount++)
				begin
					for(acount = 0; acount < 7; acount++)
						begin
							for(bcount = 0; bcount < 7; bcount++)
								begin
									WrEn = 1'b1;
									Ain = ABrange[acount];
									Bin = ABrange[bcount];
									Cin = ccount;
									@(posedge clk);
									WrEn = 1'b0;
									@(posedge clk);
									mult_val = Ain * Bin;
									accum_expected = Cin + mult_val;
									#1 if(Cout != accum_expected)
									begin
										$display("Error! Bad accumulation. Expected: %d. got: %d", accum_expected, Cout);
										$stop;
									end
								
								end
						end
				end
		
		

		$display("All tests pass!");
		$stop;
	end
endmodule

