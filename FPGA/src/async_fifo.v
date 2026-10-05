// Асинхронный FIFO с двумя независимыми доменами тактирования.
// Запись и чтение используют Gray-кодированные указатели, синхронизируемые
// двумя триггерами в противоположный домен.
module async_fifo #(
    parameter integer DATA_WIDTH = 20,
    parameter integer ADDR_WIDTH = 4 // глубина FIFO: 2**ADDR_WIDTH
) (
    input  wire                  wr_clk,
    input  wire                  wr_rst_n,
    input  wire [DATA_WIDTH-1:0] wr_data,
    input  wire                  wr_en,
    output reg                   wr_full = 1'b0,
    output reg                   wr_overflow = 1'b0,

    input  wire                  rd_clk,
    input  wire                  rd_rst_n,
    input  wire                  rd_en,
    output reg [DATA_WIDTH-1:0] rd_data = {DATA_WIDTH{1'b0}},
    output reg                   rd_empty = 1'b1
);
    localparam integer PTR_WIDTH = ADDR_WIDTH + 1;

    reg [DATA_WIDTH-1:0] mem [0:(1 << ADDR_WIDTH)-1];
    reg [PTR_WIDTH-1:0] wr_bin = {PTR_WIDTH{1'b0}};
    reg [PTR_WIDTH-1:0] wr_gray = {PTR_WIDTH{1'b0}};
    reg [PTR_WIDTH-1:0] rd_bin = {PTR_WIDTH{1'b0}};
    reg [PTR_WIDTH-1:0] rd_gray = {PTR_WIDTH{1'b0}};
    reg [PTR_WIDTH-1:0] rd_gray_wr_sync1 = {PTR_WIDTH{1'b0}};
    reg [PTR_WIDTH-1:0] rd_gray_wr_sync2 = {PTR_WIDTH{1'b0}};
    reg [PTR_WIDTH-1:0] wr_gray_rd_sync1 = {PTR_WIDTH{1'b0}};
    reg [PTR_WIDTH-1:0] wr_gray_rd_sync2 = {PTR_WIDTH{1'b0}};

    wire wr_take = wr_en && !wr_full;
    wire rd_take = rd_en && !rd_empty;
    wire [PTR_WIDTH-1:0] wr_bin_next = wr_bin + wr_take;
    wire [PTR_WIDTH-1:0] rd_bin_next = rd_bin + rd_take;
    wire [PTR_WIDTH-1:0] wr_gray_next = (wr_bin_next >> 1) ^ wr_bin_next;
    wire [PTR_WIDTH-1:0] rd_gray_next = (rd_bin_next >> 1) ^ rd_bin_next;

    // FIFO заполнен, если следующий write pointer догоняет read pointer,
    // изменивший два старших бита после перехода в Gray-код.
    wire [PTR_WIDTH-1:0] wr_gray_full_compare = {
        ~rd_gray_wr_sync2[PTR_WIDTH-1:PTR_WIDTH-2],
         rd_gray_wr_sync2[PTR_WIDTH-3:0]
    };
    wire wr_full_next = (wr_gray_next == wr_gray_full_compare);
    wire rd_empty_next = (rd_gray_next == wr_gray_rd_sync2);

    always @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            wr_bin <= {PTR_WIDTH{1'b0}};
            wr_gray <= {PTR_WIDTH{1'b0}};
            wr_full <= 1'b0;
            wr_overflow <= 1'b0;
            rd_gray_wr_sync1 <= {PTR_WIDTH{1'b0}};
            rd_gray_wr_sync2 <= {PTR_WIDTH{1'b0}};
        end else begin
            rd_gray_wr_sync1 <= rd_gray;
            rd_gray_wr_sync2 <= rd_gray_wr_sync1;
            wr_full <= wr_full_next;
            if (wr_en && wr_full)
                wr_overflow <= 1'b1;
            if (wr_take) begin
                mem[wr_bin[ADDR_WIDTH-1:0]] <= wr_data;
                wr_bin <= wr_bin_next;
                wr_gray <= wr_gray_next;
            end
        end
    end

    always @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            rd_bin <= {PTR_WIDTH{1'b0}};
            rd_gray <= {PTR_WIDTH{1'b0}};
            rd_empty <= 1'b1;
            rd_data <= {DATA_WIDTH{1'b0}};
            wr_gray_rd_sync1 <= {PTR_WIDTH{1'b0}};
            wr_gray_rd_sync2 <= {PTR_WIDTH{1'b0}};
        end else begin
            wr_gray_rd_sync1 <= wr_gray;
            wr_gray_rd_sync2 <= wr_gray_rd_sync1;
            rd_empty <= rd_empty_next;
            if (rd_take) begin
                rd_data <= mem[rd_bin[ADDR_WIDTH-1:0]];
                rd_bin <= rd_bin_next;
                rd_gray <= rd_gray_next;
            end
        end
    end
endmodule
