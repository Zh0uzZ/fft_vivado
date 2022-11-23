module adder_4in #(
    parameter expWidth   = 4,
    parameter sigWidth   = 4,
    parameter low_expand = 2
) (
    input  [(sigWidth+4+low_expand)*4-1:0] manOffset,
    output [               (sigWidth-1):0] mantissa,
    output                                 sign,
    output [                 expWidth-1:0] expOffset
);

  wire [sigWidth+4+low_expand-1:0] manTemp;
  wire [                      3:0] pos;
  wire [sigWidth+4+low_expand-1:0] expand_mantissa;
  reg  [               sigWidth:0] mantissa_reg;
  reg  [             expWidth-1:0] expOffset_reg;


  assign manTemp =  manOffset[sigWidth+low_expand+3:0] 
                  + manOffset[2*(sigWidth+4+low_expand)-1:sigWidth+4+low_expand] 
                  + manOffset[3*(sigWidth+low_expand+4)-1:2*(sigWidth+low_expand+4)] 
                  + manOffset[4*(sigWidth+4+low_expand)-1:3*(sigWidth+4+low_expand)];

  assign expand_mantissa = manTemp[(sigWidth+4+low_expand)-1] ? {1'b1 , ~manTemp[(sigWidth+4+low_expand)-2:0] +1  } : manTemp;

  find_one #(
      .sigWidth  (sigWidth),
      .low_expand(low_expand)
  ) u1_find (
      .input_num(expand_mantissa[(sigWidth+4+low_expand)-2:0]),
      .pos      (pos)
  );
  always @(*) begin
    case (pos)
      // 4'd11: begin
      //   mantissa_reg = expand_mantissa[]
      //   mantissa[(sigWidth-1):0] = expand_mantissa[8:5];
      //   expOffset                = 7 - low_expand;
      // end
      4'd12: begin
        mantissa_reg  = expand_mantissa[7] ? expand_mantissa[11:8]         : expand_mantissa[11:8];
        // mantissa[(sigWidth-1):0] = expand_mantissa[8:5];
        expOffset_reg                = 8 - low_expand;
      end
      4'd11: begin
        mantissa_reg  = expand_mantissa[6] ? expand_mantissa[10:7]         : expand_mantissa[10:7];
        // mantissa[(sigWidth-1):0] = expand_mantissa[8:5];
        expOffset_reg                = 7 - low_expand;
      end
      4'd10: begin
        mantissa_reg  = expand_mantissa[5] ? expand_mantissa[9:6]         : expand_mantissa[9:6];
        // mantissa[(sigWidth-1):0] = expand_mantissa[8:5];
        expOffset_reg                = 6 - low_expand;
      end
      4'd9: begin
        mantissa_reg  = expand_mantissa[4] ? expand_mantissa[8:5]         : expand_mantissa[8:5];
        // mantissa[(sigWidth-1):0] = expand_mantissa[8:5];
        expOffset_reg                = 5 - low_expand;
      end
      4'd8: begin
        mantissa_reg  = expand_mantissa[3] ? expand_mantissa[7:4]         : expand_mantissa[7:4];
        // mantissa[(sigWidth-1):0] = expand_mantissa[7:4];
        expOffset_reg = 4 - low_expand;
      end
      4'd7: begin
        mantissa_reg  = expand_mantissa[2] ? expand_mantissa[6:3]         : expand_mantissa[6:3];
        // mantissa[(sigWidth-1):0] = expand_mantissa[6:3];
        expOffset_reg = 3 - low_expand;
      end
      4'd6: begin
        mantissa_reg  = expand_mantissa[1] ? expand_mantissa[5:2]         : expand_mantissa[5:2];
        // mantissa[(sigWidth-1):0] = expand_mantissa[5:2];
        expOffset_reg = 2 - low_expand;
      end
      4'd5: begin
        mantissa_reg  = expand_mantissa[0] ? expand_mantissa[4:1]         : expand_mantissa[4:1];
        // mantissa[(sigWidth-1):0] = expand_mantissa[4:1];
        expOffset_reg = 1 - low_expand;
      end
      4'd4: begin
        // mantissa_reg = {1'b0 , expand_mantissa[3:0]};
        mantissa_reg  = expand_mantissa[3:0];
        expOffset_reg = -low_expand;
      end
      4'd3: begin
        mantissa_reg  = {expand_mantissa[2:0], 1'b0};
        expOffset_reg = -1 - low_expand;
      end
      4'd2: begin
        mantissa_reg  = {expand_mantissa[1:0], 2'b0};
        expOffset_reg = -2 - low_expand;
      end
      4'd1: begin
        mantissa_reg  = {expand_mantissa[0], 3'b0};
        expOffset_reg = -3 - low_expand;
      end
      4'd0: begin
        mantissa_reg  = {4'b0};
        expOffset_reg = -4 - low_expand;
      end
      default: begin
        mantissa_reg  = 0;
        expOffset_reg = 4'b0;
      end
    endcase
  end
  assign sign = expand_mantissa[sigWidth+4+low_expand-1];
  assign mantissa = mantissa_reg[sigWidth] ? mantissa_reg[sigWidth-:4] : mantissa_reg[sigWidth-1:0];
  assign expOffset = mantissa_reg[sigWidth] ? expOffset_reg + 1 : expOffset_reg;


endmodule
