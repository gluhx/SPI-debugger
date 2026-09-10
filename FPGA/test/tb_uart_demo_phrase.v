`timescale 1ns/1ps

module tb_uart_demo_phrase;
    localparam integer CLK_HZ       = 100;
    localparam integer BAUD_RATE    = 10;
    localparam integer PERIOD_TICKS = CLK_HZ / BAUD_RATE;

    reg clk = 1'b0;
    wire tx;
    wire busy;
    integer byte_number;
    integer bit_number;
    reg [7:0] received;

    UART_demo #(.CLK_HZ(CLK_HZ), .BAUD_RATE(BAUD_RATE)) dut (
        .clk(clk), .tx(tx), .busy(busy)
    );

    always #5 clk = ~clk;

    function [7:0] expected_byte;
        input integer index;
        begin
            case (index)
                0:  expected_byte = "M";
                1:  expected_byte = "a";
                2:  expected_byte = "y";
                3:  expected_byte = " ";
                4:  expected_byte = "b";
                5:  expected_byte = "e";
                6:  expected_byte = "e";
                7:  expected_byte = "r";
                8:  expected_byte = "?";
                9:  expected_byte = 8'h0d;
                10: expected_byte = 8'h0a;
                default: expected_byte = 8'h00;
            endcase
        end
    endfunction

    task receive_byte;
        input [7:0] expected_value;
        begin
            @(negedge tx);
            repeat (PERIOD_TICKS + PERIOD_TICKS / 2) @(posedge clk);
            received = 8'h00;
            for (bit_number = 0; bit_number < 8; bit_number = bit_number + 1) begin
                received[bit_number] = tx;
                repeat (PERIOD_TICKS) @(posedge clk);
            end
            #1;
            if (received !== expected_value) begin
                $display("FAIL: byte %0d: received 0x%02h, expected 0x%02h", byte_number, received, expected_value);
                $finish(1);
            end
            if (tx !== 1'b1) begin
                $display("FAIL: byte %0d: missing stop bit", byte_number);
                $finish(1);
            end
        end
    endtask

    initial begin
        $dumpfile("test/tb_uart_demo_phrase.vcd");
        $dumpvars(0, tb_uart_demo_phrase);
        for (byte_number = 0; byte_number < 22; byte_number = byte_number + 1)
            receive_byte(expected_byte(byte_number % 11));
        $display("PASS: UART_demo continuously transmitted 'May be beer?\\r\\n'");
        $finish;
    end
endmodule
