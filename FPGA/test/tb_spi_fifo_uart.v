`timescale 1ns/1ps

module tb_spi_fifo_uart;
    reg clk = 1'b0;
    reg rst_n = 1'b0;
    reg [19:0] fifo_rd_data = 20'b0;
    reg uart_busy = 1'b0;
    reg uart_done = 1'b0;
    wire fifo_rd_en;
    wire [7:0] uart_data;
    wire uart_send;

    reg [19:0] fifo_model [0:1];
    integer fifo_read_count = 0;
    wire fifo_empty = (fifo_read_count == 2);

    spi_fifo_uart #(.BUFFER_ADDR_WIDTH(2)) dut (
        .clk(clk), .rst_n(rst_n),
        .fifo_rd_data(fifo_rd_data), .fifo_empty(fifo_empty), .fifo_rd_en(fifo_rd_en),
        .uart_data(uart_data), .uart_send(uart_send),
        .uart_busy(uart_busy), .uart_done(uart_done)
    );

    always #5 clk = ~clk;

    // Модель registered-read интерфейса async_fifo.
    always @(posedge clk) begin
        if (fifo_rd_en) begin
            fifo_rd_data <= fifo_model[fifo_read_count];
            fifo_read_count <= fifo_read_count + 1;
        end
    end

    task finish_uart_byte;
        begin
            @(posedge clk);
            uart_busy = 1'b1;
            repeat (2) @(posedge clk);
            uart_busy = 1'b0;
            uart_done = 1'b1;
            @(posedge clk);
            uart_done = 1'b0;
        end
    endtask

    task expect_send;
        input [7:0] expected;
        begin
            wait (uart_send === 1'b1);
            #1;
            if (uart_data !== expected) begin
                $display("FAIL: sent %h, expected %h", uart_data, expected);
                $finish(1);
            end
            finish_uart_byte;
        end
    endtask

    initial begin
        $dumpfile("test/tb_spi_fifo_uart.vcd");
        $dumpvars(0, tb_spi_fifo_uart);

        // Две записи приходят в FIFO до окончания первой UART-посылки.
        // Они должны накопиться в кольцевом буфере и не перемешаться.
        fifo_model[0] = {4'd4, 8'hA5, 8'h3C}; // header = 41
        fifo_model[1] = {4'd2, 8'h01, 8'h80}; // header = 27
        #12 rst_n = 1'b1;

        expect_send(8'h41);
        expect_send(8'hA5);
        expect_send(8'h3C);
        expect_send(8'h27);
        expect_send(8'h01);
        expect_send(8'h80);

        repeat (3) @(posedge clk);
        if (fifo_read_count != 2) begin
            $display("FAIL: FIFO read count is %0d, expected 2", fifo_read_count);
            $finish(1);
        end
        $display("PASS: byte ring buffer preserved two SPI records for UART");
        $finish;
    end
endmodule
