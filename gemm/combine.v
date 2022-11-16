module combine #(
    parameter expWidth    = 4,
    parameter sigWidth    = 4,
    parameter formatWidth = 9
) (
    input  [   expWidth-1:0] max_exp,
    input  [   sigWidth-1:0] mantissa,
    input                    sign,
    input  [   expWidth-1:0] expOffset,
    output [formatWidth-1:0] output_sfp
);

  wire [expWidth:0] expand_exp;
  wire sign_wire;

  assign expand_exp = max_exp + expOffset;
  assign sign_wire = (expand_exp[expWidth-1:0] == 4'b0000) ? 1'b0 : sign;
  assign output_sfp = expOffset[expWidth-1] ? (expand_exp[expWidth] ? {sign_wire,expand_exp[expWidth-1:0],mantissa} : {formatWidth*{1'b0}} ) : (expand_exp[expWidth] ? {formatWidth*{1'b1}} : {sign_wire , expand_exp[expWidth-1:0],mantissa});
endmodule
