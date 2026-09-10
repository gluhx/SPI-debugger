module uart_rx #(
    parameter integer CLK_HZ    = 27_000_000,
    parameter integer BAUD_RATE = 9_600
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       rx,
    output reg  [7:0] data     = 8'b0,
    output reg        accepted = 1'b0
);

    localparam integer PERIOD = CLK_HZ / BAUD_RATE;
    localparam integer HALF   = PERIOD / 2;
    localparam integer CNT_W  = $clog2(PERIOD);

    // 2FF синхронизатор
    reg [1:0] rx_sync = 2'b11;
    always @(posedge clk) rx_sync <= {rx_sync[0], rx};
    wire rx_s = rx_sync[1];

    reg [CNT_W-1:0] counter = 0;
    reg [3:0]       bit_idx = 0;
    reg [7:0]       shift   = 0;

    localparam [1:0] IDLE  = 2'd0;
    localparam [1:0] START = 2'd1;
    localparam [1:0] DATA  = 2'd2;
    localparam [1:0] STOP  = 2'd3;

    reg [1:0] state   = IDLE;
    reg       prev_rx = 1'b1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state    <= IDLE;
            counter  <= 0;
            bit_idx  <= 0;
            shift    <= 0;
            data     <= 0;
            accepted <= 0;
            prev_rx  <= 1'b1;
        end else begin
            accepted <= 1'b0;
            prev_rx  <= rx_s;

            case (state)
                IDLE: begin
                    if (prev_rx && !rx_s) begin // спад — старт
                        state   <= START;
                        counter <= 0;
                    end
                end

                START: begin
                    if (counter == HALF-1) begin
                        if (rx_s == 1'b0) begin
                            state   <= DATA;
                            counter <= 0;
                            bit_idx <= 0;
                        end else begin
                            state <= IDLE; // ложный старт
                        end
                    end else begin
                        counter <= counter + 1;
                    end
                end

                DATA: begin
                    if (counter == PERIOD-1) begin
                        counter <= 0;
                        shift[bit_idx] <= rx_s;
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
                    if (counter == PERIOD-1) begin
                        if (rx_s == 1'b1) begin
                            data     <= shift;
                            accepted <= 1'b1;
                        end
                        state   <= IDLE;
                        counter <= 0;
                    end else begin
                        counter <= counter + 1;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end
endmodule
