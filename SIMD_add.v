module SIMD_add(A,B,H,C,X,sub,cout,sum);
input [8:0]A;
input [8:0]B;
input H;
input C;
input X;
input sub;
output [7:0]sum;
output cout;

wire [7:0] b_real = sub ? (~B):B;
wire initial_carry_in = sub;

wire X_active = X || (!H && !C);
wire H_active = H && !X;
wire C_active = C && !H && !X;

wire c_in_seg0;
wire c_in_seg1;
wire c_in_seg2;
wire c_in_seg3;

assign c_in_seg0 = initial_carry_in;

wire [2:0] sum_seg0_carry = A[1:0] + b_real[1:0] + c_in_seg0;
wire [2:0] sum_seg1_carry = A[3:2] + b_real[3:2] + c_in_seg1;
wire [2:0] sum_seg2_carry = A[5:4] + b_real[5:4] + c_in_seg2;
wire [2:0] sum_seg3_carry = A[7:6] + b_real[7:6] + c_in_seg3;

assign c_in_seg1 = (X_active || H_active) ? sum_seg0_carry[2] : initial_carry_in;
assign c_in_seg2 = X_active ? sum_seg1_carry[2] : initial_carry_in;
assign c_in_seg3 = X_active ? sum_seg2_carry[2] : initial_carry_in;
assign sum = {sum_seg3_carry[1:0], sum_seg2_carry[1:0], sum_seg1_carry[1:0], sum_seg0_carry[1:0]};
assign carry_out = X_active ? sum_seg3_carry[2] : 1'b0;
