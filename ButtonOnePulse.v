module ButtonOnePulse (
    input wire clk,
    input wire buttonInput,
    output reg pulse
);

    reg [19:0] stableCount = 20'd0;
    reg buttonSyncStage0 = 1'b1;
    reg buttonSyncStage1 = 1'b1;
    reg buttonStableState = 1'b1;
    reg buttonPreviousState = 1'b1;

    always @(posedge clk) begin
        buttonSyncStage0 <= buttonInput;
        buttonSyncStage1 <= buttonSyncStage0;

        if (buttonSyncStage1 == buttonStableState) begin
            stableCount <= 20'd0;
        end else begin
            stableCount <= stableCount + 20'd1;
            if (stableCount == 20'hFFFFF) begin
                buttonStableState <= buttonSyncStage1;
                stableCount <= 20'd0;
            end
        end

        buttonPreviousState <= buttonStableState;
        pulse <= (buttonPreviousState == 1'b1) && (buttonStableState == 1'b0);
    end

endmodule