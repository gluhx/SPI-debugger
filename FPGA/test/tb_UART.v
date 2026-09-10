`timescale 1ns/1ps

module tb_UART;

    reg clk = 1'b0;
    reg rst_n = 1'b0;
    reg [7:0] data = 8'hA5;
    reg send = 1'b0;
    wire tx;
    wire busy;
    wire baud_clk;
    integer bit_number;

    UART #(
        .CLK_HZ(100),
        .BAUD_RATE(10)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .data(data),
        .send(send),
        .tx(tx),
        .busy(busy),
        .baud_clk(baud_clk)
    );

    always #5 clk = ~clk;

    function expected_tx;
        input integer index;
        begin
            case (index)
                0: expected_tx = 1'b0; // стартовый бит
                1: expected_tx = 1'b1; // 0-й бит A5
                2: expected_tx = 1'b0;
                3: expected_tx = 1'b1;
                4: expected_tx = 1'b0;
                5: expected_tx = 1'b0;
                6: expected_tx = 1'b1;
                7: expected_tx = 1'b0;
                8: expected_tx = 1'b1; // 7-й бит A5
                9: expected_tx = 1'b1; // стоповый бит
                default: expected_tx = 1'b1;
            endcase
        end
    endfunction

    initial begin
        $dumpfile("test/tb_UART.vcd");
        $dumpvars(0, tb_UART);

        repeat (2) @(posedge clk);
        #1 rst_n = 1'b1;
        @(negedge clk);
        send = 1'b1;
        @(posedge busy);
        send = 1'b0;
        #1;

        if (tx !== expected_tx(0)) begin
            $display("FAIL: стартовый бит: получен %b, ожидался %b", tx, expected_tx(0));
            $finish(1);
        end

        for (bit_number = 1; bit_number < 10; bit_number = bit_number + 1) begin
            @(posedge baud_clk);
            #1;
            if (tx !== expected_tx(bit_number)) begin
                $display("FAIL: бит %0d: получен %b, ожидался %b", bit_number, tx, expected_tx(bit_number));
                $finish(1);
            end
        end

        if (busy !== 1'b0) begin
            $display("FAIL: busy должен сброситься после стопового бита");
            $finish(1);
        end

        $display("PASS: UART передал байт 0xA5 в формате 8N1");
        $finish;
    end

endmodule
