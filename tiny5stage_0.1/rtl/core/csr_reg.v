

`include "defines.v"

// CSR寄存器模块   Control and Status Register 控制与状态寄存器
module csr_reg(

    input wire clk,
    input wire rst,
   
    // form ex
    input wire we_i,                        // ex模块写寄存器标志
    input wire[`MemAddrBus] waddr_i,        // （是来自id吧！！！）ex模块写寄存器地址 32位
    input wire[`RegBus] data_i,             // ex模块写寄存器数据 32位
    // form id
    input wire[`MemAddrBus] raddr_i,        // ex模块读寄存器地址 32位
    // to id
    output reg[`RegBus] data_o ,             // id模块读寄存器数据

    // from clint
    input wire clint_we_i,                  // clint模块写寄存器标志
    input wire[`MemAddrBus] clint_raddr_i,  // clint模块读寄存器地址
    input wire[`MemAddrBus] clint_waddr_i,  // clint模块写寄存器地址
    input wire[`RegBus] clint_data_i,       // clint模块写寄存器数据
    // to clint
    output wire global_int_en_o,            // 全局中断使能标志   
    output reg[`RegBus] clint_data_o,       // clint模块读寄存器数据(未使用)
    output wire[`RegBus] clint_csr_mtvec,   // mtvec 保存发生异常时处理器需要跳转的地址
    output wire[`RegBus] clint_csr_mepc,    // mepc 保存发生异常指令的地址
    output wire[`RegBus] clint_csr_mstatus // mstatus 全局中断使能和其他状态信息
   

    );

    reg[`DoubleRegBus] cycle; //64位
    reg[`RegBus] mtvec;  //32位 保存发生异常时处理器需要跳转的地址（用来设置中断和异常的入口）。
    reg[`RegBus] mcause;//当产生中断和异常时，mcause寄存器中会记录当前产生的中断或者异常类型。
    reg[`RegBus] mepc;//保存发生异常指令的地址。
    reg[`RegBus] mie;//指明处理器目前能处理和忽略的中断。三种中断类型在m模式和s模式下都有相应的中断使能位设置，这是通过mie寄存器实现的。
    reg[`RegBus] mstatus; //全局中断使能和其他状态信息
    reg[`RegBus] mscratch;//mscratch寄存器用于机器模式下的程序临时保存某些数据


	//csr寄存器的第4位mstatus[3]是中断的全局使能位 
	//1：中断全局打开，0：中断全局关闭
    assign global_int_en_o = (mstatus[3] == 1'b1)? `True: `False;  //该寄存器mstatus[3]该位表示  MIE控制M模式下全局中断。

    assign clint_csr_mtvec = mtvec;
    assign clint_csr_mepc = mepc;
    assign clint_csr_mstatus = mstatus;

    // cycle counter
    // 复位撤销后就一直计数  计数器统计自CPU复位以来共运行了多少个周期。（核心时钟可能是动态调整的）
    always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            cycle <= {`ZeroWord, `ZeroWord};//时钟周期计数器 mcycle mcycleh
        end else begin
            cycle <= cycle + 1'b1;
        end
    end

    // write reg
    // 写寄存器操作
    always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            mtvec <= `ZeroWord;
            mcause <= `ZeroWord;
            mepc <= `ZeroWord;
            mie <= `ZeroWord;
            mstatus <= `ZeroWord;
            mscratch <= `ZeroWord;
        end else begin
            // 优先响应ex模块的写操作
            if (we_i == `WriteEnable) begin
                case (waddr_i[11:0])  //判断ex模块写寄存器地址后12位的值，状态寄存器的地址一共使用了12位。
                //地址由指令译码 
				//id译码模块传出的写csr地址 经由 执行模块ex 传入
				//csr_waddr_o = {20'h0, inst_i[31:20]};          
                  `CSR_MTVEC: begin   //12'h305
                        mtvec <= data_i;
                    end
                    `CSR_MCAUSE: begin  //12'h342
                        mcause <= data_i;
                    end
                    `CSR_MEPC: begin  //12'h341
                        mepc <= data_i;
                    end
                    `CSR_MIE: begin  //12'h304
                        mie <= data_i;
                    end
                    `CSR_MSTATUS: begin //12'h300
                        mstatus <= data_i;
                    end
                    `CSR_MSCRATCH: begin //12'h340
                        mscratch <= data_i;
                    end
                    default: begin

                    end
                endcase
            // clint模块写操作
            end else if (clint_we_i == `WriteEnable) begin
                case (clint_waddr_i[11:0])//地址 直接根据相关csr寄存器具体地址给出
                    `CSR_MTVEC: begin
                        mtvec <= clint_data_i;
                    end
                    `CSR_MCAUSE: begin
                        mcause <= clint_data_i;
                    end
                    `CSR_MEPC: begin
                        mepc <= clint_data_i;
                    end
                    `CSR_MIE: begin
                        mie <= clint_data_i;
                    end
                    `CSR_MSTATUS: begin
                        mstatus <= clint_data_i;
                    end
                    `CSR_MSCRATCH: begin
                        mscratch <= clint_data_i;
                    end
                    default: begin

                    end
                endcase
            end
        end
    end

    // read reg
    // ex模块读CSR寄存器  
    always @ (*) begin
        //第二条指令依赖于第一条指令的结果。为了解决这个数据相关的问题。
        //如果ex模块读寄存器地址等于写寄存器地址，并且正在写操作，则直接返回写数据
        if ((waddr_i[11:0] == raddr_i[11:0]) && (we_i == `WriteEnable)) begin
            data_o = data_i;
        end else begin
            case (raddr_i[11:0])
                `CSR_CYCLE: begin
                    data_o = cycle[31:0];
                end
                `CSR_CYCLEH: begin
                    data_o = cycle[63:32];
                end
                `CSR_MTVEC: begin
                    data_o = mtvec;
                end
                `CSR_MCAUSE: begin
                    data_o = mcause;
                end
                `CSR_MEPC: begin
                    data_o = mepc;
                end
                `CSR_MIE: begin
                    data_o = mie;
                end
                `CSR_MSTATUS: begin
                    data_o = mstatus;
                end
                `CSR_MSCRATCH: begin
                    data_o = mscratch;
                end
                default: begin
                    data_o = `ZeroWord;
                end
            endcase
        end
    end

    // read reg
    // clint模块读CSR寄存器
    always @ (*) begin
        if ((clint_waddr_i[11:0] == clint_raddr_i[11:0]) && (clint_we_i == `WriteEnable)) begin
            clint_data_o = clint_data_i;
        end else begin
            case (clint_raddr_i[11:0])
                `CSR_CYCLE: begin
                    clint_data_o = cycle[31:0];
                end
                `CSR_CYCLEH: begin
                    clint_data_o = cycle[63:32];
                end
                `CSR_MTVEC: begin
                    clint_data_o = mtvec;
                end
                `CSR_MCAUSE: begin
                    clint_data_o = mcause;
                end
                `CSR_MEPC: begin
                    clint_data_o = mepc;
                end
                `CSR_MIE: begin
                    clint_data_o = mie;
                end
                `CSR_MSTATUS: begin
                    clint_data_o = mstatus;
                end
                `CSR_MSCRATCH: begin
                    clint_data_o = mscratch;
                end
                default: begin
                    clint_data_o = `ZeroWord;
                end
            endcase
        end
    end

endmodule
