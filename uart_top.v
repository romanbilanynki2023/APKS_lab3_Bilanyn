// =============================================================
// uart_top.v - Верхній модуль: об'єднує передавач і приймач.
// Потрібен для синтезу (щоб Yosys/Vivado синтезував обидва блоки).
// =============================================================
module uart_top #(
    parameter CLK_FREQ = 50_000_000,
    parameter BAUD     = 115_200
)(
    input  wire       clk,
    input  wire       rst,
    // Передавач
    input  wire [7:0] data_in,
    input  wire       start,
    output wire       tx,
    output wire       busy,
    // Приймач
    input  wire       rx,
    output wire [7:0] data_out,
    output wire       valid
);
    uart_tx #(.CLK_FREQ(CLK_FREQ), .BAUD(BAUD)) u_tx (
        .clk(clk), .rst(rst), .data_in(data_in),
        .start(start), .tx(tx), .busy(busy)
    );

    uart_rx #(.CLK_FREQ(CLK_FREQ), .BAUD(BAUD)) u_rx (
        .clk(clk), .rst(rst), .rx(rx),
        .data_out(data_out), .valid(valid)
    );
endmodule