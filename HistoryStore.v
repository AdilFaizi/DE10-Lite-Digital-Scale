
module HistoryStore (
    input wire clk,
    input wire dataReady,
    input wire [31:0] weightInput,
    input wire historyPress,
    output reg [2:0] historyIndex = 3'd0,
    output reg historyMode = 1'b0,
    output reg [31:0] historyOutput = 32'd0,
    output reg savedPulse = 1'b0
);

    reg [31:0] savedReadings [0:4];
    reg [2:0] writePointer = 3'd0;
    reg [31:0] lastSavedValue = 32'd0;
    reg [31:0] anchorValue = 32'd0;
    reg [31:0] stabilityTimer = 32'd0;
    reg alreadySaved = 1'b0;
    reg anchorIsSet = 1'b0;
    reg [31:0] browseTimer = 32'd0;

    localparam [31:0] stableThreshold = 32'd5;
    localparam [31:0] stableTime = 32'd100_000_000;
    localparam [31:0] saveThreshold = 32'd5;
    localparam [31:0] browseTimeout = 32'd100_000_000;

    integer slotIndex;
    reg [2:0] selectedSlot;

    initial begin
        for (slotIndex = 0; slotIndex < 5; slotIndex = slotIndex + 1)
            savedReadings[slotIndex] = 32'd0;
    end

    always @(posedge clk) begin
        savedPulse <= 1'b0;

        if (!historyMode) begin
            if (dataReady) begin
                if (!anchorIsSet) begin
                    anchorValue <= weightInput;
                    anchorIsSet <= 1'b1;
                    stabilityTimer <= 32'd0;
                end else if ((weightInput >= anchorValue ? weightInput - anchorValue : anchorValue - weightInput) <= stableThreshold) begin end 
					 else begin
                    anchorValue <= weightInput;
                    stabilityTimer <= 32'd0;
                    alreadySaved <= 1'b0;
                end
            end

            if (anchorIsSet) begin
                if (stabilityTimer < stableTime)
                    stabilityTimer <= stabilityTimer + 32'd1;

                if (stabilityTimer >= stableTime && !alreadySaved) begin
                    if ((anchorValue >= lastSavedValue ? anchorValue - lastSavedValue : lastSavedValue - anchorValue) >= saveThreshold) begin
                        savedReadings[writePointer] <= anchorValue;
                        lastSavedValue <= anchorValue;
                        writePointer <= (writePointer == 3'd4) ? 3'd0 : writePointer + 3'd1;
                        savedPulse <= 1'b1;
                    end
                    alreadySaved <= 1'b1;
                end
            end
        end else begin
            stabilityTimer <= 32'd0;
            alreadySaved <= 1'b0;
            anchorIsSet <= 1'b0;
        end
    end

    always @(posedge clk) begin
        if (!historyMode) begin
            browseTimer <= 32'd0;
            historyIndex <= 3'd0;
            if (historyPress)
                historyMode <= 1'b1;
        end else begin
            browseTimer <= browseTimer + 32'd1;
            if (historyPress) begin
                browseTimer <= 32'd0;
                historyIndex <= (historyIndex == 3'd4) ? 3'd0 : historyIndex + 3'd1;
            end
            if (browseTimer >= browseTimeout)
                historyMode <= 1'b0;
        end
    end

    always @(*) begin
        selectedSlot = writePointer - 3'd1 - historyIndex;
        if (selectedSlot > 3'd4)
            selectedSlot = selectedSlot + 3'd5;
        historyOutput = savedReadings[selectedSlot];
    end

endmodule