`timescale 1ns/1ps
module tb_uart_demo_echo;
    localparam integer CLK_HZ=100, BAUD_RATE=10, PERIOD_TICKS=10;
    reg clk=0, rx=1;
    wire tx, busy, led1, led2, led3, led4;
    integer bit_number;
    reg [7:0] received;
    UART_demo #(.CLK_HZ(CLK_HZ),.BAUD_RATE(BAUD_RATE),.LED_ACTIVE_LOW(0)) dut
      (.clk(clk),.rx(rx),.tx(tx),.busy(busy),.led1(led1),.led2(led2),.led3(led3),.led4(led4));
    always #5 clk=~clk;
    task send_host_byte; input [7:0] value; begin
        @(negedge clk); rx=0; repeat(PERIOD_TICKS) @(negedge clk);
        for(bit_number=0;bit_number<8;bit_number=bit_number+1) begin
            rx=value[bit_number]; repeat(PERIOD_TICKS) @(negedge clk);
        end
        rx=1;
    end endtask
    task receive_tx_byte; input [7:0] expected; begin
        @(negedge tx); repeat(PERIOD_TICKS+PERIOD_TICKS/2) @(posedge clk);
        received=0;
        for(bit_number=0;bit_number<8;bit_number=bit_number+1) begin
            received[bit_number]=tx; repeat(PERIOD_TICKS) @(posedge clk);
        end
        #1;
        if(received!==expected || tx!==1) begin
            $display("FAIL: tx=%02h expected=%02h stop=%b",received,expected,tx); $finish(1);
        end
    end endtask
    initial begin
        $dumpfile("test/tb_uart_demo_echo.vcd"); $dumpvars(0,tb_uart_demo_echo);
        repeat(3) @(posedge clk);
        send_host_byte("X"); receive_tx_byte("X"); receive_tx_byte(8'h0d); receive_tx_byte(8'h0a);
        if({led4,led3,led2,led1}!==4'b1000) begin $display("FAIL: LEDs after X"); $finish(1); end
        send_host_byte("Y"); receive_tx_byte("Y"); receive_tx_byte(8'h0d); receive_tx_byte(8'h0a);
        if({led4,led3,led2,led1}!==4'b1001) begin $display("FAIL: LEDs after Y"); $finish(1); end
        send_host_byte(8'h00); receive_tx_byte(8'h00); receive_tx_byte(8'h0d); receive_tx_byte(8'h0a);
        if({led4,led3,led2,led1}!==4'b0000) begin $display("FAIL: LEDs after 0x00"); $finish(1); end
        $display("PASS: every received byte changes LEDs and is echoed with CRLF"); $finish;
    end
endmodule
