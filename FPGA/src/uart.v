module uart #(
    parameter integer CLK_HZ = 27_000_000,
    parameter integer BAUD_RATE = 115_200
)(
    // тактовый сигнал + сброс
    input  clk,
    input rst_n,
    // интерфес передачи
    input  rx,
    output tx,
    // выводы для tx
    input [7:0] data_tx,
    input tx_send,
    output tx_busy,
    output tx_done,
    // выводы для rx
    output [7:0] rx_data,
    output rx_accepted
);

uart_rx #(
        .CLK_HZ(CLK_HZ),
        .BAUD_RATE(BAUD_RATE)
    ) RX_module (
        .clk(clk),
        .rst_n(rst_n),
        .rx(rx),
        .data(rx_data),
        .accepted(rx_accepted)
    );

    uart_tx #(
        .CLK_HZ(CLK_HZ),
        .BAUD_RATE(BAUD_RATE)
    ) TX_module (
        .clk(clk),
        .rst_n(rst_n),
        .data(tx_data),
        .send(tx_send),
        .tx(tx),
        .busy(tx_busy),
        .done(tx_done)
    );

endmodule // uart
