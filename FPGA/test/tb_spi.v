`timescale 1ns/1ps

module tb_spi;
    reg rst_n = 1'b0;
    reg mosi = 1'b0;
    reg miso = 1'b0;
    reg sck  = 1'b0;
    reg [7:0] cs = 8'hFF;

    wire [7:0] data_mosi;
    wire [7:0] data_miso;
    wire [3:0] data_cs;
    wire ready_data;
    integer received_count = 0;

    spi dut (
        .rst_n(rst_n),
        .mosi(mosi),
        .miso(miso),
        .sck(sck),
        .cs(cs),
        .data_mosi(data_mosi),
        .data_miso(data_miso),
        .data_cs(data_cs),
        .ready_data(ready_data)
    );

    task clock_bit;
        input mosi_bit;
        input miso_bit;
        begin
            #5;
            mosi = mosi_bit;
            miso = miso_bit;
            #5 sck = 1'b1;
            #5 sck = 1'b0;
        end
    endtask

    task send_byte;
        input [7:0] mosi_byte;
        input [7:0] miso_byte;
        integer i;
        begin
            for (i = 7; i >= 0; i = i - 1)
                clock_bit(mosi_byte[i], miso_byte[i]);
        end
    endtask

    task expect_equal;
        input [7:0] actual;
        input [7:0] expected;
        input [8*40-1:0] description;
        begin
            if (actual !== expected) begin
                $display("FAIL: %0s: got %h, expected %h", description, actual, expected);
                $finish(1);
            end
        end
    endtask

    always @(posedge ready_data) begin
        #1;
        received_count = received_count + 1;
    end

    initial begin
        $dumpfile("test/tb_spi.vcd");
        $dumpvars(0, tb_spi);

        #10 rst_n = 1'b1;

        // CS1 active-low: передаём один полный байт MSB-first.
        cs = 8'hFE;
        send_byte(8'hA5, 8'h3C);
        #1;
        expect_equal(data_mosi, 8'hA5, "MOSI byte");
        expect_equal(data_miso, 8'h3C, "MISO byte");
        expect_equal({4'd0, data_cs}, 8'h01, "CS1 number");
        expect_equal({7'd0, ready_data}, 8'h01, "ready after byte");
        clock_bit(1'b0, 1'b0);
        expect_equal({7'd0, ready_data}, 8'h00, "ready one SCK pulse");

        // Неполный байт на CS1 не должен попасть в следующую транзакцию CS2.
        clock_bit(1'b1, 1'b1);
        clock_bit(1'b0, 1'b0);
        clock_bit(1'b1, 1'b1);
        cs = 8'hFF;
        #1;
        cs = 8'hFD;
        send_byte(8'h96, 8'h69);
        #1;
        expect_equal(data_mosi, 8'h96, "MOSI after partial transaction");
        expect_equal(data_miso, 8'h69, "MISO after partial transaction");
        expect_equal({4'd0, data_cs}, 8'h02, "CS2 number");

        if (received_count !== 2) begin
            $display("FAIL: got %0d complete bytes, expected 2", received_count);
            $finish(1);
        end

        $display("PASS: SPI captures MSB-first bytes and resets on CS release");
        $finish;
    end
endmodule
