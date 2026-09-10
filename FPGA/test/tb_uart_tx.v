`timescale 1ns/1ps

// Проверка uart_tx в формате 8N1: стартовый бит, 8 бит LSB-first и стоповый бит.
module tb_uart_tx;

    localparam integer CLK_HZ      = 100;
    localparam integer BAUD_RATE   = 10;
    localparam integer PERIOD_TICKS = CLK_HZ / BAUD_RATE;

    reg        clk   = 1'b0;
    reg        rst_n = 1'b0;
    reg [7:0]  data  = 8'h00;
    reg        send  = 1'b0;
    wire       tx;
    wire       busy;
    integer    bit_number;

    uart_tx #(
        .CLK_HZ(CLK_HZ),
        .BAUD_RATE(BAUD_RATE)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .data(data),
        .send(send),
        .tx(tx),
        .busy(busy)
    );

    always #5 clk = ~clk;

    task expect_value;
        input actual;
        input expected;
        input [8*48-1:0] description;
        begin
            if (actual !== expected) begin
                $display("FAIL: %0s: получено %b, ожидалось %b", description, actual, expected);
                $finish(1);
            end
        end
    endtask

    task send_byte_and_check;
        input [7:0] expected_data;
        begin
            // Запрос принимается по фронту clk.
            @(negedge clk);
            data = expected_data;
            send = 1'b1;
            @(posedge clk);
            #1;
            send = 1'b0;

            expect_value(busy, 1'b1, "busy after send");
            expect_value(tx,   1'b0, "start bit");

            // Новый запрос во время передачи не должен менять уже сохранённый байт.
            @(negedge clk);
            data = ~expected_data;
            send = 1'b1;
            @(posedge clk);
            #1;
            send = 1'b0;
            expect_value(tx,   1'b0, "start bit while busy");
            expect_value(busy, 1'b1, "busy during second send");

            // Первый такт стартового бита уже прошёл при проверке send во время busy.
            repeat (PERIOD_TICKS - 1) @(posedge clk);
            #1;
            expect_value(tx, expected_data[0], "first data bit");
            expect_value(busy, 1'b1, "busy during data");

            // Каждый последующий символ UART занимает PERIOD_TICKS тактов clk.
            for (bit_number = 1; bit_number < 8; bit_number = bit_number + 1) begin
                repeat (PERIOD_TICKS) @(posedge clk);
                #1;
                expect_value(tx, expected_data[bit_number], "data bit");
                expect_value(busy, 1'b1, "busy during data");
            end

            repeat (PERIOD_TICKS) @(posedge clk);
            #1;
            expect_value(tx,   1'b1, "stop bit");
            expect_value(busy, 1'b1, "busy during stop bit");

            // Стоповый бит также должен длиться полный период baud.
            repeat (PERIOD_TICKS) @(posedge clk);
            #1;
            expect_value(tx,   1'b1, "tx idle");
            expect_value(busy, 1'b0, "busy after stop bit");
        end
    endtask

    initial begin
        $dumpfile("test/tb_uart_tx.vcd");
        $dumpvars(0, tb_uart_tx);

        repeat (2) @(posedge clk);
        #1 rst_n = 1'b1;
        expect_value(tx,   1'b1, "tx idle");
        expect_value(busy, 1'b0, "busy idle");

        // A5 проверяет порядок LSB-first: 1,0,1,0,0,1,0,1.
        send_byte_and_check(8'hA5);
        send_byte_and_check(8'h3C);

        $display("PASS: uart_tx передал 0xA5 и 0x3C в формате 8N1");
        $finish;
    end

endmodule
