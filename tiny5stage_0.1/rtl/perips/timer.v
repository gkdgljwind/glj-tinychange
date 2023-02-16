`include "../core/defines.v"

// 32 bits count up timer module
module timer(

    input wire clk,
    input wire rst,

    input wire[31:0] data_i,
    input wire[31:0] addr_i,
    input wire we_i,

    output reg[31:0] data_o,
    output wire int_sig_o

    );
	
	//寄存器地址规划
    localparam REG_CTRL = 4'h0; //定时器使能 定时器中断使能 
    localparam REG_COUNT = 4'h4; //定时器计数器（只读类型）
    localparam REG_VALUE = 4'h8; //设置阈值

    // [0]: timer enable 1
    // [1]: timer int enable 1
    // [2]: timer int pending, write 1 to clear it ，C代码中初始化置1清零 1
	//*中断的等待(pending)状态，有效时表示表示定时器中断正在等待(pending)*//
    // addr offset: 0x00
    reg[31:0] timer_ctrl;

    // timer current count, read only
    // addr offset: 0x04
    reg[31:0] timer_count;

    // timer expired value
    // addr offset: 0x08
    reg[31:0] timer_value;  //设置阈值

	//定时器中断使能 且 定时器达到计数阈值 发出中断信号，通过取指打拍模块if_id传给中断模块clint模块进行中断仲裁及处理
    assign int_sig_o = ((timer_ctrl[1] == 1'b1) && (timer_ctrl[2] == 1'b1))? `INT_ASSERT: `INT_DEASSERT;

    // counter
    always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            timer_count <= `ZeroWord;
        end else begin
			//定时器使能 则定时器计数器开始计数 计数至阈值时清零
            if (timer_ctrl[0] == 1'b1) begin 
                timer_count <= timer_count + 1'b1;
                if (timer_count >= timer_value) begin
                    timer_count <= `ZeroWord;
                end
            end else begin
                timer_count <= `ZeroWord;
            end
        end
    end

    // write regs
    always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            timer_ctrl <= `ZeroWord;
            timer_value <= `ZeroWord;
        end else begin
            if (we_i == `WriteEnable) begin
                case (addr_i[3:0])
                    REG_CTRL: begin
						//timer_ctrl[2] 写1清0
                        timer_ctrl <= {data_i[31:3], (timer_ctrl[2] & (~data_i[2])), data_i[1:0]};
                    end                                  //                ~1 = 0
                    REG_VALUE: begin
                        timer_value <= data_i;
                    end
                endcase
            end else begin
                if ((timer_ctrl[0] == 1'b1) && (timer_count >= timer_value)) begin
                    timer_ctrl[0] <= 1'b0;
					//定时器达到计数阈值，中断的等待(pending)状态置为1，触发中断
                    timer_ctrl[2] <= 1'b1; 
                end
            end
        end
    end

    // read regs
    always @ (*) begin
        if (rst == `RstEnable) begin
            data_o = `ZeroWord;
        end else begin
            case (addr_i[3:0])
                REG_VALUE: begin
                    data_o = timer_value;
                end
                REG_CTRL: begin
                    data_o = timer_ctrl;
                end
                REG_COUNT: begin
                    data_o = timer_count;
                end
                default: begin
                    data_o = `ZeroWord;
                end
            endcase
        end
    end

endmodule
