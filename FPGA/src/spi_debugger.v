// Верхний модуль SPI-отладчика.
// Принимает пассивно наблюдаемый SPI-трафик, передаёт записи между доменами
// SCK и clk через async_fifo и выводит подготовленные пакеты в UART.
module spi_debugger #(
    parameter integer CLK_HZ = 27_000_000,
    parameter integer BAUD_RATE = 115_200,
    parameter integer FIFO_ADDR_WIDTH = 4,
    parameter integer UART_BUFFER_ADDR_WIDTH = 4
) (
    input  wire       clk,
    input  wire       rst_n,

    input  wire       spi_mosi,
    input  wire       spi_miso,
    input  wire       spi_sck,
    input  wire [7:0] spi_cs,

    input  wire       uart_rx,
    output wire       uart_tx,

    // Диагностика переполнения входного FIFO.
    output wire       fifo_overflow
);
    wire [19:0] spi_fifo_wr_data;
    wire        spi_fifo_wr_en;
    wire        fifo_full;
    wire [19:0] fifo_rd_data;
    wire        fifo_rd_en;
    wire        fifo_empty;
    wire [7:0]  uart_data;
    wire        uart_send;
    wire        uart_busy;
    wire        uart_done;

    spi spi_capture (
        .rst_n(rst_n),
        .mosi(spi_mosi), .miso(spi_miso), .sck(spi_sck), .cs(spi_cs),
        .data_miso(), .data_mosi(), .data_cs(), .ready_data(),
        .fifo_wr_data(spi_fifo_wr_data), .fifo_wr_en(spi_fifo_wr_en)
    );

    async_fifo #(
        .DATA_WIDTH(20),
        .ADDR_WIDTH(FIFO_ADDR_WIDTH)
    ) spi_async_fifo (
        .wr_clk(spi_sck), .wr_rst_n(rst_n),
        .wr_data(spi_fifo_wr_data), .wr_en(spi_fifo_wr_en),
        .wr_full(fifo_full), .wr_overflow(fifo_overflow),
        .rd_clk(clk), .rd_rst_n(rst_n), .rd_en(fifo_rd_en),
        .rd_data(fifo_rd_data), .rd_empty(fifo_empty)
    );

    spi_fifo_uart #(
        .BUFFER_ADDR_WIDTH(UART_BUFFER_ADDR_WIDTH)
    ) uart_queue (
        .clk(clk), .rst_n(rst_n),
        .fifo_rd_data(fifo_rd_data), .fifo_empty(fifo_empty), .fifo_rd_en(fifo_rd_en),
        .uart_data(uart_data), .uart_send(uart_send),
        .uart_busy(uart_busy), .uart_done(uart_done)
    );

    uart #(
        .CLK_HZ(CLK_HZ),
        .BAUD_RATE(BAUD_RATE)
    ) uart_port (
        .clk(clk), .rst_n(rst_n), .rx(uart_rx), .tx(uart_tx),
        .data_tx(uart_data), .tx_send(uart_send),
        .tx_busy(uart_busy), .tx_done(uart_done),
        .rx_data(), .rx_accepted()
    );
endmodule
