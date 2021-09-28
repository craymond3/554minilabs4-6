// Spec v1.1
module tpumac
 #(parameter BITS_AB=8,
   parameter BITS_C=16)
  (
   input clk, rst_n, WrEn, en,
   input signed [BITS_AB-1:0] Ain,
   input signed [BITS_AB-1:0] Bin,
   input signed [BITS_C-1:0] Cin,
   output reg signed [BITS_AB-1:0] Aout,
   output reg signed [BITS_AB-1:0] Bout,
   output reg signed [BITS_C-1:0] Cout
  );
  
  logic signed [BITS_C-1:0] C_reg_in;
  logic signed [BITS_C-1:0] Mult_result;
  logic signed [BITS_C-1:0] Add_result;
// Modelsim prefers "reg signed" over "signed reg"

assign Mult_result = Ain * Bin;
assign Add_result = Mult_result + Cout;
assign C_reg_in = (WrEn) ? Cin : Add_result;

always_ff@(posedge clk, negedge rst_n)
	begin
		if (~rst_n)
			begin
				Aout <= 'b0;
				Bout <= 'b0;
				Cout <= 'b0;
			end
		else
			begin
				if(WrEn)
					begin
						Cout <= C_reg_in;
					end
				else if(en)
					begin
						Aout <= Ain;
						Bout <= Bin;
						Cout <= C_reg_in;
					end
			end
	end
endmodule
