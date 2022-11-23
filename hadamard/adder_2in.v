//求补码并且求出两个数的和
module adder_2in #(
    parameter sigWidth   = 4,
    parameter low_expand = 2
) (
    input  [(sigWidth+4+low_expand)*2-1:0] input_num,
    output [sigWidth+3+low_expand : 0] adder_num
);

  wire [1:0] zero;
  wire [1:0] complement_sign;
  wire [(sigWidth+4+low_expand)*2-1:0] complement_num_buf;
  wire [(sigWidth+4+low_expand)*2-1:0] complement_num;

  genvar i;
  generate 
    for(i = 0;i < 2;i = i + 1) begin
      assign zero[i] = (input_num[(sigWidth+4+low_expand)*(i+1)-1 : (sigWidth+4+low_expand)*i] == {(sigWidth+4+low_expand){1'b0}});
  end
  endgenerate
  
  assign complement_num_buf[(sigWidth+4+low_expand)*1-2:(sigWidth+4+low_expand)*0] = complement_sign[0] ? ~input_num[(sigWidth+4+low_expand)*1-2:(sigWidth+4+low_expand)*0] + 1 : input_num[(sigWidth+4+low_expand)*1-2:(sigWidth+4+low_expand)*0];
  assign complement_num_buf[(sigWidth+4+low_expand)*2-2:(sigWidth+4+low_expand)*1] = complement_sign[1] ? ~input_num[(sigWidth+4+low_expand)*2-2:(sigWidth+4+low_expand)*1] + 1 : input_num[(sigWidth+4+low_expand)*2-2:(sigWidth+4+low_expand)*1];
  assign complement_num_buf[(sigWidth+4+low_expand)*1-1] = complement_sign[0];
  assign complement_num_buf[(sigWidth+4+low_expand)*2-1] = complement_sign[1];

  generate 
    for(i = 0; i < 2; i = i + 1) begin
      assign complement_num[(sigWidth+4+low_expand)*(i+1)-1 : (sigWidth+4+low_expand)*i] = zero[i] ? {(sigWidth+4+low_expand){1'b0}} : complement_num_buf[(sigWidth+4+low_expand)*(i+1)-1 : (sigWidth+4+low_expand)*i];
  end
  endgenerate
  assign adder_num = complement_num[(sigWidth+4+low_expand)*2-1 : sigWidth+4+low_expand] + complement_num[sigWidth+3+low_expand:0];

endmodule
