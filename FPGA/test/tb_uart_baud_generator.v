`timescale 1ns/1ps

module tb_uart_baud_generator;

    reg clk = 1'b0;
    reg rst_n = 1'b0;
    wire baud_clk;
    integer ticks_since_edge = 0;
    integer edge_count = 0;
    reg previous_baud_clk = 1'b0;

    uart_baud_generator #(
        .CLK_HZ(100),
        .BAUD_RATE(10)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .baud_clk(baud_clk)
    );

    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (!rst_n) begin
            ticks_since_edge = 0;
            previous_baud_clk = baud_clk;
        end else begin
            ticks_since_edge = ticks_since_edge + 1;
            #1;
            if (baud_clk != previous_baud_clk) begin
                if (ticks_since_edge != 5) begin
                    $display("FAIL: полупериод составил %0d тактов вместо 5", ticks_since_edge);
                    $finish(1);
                end

                edge_count = edge_count + 1;
                $display("baud_clk переключился: фронт %0d", edge_count);
                previous_baud_clk = baud_clk;
                ticks_since_edge = 0;

                if (edge_count == 6) begin
                    $display("PASS: проверено 6 переключений baud_clk");
                    $finish;
                end
            end
        end
    end

    initial begin
        $dumpfile("test/tb_uart_baud_generator.vcd");
        $dumpvars(0, tb_uart_baud_generator);

        repeat (2) @(posedge clk);
        #1 rst_n = 1'b1;
    end

endmodule
