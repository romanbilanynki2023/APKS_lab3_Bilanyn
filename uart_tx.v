// =============================================================
// uart_tx.v - Передавач UART (8N1: 8 біт даних, без парності, 1 стоп-біт)
// FSM: IDLE -> START -> DATA (8 біт, молодший першим) -> STOP -> IDLE
// =============================================================
module uart_tx #(
    parameter CLK_FREQ = 50_000_000,   // тактова частота, Гц
    parameter BAUD     = 115_200       // баудова швидкість
)(
    input  wire       clk,       // тактовий сигнал
    input  wire       rst,       // синхронне скидання (активний 1)
    input  wire [7:0] data_in,   // байт для передачі
    input  wire       start,     // імпульс "почати передачу" (коли busy = 0)
    output reg        tx,        // послідовний вихід (у спокої = 1)
    output wire       busy       // 1 - передача триває
);
    // Дільник частоти: кількість тактів clk на один біт
    localparam CLKS_PER_BIT = CLK_FREQ / BAUD;

    // Стани автомата
    localparam [1:0] IDLE  = 2'd0,
                     START = 2'd1,
                     DATA  = 2'd2,
                     STOP  = 2'd3;

    reg [1:0]  state;     // поточний стан
    reg [15:0] clk_cnt;   // лічильник тактів у межах одного біта
    reg [2:0]  bit_idx;   // номер біта, що передається (0..7)
    reg [7:0]  shreg;     // зафіксований байт даних

    assign busy = (state != IDLE);

    always @(posedge clk) begin
        if (rst) begin
            state   <= IDLE;
            tx      <= 1'b1;
            clk_cnt <= 0;
            bit_idx <= 0;
            shreg   <= 8'd0;
        end else begin
            case (state)
                IDLE: begin
                    tx      <= 1'b1;
                    clk_cnt <= 0;
                    bit_idx <= 0;
                    if (start) begin
                        shreg <= data_in;   // фіксуємо дані
                        state <= START;
                    end
                end

                START: begin                // стартовий біт = 0
                    tx <= 1'b0;
                    if (clk_cnt == CLKS_PER_BIT - 1) begin
                        clk_cnt <= 0;
                        state   <= DATA;
                    end else
                        clk_cnt <= clk_cnt + 1;
                end

                DATA: begin                 // 8 бітів, LSB першим
                    tx <= shreg[bit_idx];
                    if (clk_cnt == CLKS_PER_BIT - 1) begin
                        clk_cnt <= 0;
                        if (bit_idx == 3'd7) begin
                            bit_idx <= 0;
                            state   <= STOP;
                        end else
                            bit_idx <= bit_idx + 1;
                    end else
                        clk_cnt <= clk_cnt + 1;
                end

                STOP: begin                 // стоповий біт = 1
                    tx <= 1'b1;
                    if (clk_cnt == CLKS_PER_BIT - 1) begin
                        clk_cnt <= 0;
                        state   <= IDLE;
                    end else
                        clk_cnt <= clk_cnt + 1;
                end
            endcase
        end
    end
endmodule