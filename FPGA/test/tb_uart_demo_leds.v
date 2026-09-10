`timescale 1ns/1ps

module tb_uart_demo_leds;
    localparam integer CLK_HZ = 100;
    localparam integer BAUD_RATE = 10;
    localparam integer PERIOD_TICKS = CLK_HZ / BAUD_RATE;

    reg clk = 1'b0;
    reg rx = 1'b1;
    wire led1, led2, led3;
    integer bit_number;

    UART_demo #(.CLK_HZ(CLK_HZ), .BAUD_RATE(BAUD_RATE)) dut (
        .clk(clk), .rx(rx), .led1(led1), .led2(led2), .led3(led3)
    );

    always #5 clk = ~clk;

    task send_byte;
        input [7:0] value;
        begin
            @(negedge clk);
            rx = 1'b0;
            repeat (PERIOD_TICKS) @(negedge clk);
            for (bit_number = 0; bit_number < 8; bit_number = bit_number + 1) begin
                rx = value[bit_number];
                repeat (PERIOD_TICKS) @(negedge clk);
            end
            rx = 1'b1;
            repeat (PERIOD_TICKS + 3) @(negedge clk);
        end
    endtask

    task check_leds;
        input expected1;
        input expected2;
        input expected3;
        begin
            #1;
            if ({led3, led2, led1} !== {expected3, expected2, expected1}) begin
                $display("FAIL: LEDs=%b%b%b, expected=%b%b%b", led3, led2, led1,
                         expected3, expected2, expected1);
                $finish(1);
            end
        end
    endtask

    initial begin
        $dumpfile("test/tb_uart_demo_leds.vcd");
        $dumpvars(0, tb_uart_demo_leds);

        repeat (3) @(posedge clk);
        check_leds(1'b0, 1'b0, 1'b0);

        send_byte("1");
        check_leds(1'b1, 1'b0, 1'b0);
        send_byte("9"); // неизвестная команда: состояние не меняется
        check_leds(1'b1, 1'b0, 1'b0);
        send_byte("2");
        check_leds(1'b1, 1'b1, 1'b0);
        send_byte("3");
        check_leds(1'b1, 1'b1, 1'b1);

        $display("PASS: commands 1, 2, 3 set the corresponding LEDs; other data is ignored");
        $finish;
    end
endmodule
