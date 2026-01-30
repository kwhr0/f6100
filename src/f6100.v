// IM6100 (PDP-8)
// Copyright 2026 © Yasuo Kuwahara

// MIT License

// not implemented: interrupt

`define GW1NZ

module f6100(clk, reset, tx_ready, tx_valid, tx_data, halted);
input clk, reset, tx_ready;
output [8:0] tx_data;
output tx_valid, halted;

reg [11:0] ac, mq, pc = 'h80;
reg l;

// STATE

localparam F = 0;
localparam I = 1;
localparam E = 2;

reg [2:0] s = 0;
always @(posedge clk)
	if (reset) s <= 0;
	else s <= { s[1] | ~indirect & s[0], indirect & s[0], s[2] | ~|s };

// DECODE

wire [11:0] douta, doutb;
reg [11:0] i;
always @(posedge clk)
	if (s[F]) i <= douta;

wire _and = i[11:9] == 3'b000;
wire tad = i[11:9] == 3'b001;
wire isz = i[11:9] == 3'b010;
wire dca = i[11:9] == 3'b011;
wire jms = i[11:9] == 3'b100;
wire jmp = i[11:9] == 3'b101;
wire iot = i[11:9] == 3'b110;
wire opr = i[11:9] == 3'b111;
wire opr_g1 = opr & ~i[8];
wire opr_g2 = opr & i[8] & ~i[0];
wire opr_g3 = opr & i[8] & i[0];
wire cla = opr & i[7];
wire iac = opr_g1 & i[0];
wire bsw = opr_g1 & i[3:1] == 3'b001;
wire sft = opr_g1 & |i[3:2];
wire cml = opr_g1 & i[4];
wire cma = opr_g1 & i[5];
wire cll = opr_g1 & i[6];
wire mql = opr_g3 & i[4];
wire mqa = opr_g3 & i[6];

// EA

wire [11:0] i_t = s[F] ? douta : i;
wire [11:0] adr_ea = { i_t[7] ? pc[11:7] : 5'b0, i_t[6:0] };
wire auto_inc = s[I] & ~|adr_ea[11:4] & adr_ea[3];
wire [11:0] adr_op = i_t[8] ? douta + auto_inc : adr_ea;
wire indirect = s[F] & ~&douta[11:10] & douta[8];

// DATA

wire [11:0] mq_d = {12{ ~(isz | cla) }} & ac;
wire [11:0] add_a = ({12{ ~mql }} & mq_d | {12{ mqa }} & mq) ^ {12{ cma }};
wire [11:0] add_b = {12{ tad | isz }} & doutb;
wire [12:0] add_y = add_a + add_b + (isz | iac);
wire lt = (~cll & l ^ cml) ^ (tad | iac) & add_y[12];
wire [12:0] sft_y = i[2] ?
	i[1] ? { add_y[10:0], lt, add_y[11] } : { add_y[11:0], lt } :
	i[1] ? { add_y[1:0], lt, add_y[11:2] } : { add_y[0], lt, add_y[11:1] };

always @(posedge clk) if (s[E]) begin
	if (dca) ac <= 0;
	else if (_and | tad | dca | opr & i[7] |
		opr_g1 & (i[5] | |i[3:0]) | opr_g3 & (i[6] | i[4]))
		ac <= _and | bsw ?
			_and ? ac & doutb : { add_y[5:0], add_y[11:6] } :
			sft ? sft_y[11:0] : add_y[11:0];
	if (tad | opr_g1 & (i[6] | |i[4:2] | i[0]))
		l <= sft ? sft_y[12] : lt;
	if (mql) mq <= mq_d;
end

// IOT

wire iot_tty = iot & i[8:3] == 6'b000100;
assign tx_valid = s[E] & iot_tty & i[2:0] == 3'b110;
assign tx_data = ac[8:0];

// PC

wire pc_inc_iot = iot_tty & i[2:0] == 3'b001 & tx_ready;
wire pc_inc_opr = opr_g2 & ((i[6] & ac[11] | i[5] & ~|ac | i[4] & l) ^ i[3]);
wire pc_inc = isz & &doutb | jms | pc_inc_opr | pc_inc_iot;
wire [11:0] pc_t = s[E] & (jms | jmp) ? adr_op : pc;
wire [11:0] pc_next = pc_t + (s[F] | s[E] & pc_inc);
reg halted = 0;
always @(posedge clk)
	if (reset) halted <= 0;
	else if (opr_g2 & i[1]) halted <= 1;
always @(posedge clk)
	if (reset) pc <= 'h80;
	else if (~halted & (s[F] & ~(&douta[11:8] & douta[1]) | s[E]))
		pc <= pc_next;

// MEMORY

wire [11:0] ada = s[F] | s[I] ? adr_ea : pc_next;
wire [11:0] dina = adr_op;
wire wra = s[I] & auto_inc;

wire [11:0] adb = adr_op;
wire [11:0] dinb = dca ? ac : jms ? pc : add_y[11:0];
wire wrb = s[E] & (isz | dca | jms);

`ifdef GW1NZ
wire [11:0] douta0, douta1;
wire [11:0] doutb0, doutb1;
mem #(.FILE("ram0.mem"))
	mem0(.clk(clk), .wra(wra & ~ada[10]), .wrb(wrb & ~adb[10]),
		.ada(ada[9:0]), .adb(adb[9:0]),
		.dina(dina), .dinb(dinb), .douta(douta0), .doutb(doutb0));
mem #(.FILE("ram1.mem"))
	mem1(.clk(clk), .wra(wra &  ada[10]), .wrb(wrb &  adb[10]),
		.ada(ada[9:0]), .adb(adb[9:0]),
		.dina(dina), .dinb(dinb), .douta(douta1), .doutb(doutb1));
reg ada_u, adb_u;
always @(posedge clk) begin
	ada_u <= ada[10];
	adb_u <= adb[10];
end
assign douta = ada_u ? douta1 : douta0;
assign doutb = adb_u ? doutb1 : doutb0;
`else
mem #(.AMSB(11))
	mem(.clk(clk), .wra(wra), .wrb(wrb), .ada(ada), .adb(adb),
		.dina(dina), .dinb(dinb), .douta(douta), .doutb(doutb));
`endif

wire [7:0] sta = wra ? 'h53 : 'h20;
wire [7:0] stb = wrb ? 'h53 : 'h20;
initial $monitor("%o %o %o %o %o %c %o %o %c %o %o",
	pc, i_t, s, ac, l, sta, ada, dina, stb, adb, dinb);
endmodule
