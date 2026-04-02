// Testbench - Snake Game (Tang Nano 9K + Sipeed 7-inch LCD 800x480)
//
// Phase 1 - ST_IDLE:    white title text visible, no green/red game pixels
// Phase 2 - ST_PLAYING: after key press -> green head, red food, white score
//
// Build & run:
//   iverilog -g2005 -o snake_sim.vvp clock_divider.v vga_controller.v \
//            keypad_scanner.v snake_top.v snake_top_tb.v
//   vvp snake_sim.vvp

`timescale 1ns/1ps

module snake_top_tb;

    reg clk       = 0;
    reg reset_btn = 0;
    reg [3:0] KEY_COL = 4'b0000;

    wire        LCD_CLK, LCD_HYNC, LCD_SYNC, LCD_DEN;
    wire [4:0]  LCD_R;
    wire [5:0]  LCD_G;
    wire [4:0]  LCD_B;
    wire [3:0]  KEY_ROW;

    snake_top dut (
        .clk(clk), .reset_btn(reset_btn),
        .LCD_CLK(LCD_CLK), .LCD_HYNC(LCD_HYNC), .LCD_SYNC(LCD_SYNC),
        .LCD_DEN(LCD_DEN), .LCD_R(LCD_R), .LCD_G(LCD_G), .LCD_B(LCD_B),
        .KEY_ROW(KEY_ROW), .KEY_COL(KEY_COL)
    );

    always #18.5 clk = ~clk;

    integer vsync_count  = 0;
    integer hsync_count  = 0;
    integer white_pixels = 0;
    integer green_pixels = 0;
    integer red_pixels   = 0;
    integer bad_pixels   = 0;

    always @(negedge LCD_HYNC) hsync_count = hsync_count + 1;
    always @(negedge LCD_SYNC) vsync_count = vsync_count + 1;

    always @(posedge LCD_CLK) begin
        if (LCD_DEN && LCD_R==5'b11111 && LCD_G==6'b111111 && LCD_B==5'b11111)
            white_pixels = white_pixels + 1;
        if (LCD_DEN && LCD_R==5'b00000 && LCD_G==6'b111111 && LCD_B==5'b00000)
            green_pixels = green_pixels + 1;
        if (LCD_DEN && LCD_R==5'b11111 && LCD_G==6'b000000 && LCD_B==5'b00000)
            red_pixels   = red_pixels + 1;
        if (!LCD_DEN && (LCD_R!=5'b0 || LCD_G!=6'b0 || LCD_B!=5'b0))
            bad_pixels   = bad_pixels + 1;
    end

    task reset_counters;
        begin
            white_pixels = 0; green_pixels = 0;
            red_pixels   = 0; vsync_count  = 0;
            hsync_count  = 0;
        end
    endtask

    initial begin
        $dumpfile("snake_top_tb.vcd");
        $dumpvars(0, snake_top_tb);
        #500_000;
        $dumpoff;
    end

    localparam ONE_FRAME = 17_000_000;

    initial begin
        $display("=== Snake Game Testbench ===");

        reset_btn = 1'b0; #200;
        reset_btn = 1'b1; #100;
        reset_counters;

        // ---- Phase 1: ST_IDLE (2 frames, no key pressed) ----
        #(2 * ONE_FRAME);
        $display("--- Phase 1: ST_IDLE ---");
        $display("VSYNC  : %0d (expect 2)",  vsync_count);
        $display("White  : %0d (expect >0 title text)", white_pixels);
        $display("Green  : %0d (expect 0  no game yet)", green_pixels);

        if (vsync_count >= 1 && vsync_count <= 3)
            $display("PASS: VSYNC timing OK");
        else
            $display("FAIL: VSYNC wrong - got %0d", vsync_count);

        if (white_pixels > 0)
            $display("PASS: Title text visible");
        else
            $display("FAIL: No title text pixels");

        if (green_pixels == 0)
            $display("PASS: No game pixels in IDLE");
        else
            $display("FAIL: Unexpected green in IDLE: %0d", green_pixels);

        reset_counters;

        // ---- Phase 2: press UP key -> ST_PLAYING ----
        // Must hold for at least one full frame so frame_tick sees any_key=1
        KEY_COL = 4'b0010;           // COL1=1 -> key "2" (UP)
        #(ONE_FRAME + ONE_FRAME / 2); // hold 1.5 frames to guarantee frame_tick sees it
        KEY_COL = 4'b0000;
        reset_counters;              // start counting only after key released
        #(2 * ONE_FRAME);

        $display("--- Phase 2: ST_PLAYING ---");
        $display("Green  : %0d (expect ~1800 head pixels)", green_pixels);
        $display("Red    : %0d (expect >0 food)", red_pixels);
        $display("White  : %0d (expect >0 score)", white_pixels);
        $display("Bad    : %0d (expect 0)", bad_pixels);

        if (green_pixels >= 1700 && green_pixels <= 1900)
            $display("PASS: Head pixel count OK");
        else
            $display("FAIL: Head pixels wrong - got %0d", green_pixels);

        if (red_pixels > 0)
            $display("PASS: Food rendered");
        else
            $display("FAIL: No food pixels");

        if (white_pixels > 0)
            $display("PASS: Score overlay rendered");
        else
            $display("FAIL: No score pixels");

        if (bad_pixels == 0)
            $display("PASS: No pixels outside DE");
        else
            $display("FAIL: %0d pixels outside DE", bad_pixels);

        $display("=== Done ===");
        $finish;
    end

endmodule
