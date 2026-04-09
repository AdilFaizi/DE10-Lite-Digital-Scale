
module UnitDisplay (
    input [1:0] unitSel,
    input historyMode,
    output reg [6:0] hex5,
    output reg [6:0] hex4
);

    always @(*) begin
        if (historyMode) begin //HI for History
            hex5 = 7'b0001001;
            hex4 = 7'b1111001; 
        end else begin
            case (unitSel)
                2'b00: begin //KG for Kilogram
                    hex5 = 7'b0001010;
                    hex4 = 7'b0000010; 
                end
                2'b01: begin //Lb for Pounds
                    hex5 = 7'b1000111; 
                    hex4 = 7'b0000011; 
                end
                2'b10: begin//ML for Mililitre
                    hex5 = 7'b1101010; 
                    hex4 = 7'b1000111;
                end
                default: begin
                    hex5 = 7'b1111111;
                    hex4 = 7'b1111111;
                end
            endcase
        end
    end

endmodule