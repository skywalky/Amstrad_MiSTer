// PlayCity expansion by TotO,
// implemented in VHDL by Slingshot
// Verilog version with some modifications by Sorgelig
// https://www.cpcwiki.eu/index.php/PlayCity

module playSIDy
(
   	input         clock,
		input         reset,
   	input	        conf,
   
   	input         phi_n,
//   	input         phi_en,
   	input  [15:0] addr,
   	input   [7:0] din,
//  	output  [7:0] dout,
//   	input   [7:0] cpu_di,		// for CTC RETI detection
//		input         m1_n,
   	input         iorq_n,
// 	input         rd_n,
   	input         wr_n,
//		output        int_n,
//   	output        nmi,
//		input         cursor,   
   	
		output  [15:0] audio_out_l,
		output  [15:0] audio_out_r
);

reg ena = 1;
reg stereo = 0;
always @(posedge clock) begin
	stereo <= (conf ? 1 : 0);
end

wire sid_sel = (ena && ~iorq_n && ~wr_n && addr[15:8] == 8'hF8 && addr[7:6] == 2'b00);

reg phi_n_2;
always @(posedge phi_n) begin
	reg [2:0] div = 0;
	div     <= div + 1'd1;
	phi_n_2 <= !div[1:0];
end

reg  sid_ce;
always @(posedge clock) begin
	reg sid_ce_d;
	sid_ce_d <= phi_n_2;
	sid_ce <= (~sid_ce_d & phi_n_2);
end

wire n_cs_left = ~(sid_sel && ~addr[5]);
wire [15:0] sid_left_out;

MOS6581 MOS6581_left
(
	.n_reset(~reset),
	.clk_en(sid_ce),
	.clk(clock),
	.rw(0),
	.n_cs(n_cs_left),
	.data(din),
	.addr(addr[4:0]),
	.audio_out(sid_left_out)
);

wire n_cs_right = ~(sid_sel && addr[5]);
wire [15:0] sid_right_out;

MOS6581 MOS6581_right
(
	.n_reset(~reset),
	.clk_en(sid_ce),
	.clk(clock),
	.rw(0),
	.n_cs(n_cs_right),
	.data(din),
	.addr(addr[4:0]),
	.audio_out(sid_right_out)
);

assign audio_out_l = (ena ? sid_left_out : {15'd0});
assign audio_out_r = (ena ? (stereo ? sid_right_out : sid_left_out) : {15'd0});

endmodule