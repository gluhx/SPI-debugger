`timescale 1ns/1ps

module tb_spi_fifo;
    reg rst_n = 1'b0;
    reg mosi = 1'b0;
    reg miso = 1'b0;
    reg sck = 1'b0;
    reg [7:0] cs = 8'hFF;
    reg clk = 1'b0;
    reg rd_en = 1'b0;

    wire [19:0] fifo_wr_data;
    wire fifo_wr_en;
    wire [19:0] fifo_rd_data;
    wire fifo_empty;
    wire fifo_full;
    wire fifo_overflow;

    spi spi_dut (
        .rst_n(rst_n), .mosi(mosi), .miso(miso), .sck(sck), .cs(cs),
        .fifo_wr_data(fifo_wr_data), .fifo_wr_en(fifo_wr_en)
    );

    async_fifo #(.DATA_WIDTH(20), .ADDR_WIDTH(2)) fifo_dut (
        .wr_clk(sck), .wr_rst_n(rst_n), .wr_data(fifo_wr_data),
        .wr_en(fifo_wr_en), .wr_full(fifo_full), .wr_overflow(fifo_overflow),
        .rd_clk(clk), .rd_rst_n(rst_n), .rd_en(rd_en),
        .rd_data(fifo_rd_data), .rd_empty(fifo_empty)
    );

    always #7 clk = ~clk;

    task clock_bit;
        input mosi_bit;
        input miso_bit;
        begin
            #5 mosi = mosi_bit;
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

    initial begin
        $dumpfile("test/tb_spi_fifo.vcd");
        $dumpvars(0, tb_spi_fifo);

        #20 rst_n = 1'b1;
        cs = 8'hF7; // CS4 active-low
        send_byte(8'hA5, 8'h3C);
        cs = 8'hFF;

        // Два синхронизатора + обновление empty в домене clk.
        repeat (5) @(posedge clk);
        #1;
        if (fifo_empty !== 1'b0) begin
            $display("FAIL: FIFO stayed empty after SPI byte");
            $finish(1);
        end

        rd_en = 1'b1;
        @(posedge clk);
        #1 rd_en = 1'b0;
        #1;
        if (fifo_rd_data !== {4'd4, 8'hA5, 8'h3C}) begin
            $display("FAIL: got %h, expected 4A53C", fifo_rd_data);
            $finish(1);
        end
        if (fifo_overflow !== 1'b0) begin
            $display("FAIL: unexpected FIFO overflow");
            $finish(1);
        end

        $display("PASS: SPI byte crossed from SCK to clk through async FIFO");
        $finish;
    end
endmodule
