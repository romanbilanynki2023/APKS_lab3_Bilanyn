// =============================================================
// uart_rx.v - Приймач UART (8N1)
// FSM: IDLE -> START (перевірка в середині біта) -> DATA -> STOP -> IDLE
// Кожен біт семплується посередині його тривалості.
// =============================================================
module uart_rx #(
    parameter CLK_FREQ = 50_000_000,
    parameter BAUD     = 115_200
)(
    input  wire       clk,        // тактовий сигнал
    input  wire       rst,        // синхронне скидання (активний 1)
    input  wire       rx,         // послідовний вхід
    output reg  [7:0] data_out,   // прийнятий байт
    output reg        valid       // імпульс на 1 такт: data_out достовірний
);
    localparam CLKS_PER_BIT = CLK_FREQ / BAUD;

    localparam [1:0] IDLE  = 2'd0,
                     START = 2'd1,
                     DATA  = 2'd2,
                     STOP  = 2'd3;

    reg [1:0]  state;
    reg [15:0] clk_cnt;
    reg [2:0]  bit_idx;
    reg [7:0]  shreg;          // регістр збирання біт

    // Двоступенева синхронізація асинхронного входу rx (захист від метастабільності)
    reg rx_s1, rx_s;
    always @(posedge clk) begin
        rx_s1 <= rx;
        rx_s  <= rx_s1;
    end

    always @(posedge clk) begin
        valid <= 1'b0;   // за замовчуванням імпульс вимкнений
        if (rst) begin
            state    <= IDLE;
            clk_cnt  <= 0;
            bit_idx  <= 0;
            shreg    <= 8'd0;
            data_out <= 8'd0;
            rx_s1    <= 1'b1;
            rx_s     <= 1'b1;
        end else begin
            case (state)
                IDLE: begin
                    clk_cnt <= 0;
                    bit_idx <= 0;
                    if (rx_s == 1'b0)          // виявлено спад - можливий старт-біт
                        state <= START;
                end

                START: begin                   // чекаємо середину старт-біта
                    if (clk_cnt == (CLKS_PER_BIT - 1) / 2) begin
                        if (rx_s == 1'b0) begin // старт-біт підтверджено
                            clk_cnt <= 0;
                            state   <= DATA;
                        end else
                            state <= IDLE;      // завада
                    end else
                        clk_cnt <= clk_cnt + 1;
                end

                DATA: begin                    // семплуємо кожен біт посередині
                    if (clk_cnt == CLKS_PER_BIT - 1) begin
                        clk_cnt        <= 0;
                        shreg[bit_idx] <= rx_s;
                        if (bit_idx == 3'd7) begin
                            bit_idx <= 0;
                            state   <= STOP;
                        end else
                            bit_idx <= bit_idx + 1;
                    end else
                        clk_cnt <= clk_cnt + 1;
                end

                STOP: begin                    // середина стоп-біта - байт готовий
                    if (clk_cnt == CLKS_PER_BIT - 1) begin
                        clk_cnt  <= 0;
                        data_out <= shreg;
                        valid    <= 1'b1;
                        state    <= IDLE;
                    end else
                        clk_cnt <= clk_cnt + 1;
                end
            endcase
        end
    end
endmodule