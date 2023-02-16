/* 1.先设计两个寄存器：gpio_ctrl（控制GPIO的输入和输出模式）
                       gpio_data（存放GPIO的输入或输出数据）
   2.给这两个寄存器规划地址
   3.通过寻址来写这两个寄存器。
   4.通过配置寄存器来实现GPIO的输入输出。
 */  
// GPIO模块 
module gpio(
	
	input wire clk,  
	input wire rst,  
	
	input wire we_i,  //总线写使能
	input wire[31:0] addr_i,   //总线 配置IO口寄存器地址
	input wire[31:0] data_i,   //总线 写数据（用来配置IO口相关寄存器）
	input wire[1:0] io_pin_i,  //输入模式下，IO口的输入逻辑电平
	
	output wire[31:0] reg_ctrl,  //IO口控制寄存器数据 0: 高阻，1：输出，2：输入
	output wire[31:0] reg_data,  //IO口数据寄存器数据
	output reg[31:0] data_o       // 总线读IO口寄存器数据

    );


    // GPIO控制寄存器的地址
    localparam GPIO_CTRL = 4'h0;
    // GPIO数据寄存器的地址
    localparam GPIO_DATA = 4'h4;

    // 每2位控制1个IO的模式，最多支持16个IO
    // 0: 高阻，1：输出，2：输入
    reg[31:0] gpio_ctrl;
    // 输入输出数据
    reg[31:0] gpio_data;


    assign reg_ctrl = gpio_ctrl;
    assign reg_data = gpio_data;


    // 写寄存器
    always @ (posedge clk) begin
        if (rst == 1'b0) begin
            gpio_data <= 32'h0;
            gpio_ctrl <= 32'h0;
        end else begin
            if (we_i == 1'b1) begin
                case (addr_i[3:0]) //寄存器寻址
                    GPIO_CTRL: begin
                        gpio_ctrl <= data_i; //通过配置寄存器gpio_ctrl来实现GPIO的输入输出
                    end
                    GPIO_DATA: begin
                        gpio_data <= data_i;
                    end
                endcase
            end else begin //如果IO口是输入模式，则将输入的逻辑电平存放到gpio_data寄存器中
                if (gpio_ctrl[1:0] == 2'b10) begin
                    gpio_data[0] <= io_pin_i[0];
                end
                if (gpio_ctrl[3:2] == 2'b10) begin
                    gpio_data[1] <= io_pin_i[1];
                end
            end
        end
    end

    // 读寄存器
    always @ (*) begin
        if (rst == 1'b0) begin
            data_o = 32'h0;
        end else begin
            case (addr_i[3:0])
                GPIO_CTRL: begin
                    data_o = gpio_ctrl;
                end
                GPIO_DATA: begin
                    data_o = gpio_data;
                end
                default: begin
                    data_o = 32'h0;
                end
            endcase
        end
    end

endmodule
