module sfpadd #(
  parameter expWidth    = 4,
  parameter sigWidth    = 4,
  parameter formatWidth = 9
) (
  input                    clk,
  input start,
  input  [formatWidth-1:0] a,
  input  [formatWidth-1:0] b,
  output [formatWidth-1:0] c
);
  localparam fixWidth = 21;

  wire [fixWidth-1:0] fixa;
  wire [fixWidth-1:0] fixb;
  wire [fixWidth-1:0] fixc;
  wire [fixWidth-1:0] addA;
  wire [fixWidth-1:0] addB;
  reg [1:0] flag_reg;
  
  sfp2fix #(
    .expWidth(expWidth),
    .sigWidth(sigWidth),
    .formatWidth(formatWidth),
    .fixWidth(fixWidth)
  ) u1_sfp2fix (
    .sfpin(a),
    .fixout(addA)
  );

  sfp2fix #(
    .expWidth(expWidth),
    .sigWidth(sigWidth),
    .formatWidth(formatWidth),
    .fixWidth(fixWidth)
  ) u2_sfp2fix (
    .sfpin(b),
    .fixout(addB)
  );
  add_21 u1add(
    .CLK(clk),
    .A(fixa),
    .B(fixb),
    .P(fixc)
  );
  always @(posedge clk) begin
    if(start) begin
        fixa <= addA;
        fixb <= addB;
        flag_reg <= 0;        
    end  else begin
        fixa <= fixa;
        fixb <= fixb;
        flag_reg <= flag_reg + 1;
    end
  end
endmodule
