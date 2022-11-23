module man_shifter_2 #(
  parameter expWidth   = 3,
  parameter sigWidth   = 3,
  parameter low_expand = 2
) (
  input  [             (expWidth*2-1) : 0] exp_offset_num,
  input  [             (sigWidth*2-1) : 0] mantissa,
  input  [                            2:0] sign,
  output [(sigWidth+4+low_expand)*2-1 : 0] man_off
);

  genvar i;
  generate
    for (i = 0; i < 2; i = i + 1) begin : ushifter0
      assign man_off[(sigWidth+4+low_expand)*(i+1)-2 : (sigWidth+4+low_expand)*i] = 
      {3'b001 , mantissa[sigWidth*i+sigWidth-1:sigWidth*i] , {low_expand{1'b0}}} >> exp_offset_num[expWidth*i+expWidth-1:expWidth*i];
    end
  endgenerate

  generate
    for (i = 0; i < 2; i = i + 1) begin : ushifter1
      assign man_off[(sigWidth+4+low_expand)*(i+1)-1] = sign[i];
    end
  endgenerate

endmodule
