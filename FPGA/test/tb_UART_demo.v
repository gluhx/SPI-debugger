`timescale 1ns/1ps

module tb_UART_demo;

    reg clk = 1'b0;
    wire tx;
    wire busy;

    UART_demo #(
        .CLK_HZ(100),
        .BAUD_RATE(10)
    ) dut (
        .clk(clk),
        .tx(tx),
        .busy(busy)
    );

    always #5 clk = ~clk;

    task check_frame;
        input [7:0] expected_data;
        integer bit_number;
        begin
            @(negedge tx); // стартовый бит
            for (bit_number = 0; bit_number < 8; bit_number = bit_number + 1) begin
                // Передатчик меняет tx на фронте своего baud_clk.
                repeat (10) @(posedge clk);
                #1;
                if (tx !== expected_data[bit_number]) begin
                    $display("FAIL: байт %0d, бит %0d: %b вместо %b", expected_data, bit_number, tx, expected_data[bit_number]);
                    $finish(1);
                end
            end

            repeat (10) @(posedge clk);
            #1;
            if (tx !== 1'b1) begin
                $display("FAIL: отсутствует стоповый бит для байта %0d", expected_data);
                $finish(1);
            end
        end
    endtask

    initial begin
        $dumpfile("test/tb_UART_demo.vcd");
        $dumpvars(0, tb_UART_demo);

        check_frame(8'd1);
        check_frame(8'd2);
        check_frame(8'd3);

        $display("PASS: UART_demo отправил байты 1, 2, 3");
        $finish;
    end

endmodule
