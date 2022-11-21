//相加之后定点数的补码转为sfp
module fix2sfp #(
    parameter expWidth    = 4,
    parameter sigWidth    = 4,
    parameter formatWidth = 9,
    parameter fixWidth    = 21
) (
    input  [   fixWidth-1:0] fixin,
    output [formatWidth-1:0] sfpout
);

  wire [         4:0] pos;
  reg  [  expWidth:0] exponent;
  reg  [  sigWidth:0] mantissa;
  wire [fixWidth-2:0] tempfix;


  assign tempfix = fixin[fixWidth-1] ? (~fixin[fixWidth-2:0]) : fixin[fixWidth-2:0];
  find_one_fix #(
      .fixWidth(fixWidth)
  ) u1_findone (
      .input_num(tempfix),
      .pos      (pos)
  );
  //四舍五入之前尾数数据
  always @(*) begin
    case (pos)
      5'd19: begin
        mantissa = tempfix[14] ? tempfix[18:15] + 1 : tempfix[18:15];
        exponent = 16;
      end
      5'd18: begin
        mantissa = tempfix[13] ? tempfix[17:14] + 1 : tempfix[17:14];
        exponent = 15;
      end
      5'd17: begin
        mantissa = tempfix[12] ? tempfix[16:13] + 1 : tempfix[16:13];
        exponent = 14;
      end
      5'd16: begin
        mantissa = tempfix[11] ? tempfix[15:12] + 1 : tempfix[15:12];
        exponent = 13;
      end
      5'd15: begin
        mantissa = tempfix[10] ? tempfix[14:11] + 1 : tempfix[14:11];
        exponent = 12;
      end
      5'd14: begin
        mantissa = tempfix[9] ? tempfix[13:10] + 1 : tempfix[13:10];
        exponent = 11;
      end
      5'd13: begin
        mantissa = tempfix[8] ? tempfix[12:9] + 1 : tempfix[12:9];
        exponent = 10;
      end
      5'd12: begin
        mantissa = tempfix[7] ? tempfix[11:8] + 1 : tempfix[11:8];
        exponent = 9;
      end
      5'd11: begin
        mantissa = tempfix[6] ? tempfix[10:7] + 1 : tempfix[10:7];
        exponent = 8;
      end
      5'd10: begin
        mantissa = tempfix[5] ? tempfix[9:6] + 1 : tempfix[9:6];
        exponent = 7;
      end
      5'd9: begin
        mantissa = tempfix[4] ? tempfix[8:5] + 1 : tempfix[8:5];
        exponent = 6;
      end
      5'd8: begin
        mantissa = tempfix[3] ? tempfix[7:4] + 1 : tempfix[7:4];
        exponent = 5;
      end
      5'd7: begin
        mantissa = tempfix[2] ? tempfix[6:3] + 1 : tempfix[6:3];
        exponent = 4;
      end
      5'd6: begin
        mantissa = tempfix[1] ? tempfix[5:2] + 1 : tempfix[5:2];
        exponent = 3;
      end
      5'd5: begin
        mantissa = tempfix[0] ? tempfix[4:1] + 1 : tempfix[4:1];
        exponent = 2;
      end
      5'd4: begin
        mantissa = tempfix[3:0];
        exponent = 2;
      end
      default: begin
        mantissa = 5'b0;
        exponent = 0;
      end
    endcase
  end
  assign sfpout[sigWidth-1:0]           = mantissa[4] ? 4'b0 : mantissa[3:0];
  assign sfpout[formatWidth-2:sigWidth] = mantissa[4] ? exponent + 1 : exponent;
  assign sfpout[formatWidth-1]          = fixin[fixWidth-1];

endmodule
