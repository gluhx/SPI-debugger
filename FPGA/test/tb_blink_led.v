`timescale 1ns/1ps

module tb_blink_led;

    reg clk = 1'b0;
    wire led;

    // Малые значения параметров делают тест быстрым.
    blink_led #(
        .CLK_HZ(8),
        .BLINK_HZ(1)
    ) dut (
        .clk(clk),
        .led(led)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("test/tb_blink_led.vcd");
        $dumpvars(0, tb_blink_led);

        // При CLK_HZ=8 LED должен переключиться после 4 фронтов clk.
        repeat (4) @(posedge clk);
        #1;
        if (led !== 1'b1) begin
            $display("FAIL: после 4 тактов led должен быть равен 1");
            $finish(1);
        end

        repeat (4) @(posedge clk);
        #1;
        if (led !== 1'b0) begin
            $display("FAIL: после 8 тактов led должен быть равен 0");
            $finish(1);
        end

        $display("PASS: blink_led работает корректно");
        $finish;
    end

endmodule
