// find top one
module find_one_fix #(
  parameter fixWidth = 21
) (
  input  [fixWidth-2:0] input_num,
  output [         4:0] pos
);
  wire [15:0] data_4;
  wire [ 7:0] data_3;
  wire [ 3:0] data_2;
  wire [ 1:0] data_1;

  assign pos[4] = |input_num[(fixWidth-2):16];
  assign data_4 = pos[4] ? {{(33 - fixWidth) {1'b0}}, input_num[fixWidth-2:16]} : input_num[15:0];
  assign pos[3] = |data_4[15:8];
  assign data_3 = pos[3] ? data_4[15:8] : data_4[7:0];
  assign pos[2] = |data_3[7:4];
  assign data_2 = pos[2] ? data_3[7:4] : data_3[3:0];
  assign pos[1] = |data_2[3:2];
  assign data_1 = pos[1] ? data_2[3:2] : data_2[1:0];
  assign pos[0] = data_1[1];
endmodule
