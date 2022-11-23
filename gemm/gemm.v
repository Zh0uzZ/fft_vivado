// control[1:0] , control[1] = 1 : size4  

module gemm #(
    parameter expWidth    = 4,
    parameter sigWidth    = 4,
    parameter formatWidth = 9,
    parameter low_expand  = 2
) (
    input                              clk,
    input                              rst,
    input                              start,
    input                              control,
    input      [(formatWidth*4-1) : 0] input_real,
    input      [(formatWidth*4-1) : 0] input_imag,
    output reg [(formatWidth*4-1) : 0] output_real,
    output reg [(formatWidth*4-1) : 0] output_imag,
    output reg                         gemm_done
);
  localparam IDLE = 3'b000;  //等待start信号
  localparam EXPONENT_NORMALIZE = 3'b001;  //指数归一化，找到最大指数
  localparam MANTISSA_OFFSET = 3'b010;  //尾数对齐
  localparam COMPLEMENT = 3'b011;  //取尾数的补码
  localparam ADDER = 3'b100;  //尾数补码进行加法
  localparam COMBINE = 3'b101;  //对sfp数字进行指数、尾数的拼接



  reg  [                          3:0] i;
  reg  [                          2:0] current_state;
  reg  [                          2:0] next_state;
  wire [               (expWidth-1):0] max_exp             [3:0];
  wire [             (expWidth*4-1):0] exp_offset_num      [3:0];
  reg  [             (expWidth*4-1):0] exp_offset_num_reg  [3:0];
  wire [(sigWidth+4+low_expand)*4-1:0] man_off             [3:0];
  reg  [(sigWidth+4+low_expand)*4-1:0] man_off_reg         [3:0];
  wire [(sigWidth+4+low_expand)*4-1:0] adder_num           [7:0];
  reg  [(sigWidth+4+low_expand)*4-1:0] adder_num_reg       [7:0];

  wire [                 expWidth-1:0] expOffset           [7:0];
  reg  [                 expWidth-1:0] expOffset_reg       [7:0];
  wire [                 sigWidth-1:0] mantissa            [7:0];
  reg  [                 sigWidth-1:0] mantissa_reg        [7:0];
  wire [                          7:0] sign;
  reg  [                          7:0] sign_reg;
  wire [               4*expWidth-1:0] exp_normalizer_input[3:0];
  wire [                          3:0] man_shifter_sign    [3:0];
  wire [               4*sigWidth-1:0] man_shifter_input   [3:0];

  wire [                          3:0] complement_sign     [7:0];

  wire [              formatWidth-1:0] output_real_wire    [3:0];
  wire [              formatWidth-1:0] output_imag_wire    [3:0];






  //debug signals 
  wire [              formatWidth-1:0] wire_input_real     [3:0];
  wire [              formatWidth-1:0] wire_input_imag     [3:0];
  wire [              formatWidth-1:0] wire_output_real    [3:0];
  wire [              formatWidth-1:0] wire_output_imag    [3:0];
  wire [              formatWidth-1:0] wire_twiddle_real   [3:0];
  wire [              formatWidth-1:0] wire_twiddle_imag   [3:0];
  genvar j;
  generate
    for (j = 0; j < 4; j = j + 1) begin
      assign wire_input_real[j]  = input_real[formatWidth*(j+1)-1:formatWidth*j];
      assign wire_input_imag[j]  = input_imag[formatWidth*(j+1)-1:formatWidth*j];
      assign wire_output_real[j] = output_real[formatWidth*(j+1)-1:formatWidth*j];
      assign wire_output_imag[j] = output_imag[formatWidth*(j+1)-1:formatWidth*j];
      // assign wire_twiddle_real[j] = twiddle_real[formatWidth*(j+1)-1:formatWidth*j];
      // assign wire_twiddle_imag[j] = twiddle_imag[formatWidth*(j+1)-1:formatWidth*j];
    end
  endgenerate



  //state machine state change 状态机状态变化
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      current_state <= IDLE;
      for (i = 0; i < 4; i = i + 1) begin
        exp_offset_num_reg[i] <= {(expWidth * 4) {1'b0}};
      end
      for (i = 0; i < 4; i = i + 1) begin
        man_off_reg[i] <= {(40) {1'b0}};
      end
      for (i = 0; i < 8; i = i + 1) begin
        adder_num_reg[i] <= {(40) {1'b0}};
      end
      for (i = 0; i < 8; i = i + 1) begin
        expOffset_reg[i] <= {(4) {1'b0}};
      end
      for (i = 0; i < 8; i = i + 1) begin
        mantissa_reg[i] <= {(4) {1'b0}};
      end
      output_real <= 36'b0;
      output_imag <= 36'b0;
      sign_reg <= 8'b0;

    end else begin
      current_state <= next_state;
    end
  end



  //状态中变量的赋值
  always @(*) begin
    case (current_state)
      IDLE: begin
        if (start) begin
          next_state = EXPONENT_NORMALIZE;
        end else begin
          next_state = IDLE;
        end
        gemm_done = 0;
      end
      EXPONENT_NORMALIZE: begin
        begin
          next_state = MANTISSA_OFFSET;
          for (i = 0; i < 4; i = i + 1) begin
            exp_offset_num_reg[i] = exp_offset_num[i];
          end
        end
      end
      MANTISSA_OFFSET: begin
        begin
          next_state = COMPLEMENT;
          for (i = 0; i < 4; i = i + 1) begin
            man_off_reg[i] = man_off[i];
          end
        end
      end
      COMPLEMENT: begin
        begin
          next_state = ADDER;
          for (i = 0; i < 8; i = i + 1) begin
            adder_num_reg[i] = adder_num[i];
          end
        end
      end
      ADDER: begin
        begin
          next_state = COMBINE;
          for (i = 0; i < 8; i = i + 1) begin
            mantissa_reg[i]  = mantissa[i];
            sign_reg[i]      = sign[i];
            expOffset_reg[i] = expOffset[i];
          end
        end
      end
      COMBINE: begin
        begin
          next_state = IDLE;
          output_real = {
            output_real_wire[0], output_real_wire[1], output_real_wire[2], output_real_wire[3]
          };
          output_imag = {
            output_imag_wire[0], output_imag_wire[1], output_imag_wire[2], output_imag_wire[3]
          };
          gemm_done = 1;
        end
      end
      default: begin
        next_state = IDLE;
      end
    endcase
  end




  //找出最大指数值，并进行尾数移位
  //第一个指数对齐module
  assign exp_normalizer_input[0] = control ? {
      input_real[(formatWidth*4-2):(formatWidth*4-1-expWidth)],
      input_real[(formatWidth*3-2):(formatWidth*3-1-expWidth)],
      input_real[(formatWidth*2-2):(formatWidth*2-1-expWidth)],
      input_real[(formatWidth-2) : (formatWidth-1-expWidth)]
    } : {
      input_real[(formatWidth*4-2):(formatWidth*4-1-expWidth)],
      input_real[(formatWidth*3-2):(formatWidth*3-1-expWidth)],
      8'b00000000
    };
  exp_normalizer #(  //real[3:0]  or real[3:2]
      .expWidth(expWidth)
  ) u1_exp_normalizer (
      .input_exp     (exp_normalizer_input[0]),
      .max_exp       (max_exp[0]),
      .exp_offset_num(exp_offset_num[0])
  );


  assign exp_normalizer_input[1] = control ? {
      input_real[(formatWidth*4-2):(formatWidth*4-1-expWidth)],
      input_real[(formatWidth*2-2):(formatWidth*2-1-expWidth)],
      input_imag[(formatWidth*3-2):(formatWidth*3-1-expWidth)],
      input_imag[(formatWidth-2) : (formatWidth-1-expWidth)]
    }: {
      input_real[(formatWidth*2-2):(formatWidth*2-1-expWidth)],
      input_real[(formatWidth*1-2):(formatWidth*1-1-expWidth)],
      8'b00000000
    };

  exp_normalizer #(  //real[3] , real[1] , imag[2] , imag[0]  or real[1:0]
      .expWidth(expWidth)
  ) u2_exp_normalizer (
      .input_exp     (exp_normalizer_input[1]),
      .max_exp       (max_exp[1]),
      .exp_offset_num(exp_offset_num[1])
  );


  assign exp_normalizer_input[2] = control ? {
      input_imag[(formatWidth*4-2):(formatWidth*4-1-expWidth)],
      input_imag[(formatWidth*3-2):(formatWidth*3-1-expWidth)],
      input_imag[(formatWidth*2-2):(formatWidth*2-1-expWidth)],
      input_imag[(formatWidth-2) : (formatWidth-1-expWidth)]
    }: {
      input_imag[(formatWidth*4-2):(formatWidth*4-1-expWidth)],
      input_imag[(formatWidth*3-2):(formatWidth*3-1-expWidth)],
      8'b00000000
    };
  exp_normalizer #(
      .expWidth(expWidth)
  ) u3_exp_normalizer (  //imag[3:0] or imag[3:2] 
      .input_exp     (exp_normalizer_input[2]),
      .max_exp       (max_exp[2]),
      .exp_offset_num(exp_offset_num[2])
  );


  assign exp_normalizer_input[3] = control ? {
      input_real[(formatWidth*3-2):(formatWidth*3-1-expWidth)],
      input_real[(formatWidth-2):(formatWidth-1-expWidth)],
      input_imag[(formatWidth*4-2):(formatWidth*4-1-expWidth)],
      input_imag[(formatWidth*2-2) : (formatWidth*2-1-expWidth)]
    }: {
      input_imag[(formatWidth*2-2):(formatWidth*2-1-expWidth)],
      input_imag[(formatWidth*1-2):(formatWidth*1-1-expWidth)],
      8'b00000000
    };
  exp_normalizer #(  //real[2] real[0] imag[3] imag[1]   or  imag[1:0]
      .expWidth(expWidth)
  ) u4_exp_normalizer (
      .input_exp     (exp_normalizer_input[3]),
      .max_exp       (max_exp[3]),
      .exp_offset_num(exp_offset_num[3])
  );



  //根据max_exp 求得mantissa移位结果

  assign man_shifter_sign[0] = control ? {
      input_real[formatWidth*4-1],
      input_real[formatWidth*3-1],
      input_real[formatWidth*2-1],
      input_real[formatWidth-1]
    } : {
      input_real[formatWidth*4-1],
      input_real[formatWidth*3-1],
      2'b00
    };
  assign man_shifter_input[0] = control ? {
      input_real[(formatWidth*4-2-expWidth):(formatWidth*3)],
      input_real[(formatWidth*3-2-expWidth):(formatWidth*2)],
      input_real[(formatWidth*2-2-expWidth):(formatWidth*1)],
      input_real[formatWidth-2-expWidth:0]
    } : {
      input_real[(formatWidth*4-2-expWidth):(formatWidth*3)],
      input_real[(formatWidth*3-2-expWidth):(formatWidth*2)],
      8'b0000_0000
    } ;
  man_shifter #(  //real[3:0]
      .expWidth  (expWidth),
      .sigWidth  (sigWidth),
      .low_expand(low_expand)
  ) u1_man_shifter (
      .exp_offset_num(exp_offset_num_reg[0]),
      .mantissa      (man_shifter_input[0]),
      .sign          (man_shifter_sign[0]),
      .man_off       (man_off[0])
  );


  assign man_shifter_sign[1] = control ? {
      input_real[formatWidth*4-1],
      input_real[formatWidth*2-1],
      input_imag[formatWidth*3-1],
      input_imag[formatWidth-1]
    } : {
      input_real[formatWidth*2-1],
      input_real[formatWidth*1-1],
      2'b00
    };
  assign man_shifter_input[1] = control ? {
      input_real[(formatWidth*4-2-expWidth):(formatWidth*3)],
      input_real[(formatWidth*2-2-expWidth):(formatWidth*1)],
      input_imag[(formatWidth*3-2-expWidth):(formatWidth*2)],
      input_imag[formatWidth-2-expWidth:0]
    } : {
      input_real[(formatWidth*2-2-expWidth):(formatWidth)],
      input_real[(formatWidth*1-2-expWidth):0],
      8'b0000_0000
    } ;
  man_shifter #(  //real[3] , real[1] , imag[2] , imag[0]
      .expWidth  (expWidth),
      .sigWidth  (sigWidth),
      .low_expand(low_expand)
  ) u2_man_shifter (
      .exp_offset_num(exp_offset_num_reg[1]),
      .mantissa      (man_shifter_input[1]),
      .sign          (man_shifter_sign[1]),
      .man_off       (man_off[1])
  );


  assign man_shifter_sign[2] = control ? {
      input_imag[formatWidth*4-1],
      input_imag[formatWidth*3-1],
      input_imag[formatWidth*2-1],
      input_imag[formatWidth-1]
    } : {
      input_imag[formatWidth*4-1],
      input_imag[formatWidth*3-1],
      2'b00
    };
  assign man_shifter_input[2] = control ? {
      input_imag[(formatWidth*4-2-expWidth):(formatWidth*3)],
      input_imag[(formatWidth*3-2-expWidth):(formatWidth*2)],
      input_imag[(formatWidth*2-2-expWidth):(formatWidth*1)],
      input_imag[formatWidth-2-expWidth:0]
    } : {
      input_imag[(formatWidth*4-2-expWidth):(formatWidth*3)],
      input_imag[(formatWidth*3-2-expWidth):(formatWidth*2)],
      8'b0000_0000
    } ;
  man_shifter #(  //imag[3:0]
      .expWidth  (expWidth),
      .sigWidth  (sigWidth),
      .low_expand(low_expand)
  ) u3_man_shifter (
      .exp_offset_num(exp_offset_num_reg[2]),
      .mantissa      (man_shifter_input[2]),
      .sign          (man_shifter_sign[2]),
      .man_off       (man_off[2])
  );


  assign man_shifter_sign[3] = control ? {
      input_real[formatWidth*3-1],
      input_real[formatWidth*1-1],
      input_imag[formatWidth*4-1],
      input_imag[formatWidth*2-1]
    } : {
      input_imag[formatWidth*2-1],
      input_imag[formatWidth*1-1],
      2'b00
    };
  assign man_shifter_input[3] = control ? {
      input_real[(formatWidth*3-2-expWidth):(formatWidth*2)],
      input_real[(formatWidth*1-2-expWidth):(formatWidth*0)],
      input_imag[(formatWidth*4-2-expWidth):(formatWidth*3)],
      input_imag[formatWidth*2-2-expWidth:formatWidth*1]
    } : {
      input_imag[(formatWidth*2-2-expWidth):(formatWidth*1)],
      input_imag[(formatWidth*1-2-expWidth):0],
      8'b0000_0000
    } ;
  man_shifter #(  //real[2] real[0] imag[3] imag[1]
      .expWidth  (expWidth),
      .sigWidth  (sigWidth),
      .low_expand(low_expand)
  ) u4_man_shifter (
      .exp_offset_num(exp_offset_num_reg[3]),
      .mantissa      (man_shifter_input[3]),
      .sign          (man_shifter_sign[3]),
      .man_off       (man_off[3])
  );




  //求出adder_4in的加数

  assign complement_sign[0] = control ? 4'b0000 : 4'b0000;
  complement #(
      .sigWidth  (sigWidth),
      .low_expand(low_expand)
  ) u1_complement (
      .sign          (complement_sign[0]),
      .input_num     (man_off_reg[0]),
      .complement_num(adder_num[0])
  );

  assign complement_sign[1] = control ? 4'b0101 : 4'b0000;
  complement #(
      .sigWidth  (sigWidth),
      .low_expand(low_expand)
  ) u2_complement (
      .sign          (complement_sign[1]),
      .input_num     (man_off_reg[1]),
      .complement_num(adder_num[1])
  );


  assign complement_sign[2] = control ? 4'b0101 : 4'b0100;
  complement #(
      .sigWidth  (sigWidth),
      .low_expand(low_expand)
  ) u3_complement (
      .sign          (complement_sign[2]),
      .input_num     (man_off_reg[0]),
      .complement_num(adder_num[2])
  );


  assign complement_sign[3] = control ? 4'b0110 : 4'b0100;
  complement #(
      .sigWidth  (sigWidth),
      .low_expand(low_expand)
  ) u4_complement (
      .sign          (complement_sign[3]),
      .input_num     (man_off_reg[1]),
      .complement_num(adder_num[3])
  );


  assign complement_sign[4] = control ? 4'b0000 : 4'b0000;
  complement #(
      .sigWidth  (sigWidth),
      .low_expand(low_expand)
  ) u5_complement (
      .sign          (complement_sign[4]),
      .input_num     (man_off_reg[2]),
      .complement_num(adder_num[4])
  );


  assign complement_sign[5] = control ? 4'b1001 : 4'b0000;
  complement #(
      .sigWidth  (sigWidth),
      .low_expand(low_expand)
  ) u6_complement (
      .sign          (complement_sign[5]),
      .input_num     (man_off_reg[3]),
      .complement_num(adder_num[5])
  );


  assign complement_sign[6] = control ? 4'b0101 : 4'b0100;
  complement #(
      .sigWidth  (sigWidth),
      .low_expand(low_expand)
  ) u7_complement (
      .sign          (complement_sign[6]),
      .input_num     (man_off_reg[2]),
      .complement_num(adder_num[6])
  );


  assign complement_sign[7] = control ? 4'b0101 : 4'b0100;
  complement #(
      .sigWidth  (sigWidth),
      .low_expand(low_expand)
  ) u8_complement (
      .sign          (complement_sign[7]),
      .input_num     (man_off_reg[3]),
      .complement_num(adder_num[7])
  );




  //计算加法的部分
  adder_4in #(
      .expWidth  (expWidth),
      .sigWidth  (sigWidth),
      .low_expand(low_expand)
  ) u1_adder (
      .manOffset(adder_num_reg[0]),
      .mantissa (mantissa[0]),
      .sign     (sign[0]),
      .expOffset(expOffset[0])
  );
  adder_4in #(
      .expWidth  (expWidth),
      .sigWidth  (sigWidth),
      .low_expand(low_expand)
  ) u2_adder (
      .manOffset(adder_num_reg[1]),
      .mantissa (mantissa[1]),
      .sign     (sign[1]),
      .expOffset(expOffset[1])
  );
  adder_4in #(
      .expWidth  (expWidth),
      .sigWidth  (sigWidth),
      .low_expand(low_expand)
  ) u3_adder (
      .manOffset(adder_num_reg[2]),
      .mantissa (mantissa[2]),
      .sign     (sign[2]),
      .expOffset(expOffset[2])
  );
  adder_4in #(
      .expWidth  (expWidth),
      .sigWidth  (sigWidth),
      .low_expand(low_expand)
  ) u4_adder (
      .manOffset(adder_num_reg[3]),
      .mantissa (mantissa[3]),
      .sign     (sign[3]),
      .expOffset(expOffset[3])
  );
  adder_4in #(
      .expWidth  (expWidth),
      .sigWidth  (sigWidth),
      .low_expand(low_expand)
  ) u5_adder (
      .manOffset(adder_num_reg[4]),
      .mantissa (mantissa[4]),
      .sign     (sign[4]),
      .expOffset(expOffset[4])
  );
  adder_4in #(
      .expWidth  (expWidth),
      .sigWidth  (sigWidth),
      .low_expand(low_expand)
  ) u6_adder (
      .manOffset(adder_num_reg[5]),
      .mantissa (mantissa[5]),
      .sign     (sign[5]),
      .expOffset(expOffset[5])
  );
  adder_4in #(
      .expWidth  (expWidth),
      .sigWidth  (sigWidth),
      .low_expand(low_expand)
  ) u7_adder (
      .manOffset(adder_num_reg[6]),
      .mantissa (mantissa[6]),
      .sign     (sign[6]),
      .expOffset(expOffset[6])
  );
  adder_4in #(
      .expWidth  (expWidth),
      .sigWidth  (sigWidth),
      .low_expand(low_expand)
  ) u8_adder (
      .manOffset(adder_num_reg[7]),
      .mantissa (mantissa[7]),
      .sign     (sign[7]),
      .expOffset(expOffset[7])
  );


  //进行拼接 combine
  combine #(
      .expWidth   (expWidth),
      .sigWidth   (sigWidth),
      .formatWidth(formatWidth)
  ) u1_combine (
      .max_exp   (max_exp[0]),
      .mantissa  (mantissa_reg[0]),
      .sign      (sign_reg[0]),
      .expOffset (expOffset_reg[0]),
      .output_sfp(output_real_wire[0])
  );
  combine #(
      .expWidth   (expWidth),
      .sigWidth   (sigWidth),
      .formatWidth(formatWidth)
  ) u2_combine (
      .max_exp   (max_exp[1]),
      .mantissa  (mantissa_reg[1]),
      .sign      (sign_reg[1]),
      .expOffset (expOffset_reg[1]),
      .output_sfp(output_real_wire[1])
  );
  combine #(
      .expWidth   (expWidth),
      .sigWidth   (sigWidth),
      .formatWidth(formatWidth)
  ) u3_combine (
      .max_exp   (max_exp[0]),
      .mantissa  (mantissa_reg[2]),
      .sign      (sign_reg[2]),
      .expOffset (expOffset_reg[2]),
      .output_sfp(output_real_wire[2])
  );
  combine #(
      .expWidth   (expWidth),
      .sigWidth   (sigWidth),
      .formatWidth(formatWidth)
  ) u4_combine (
      .max_exp   (max_exp[1]),
      .mantissa  (mantissa_reg[3]),
      .sign      (sign_reg[3]),
      .expOffset (expOffset_reg[3]),
      .output_sfp(output_real_wire[3])
  );
  combine #(
      .expWidth   (expWidth),
      .sigWidth   (sigWidth),
      .formatWidth(formatWidth)
  ) u5_combine (
      .max_exp   (max_exp[2]),
      .mantissa  (mantissa_reg[4]),
      .sign      (sign_reg[4]),
      .expOffset (expOffset_reg[4]),
      .output_sfp(output_imag_wire[0])
  );
  combine #(
      .expWidth   (expWidth),
      .sigWidth   (sigWidth),
      .formatWidth(formatWidth)
  ) u6_combine (
      .max_exp   (max_exp[3]),
      .mantissa  (mantissa_reg[5]),
      .sign      (sign_reg[5]),
      .expOffset (expOffset_reg[5]),
      .output_sfp(output_imag_wire[1])
  );
  combine #(
      .expWidth   (expWidth),
      .sigWidth   (sigWidth),
      .formatWidth(formatWidth)
  ) u7_combine (
      .max_exp   (max_exp[2]),
      .mantissa  (mantissa_reg[6]),
      .sign      (sign_reg[6]),
      .expOffset (expOffset_reg[6]),
      .output_sfp(output_imag_wire[2])
  );
  combine #(
      .expWidth   (expWidth),
      .sigWidth   (sigWidth),
      .formatWidth(formatWidth)
  ) u8_combine (
      .max_exp   (max_exp[3]),
      .mantissa  (mantissa_reg[7]),
      .sign      (sign_reg[7]),
      .expOffset (expOffset_reg[7]),
      .output_sfp(output_imag_wire[3])
  );


endmodule
