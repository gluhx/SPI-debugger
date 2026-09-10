`timescale 1ns/1ps

module tb_uart_rx;
    localparam integer CLK_HZ = 100;
    localparam integer BAUD_RATE = 10;
    localparam integer PERIOD_TICKS = CLK_HZ / BAUD_RATE;

    reg clk = 1'b0;
    reg rst_n = 1'b0;
    reg rx = 1'b1;
    wire [7:0] data;
    wire accepted;
    reg seen_accepted;
    reg [7:0] accepted_data;
    integer bit_number;

    uart_rx #(.CLK_HZ(CLK_HZ), .BAUD_RATE(BAUD_RATE)) dut (
        .clk(clk), .rst_n(rst_n), .rx(rx), .data(data), .accepted(accepted)
    );

    always #5 clk = ~clk;

    always @(posedge clk) begin
        #1;
        if (accepted) begin
            seen_accepted = 1'b1;
            accepted_data = data;
        end
    end

    task send_byte;
        input [7:0] value;
        begin
            seen_accepted = 1'b0;
            accepted_data = 8'h00;
            @(negedge clk);
            rx = 1'b0;
            repeat (PERIOD_TICKS) @(negedge clk);
            for (bit_number = 0; bit_number < 8; bit_number = bit_number + 1) begin
                rx = value[bit_number];
                repeat (PERIOD_TICKS) @(negedge clk);
            end
            rx = 1'b1;
            repeat (PERIOD_TICKS) @(negedge clk);
            repeat (3) @(posedge clk);
            #1;
            if (!seen_accepted) begin
                $display("FAIL: no accepted pulse for byte 0x%02h", value);
                $finish(1);
            end
            if (accepted_data !== value) begin
                $display("FAIL: received 0x%02h, expected 0x%02h", accepted_data, value);
                $finish(1);
            end
        end
    endtask

    initial begin
        $dumpfile("test/tb_uart_rx.vcd");
        $dumpvars(0, tb_uart_rx);
        repeat (2) @(posedge clk);
        #1 rst_n = 1'b1;
        repeat (2) @(posedge clk);
        send_byte(8'hA5);
        send_byte(8'h3C);
        $display("PASS: uart_rx accepted 0xA5 and 0x3C");
        $finish;
    end
endmodule
