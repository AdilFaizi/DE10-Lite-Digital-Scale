module BinaryToBCD (
    input [19:0] binaryInput,
    output reg [19:0] bcdOutput
);

    integer bitIndex;
    reg [39:0] shiftRegister;

    always @(*) begin
        shiftRegister = {20'd0, binaryInput};

        for (bitIndex = 0; bitIndex < 20; bitIndex = bitIndex + 1) begin
            if (shiftRegister[23:20] >= 5)
                shiftRegister[23:20] = shiftRegister[23:20] + 3;
            if (shiftRegister[27:24] >= 5)
                shiftRegister[27:24] = shiftRegister[27:24] + 3;
            if (shiftRegister[31:28] >= 5)
                shiftRegister[31:28] = shiftRegister[31:28] + 3;
            if (shiftRegister[35:32] >= 5)
                shiftRegister[35:32] = shiftRegister[35:32] + 3;
            if (shiftRegister[39:36] >= 5)
                shiftRegister[39:36] = shiftRegister[39:36] + 3;

            shiftRegister = shiftRegister << 1;
        end

        bcdOutput = shiftRegister[39:20];
    end

endmodule