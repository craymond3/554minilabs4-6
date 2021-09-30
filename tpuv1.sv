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

	logic enA;
	logic enB;
	logic enC;
	logic WrEnA;
	logic WrEnC;
    logic signed [BITS_AB-1:0] Ain [DIM-1:0];
    logic [$clog2(DIM)-1:0] Arow;
    logic signed [BITS_AB-1:0] Aout [DIM-1:0];
    logic signed [BITS_AB-1:0] Bin [DIM-1:0];
	logic signed [BITS_AB-1:0] Bout [DIM-1:0];
	logic signed [BITS_C-1:0] Cin [DIM-1:0];
	logic signed [BITS_C-1:0] Cout [DIM-1:0];
	logic [$clog2(DIM)-1:0] Crow;
	logic signed [BITS_C-1:0] Creg [DIM-1:0];
	logic [ADDRW-1:0] dataOutInt; 
	logic [$clog2(2*DIM)-1:0] timer;
	logic busy;
	
	logic a_mem_range;
	logic b_mem_range;
	logic c_mem_range;
	logic a_write;
	logic b_write;
	logic c_write;
	logic c_read;
	assign a_mem_range = (addr >= 16'h0100) && (addr <= 16'h013f);
	assign b_mem_range = (addr >= 16'h0200) && (addr <= 16'h023f);
	assign c_mem_range = (addr >= 16'h0300) && (addr <= 16'h037f);
	assign a_write = r_w && a_mem_range;
	assign b_write = r_w && b_mem_range;
	assign c_write = r_w && c_mem_range;
	assign c_read = (~r_w) && c_mem_range;
	assign dataOut = dataOutInt;
	assign busy = (addr == 16'h0400) || (timer > 0);
	
	
	// Mechanism to run the matrix mult for the required number of cycles
	always_ff@(posedge clk, negedge rst_n)
		begin
			if(~rst_n)
				begin
					timer <= 'b0;
				end
			else
				begin
					if(busy)
						begin
							timer <= timer + 1;
						end
					else
						begin
							timer <= 'b0;
						end
				end
		end
	
	
	// Logic for mechanism to store Cin Row
	always_ff@(posedge clk, negedge rst_n)
		begin
			if(~rst_n)
				begin
					for(int i = 0; i < DIM; i++)
						begin
							Creg[i] <= 'b0;
						end
				end
			else
				begin
					if (c_write)
						begin
							if(addr[3])
								begin
									for(int i = 0; i < DATAW/BITS_C; i++)
										begin
											Creg[i + (DATAW/BITS_C)] <= dataIn[(i*BITS_C) +: BITS_C];
										end
								end
							// Lower 4 elements
							else
								begin
									for(int i = 0; i < DATAW/BITS_C; i++)
										begin
											Creg[i] <= dataIn[(i*BITS_C) +: BITS_C];
										end
								end
						end
				end
		end
   
   
   // Logic for A and B writes can be handled in comb logic
	always_comb
		begin
			enA = 'b0;
			enB = 'b0;
			enC = 'b0;
			WrEnA = 'b0;
			WrEnC = 'b0;
			Arow = 'b0;
			Crow = 'b0;
			for(int i = 0; i < DIM; i++)
				begin
					Ain [i] = 'b0;
					Bin [i] = 'b0;
					Cin [i] = 'b0;
					Creg [i] = 'b0;
				end
			if(busy)
				begin
				enA = 1'b1;
				enB = 1'b1;
				enC = 1'b1;
				end
			else if(a_write)
				begin
					for(int i = 0; i < DATAW/BITS_AB; i++)
						begin
							Ain[i] = dataIn[(i*BITS_AB)+:BITS_AB];
							Arow = addr[5:3];
							WrEnA = 1'b1;
						end
				end
			else if(b_write)
				begin
					for(int i = 0; i < DATAW/BITS_AB; i++)
						begin
							Bin[i] = dataIn[(i*BITS_AB)+:BITS_AB];
							enB = 1'b1;
						end
				end
			else if (c_write)
				begin
					WrEnC = 1'b1;
					Crow = addr[6:4];
					// As the systolic_array can only write by row, then it will
					// take technically 2 write commands from the input to form a whole row
					// To avoid using timers, every time a write for C is recieved, the entire row
					// Is written, however, whichever half of the row is being written is also being
					// stored in a register so that when the next write is recieved, that the stored half
					// and the new input half are but sent to C at the same time. While this means that each
					// Row will be written twice, the first one only being half-correct, it makes the logic
					// A bit simpler (no timers) and it should also result in a correct answer
					for(int i = 0; i < DATAW/BITS_C; i++)
						begin
							// Upper 4 elements
							if(addr[3])
								begin
									Cin[i + (DATAW/BITS_C)] = dataIn[(i*BITS_C)+:BITS_C];
									Cin[i] = Creg[i];
								end
							// Lower 4 elements
							else
								begin
									Cin[i] = dataIn[(i*BITS_C)+:BITS_C];
									Cin[i + (DATAW/BITS_C)] = Creg[i + (DATAW/BITS_C)];
								end
						end
				end		
			else if (c_read)
				begin
					Crow = addr[6:4];
					for(int i = 0; i < DATAW/BITS_C; i++)
						begin
							if(addr[3])
								begin
									dataOutInt[(i*BITS_C)+:BITS_C] = Cout[i + (DATAW/BITS_C)];
								end
							else
								begin
									dataOutInt[(i*BITS_C)+:BITS_C] = Cout[i];
								end
						end
				end
			else
				begin
					enA = 'b0;
					enB = 'b0;
					enC = 'b0;
					WrEnA = 'b0;
					WrEnC = 'b0;
					Arow = 'b0;
					Crow = 'b0;
					for(int i = 0; i < DIM; i++)
						begin
							Ain [i] = 'b0;
							Bin [i] = 'b0;
							Cin [i] = 'b0;
							Creg [i] = 'b0;
						end
				end
		end
		
		
		
		//Logic for C write and mat_mult needs to be handled in state machine
   
	memA  #(
    .BITS_AB(BITS_AB),
    .DIM(DIM)    
	) a_fifo (    
	.clk	(clk),
	.rst_n	(rst_n),
	.en		(enA),
	.WrEn	(WrEnA),    
	.Ain	(Ain),    
	.Arow	(Arow),    
	.Aout	(Aout)   
	);
	
	memB  #(    
	.BITS_AB(BITS_AB),    
	.DIM(DIM)    
	) b_fifo (    
	.clk	(clk),
	.rst_n	(rst_n),
	.en		(enB),    
	.Bin	(Bin),    
	.Bout	(Bout)    
	);
	
	systolic_array #(
		.BITS_AB(BITS_AB),
		.BITS_C(BITS_C),
		.DIM(DIM)
   ) array (
   .clk		(clk),
   .rst_n	(rst_n),
   .WrEn	(WrEnC),
   .en		(enC),
   .A		(Aout),
   .B		(Bout),
   .Cin		(Cin),
   .Crow	(Crow),
   .Cout	(Cout)
   );
   
endmodule