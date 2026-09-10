module uart_tx #(
    parameter integer CLK_HZ    = 27_000_000,
    parameter integer BAUD_RATE = 9_600
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] data,
    input  wire       send,
    output reg        tx   = 1'b1,
    output reg        busy = 1'b0,
    output reg        done = 1'b0
);

    localparam integer PERIOD = CLK_HZ / BAUD_RATE;
    localparam integer CNT_WIDTH  = $clog2(PERIOD);

    reg [CNT_WIDTH - 1:0] counter = 0;
    reg [3:0] bit_idx = 0;
    reg [7:0] shift = 0;

    localparam [1:0] IDLE = 2'd0;
    localparam [1:0] START = 2'd1;
    localparam [1:0] DATA = 2'd2;
    localparam [1:0] STOP = 2'd3;

    reg [1:0] state = IDLE;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state   <= IDLE;
            tx      <= 1'b1;
            busy    <= 1'b0;
            done    <= 1'b0;
            counter <= 0;
            bit_idx <= 0;
            shift   <= 0;
        end else begin
            done <= 1'b0;

            case (state)
                IDLE: begin
                    tx   <= 1'b1;
                    busy <= 1'b0;
                    if (send) begin
                        shift   <= data;
                        state   <= START;
                        busy    <= 1'b1;
                        counter <= 0;
                    end
                end

                START: begin
                    tx <= 1'b0;
                    if (counter == PERIOD-1) begin
                        counter <= 0;
                        state   <= DATA;
                        bit_idx <= 0;
                    end else begin
                        counter <= counter + 1;
                    end
                end

                DATA: begin
                    tx <= shift[bit_idx];
                    if (counter == PERIOD-1) begin
                        counter <= 0;
                        if (bit_idx == 7) begin
                            state <= STOP;
                        end else begin
                            bit_idx <= bit_idx + 1;
                        end
                    end else begin
                        counter <= counter + 1;
                    end
                end

                STOP: begin
                    tx <= 1'b1;
                    if (counter == PERIOD-1) begin
                        counter <= 0;
                        state   <= IDLE;
                        busy    <= 1'b0;
                        done    <= 1'b1;
                    end else begin
                        counter <= counter + 1;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end
endmodule
