`timescale 1ns/1ps

// Gowin rPLL - Clock Generator
// Tang Nano 9K: 27 MHz input -> 33 MHz pixel clock output
//
// PLL calculation:
//   CLKVCO = CLKIN / (IDIV_SEL+1) * (FBDIV_SEL+1)
//          = 27 / 1 * 22 = 594 MHz  (within Gowin VCO range: 400-1200 MHz)
//   CLKOUT = CLKVCO / ODIV_SEL
//          = 594 / 18 = 33 MHz  (pixel clock for 800x480 @ 60Hz)

module clock_divider (
    input  wire clk_27MHz,
    input  wire reset,
    output wire clk_pixel,   // 33 MHz
    output wire pll_locked   // HIGH when PLL is stable - use to hold reset
);

`ifndef SYNTHESIS
    // -------------------------------------------------------
    // Behavioral simulation model (iverilog)
    // מייצר 33 MHz ללא תלות ב-clk_27MHz
    // -------------------------------------------------------
    reg clk_out = 0;
    always #15 clk_out = ~clk_out;   // 30ns period = 33.3 MHz
    assign clk_pixel  = clk_out;
    assign pll_locked = 1'b1;

`else
    // -------------------------------------------------------
    // Gowin rPLL (synthesis only - Gowin EDA)
    // -------------------------------------------------------
    rPLL #(
        .FCLKIN     ("27"),
        .IDIV_SEL   (0),     // IDIV = 0+1 = 1
        .FBDIV_SEL  (21),    // FBDIV = 21+1 = 22  =>  VCO = 27*22 = 594 MHz
        .ODIV_SEL   (18),    // CLKOUT = 594/18 = 33 MHz
        .CLKFB_SEL  ("INTERNAL"),
        .DEVICE     ("GW1NR-9C")
    ) u_pll (
        .CLKOUT  (clk_pixel),
        .LOCK    (pll_locked),
        .CLKIN   (clk_27MHz),
        .CLKFB   (1'b0),
        .RESET   (reset),
        .RESET_P (1'b0),
        .FBDSEL  (6'b0),
        .IDSEL   (6'b0),
        .ODSEL   (6'b0),
        .PSDA    (4'b0),
        .DUTYDA  (4'b0),
        .FDLY    (4'b0)
    );
`endif

endmodule
