module vector_size4 #(
    parameter expWidth    = 4,
    parameter sigWidth    = 4,
    parameter formatWidth = 9,
    parameter low_expand  = 2,
    parameter fixWidth    = 21
) (
    input                          clk,
    input                          rst,
    input                          start,
    input  [                1 : 0] control,
    input  [(formatWidth*4-1) : 0] input_real,
    input  [(formatWidth*4-1) : 0] input_imag,
    input  [(formatWidth*4-1) : 0] twiddle_real,
    input  [(formatWidth*4-1) : 0] twiddle_imag,
    output [(formatWidth*4-1) : 0] output_real,
    output [(formatWidth*4-1) : 0] output_imag,
    output                         vector_done
);

  wire gemm_done;
  wire hadamard_start, hadamard_done;
  wire vector_done;
  wire [(formatWidth*4-1) : 0] temp_real, temp_imag;

  gemm #(
      .expWidth   (expWidth),
      .sigWidth   (sigWidth),
      .formatWidth(formatWidth),
      .low_expand (low_expand)
  ) u_gemm (
      .clk        (clk),
      .rst        (rst),
      .start      (start),
      .control    (control[1]),
      .input_real (input_real),
      .input_imag (input_imag),
      .output_real(temp_real),
      .output_imag(temp_imag),
      .gemm_done  (gemm_done)
  );


  complexhadamard #(
      .expWidth   (expWidth),
      .sigWidth   (sigWidth),
      .formatWidth(formatWidth),
      .fixWidth   (fixWidth)
  ) u_complexhadamard (
      .clk          (clk),
      .rst          (rst),
      .start        (gemm_done),
      .input_real   (temp_real),
      .input_imag   (temp_imag),
      .twiddle_real (twiddle_real),
      .twiddle_imag (twiddle_imag),
      .output_real  (output_real),
      .output_imag  (output_imag),
      .hadamard_done(hadamard_done)
  );
  assign hadamard_start = control[0] ? gemm_done : 1'b0;
  assign vector_done    = control[0] ? hadamard_done : gemm_done;

endmodule
