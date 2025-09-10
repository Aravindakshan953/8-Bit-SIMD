module SIMD_x(multiplya,multiplyb,H,X,C,multoutput);

input [7:0] multiplya;
input [7:0] multiplyb;
input H;
input X;
input C;
output [7:0] multoutput;

wire [7:0] sel0 = H?8'hFF:(X?8'h0F:8'h03);
wire [7:0] sel1 = H?8'hFF:(X?8'hF0:8'h0C);
wire [7:0] sel2 = H?8'hFF:(X?8'hF0:8'h30);
wire [7:0] sel3 = H?8'hFF:(X?8'hF0:8'hC0);

wire [7:0] a0 = (multiplyb[0]?multiplya:8'h00)&sel0;
wire [7:0] a1 = (multiplyb[1]?multiplya:8'h00)&sel0;
wire [7:0] a2 = (multiplyb[2]?multiplya:8'h00)&sel1;
wire [7:0] a3 = (multiplyb[3]?multiplya:8'h00)&sel1;
wire [7:0] a4 = (multiplyb[4]?multiplya:8'h00)&sel2;
wire [7:0] a5 = (multiplyb[5]?multiplya:8'h00)&sel2;
wire [7:0] a6 = (multiplyb[6]?multiplya:8'h00)&sel3;
wire [7:0] a7 = (multiplyb[7]?multiplya:8'h00)&sel3;

wire[9:0] tmp0 = a0 + (a0 << 1);
wire[9:0] tmp1 = a2 + (a3 << 1);
wire[9:0] tmp2 = a4 + (a5 << 1);
wire[9:0] tmp3 = a6 + (a7 << 1);

wire [12:0] tmp_o0 = tmp0 + (tmp1 << 2);
wire [12:0] tmp_o1 = tmp2 + (tmp3 << 2);

wire [17:0] tmp_h0 = tmp_o0 + (tmp_o1 << 4);

assign multoutput[1:0] = tmp0[1:0];

assign multoutput[3:2] = C?tmp1[1:0] : (X ? tmp0[3:2] : tmp_h0[3:2]);
assign multoutput[5:4] = C?tmp1[1:0] : (X ? tmp0[1:0] : tmp_h0[5:4]);
assign multoutput[7:6] = C?tmp1[1:0] : (X ? tmp0[3:2] : tmp_h0[7:6]);



endmodule
