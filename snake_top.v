// Snake Game - Top Module
// Hardware: Tang Nano 9K (Gowin GW1NR-9C) + Sipeed 7-inch LCD 800x480
//
// System clock: 27 MHz (onboard crystal, פין 52)
// Pixel clock:  33 MHz (via Gowin rPLL)
// Color depth:  RGB565 - המחבר הפיזי על Tang Nano 9K: R[4:0] G[5:0] B[4:0]

module snake_top (
    input  wire        clk,       // 27 MHz (פין 52)
    input  wire        reset_btn, // כפתור S1 active-low (פין 4)

    // ממשק LCD - שמות תואמים בדיוק את קובץ ה-CST
    output wire        LCD_CLK,   // פין 35
    output wire        LCD_HYNC,  // פין 40
    output wire        LCD_SYNC,  // פין 34
    output wire        LCD_DEN,   // פין 33
    output wire [4:0]  LCD_R,     // פינים 75,74,73,72,71
    output wire [5:0]  LCD_G,     // פינים 70,69,68,57,56,55
    output wire [4:0]  LCD_B      // פינים 54,53,51,42,41
);
    // --- Reset: כפתור active-low -> reset פנימי active-high ---
    wire reset = ~reset_btn;

    // --- PLL: 27 MHz -> 33 MHz ---
    wire clk_pixel;
    wire pll_locked;

    clock_divider u_pll (
        .clk_27MHz  (clk),
        .reset      (reset),
        .clk_pixel  (clk_pixel),
        .pll_locked (pll_locked)
    );

    // Reset מופעל עד ייצוב PLL
    wire sys_reset = reset | ~pll_locked;

    // --- LCD Controller ---
    wire        de;
    wire [9:0]  pixel_x;
    wire [9:0]  pixel_y;

    vga_controller u_lcd (
        .clk_pixel (clk_pixel),
        .reset     (sys_reset),
        .hsync     (LCD_HYNC),
        .vsync     (LCD_SYNC),
        .de        (de),
        .pixel_x   (pixel_x),
        .pixel_y   (pixel_y)
    );

    assign LCD_CLK = clk_pixel;
    assign LCD_DEN = de;

    // -------------------------------------------------------
    //  Snake rendering
    //  גריד: CELL_SIZE=32 פיקסלים
    //    800 / 32 = 25 עמודות
    //    480 / 32 = 15 שורות
    //  נחש ראשוני: תא מרכזי (12, 7) -> פיקסל (384, 224)
    //  גודל תא על 7 אינץ: ~7.1 מ"מ
    // -------------------------------------------------------
    localparam CELL_SIZE = 32;
    localparam SNAKE_X   = 10'd384;  // 12 * 32
    localparam SNAKE_Y   = 10'd224;  //  7 * 32
    localparam BORDER    = 1;

    wire in_snake = (pixel_x >= SNAKE_X + BORDER) &&
                    (pixel_x <  SNAKE_X + CELL_SIZE - BORDER) &&
                    (pixel_y >= SNAKE_Y + BORDER) &&
                    (pixel_y <  SNAKE_Y + CELL_SIZE - BORDER);

    // --- Color output RGB565 ---
    // לבן: R=11111, G=111111, B=11111
    // שחור: כל הביטים 0
    assign LCD_R = (de && in_snake) ? 5'b11111 : 5'b00000;
    assign LCD_G = (de && in_snake) ? 6'b111111 : 6'b000000;
    assign LCD_B = (de && in_snake) ? 5'b11111 : 5'b00000;

endmodule
