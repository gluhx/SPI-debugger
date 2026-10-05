// Очередь передачи SPI -> UART.
//
// Входной async_fifo хранит записи SPI в формате
// { CS[3:0], MOSI[7:0], MISO[7:0] }. После чтения одной такой записи этот
// модуль кладёт в собственный кольцевой буфер три уже сформированных байта:
//   { CS[3:0], 1'b0, parity(MOSI), parity(MISO), parity(header[7:1]) },
//   MOSI, MISO.
// parity(x) = XOR(x), то есть это бит чётности.
// Bit 3 первого байта зарезервирован и равен нулю: CS и три parity-бита
// вместе занимают семь битов.
module spi_fifo_uart #(
    // Глубина байтового кольцевого буфера: 2**BUFFER_ADDR_WIDTH.
    // Значение должно быть не меньше 2, так как одна запись занимает 3 байта.
    parameter integer BUFFER_ADDR_WIDTH = 4
) (
    input  wire        clk,
    input  wire        rst_n,

    // Интерфейс чтения FIFO в домене clk.
    input  wire [19:0] fifo_rd_data,
    input  wire        fifo_empty,
    output reg         fifo_rd_en = 1'b0,

    // Интерфейс передатчика UART.
    output reg  [7:0]  uart_data = 8'b0,
    output reg         uart_send = 1'b0,
    input  wire        uart_busy,
    input  wire        uart_done
);
    localparam integer BUFFER_DEPTH = (1 << BUFFER_ADDR_WIDTH);
    localparam [1:0] FIFO_IDLE    = 2'd0;
    localparam [1:0] FIFO_POP     = 2'd1;
    localparam [1:0] FIFO_CAPTURE = 2'd2;

    reg [7:0] tx_buffer [0:BUFFER_DEPTH-1];
    reg [BUFFER_ADDR_WIDTH-1:0] write_ptr = {BUFFER_ADDR_WIDTH{1'b0}};
    reg [BUFFER_ADDR_WIDTH-1:0] read_ptr  = {BUFFER_ADDR_WIDTH{1'b0}};
    reg [BUFFER_ADDR_WIDTH:0] buffered_count = {(BUFFER_ADDR_WIDTH+1){1'b0}};
    reg [1:0] fifo_state = FIFO_IDLE;
    reg uart_send_pending = 1'b0;

    wire [3:0] cs   = fifo_rd_data[19:16];
    wire [7:0] mosi = fifo_rd_data[15:8];
    wire [7:0] miso = fifo_rd_data[7:0];
    wire parity_mosi = ^mosi;
    wire parity_miso = ^miso;
    wire parity_header = ^{cs, 1'b0, parity_mosi, parity_miso};
    wire [7:0] header = {cs, 1'b0, parity_mosi, parity_miso, parity_header};

    // Данные удаляются из кольца одновременно с выдачей send. uart_data
    // удерживает байт стабильным до его захвата uart_tx на следующем clk.
    // После поднятия send ждём один такт, пока uart_tx захватит этот строб и
    // поднимет busy. Иначе два соседних байта могли бы быть выданы до того,
    // как busy успеет измениться.
    wire uart_take = !uart_send_pending && !uart_busy && (buffered_count != 0);
    // В кольцо нельзя помещать часть SPI-записи: для неё всегда нужны 3 места.
    wire ring_has_record_space = (buffered_count <= BUFFER_DEPTH - 3);
    wire fifo_enqueue = (fifo_state == FIFO_CAPTURE);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            write_ptr      <= {BUFFER_ADDR_WIDTH{1'b0}};
            read_ptr       <= {BUFFER_ADDR_WIDTH{1'b0}};
            buffered_count <= {(BUFFER_ADDR_WIDTH+1){1'b0}};
            fifo_state     <= FIFO_IDLE;
            uart_send_pending <= 1'b0;
            fifo_rd_en     <= 1'b0;
            uart_data      <= 8'b0;
            uart_send      <= 1'b0;
        end else begin
            // Оба управляющих сигнала являются однократными стробами.
            fifo_rd_en <= 1'b0;
            uart_send  <= 1'b0;

            if (uart_send_pending)
                uart_send_pending <= 1'b0;

            // UART извлекает очередной готовый байт, не ожидая окончания
            // предыдущего FSM чтения FIFO.
            if (uart_take) begin
                uart_data <= tx_buffer[read_ptr];
                uart_send <= 1'b1;
                uart_send_pending <= 1'b1;
                read_ptr <= read_ptr + 1'b1;
            end

            // Чтение async_fifo занимает два такта после выдачи rd_en:
            // один такт FIFO захватывает запрос, на следующем rd_data уже
            // можно поместить в кольцевой буфер.
            case (fifo_state)
                FIFO_IDLE: begin
                    if (!fifo_empty && ring_has_record_space) begin
                        fifo_rd_en <= 1'b1;
                        fifo_state <= FIFO_POP;
                    end
                end

                FIFO_POP: fifo_state <= FIFO_CAPTURE;

                FIFO_CAPTURE: begin
                    tx_buffer[write_ptr]       <= header;
                    tx_buffer[write_ptr + 1'b1] <= mosi;
                    tx_buffer[write_ptr + 2'd2] <= miso;
                    write_ptr <= write_ptr + 2'd3;
                    fifo_state <= FIFO_IDLE;
                end

                default: fifo_state <= FIFO_IDLE;
            endcase

            // Одновременно может добавиться запись (3 байта) и уйти один
            // байт в UART. Такое обновление счётчика сохраняет порядок и
            // корректно учитывает оба события.
            case ({fifo_enqueue, uart_take})
                2'b10: buffered_count <= buffered_count + 2'd3;
                2'b01: buffered_count <= buffered_count - 1'b1;
                2'b11: buffered_count <= buffered_count + 2'd2;
                default: buffered_count <= buffered_count;
            endcase
        end
    end
endmodule
