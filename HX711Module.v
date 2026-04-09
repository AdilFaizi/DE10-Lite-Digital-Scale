
module HX711Driver (
    input wire clock50,
    output reg sck = 1'b0,
    input wire dout,
    output reg dataReady = 1'b0,
    output reg [23:0] dataOutput = 24'd0
);

    reg doutSync1 = 1'b1, doutSync2 = 1'b1;

    always @(posedge clock50) begin
        doutSync1 <= dout;
        doutSync2 <= doutSync1;
    end

    localparam startup = 3'd0;
    localparam waitHigh = 3'd1;
    localparam idle = 3'd2;
    localparam shifting = 3'd3;
    localparam extraClock = 3'd4;
    localparam done = 3'd5;

    reg [2:0] currentState = startup;
    reg [24:0] startupTimer = 25'd0;
    reg [5:0] sckDivider = 6'd0;
    reg [4:0] bitsReceived = 5'd0;
    reg [23:0] shiftRegister = 24'd0;
    reg [31:0] watchdogTimer = 32'd0;

    localparam startupDelay = 25'd25_000_000;
    localparam watchdogMax = 32'd100_000_000;

    always @(posedge clock50) begin
        dataReady <= 1'b0;

        if (currentState == idle || currentState == shifting || currentState == extraClock) begin
            watchdogTimer <= watchdogTimer + 32'd1;
            if (watchdogTimer >= watchdogMax) begin
                watchdogTimer <= 32'd0;
                startupTimer <= 25'd0;
                currentState <= startup;
            end
        end else begin
            watchdogTimer <= 32'd0;
        end

        case (currentState)
            startup: begin
                sck <= 1'b0;
                if (startupTimer < startupDelay)
                    startupTimer <= startupTimer + 25'd1;
                else
                    currentState <= waitHigh;
            end

            waitHigh: begin
                sck <= 1'b0;
                if (doutSync2)
                    currentState <= idle;
            end

            idle: begin
                sck <= 1'b0;
                sckDivider <= 6'd0;
                bitsReceived <= 5'd0;
                if (!doutSync2) begin
                    watchdogTimer <= 32'd0;
                    currentState <= shifting;
                end
            end

            shifting: begin
                if (sckDivider == 6'd49) begin
                    sckDivider <= 6'd0;
                    sck <= ~sck;
                    if (sck == 1'b1) begin
                        shiftRegister <= {shiftRegister[22:0], doutSync2};
                        if (bitsReceived == 5'd23)
                            currentState <= extraClock;
                        else
                            bitsReceived <= bitsReceived + 5'd1;
                    end
                end else begin
                    sckDivider <= sckDivider + 6'd1;
                end
            end

            extraClock: begin
                if (sckDivider == 6'd49) begin
                    sckDivider <= 6'd0;
                    sck <= ~sck;
                    if (sck == 1'b1)
                        currentState <= done;
                end else begin
                    sckDivider <= sckDivider + 6'd1;
                end
            end

            done: begin
                sck <= 1'b0;
                dataOutput <= shiftRegister;
                dataReady <= 1'b1;
                currentState <= idle;
            end

            default: currentState <= startup;
        endcase
    end

endmodule