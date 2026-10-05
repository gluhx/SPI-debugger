`timescale 1ns/1ps

module tb_spi_debugger;
    localparam integer CLK_HZ = 100;
    localparam integer BAUD_RATE = 10;
    localparam integer BIT_TIME_NS = 100;

    reg clk = 1'b0;
    reg rst_n = 1'b0;
    reg spi_mosi = 1'b0;
    reg spi_miso = 1'b0;
    reg spi_sck = 1'b0;
    reg [7:0] spi_cs = 8'hFF;
    reg uart_rx = 1'b1;
    wire uart_tx;
    wire fifo_overflow;

    spi_debugger #(
        .CLK_HZ(CLK_HZ), .BAUD_RATE(BAUD_RATE),
        .FIFO_ADDR_WIDTH(4), .UART_BUFFER_ADDR_WIDTH(5)
    ) dut (
        .clk(clk), .rst_n(rst_n),
        .spi_mosi(spi_mosi), .spi_miso(spi_miso),
        .spi_sck(spi_sck), .spi_cs(spi_cs),
        .uart_rx(uart_rx), .uart_tx(uart_tx),
        .fifo_overflow(fifo_overflow)
    );

    always #5 clk = ~clk;

    task spi_clock_bit;
        input mosi_bit;
        input miso_bit;
        begin
            #7 spi_mosi = mosi_bit;
            spi_miso = miso_bit;
            #7 spi_sck = 1'b1;
            #7 spi_sck = 1'b0;
        end
    endtask

    task spi_send_byte;
        input [3:0] cs_number;
        input [7:0] mosi_byte;
        input [7:0] miso_byte;
        integer i;
        begin
            spi_cs = ~(8'b1 << (cs_number - 1'b1));
            for (i = 7; i >= 0; i = i - 1)
                spi_clock_bit(mosi_byte[i], miso_byte[i]);
            #7 spi_cs = 8'hFF;
        end
    endtask

    task uart_expect_byte;
        input [7:0] expected;
        reg [7:0] received;
        integer i;
        begin
            wait (uart_tx === 1'b0);
            #(BIT_TIME_NS / 2);
            if (uart_tx !== 1'b0) begin
                $display("FAIL: UART start bit is not low");
                $finish(1);
            end
            for (i = 0; i < 8; i = i + 1) begin
                #BIT_TIME_NS;
                received[i] = uart_tx;
            end
            #BIT_TIME_NS;
            if (uart_tx !== 1'b1) begin
                $display("FAIL: UART stop bit is not high");
                $finish(1);
            end
            if (received !== expected) begin
                $display("FAIL: UART got %h, expected %h", received, expected);
                $finish(1);
            end
        end
    endtask

    initial begin
        $dumpfile("test/tb_spi_debugger.vcd");
        $dumpvars(0, tb_spi_debugger);

        #20 rst_n = 1'b1;
        // Приёмник UART запускается параллельно: первая посылка может
        // начаться ещё до завершения третьей SPI-транзакции.
        fork
            begin
                // Отправляем несколько SPI-записей быстрее UART. Они должны
                // пройти через оба буфера без потери и сохранить порядок.
                spi_send_byte(4'd1, 8'hA5, 8'h3C); // UART: 11 A5 3C
                spi_send_byte(4'd4, 8'h01, 8'h80); // UART: 47 01 80
                spi_send_byte(4'd8, 8'hFF, 8'h00); // UART: 81 FF 00
            end
            begin
                uart_expect_byte(8'h11);
                uart_expect_byte(8'hA5);
                uart_expect_byte(8'h3C);
                uart_expect_byte(8'h47);
                uart_expect_byte(8'h01);
                uart_expect_byte(8'h80);
                uart_expect_byte(8'h81);
                uart_expect_byte(8'hFF);
                uart_expect_byte(8'h00);
            end
        join

        if (fifo_overflow !== 1'b0) begin
            $display("FAIL: input FIFO overflowed");
            $finish(1);
        end
        $display("PASS: SPI debugger sent all SPI records through UART");
        $finish;
    end
endmodule
