module mem #(parameter AMSB = 9, parameter DMSB = 11, parameter FILE = "ram.mem")
	(clk, wra, wrb, ada, adb, dina, dinb, douta, doutb);
input clk, wra, wrb;
input [AMSB:0] ada, adb;
input [DMSB:0] dina, dinb;
output reg [DMSB:0] douta, doutb;

reg [DMSB:0] mem[0:2**(AMSB+1)-1];
initial $readmemh(FILE, mem);
always @(posedge clk) begin
	if (wra) begin
		mem[ada] <= dina;
		douta <= dina;
	end
	else douta <= mem[ada];
	if (wrb) begin
		mem[adb] <= dinb;
		doutb <= dinb;
	end
	else doutb <= mem[adb];
end

endmodule
