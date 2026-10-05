// Пассивный приёмник SPI mode 0/3: данные считываются по положительному
// фронту SCK. CS считается active-low; за одну транзакцию должен быть выбран
// ровно один из восьми CS.
module spi (
    input rst_n,

    input mosi,
    input miso,
    input sck,
    input [7:0] cs,

    output reg [7:0] data_miso = 8'b0,
    output reg [7:0] data_mosi = 8'b0,
    output reg [3:0] data_cs   = 4'b0,
    output reg       ready_data = 1'b0,

    // Прямой интерфейс записи в FIFO. Эти сигналы действительны до восьмого
    // положительного фронта SCK, на котором FIFO должен зафиксировать запись.
    output wire [19:0] fifo_wr_data,
    output wire        fifo_wr_en
);
    reg [2:0] cnt_data_bit = 3'b0;
    reg [7:0] shift_mosi = 8'b0;
    reg [7:0] shift_miso = 8'b0;

    // Устройство выбрано, если хотя бы одна линия CS опущена в ноль.
    wire cs_active = |(~cs);

    // Номер выбранной линии. Ноль означает, что CS не выбран или выбрано
    // сразу несколько устройств.
    reg [3:0] selected_cs;
    always @(*) begin
        case (~cs)
            8'b00000001: selected_cs = 4'd1;
            8'b00000010: selected_cs = 4'd2;
            8'b00000100: selected_cs = 4'd3;
            8'b00001000: selected_cs = 4'd4;
            8'b00010000: selected_cs = 4'd5;
            8'b00100000: selected_cs = 4'd6;
            8'b01000000: selected_cs = 4'd7;
            8'b10000000: selected_cs = 4'd8;
            default:     selected_cs = 4'd0;
        endcase
    end

    // Формируем данные комбинационно из уже принятых семи битов и текущего
    // входного бита. Поэтому FIFO может записать байт на том же фронте SCK.
    assign fifo_wr_data = {selected_cs, {shift_mosi[6:0], mosi},
                            {shift_miso[6:0], miso}};
    assign fifo_wr_en = cs_active && (cnt_data_bit == 3'd7);

    // Поднятие всех CS немедленно отбрасывает неполный байт. Это важно:
    // между двумя SPI-транзакциями SCK может не переключаться.
    always @(posedge sck or negedge cs_active or negedge rst_n) begin
        if (!rst_n || !cs_active) begin
            cnt_data_bit <= 3'd0;
            shift_mosi   <= 8'd0;
            shift_miso   <= 8'd0;
            ready_data   <= 1'b0;
        end else begin
            // ready_data — строб одного периода SCK, а не уровень до конца CS.
            ready_data <= 1'b0;

            // Стандартный SPI MSB-first: первый принятый бит становится bit 7.
            shift_mosi <= {shift_mosi[6:0], mosi};
            shift_miso <= {shift_miso[6:0], miso};

            if (cnt_data_bit == 3'd7) begin
                // В shift_* пока лежат первые семь битов; текущий входной бит
                // должен войти в опубликованный байт на позиции bit 0.
                data_mosi    <= {shift_mosi[6:0], mosi};
                data_miso    <= {shift_miso[6:0], miso};
                data_cs      <= selected_cs;
                cnt_data_bit <= 3'd0;
                ready_data   <= 1'b1;
            end else begin
                cnt_data_bit <= cnt_data_bit + 3'd1;
            end
        end
    end
endmodule // spi
