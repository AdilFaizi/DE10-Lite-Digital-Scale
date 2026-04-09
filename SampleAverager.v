
module SampleAverager (
    input wire clk,
    input wire sampleValid,
    input wire [23:0] sampleInput,
    output reg [23:0] sampleOutput = 24'd0
);

    reg [23:0] reading0 = 24'd0;
    reg [23:0] reading1 = 24'd0;
    reg [23:0] reading2 = 24'd0;
    reg [23:0] reading3 = 24'd0;

    always @(posedge clk) begin
        if (sampleValid) begin
            reading3 <= reading2;
            reading2 <= reading1;
            reading1 <= reading0;
            reading0 <= sampleInput;
            sampleOutput <= ({2'd0, reading0} + {2'd0, reading1} + {2'd0, reading2} + {2'd0, reading3}) >> 2;
        end
    end

endmodule