module tpuv1
  #(
    parameter BITS_AB=8,
    parameter BITS_C=16,
    parameter DIM=8,
    parameter ADDRW=16,
    parameter DATAW=64
    )
   (
    input clk, rst_n, r_w, // r_w=0 read, =1 write
    input [DATAW-1:0] dataIn,
    output [DATAW-1:0] dataOut,
    input [ADDRW-1:0] addr
   );
   
   // COULD TRY MAKING MEMORY AN ARRAY OF 64 BIT CHUNKS
   logic [BITS_AB-1:0] memory [ADDRW-1:0];
   integer i;
   
   logic doing_math;
   
   
   logic enA;
   logic enB;
   
   // This Should handle memory reads and writes
   
   always_ff@(posedge clk, negedge rst_n)
		begin
			if(~rst_n)
				begin
					for(i = 0; i < (2**ADDRW); i++)
						begin
							memory[i] <= 'b0;
						end
				end
			else
				begin
					if(r_w)
						begin
							if((addr >= 0x100) && (addr <= 0x0400))
								begin
									for(i = 0; i < (DATAW/BITS_AB); i++)
										begin
											memory[addr + i] <= dataIn[((i+1)*BITS_AB)-1:i*BITS_AB];
										end
								end
						end
					else
						begin
							if((addr >= 0x0300) && (addr <= 0x037f))
								begin
									for(i = 0; i < (DATAW/BITS_AB); i++)
										begin
											dataOut[((i+1)*BITS_AB)-1:i*BITS_AB] = memory[addr + i];
										end
								end
						end
				end
		end
		
		
	// State machine
	enum {IDLE, MAT_MUL} currState, nextState;
	always_ff@(posedge clk, negedge rst_n)
		begin
			if(~rst)
				begin
				end
			else
				begin
					case(currState)
						IDLE:
							begin
								
							end
						MAT_MUL:
							begin
							end
					endcase
					currState <= nextState;
				end
		end
		
		
	// State Transition logic
	always_comb
		begin
			case(currState)
				IDLE:
					begin
						if((addr == 0x0400) & r_w)
							begin
								nextState = MAT_MUL;
							end
					end
				MAT_MUL:
					begin
						doing_math = 1'b1;
					end
			endcase
		end
   
	
	memA #(
		.BITS_AB(BITS_AB),
		.DIM(DIM)
	) fifo_a(
		.clk(clk),
		.rst_n(rst_n),
		.en(),
		.WrEn(),
		.Ain(),
		.Arow(),
		.Aout()
	);
		
	memB #(
		.BITS_AB(BITS_AB),
		.DIM(DIM)
	) fifo_b(
		.clk(clk),
		.rst_n(rst_n),
		.en(),
		.bin(),
		.bout()
	);
		
	systolic_array #(
		.BITS_AB(BITS_AB),
		.BITS_C(BITS_C),
		.DIM(DIM)
	) sys_array(
		.clk(clk),
		.rst_n(rst_n),
		.WrEn(),
		.en(),
		.A(),
		.B(),
		.Cin(),
		.Crow(),
		.Cout()
	);
	
	 
	 
	 
endmodule