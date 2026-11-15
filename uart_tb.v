// =============================================================
// uart_tb.v - Testbench: loopback (tx -> rx), автоперевірка PASS/FAIL
// =============================================================
`timescale 1ns/1ps
module uart_tb;
    reg        clk = 0;
    reg        rst = 1;
    reg  [7:0] data_in = 8'd0;
    reg        start = 1'b0;
    wire       tx, busy, valid;
    wire [7:0] data_out;
    integer    errors = 0;

    // Loopback: вихід передавача заведено на вхід приймача
    uart_top #(.CLK_FREQ(50_000_000), .BAUD(115_200)) dut (
        .clk(clk), .rst(rst),
        .data_in(data_in), .start(start), .tx(tx), .busy(busy),
        .rx(tx), .data_out(data_out), .valid(valid)
    );

    always #10 clk = ~clk;   // 50 МГц (період 20 нс)

    // Передати байт і перевірити, що приймач отримав те саме
    task send_byte(input [7:0] b);
        begin
            @(posedge clk);
            data_in <= b;
            start   <= 1'b1;
            @(posedge clk);
            start   <= 1'b0;
            @(posedge valid);
            if (data_out === b)
                $display("OK   : sent 0x%02h, received 0x%02h", b, data_out);
            else begin
                $display("FAIL : sent 0x%02h, received 0x%02h", b, data_out);
                errors = errors + 1;
            end
            wait (!busy);
            repeat (100) @(posedge clk);
        end
    endtask

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, uart_tb);
        repeat (10) @(posedge clk);
        rst = 0;
        repeat (10) @(posedge clk);

        send_byte(8'h55);
        send_byte(8'hA3);
        send_byte(8'hFF);
        send_byte(8'h00);

        if (errors == 0) $display("RESULT: PASS");
        else             $display("RESULT: FAIL (%0d errors)", errors);
        $finish;
    end

    // Захист від зависання
    initial begin
        #5_000_000;
        $display("RESULT: FAIL (timeout)");
        $finish;
    end
endmodule
