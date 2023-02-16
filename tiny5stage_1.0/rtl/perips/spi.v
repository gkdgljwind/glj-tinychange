
// spi master模块
//SPI是串行外设接口（Serial Peripheral Interface）的缩写，
//是一种高速的，全双工，同步的通信总线
module spi(

    input wire clk,
    input wire rst,

    input wire[31:0] data_i,
    input wire[31:0] addr_i,
    input wire we_i,

    output reg[31:0] data_o,//通过总线，将SPI模块中的寄存器数据输出到内核中

//这4个信号，是SPI模块（主）与外设们（从）之间的交互
    output reg spi_mosi,             // spi控制器输出、spi设备输入信号
    input wire spi_miso,             // spi控制器输入、spi设备输出信号
    output wire spi_ss,              // spi设备片选，选择哪一个外设
    output reg spi_clk               // spi设备时钟，最大频率为输入clk的一半（根据外设来判定时钟频率）

    );


    localparam SPI_CTRL   = 4'h0;    // spi_ctrl寄存器地址偏移
    localparam SPI_DATA   = 4'h4;    // spi_data寄存器地址偏移
    localparam SPI_STATUS = 4'h8;    // spi_status寄存器地址偏移

    // spi控制寄存器
    // addr: 0x00
    // [0]: 1: enable, 0: disable
    // [1]: CPOL
    // [2]: CPHA
    // [3]: select slave, 1: select, 0: deselect 就是SPI的片选信号
    // [15:8]: clk div
    reg[31:0] spi_ctrl;
    // spi数据寄存器
    // addr: 0x04
    // [7:0] cmd or inout data
    reg[31:0] spi_data;
    // spi状态寄存器
    // addr: 0x08
    // [0]: 1: busy, 0: idle
    reg[31:0] spi_status;

    reg[8:0] clk_cnt;               // 分频计数
    reg en;                         // 使能，开始传输信号，传输期间一直有效
    reg[4:0] spi_clk_edge_cnt;      // spi clk时钟沿的个数
    reg spi_clk_edge_level;         // spi clk沿电平
    reg[7:0] rdata;                 // 从spi设备（从机）读回来的数据
    reg done;                       // 传输完成信号
    reg[3:0] bit_index;             // 数据bit索引
    wire[8:0] div_cnt;


    assign spi_ss = ~spi_ctrl[3];   // SPI设备片选信号
    // 0000_0000: 2分频，0000_0001：4分频，0000_0011：8分频，0000_0111：16分频，0000_1111：32分频，以此类推
    assign div_cnt = spi_ctrl[15:8];
    


    // 产生使能信号
    // 传输期间一直有效
    always @ (posedge clk) begin
        if (rst == 1'b0) begin
            en <= 1'b0;
        end else begin
            if (spi_ctrl[0] == 1'b1) begin
                en <= 1'b1;
            end else if (done == 1'b1) begin
                en <= 1'b0;
            end else begin
                en <= en;
            end
        end
    end

    // 对输入时钟进行计数
    always @ (posedge clk) begin
        if (rst == 1'b0) begin
            clk_cnt <= 9'h0;
        end else if (en == 1'b1) begin
            if (clk_cnt == div_cnt) begin
                clk_cnt <= 9'h0;
            end else begin
                clk_cnt <= clk_cnt + 1'b1;
            end
        end else begin
            clk_cnt <= 9'h0;
        end
    end

    // 对spi clk沿进行计数
    // 每当计数到分频值时产生一个上升沿脉冲
    always @ (posedge clk) begin
        if (rst == 1'b0) begin
            spi_clk_edge_cnt <= 5'h0;
            spi_clk_edge_level <= 1'b0;
        end else if (en == 1'b1) begin
            // 计数达到分频值
            if (clk_cnt == div_cnt) begin
                if (spi_clk_edge_cnt == 5'd17) begin
                    spi_clk_edge_cnt <= 5'h0;
                    spi_clk_edge_level <= 1'b0;
                end else begin
                    spi_clk_edge_cnt <= spi_clk_edge_cnt + 1'b1;
                    spi_clk_edge_level <= 1'b1;
                end
            end else begin
                spi_clk_edge_level <= 1'b0;
            end
        end else begin
            spi_clk_edge_cnt <= 5'h0;
            spi_clk_edge_level <= 1'b0;
        end
    end

    // bit序列
    always @ (posedge clk) begin
        if (rst == 1'b0) begin
            spi_clk <= 1'b0;
            rdata <= 8'h0;
            spi_mosi <= 1'b0;
            bit_index <= 4'h0;
        end else begin
            if (en) begin
                if (spi_clk_edge_level == 1'b1) begin
                    case (spi_clk_edge_cnt)
                        // 第奇数个时钟沿
                        1, 3, 5, 7, 9, 11, 13, 15: begin
                            spi_clk <= ~spi_clk;
                            if (spi_ctrl[2] == 1'b1) begin //CPHA == 1；偶数沿采样，奇数沿放数据
                                spi_mosi <= spi_data[bit_index];   // 送出1bit数据 先送高位 
                                bit_index <= bit_index - 1'b1;
                            end else begin  //CPHA == 0；奇数沿采样，偶数沿放数据
                                rdata <= {rdata[6:0], spi_miso};   // 读1bit数据
                            end
                        end
                        // 第偶数个时钟沿
                        2, 4, 6, 8, 10, 12, 14, 16: begin
                            spi_clk <= ~spi_clk;
                            if (spi_ctrl[2] == 1'b1) begin  //CPHA == 1；偶数沿采样，奇数沿放数据
                                rdata <= {rdata[6:0], spi_miso};   // 读1bit数据
                            end else begin  //CPHA == 0；奇数沿采样，偶数沿放数据
                                spi_mosi <= spi_data[bit_index];   // 送出1bit数据
                                bit_index <= bit_index - 1'b1;
                            end
                        end
                        17: begin
                            spi_clk <= spi_ctrl[1]; //传送完8bit数据之后 将spi_clk复位
                        end
                    endcase
                end
            end else begin
                // 初始状态
                spi_clk <= spi_ctrl[1];
                if (spi_ctrl[2] == 1'b0) begin //CPHA == spi_ctrl[2] == 1'b0 奇数沿采样
                    spi_mosi <= spi_data[7];           // 送出最高位数据
                    bit_index <= 4'h6;
                end else begin  //spi_ctrl[2] == 1'b1 偶数沿采样
                    bit_index <= 4'h7;
                end
            end
        end
    end

    // 产生结束(完成)信号
    always @ (posedge clk) begin
        if (rst == 1'b0) begin
            done <= 1'b0;
        end else begin
            if (en && spi_clk_edge_cnt == 5'd17) begin
                done <= 1'b1;
            end else begin
                done <= 1'b0;
            end
        end
    end

    // write reg
    always @ (posedge clk) begin
        if (rst == 1'b0) begin
            spi_ctrl <= 32'h0;
            spi_data <= 32'h0;
            spi_status <= 32'h0;
        end else begin
            spi_status[0] <= en;
            if (we_i == 1'b1) begin
                case (addr_i[3:0])
                    SPI_CTRL: begin
                        spi_ctrl <= data_i;
                    end
                    SPI_DATA: begin
                        spi_data <= data_i;
                    end
                    default: begin

                    end
                endcase
            end else begin
                spi_ctrl[0] <= 1'b0;
                // 发送完成后更新数据寄存器
                if (done == 1'b1) begin
                    spi_data <= {24'h0, rdata};
                end
            end
        end
    end

    // read reg
    always @ (*) begin
        if (rst == 1'b0) begin
            data_o = 32'h0;
        end else begin
            case (addr_i[3:0])
                SPI_CTRL: begin
                    data_o = spi_ctrl;
                end
                SPI_DATA: begin
                    data_o = spi_data;
                end
                SPI_STATUS: begin
                    data_o = spi_status;
                end
                default: begin
                    data_o = 32'h0;
                end
            endcase
        end
    end

endmodule
