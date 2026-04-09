
module main (
    input wire CLOCK_50,
    input wire [1:0] KEY,
    input wire [9:0] SW,
    output wire [6:0] HEX0,
    output wire [6:0] HEX1,
    output wire [6:0] HEX2,
    output wire [6:0] HEX3,
    output wire [6:0] HEX4,
    output wire [6:0] HEX5,
    output wire [9:0] LEDR,
    output wire GPIO_SCK,
    input wire GPIO_DOUT
);
    wire tareButtonPulse, historyButtonPulse;
    wire newSampleReady;
    wire [23:0] rawSample;
    wire [23:0] smoothedSample;
    wire [23:0] tareOffset;
    wire [31:0] displayValueLive;
    wire [2:0] historyIndex;
    wire historyModeActive;
    wire [31:0] historyDisplayValue;
    wire historySavedPulse;
    wire [19:0] bcdDigits;

    ButtonOnePulse tareButton    (.clk(CLOCK_50), .buttonInput(KEY[0]), .pulse(tareButtonPulse));
    ButtonOnePulse historyButton (.clk(CLOCK_50), .buttonInput(KEY[1]), .pulse(historyButtonPulse));
    HX711Driver    loadCellReader (.clock50(CLOCK_50), .sck(GPIO_SCK), .dout(GPIO_DOUT), .dataReady(newSampleReady), .dataOutput(rawSample));
    SampleAverager weightAverager (.clk(CLOCK_50), .sampleValid(newSampleReady), .sampleInput(rawSample), .sampleOutput(smoothedSample));
    TareControl    tareControl   (.clk(CLOCK_50), .tarePress(tareButtonPulse), .rawData(smoothedSample), .dataReady(newSampleReady), .tareValue(tareOffset));

    wire [31:0] extendedSample = {8'd0, smoothedSample};
    wire [31:0] extendedTare   = {8'd0, tareOffset};
    wire signed [31:0] weightAfterTare = $signed(extendedSample) - $signed(extendedTare);
    wire signed [31:0] weightClamped   = (weightAfterTare < 0) ? 32'sd0 : weightAfterTare;

    UnitConverter unitConvert  (.netWeight(weightClamped), .unitSel(SW[1:0]), .displayValue(displayValueLive));
    HistoryStore  weightHistory (.clk(CLOCK_50), .dataReady(newSampleReady), .weightInput(displayValueLive), .historyPress(historyButtonPulse), .historyIndex(historyIndex), .historyMode(historyModeActive), .historyOutput(historyDisplayValue), .savedPulse(historySavedPulse));

    wire [31:0] displayValue = historyModeActive ? historyDisplayValue : displayValueLive;

    BinaryToBCD bcdConverter (.binaryInput(displayValue[19:0]), .bcdOutput(bcdDigits));

    wire [3:0] hundredths = bcdDigits[3:0];
    wire [3:0] tenths = bcdDigits[7:4];
    wire [3:0] ones = bcdDigits[11:8];
    wire [3:0] tens = bcdDigits[15:12];

    SevenSegmentDisplay hundredthsDisplay (.hex(hundredths), .hexDisplay(HEX0));
    SevenSegmentDisplay tenthsDisplay (.hex(tenths), .hexDisplay(HEX1));
    SevenSegmentDisplay onesDisplay (.hex(ones), .hexDisplay(HEX2));
    SevenSegmentDisplay tensDisplay (.hex(tens), .hexDisplay(HEX3));
    UnitDisplay unitLabel (.unitSel(SW[1:0]), .historyMode(historyModeActive), .hex5(HEX5), .hex4(HEX4));

    reg [23:0] savedLedStretch = 24'd0;
    always @(posedge CLOCK_50) begin
        if (historySavedPulse)
            savedLedStretch <= 24'hFFFFFF;
        else if (savedLedStretch > 24'd0)
            savedLedStretch <= savedLedStretch - 24'd1;
    end

    assign LEDR[0] = newSampleReady;
    assign LEDR[1] = tareButtonPulse;
    assign LEDR[2] = (savedLedStretch > 24'd0);
    assign LEDR[3] = historyModeActive;
    assign LEDR[6:4] = historyModeActive ? historyIndex : 3'd0;
    assign LEDR[9:7] = 3'd0;

endmodule

// When Key[0] Is Pressed, takes 4 ADC Samples and stores the zero offset.
module TareControl (
    input wire clk,
    input wire tarePress,
    input wire [23:0] rawData,
    input wire dataReady,
    output reg [23:0] tareValue = 24'd0
);
    reg [25:0] accumulator = 26'd0;
    reg [1:0] sampleCount = 2'd0;
    reg capturing   = 1'b0;

    always @(posedge clk) begin
        if (tarePress) begin
            capturing   <= 1'b1;
            accumulator <= 26'd0;
            sampleCount <= 2'd0;
        end else if (capturing && dataReady) begin
            if (sampleCount == 2'd3) begin
                tareValue <= (accumulator + {2'd0, rawData}) >> 2;
                capturing <= 1'b0;
            end else begin
                accumulator <= accumulator + {2'd0, rawData};
                sampleCount <= sampleCount + 2'd1;
            end
        end
    end
endmodule


// Converts the ADC counts to a displayable value multiplied by 100 (to fit intisde the 00.00 Display Sequence), Then converted from KG to LB to ML.
// Calibration is 420000 : My CountsPerKg from Testing to get accurate readings. If you're trying to replicate, you'll have to play around with this value.
module UnitConverter (
    input wire signed [31:0] netWeight,
    input wire [1:0] unitSel,
    output reg [31:0] displayValue
);
    localparam signed [31:0] countsPerKg = 32'd420144;

    wire signed [63:0] kilogramsX100Full = ({{32{netWeight[31]}}, netWeight} * 64'd100) / {{32{countsPerKg[31]}}, countsPerKg};
    wire signed [31:0] kilogramsX100 = kilogramsX100Full[31:0];
    wire signed [63:0] poundsX100Full = ({{32{kilogramsX100[31]}}, kilogramsX100} * 64'd22046) / 64'd10000;
    wire signed [63:0] millilitresX100Full = {{32{kilogramsX100[31]}}, kilogramsX100} * 64'd10;

    always @(*) begin
        case (unitSel)
            2'b00: displayValue = kilogramsX100;
            2'b01: displayValue = poundsX100Full[31:0];
            2'b10: displayValue = millilitresX100Full[31:0];
            default: displayValue = kilogramsX100;
        endcase
        if (displayValue[31]) displayValue = 32'd0;
    end
endmodule
