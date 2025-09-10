module SIMD_shift(shiftin,H,C,X,left,shiftout);
input [7:0] shiftin;
input H;
input C;
input X;
input left;
output [7:0] shiftout;

wire [7:0] shift_8bit = left ? {shiftin[6:0], 1'b0} : {1'b0, shiftin[7:1]};

wire [3:0] half_up = left ? {shiftin[6:4], 1'b0} : {1'b0, shiftin[7:5]};
wire [3:0] half_lo = left ? {shiftin[2:0], 1'b0} : {1'b0, shiftin[3:1]};
wire[7:0] shift_half = {half_up, half_lo};

wire [1:0] octa_3 = left ? {shiftin[6], 1'b0} : {1'b0, shiftin[7]};
wire [1:0] octa_2 = left ? {shiftin[4], 1'b0} : {1'b0, shiftin[5]};
wire [1:0] octa_1 = left ? {shiftin[2], 1'b0} : {1'b0, shiftin[3]};
wire [1:0] octa_0 = left ? {shiftin[2], 1'b0} : {1'b0, shiftin[1]};
wire [7:0] shift_octa = {octa_3, octa_2, octa_1, octa_0};

assign shiftout = 0 ? shift_octa : (H ? shift_half : shift_8bit);

endmodule
