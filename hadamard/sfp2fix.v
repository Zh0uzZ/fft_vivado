//sfp转为定点数的补码
module sfp2fix #(
    parameter expWidth = 4,
    parameter sigWidth = 4,
    parameter formatWidth = 9,
    parameter fixWidth = 21
) (
    input [formatWidth-1:0] sfpin,
    output [fixWidth-1:0] fixout
);

    wire [fixWidth-1:0] temp;
    wire [fixWidth-1:0] temp1;
    wire zero;

    assign zero = ~(sfpin[formatWidth-2:sigWidth] == 4'b0000);
    assign temp = {{(fixWidth-13){1'b0}}, zero , sfpin[sigWidth-1:0] , 7'b0};
    assign temp1 = (sfpin[formatWidth-2:sigWidth] > 8) ? (temp<<(sfpin[formatWidth-2:sigWidth]-8)) : (temp>>(8-sfpin[formatWidth-2:sigWidth]));
    assign fixout[fixWidth-2:0] = (sfpin[formatWidth-1] & zero) ? (~temp1) : temp1 ;
    assign fixout[fixWidth-1] = zero ? sfpin[formatWidth-1] : 1'b0;
    
endmodule