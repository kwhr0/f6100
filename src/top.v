module top(I_clk, scl, sda, led);
input I_clk;
output scl, sda;
output [2:0] led;

localparam SYSCLK = 46000000;
pll pll(.clkin(I_clk), .clkout(clk), .lock(rst_n));

wire tx_ready, tx_valid;
wire [8:0] tx_data;
f6100 f6100(.clk(clk), .reset(~rst_n), .halted(halted),
	.tx_ready(tx_ready), .tx_valid(tx_valid), .tx_data(tx_data));

i2c #(.CLK(SYSCLK)) i2c(.clk(clk), .data(tx_data), .wr(tx_valid), .scl(scl_t), .sda(sda_t), .busy(i2c_busy));
assign scl = scl_t ? 1'bZ : 1'b0;
assign sda = sda_t ? 1'bZ : 1'b0;
assign tx_ready = ~i2c_busy;
assign led = { halted, 1'b1, ~halted };

endmodule
