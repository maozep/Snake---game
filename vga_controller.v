// LCD Controller - 800x480 @ 60Hz (Sipeed 7-inch RGB LCD)
// Pixel clock: 33 MHz
//
// Timing parameters:
//   H: Active=800  FP=40  Sync=128  BP=88   Total=1056
//   V: Active=480  FP=10  Sync=2    BP=33   Total=525
//   Refresh: 33,000,000 / (1056 * 525) = 59.5 Hz
//
// ממשק RGB LCD שונה מ-VGA:
//   - DE (Data Enable): HIGH כשהפיקסל תקף במקום לחשב display_active בחוץ
//   - PCLK: שעון פיקסלים מועבר ישירות למסך
//   - אין DAC - RGB דיגיטלי ישיר

module vga_controller (
    input  wire        clk_pixel,    // 33 MHz
    input  wire        reset,
    output reg         hsync,
    output reg         vsync,
    output reg         de,           // Data Enable - HIGH במהלך פיקסלים תקפים
    output wire [9:0]  pixel_x,      // עמודה נוכחית (0-799 בזמן de=1)
    output wire [9:0]  pixel_y       // שורה נוכחית  (0-479 בזמן de=1)
);
    // --- Timing parameters ---
    localparam H_ACTIVE      = 800;
    localparam H_FRONT_PORCH = 40;
    localparam H_SYNC_PULSE  = 128;
    localparam H_BACK_PORCH  = 88;
    localparam H_TOTAL       = 1056;  // 800+40+128+88

    localparam V_ACTIVE      = 480;
    localparam V_FRONT_PORCH = 10;
    localparam V_SYNC_PULSE  = 2;
    localparam V_BACK_PORCH  = 33;
    localparam V_TOTAL       = 525;   // 480+10+2+33

    // --- Counters ---
    // h_count צריך 11 ביטים: H_TOTAL-1 = 1055 > 1023 (מקסימום 10 ביטים)
    reg [10:0] h_count;
    reg [9:0]  v_count;

    // Horizontal counter
    always @(posedge clk_pixel or posedge reset) begin
        if (reset)
            h_count <= 10'd0;
        else if (h_count == H_TOTAL - 1)
            h_count <= 10'd0;
        else
            h_count <= h_count + 10'd1;
    end

    // Vertical counter
    always @(posedge clk_pixel or posedge reset) begin
        if (reset)
            v_count <= 10'd0;
        else if (h_count == H_TOTAL - 1) begin
            if (v_count == V_TOTAL - 1)
                v_count <= 10'd0;
            else
                v_count <= v_count + 10'd1;
        end
    end

    // --- Sync signals (active low) ---
    always @(posedge clk_pixel or posedge reset) begin
        if (reset) begin
            hsync <= 1'b1;
            vsync <= 1'b1;
            de    <= 1'b0;
        end else begin
            hsync <= ~(h_count >= (H_ACTIVE + H_FRONT_PORCH) &&
                       h_count <  (H_ACTIVE + H_FRONT_PORCH + H_SYNC_PULSE));
            vsync <= ~(v_count >= (V_ACTIVE + V_FRONT_PORCH) &&
                       v_count <  (V_ACTIVE + V_FRONT_PORCH + V_SYNC_PULSE));
            de    <= (h_count < H_ACTIVE) && (v_count < V_ACTIVE);
        end
    end

    // --- Pixel coordinates ---
    assign pixel_x = h_count;
    assign pixel_y = v_count;

endmodule
