module SevenSegmentDisplay (
    input [3:0] hex,
    output reg [6:0] hexDisplay
);
    always @(*) begin
        case (hex)
            4'h0: hexDisplay = 7'b1000000;
            4'h1: hexDisplay = 7'b1111001;
            4'h2: hexDisplay = 7'b0100100;
            4'h3: hexDisplay = 7'b0110000;
            4'h4: hexDisplay = 7'b0011001;
            4'h5: hexDisplay = 7'b0010010;
            4'h6: hexDisplay = 7'b0000010;
            4'h7: hexDisplay = 7'b1111000;
            4'h8: hexDisplay = 7'b0000000;
            4'h9: hexDisplay = 7'b0010000;
            default: hexDisplay = 7'b1111111;
        endcase
    end
endmodule