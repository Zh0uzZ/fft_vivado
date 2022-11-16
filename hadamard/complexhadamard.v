module complexhadamard #(
    parameter expWidth    = 4,
    parameter sigWidth    = 4,
    parameter formatWidth = 9,
    parameter fixWidth    = 21
) (
    input                          clk,
    input                          rst,
    input                          start,
    input      [formatWidth*4-1:0] input_real,
    input      [formatWidth*4-1:0] input_imag,
    input      [formatWidth*4-1:0] twiddle_real,
    input      [formatWidth*4-1:0] twiddle_imag,
    output reg [formatWidth*4-1:0] output_real,
    output reg [formatWidth*4-1:0] output_imag,
    output reg                     hadamard_done
);
  localparam IDLE = 3'b000;
  localparam MULTI = 3'b001;
  localparam SFP2FIX = 3'b010;
  localparam ADDER = 3'b011;
  localparam FIX2SFP = 3'b100;
  localparam DONE = 3'b101;


  reg  [            3:0] i;
  reg  [            2:0] current_state;
  reg  [            2:0] next_state;
  wire [formatWidth-1:0] sfp_real       [7:0];
  wire [formatWidth-1:0] sfp_imag       [7:0];
  reg  [formatWidth-1:0] sfp_real_reg   [7:0];
  reg  [formatWidth-1:0] sfp_imag_reg   [7:0];
  wire [   fixWidth-1:0] fix_real       [7:0];
  wire [   fixWidth-1:0] fix_imag       [7:0];
  reg  [   fixWidth-1:0] fix_real_reg   [7:0];
  reg  [   fixWidth-1:0] fix_imag_reg   [7:0];
  wire [         48-1:0] adder_real     [1:0];
  wire [         48-1:0] adder_imag     [1:0];
  reg  [   fixWidth-1:0] adder_real_reg [3:0];
  reg  [   fixWidth-1:0] adder_imag_reg [3:0];
  wire [formatWidth-1:0] output_sfp_real[3:0];
  wire [formatWidth-1:0] output_sfp_imag[3:0];




  //debug signals 
  wire [              formatWidth-1:0] wire_input_real     [3:0];
  wire [              formatWidth-1:0] wire_input_imag     [3:0];
  wire [              formatWidth-1:0] wire_output_real    [3:0];
  wire [              formatWidth-1:0] wire_output_imag    [3:0];
  wire [              formatWidth-1:0] wire_twiddle_real   [3:0];
  wire [              formatWidth-1:0] wire_twiddle_imag   [3:0];
  genvar k;
  generate
    for (k = 0; k < 4; k = k + 1) begin
      assign wire_input_real[k]  = input_real[formatWidth*(k+1)-1:formatWidth*k];
      assign wire_input_imag[k]  = input_imag[formatWidth*(k+1)-1:formatWidth*k];
      assign wire_output_real[k] = output_real[formatWidth*(k+1)-1:formatWidth*k];
      assign wire_output_imag[k] = output_imag[formatWidth*(k+1)-1:formatWidth*k];
      assign wire_twiddle_real[k] = twiddle_real[formatWidth*(k+1)-1:formatWidth*k];
      assign wire_twiddle_imag[k] = twiddle_imag[formatWidth*(k+1)-1:formatWidth*k];
    end
  endgenerate





  always @(posedge clk or negedge rst) begin
    if (~rst) begin
      current_state <= 0;
      for (i = 0; i < 7; i = i + 1) begin
        sfp_real_reg[i] <= {(formatWidth) {1'b0}};
        sfp_imag_reg[i] <= {(formatWidth) {1'b0}};
        fix_real_reg[i] <= {(fixWidth) {1'b0}};
        fix_imag_reg[i] <= {(fixWidth) {1'b0}};
      end

      for (i = 0; i < 4; i = i + 1) begin
        adder_real_reg[i] <= {(fixWidth) {1'b0}};
        adder_imag_reg[i] <= {(fixWidth) {1'b0}};
      end

    end else begin
      current_state <= next_state;
    end
  end
  always @(*) begin
    case (current_state)
      IDLE: begin
        if (start) begin
          next_state = MULTI;
        end else begin
          next_state = IDLE;
        end
        hadamard_done = 0;
      end
      MULTI: begin
        for ( i = 0; i < 8; i = i + 1) begin
          sfp_real_reg[i] = sfp_real[i];
          sfp_imag_reg[i] = sfp_imag[i];
        end
        next_state = SFP2FIX;
      end
      SFP2FIX: begin
        for ( i = 0; i < 8; i = i + 1) begin
          fix_real_reg[i] = fix_real[i];
          fix_imag_reg[i] = fix_imag[i];
        end
        next_state = ADDER;
      end
      ADDER: begin
        for ( i = 0; i < 2; i = i + 1) begin
          adder_real_reg[i]   = adder_real[i][44:24];
          adder_real_reg[i+2] = adder_real[i][20:0];
          adder_imag_reg[i]   = adder_imag[i][44:24];
          adder_imag_reg[i+2] = adder_imag[i][20:0];
        end
        next_state = FIX2SFP;
      end
      FIX2SFP: begin
        output_real = {
          output_sfp_real[3], output_sfp_real[2], output_sfp_real[1], output_sfp_real[0]
        };
        output_imag = {
          output_sfp_imag[3], output_sfp_imag[2], output_sfp_imag[1], output_sfp_imag[0]
        };
        hadamard_done = 1;
        next_state = IDLE;
      end

    endcase
  end

  genvar j;

  //sfp相乘
  generate
    for (j = 0; j < 4; j = j + 1) begin : u_sfpmulti0
      sfpmulti #(
          .expWidth   (expWidth),
          .sigWidth   (sigWidth),
          .formatWidth(formatWidth)
      ) u0_sfpmulti (
          .a   (input_real[(j+1)*formatWidth-1 : j*formatWidth]),
          .b   (twiddle_real[(j+1)*formatWidth-1 : j*formatWidth]),
          .c   (sfp_real[j])
      );
    end
  endgenerate
  generate
    for (j = 0; j < 4; j = j + 1) begin : u_sfpmulti1
      sfpmulti #(
          .expWidth   (expWidth),
          .sigWidth   (sigWidth),
          .formatWidth(formatWidth)
      ) u1_sfpmulti (
          .a   (input_real[(j+1)*formatWidth-1 : j*formatWidth]),
          .b   (twiddle_imag[(j+1)*formatWidth-1 : j*formatWidth]),
          .c   (sfp_imag[j])
      );
    end
  endgenerate
  generate
    for (j = 0; j < 4; j = j + 1) begin : u_sfpmulti2
      sfpmulti #(
          .expWidth   (expWidth),
          .sigWidth   (sigWidth),
          .formatWidth(formatWidth)
      ) u2_sfpmulti (
          .a   (input_imag[(j+1)*formatWidth-1 : j*formatWidth]),
          .b   (twiddle_real[(j+1)*formatWidth-1 : j*formatWidth]),
          .c   (sfp_imag[j+4])
      );
    end
  endgenerate
  generate
    for (j = 0; j < 4; j = j + 1) begin : u_sfpmulti3
      sfpmulti #(
          .expWidth   (expWidth),
          .sigWidth   (sigWidth),
          .formatWidth(formatWidth)
      ) u3_sfpmulti (
          .a   (input_imag[(j+1)*formatWidth-1 : j*formatWidth]),
          .b   (twiddle_imag[(j+1)*formatWidth-1 : j*formatWidth]),
          .c   (sfp_real[j+4])
      );
    end
  endgenerate

  //sfp2fix，将sfp转化为定点数 21bit
  generate
    for (j = 0; j < 8; j = j + 1) begin : u_sfp2fix0
      sfp2fix #(
          .expWidth   (expWidth),
          .sigWidth   (sigWidth),
          .formatWidth(formatWidth),
          .fixWidth   (fixWidth)
      ) u0_sfp2fix (
          .sfpin (sfp_imag_reg[j]),
          .fixout(fix_imag[j])
      );
    end
  endgenerate
  generate
    for (j = 0; j < 4; j = j + 1) begin : u_sfp2fix1
      sfp2fix #(
          .expWidth   (expWidth),
          .sigWidth   (sigWidth),
          .formatWidth(formatWidth),
          .fixWidth   (fixWidth)
      ) u1_sfp2fix (
          .sfpin (sfp_real_reg[j]),
          .fixout(fix_real[j])
      );
    end
  endgenerate
  generate
    for (j = 4; j < 8; j = j + 1) begin : u_sfp2fix2
      sfp2fix #(
          .expWidth   (expWidth),
          .sigWidth   (sigWidth),
          .formatWidth(formatWidth),
          .fixWidth   (fixWidth)
      ) u2_sfp2fix (
          .sfpin ({~sfp_real_reg[j][formatWidth-1], sfp_real_reg[j][formatWidth-2:0]}),
          .fixout(fix_real[j])
      );
    end
  endgenerate

  //定点数相加 21 + 21 = 21
  generate
    for (j = 0; j < 2; j = j + 1) begin : u_adder0
      // add_21 u0_adder (
      //   // .CLK(clk),
      //   .A  (fix_real_reg[j]),
      //   .D  (fix_real_reg[j+4]),
      //   .P  (adder_real[j])
      // );
      ADD_2IN u0_ADD (
          .CONCAT({3'b0, fix_real_reg[j], 3'b0, fix_real_reg[j+2]}),
          .C({3'b0, fix_real_reg[j+4], 3'b0, fix_real_reg[j+6]}),
          .P(adder_real[j])
      );
    end
  endgenerate
  generate
    for (j = 0; j < 2; j = j + 1) begin : u_adder1
      ADD_2IN u1_ADD (
          .CONCAT({3'b0, fix_imag_reg[j], 3'b0, fix_imag_reg[j+2]}),
          .C     ({3'b0, fix_imag_reg[j+4], 3'b0, fix_imag_reg[j+6]}),
          .P     (adder_imag[j])
      );
      // add_21 u1_adder (
      //     // .CLK(clk),
      //     .A(fix_imag_reg[j]),
      //     .D(fix_imag_reg[j+4]),
      //     .P(adder_imag[j])
      // );
    end
  endgenerate

  //fix2sfp ,定点数转换为sfp
  generate
    for (j = 0; j < 4; j = j + 1) begin : u_fix2sfp_real
      fix2sfp #(
          .expWidth   (expWidth),
          .sigWidth   (sigWidth),
          .formatWidth(formatWidth),
          .fixWidth   (fixWidth)
      ) u0_fix2sfp (
          .fixin (adder_real_reg[j]),
          .sfpout(output_sfp_real[j])
      );
    end
  endgenerate
  generate
    for (j = 0; j < 4; j = j + 1) begin : u_fix2sfp_imag
      fix2sfp #(
          .expWidth   (expWidth),
          .sigWidth   (sigWidth),
          .formatWidth(formatWidth),
          .fixWidth   (fixWidth)
      ) u1_fix2sfp (
          .fixin (adder_imag_reg[j]),
          .sfpout(output_sfp_imag[j])
      );
    end
  endgenerate



endmodule
