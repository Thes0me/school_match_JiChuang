`timescale 1ns / 1ps

module video_zone_judge(
    input                   clk,  // video_clk
    input                   rstn,
    input       [10:0]      pixel_x,
    input       [10:0]      pixel_y,
    input       [31:0]      para_list,
    input                   cmd_vaild,
    input       [7:0]       cmd_code,
    input                   de_o,
    input       [23:0]      vid_pData,

    output reg  [23:0]      vid_pData_zoned
);

// command define
/*
1. cmd_code = 8'ha1
此时处于设定矩形左上坐标的模式
para_list[10:0] 为Y轴坐标, para_list[21:11] 为X轴坐标

2. cmd_code = 8'ha2
此时处于设定矩形长宽的模式，矩形长为X轴方向，宽为Y轴方向
para_list[10:0] 为Y轴宽度量, para_list[21:11] 为X轴长度量

3. cmd_code = 8'ha3
此时应用内部存储的数据，对视频进行区域化显示

4. zone area
              zone_x,y ################ zone_x+L,y
                       #              #
                       #              #
                       #              #
            zone_x,y+H ################ zone_x+L,y+H
故当pixel的xy坐标中的x在zone_x与zone_x+L之间，y在zone_y与zone_y+H
之间，显示正常视频源，其余情况用黑色或其他颜色屏蔽掉
*/

// 矩形区域的坐标与长宽获取模块################################
reg [10:0] zone_x;
reg [10:0] zone_y;
reg [10:0] zone_L;
reg [10:0] zone_H;

always @(posedge clk or negedge rstn) begin
    if(~rstn) begin
        zone_x <= 11'd0;
        zone_y <= 11'd0;
        zone_L <= 11'd0;
        zone_H <= 11'd0;
    end
    else if(cmd_vaild && cmd_code == 8'ha1) begin
        zone_x <= para_list[21:11];
        zone_y <= para_list[10:0];
    end
    else if(cmd_vaild && cmd_code == 8'ha2) begin
        zone_L <= para_list[21:11];
        zone_H <= para_list[10:0];
    end
    else begin
        ;
    end
end
// ##############################################


// 视频区域判别模块 #####################################
wire flag_x, flag_y;

assign flag_x = (pixel_x >= zone_x) && (pixel_x < zone_x+zone_L);
assign flag_y = (pixel_y >= zone_y) && (pixel_y < zone_y+zone_H);

always @(posedge clk or negedge rstn) begin
    if(~rstn) begin
        vid_pData_zoned <= 23'h000000;
    end
    else if(flag_x && flag_y && cmd_code == 8'ha3) begin
        vid_pData_zoned <= vid_pData;
    end
    else begin
        vid_pData_zoned <= 8'h0000ff; //blue background
    end
end
//###############################################

endmodule
