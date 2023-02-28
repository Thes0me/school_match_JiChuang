`timescale 1ns / 1ps

module top_video_zone_display(
    input               clk,
    input               rst_n,
    input               uart_rx,
//    input wire [7:0]    mod_rgb_r,
//    input wire [7:0]    mod_rgb_g,
//    input wire [7:0]    mod_rgb_b,
//    input               de_input,
//    input               hs_input,
//    input               vs_input,
//    input               pclk_mod_in,

    output wire tmds_clk_p,
    output wire tmds_clk_n,
    output wire [2:0] tmds_data_p,
    output wire [2:0] tmds_data_n

);
wire rst;
assign rst = ~rst_n;
// 视频区域化模块例化 ####################################
// video_zone_judge Outputs   
wire  [23:0]  vid_pData_zoned;

video_zone_judge  u_video_zone_judge (
    .clk                     ( video_clock       ),
    .rstn                    ( ~rst              ),
    .pixel_x                 ( pixel_x           ),
    .pixel_y                 ( pixel_y           ),
    .para_list               ( para_list_fixed         ),
    .cmd_vaild               ( cmd_vaild         ),
    .cmd_code                ( cmdcode          ),
    .de_o                    ( de_o              ),
    .vid_pData               ( vid_pData         ),

    .vid_pData_zoned         ( vid_pData_zoned   )
);
// ##############################################

// USART command接收模块例化###########################
// 输入时钟50Mhz

// top_uart_cmd_resolve Parameters
parameter UART_BPS_RATE  = 115200                  ;
parameter BPS_DLY_BIT    = 1000000000/UART_BPS_RATE;

// top_uart_cmd_resolve Outputs
wire  [31:0]  para_list_fixed; 
wire  [7:0]  cmdcode;
wire  [7:0]  cmd_len;
wire  cmd_vaild;

top_uart_cmd_resolve #(
    .UART_BPS_RATE ( 115200                   ),
    .BPS_DLY_BIT   ( 1000000000/UART_BPS_RATE ))
 u_top_uart_cmd_resolve (
    .clk                     ( clk               ),
    .rst_n                   ( ~rst              ),
    .uart_rx                 ( uart_rx           ),

    .para_list_fixed         ( para_list_fixed   ),
    .cmdcode                 ( cmdcode           ),
    .cmd_len                 ( cmd_len           ),
    .check                   (                   ),
    .cmd_vaild               ( cmd_vaild         )
);
// ###############################################

// video pixel counter例化########################
// ------------------------> pixel_x, max=1280
// |
// |
// |
// |
// ↓
// pixel_y, max=720
// both enable when de_o is high.

// video_pixel_counter Outputs
wire  [10:0]  pixel_x;
wire  [10:0]  pixel_y;       
wire  de_o;
wire  [5:0]  block_h_cnt;     
wire  [5:0]  block_v_cnt;
wire  [5:0]  inblock_line_cnt;

video_pixel_counter  u_video_pixel_counter (
    .pclk                    ( video_clock               ),
    .rstn                    ( ~rst               ),
    .de                      ( de                 ),
    .hs                      ( hs                 ),
    .vs                      ( vs                 ),

    .p_cnt                   ( pixel_x              ),
    .line_cnt                ( pixel_y           ),
    .de_o                    ( de_o               ),
    .block_h_cnt             ( block_h_cnt        ),
    .block_v_cnt             ( block_v_cnt        ),
    .inblock_line_cnt        ( inblock_line_cnt   )
);
// ###############################################


// colorbar例化###################################
// color_bar Outputs
wire  hs;
wire  vs;
wire  de;
wire  [7:0]  rgb_r;
wire  [7:0]  rgb_g;
wire  [7:0]  rgb_b;
 color_bar u_color_bar (
     .clk                     ( video_clock),
     .rst                     ( rst        ),

     .hs                      ( hs         ),
     .vs                      ( vs         ),
     .de                      ( de         ),
     .rgb_r                   ( rgb_r      ),
     .rgb_g                   ( rgb_g      ),
     .rgb_b                   ( rgb_b      )
 );
// ###############################################


// 视频仿真时钟生成################################
wire video_clock;
wire video_clock5x;
// clk_wiz_0 video_clock_gen
//    (
//     // Clock out ports
//     .clk_out1       (video_clock),     // output clk_out1
//     .clk_out2       (video_clock5x),     // output clk_out2
//     // Status and control signals
//     .reset          (rst), // input reset
//     .locked         (),       // output locked
//    // Clock in ports
//     .clk_in1        (clk));      // input clk_in1
video_clk_gen u_video_clock_gen (
  .pll_rst(rst),      // input
  .clkin1(clk),        // input
  .pll_lock(),    // output
  .clkout0(video_clock5x),      // output
  .clkout1(video_clock)       // output
);

// ###############################################


// RGB转DVI输出IP核例化############################
wire [23:0] vid_pData;
assign vid_pData = {rgb_r, rgb_g, rgb_b};

wire [7:0] red_din = vid_pData_zoned[23:16];
wire [7:0] green_din = vid_pData_zoned[15:8];
wire [7:0] blue_din = vid_pData_zoned[7:0];

//rgb2dvi_0 rgb2dvi (
//  .TMDS_Clk_p       (TMDS_Clk_p),    // output wire TMDS_Clk_p
//  .TMDS_Clk_n       (TMDS_Clk_n),    // output wire TMDS_Clk_n
//  .TMDS_Data_p      (TMDS_Data_p),  // output wire [2 : 0] TMDS_Data_p
//  .TMDS_Data_n      (TMDS_Data_n),  // output wire [2 : 0] TMDS_Data_n
//  .aRst             (rst),                // input wire aRst
//  .vid_pData        (vid_pData_zoned),      // input wire [23 : 0] vid_pData
//  .vid_pVDE         (de_o),        // input wire vid_pVDE
//  .vid_pHSync       (hs),    // input wire vid_pHSync
//  .vid_pVSync       (vs),    // input wire vid_pVSync
//  .PixelClk         (video_clock)        // input wire PixelClk
//);
dvi_encoder rgb2dvi (
    .pixelclk(video_clock),        // input
    .pixelclk5x(video_clock5x),    // input
    .rstin(rst),              // input
    .blue_din(blue_din),        // input
    .green_din(green_din),      // input
    .red_din(red_din),          // input
    .hsync(hs),              // input
    .vsync(vs),              // input
    .de(de_o),                    // input
    .tmds_clk_p (tmds_clk_p),    // output
    .tmds_clk_n (tmds_clk_n),    // output
    .tmds_data_p(tmds_data_p),  // output
    .tmds_data_n(tmds_data_n)   // output
);
// ###############################################


endmodule
