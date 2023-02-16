//修改数据前推内容

`include "defines.v"

// 通用寄存器模块
module regs(

    input wire clk,
    input wire rst,

    // from ex
    input wire we_i,                      // 写寄存器标志
    input wire[`RegAddrBus] waddr_i,      // 写寄存器地址
    input wire[`RegBus] wdata_i,          // 写寄存器数据

    // from jtag
    input wire jtag_we_i,                 // 写寄存器标志
    input wire[`RegAddrBus] jtag_addr_i,  // 读、写寄存器地址
    input wire[`RegBus] jtag_data_i,      // 写寄存器数据
    input wire reg1_exforward_flag_i,    //寄存器1数据前推标志
    input wire reg2_exforward_flag_i,    //寄存器2数据前推标志

    input wire reg1_memforward_flag_i,    //寄存器1数据前推标志
    input wire reg2_memforward_flag_i,    //寄存器2数据前推标志

    input wire[31:0]ex_wdata_tem_i,     //执行阶段，暂存的写数据
    input wire[31:0]mem_wdata_tem_i,    //访存阶段，暂存的写数据
    // from id
    input wire[`RegAddrBus] raddr1_i,     // 读寄存器1地址

    // to id
    output reg[`RegBus] rdata1_o,         // 读寄存器1数据

    // from id
    input wire[`RegAddrBus] raddr2_i,     // 读寄存器2地址

    // to id
    output reg[`RegBus] rdata2_o,         // 读寄存器2数据

    // to jtag
    output reg[`RegBus] jtag_data_o       // 读寄存器数据

    );

    reg[`RegBus] regs[0:`RegNum - 1]; //32*32 //reg[31:0]位宽 regs[0:31] 深度 






// 写寄存器 写寄存器操作来自写回模块。
    always @ (*) begin
        if (rst == `RstDisable) begin//`define RstDisable 1'b1
            // 优先ex模块写操作 写使能为高，并且写寄存器地址不为0时，因为寄存器x0是只读寄存器并且其值固定为0。
            if ((we_i == `WriteEnable) && (waddr_i != `ZeroReg)) begin
             //将ex模块中的写数据和地址，写入寄存器相应的地址当中
                regs[waddr_i] <= wdata_i;
            //否则当 jtag的写使能为高，并且写寄存器地址不为0时，因为寄存器x0是只读寄存器并且其值固定为0。
            end else if ((jtag_we_i == `WriteEnable) && (jtag_addr_i != `ZeroReg)) begin
            //将jtag模块中的写数据和地址，写入寄存器相应的地址当中
                regs[jtag_addr_i] <= jtag_data_i;
            end
        end
    end

//读寄存器  
    // 读寄存器1  读寄存器操作来自译码模块，并且读出来的寄存器数据也会返回给译码模块。
	//assign rdata1_o = (raddr1_i == `ZeroReg) ? `ZeroWord : ((raddr1_i == waddr_i && we_i == `WriteEnable) ? wdata_i : regs[raddr1_i]); 
    always @ (*) begin
        if (raddr1_i == `ZeroReg) begin //如果读地址为0，因为寄存器x0是只读寄存器并且其值固定为0。 
            rdata1_o = `ZeroWord;//因此输出数据为32'h0

        //执行阶段数据前递：高优先级：第二条指令的译码依赖于第一条指令的结果。为了解决这个数据相关的问题，防止流水线暂停
        //结合reg1_forward_flag标志判断，执行数据前推
        end else if (reg1_exforward_flag_i == 1'b1) begin
            rdata1_o=ex_wdata_tem_i;
        //访存阶段的数据前递：次高优先级：第三条指令译码依赖于第一条指令的结果。为了解决这个数据相关的问题，防止流水线暂停
        end else if (reg1_memforward_flag_i == 1'b1) begin
            rdata1_o=mem_wdata_tem_i;       
        //如果读地址等于写地址，并且正在写操作，则直接将要写的值返回给读操作。
        end else if (raddr1_i == waddr_i && we_i == `WriteEnable) begin
            rdata1_o = wdata_i;
        end else begin  //如果没有数据相关，则返回要读的寄存器的值。
            rdata1_o = regs[raddr1_i];
        end
    end


    // 读寄存器2 读寄存器操作来自译码id模块，并且读出来的寄存器数据也会返回给译码模块。
	//assign rdata2_o = (raddr2_i == `ZeroReg) ? `ZeroWord : ((raddr2_i == waddr_i && we_i == `WriteEnable) ? wdata_i : regs[raddr2_i]); 
    always @ (*) begin
        if (raddr2_i == `ZeroReg) begin
            rdata2_o = `ZeroWord;
        //高优先级：第二条指令的译码依赖于第一条指令的结果。为了解决这个数据相关的问题，防止流水线暂停
        //结合reg1_forward_flag标志判断，执行数据前推
        end else if (reg2_exforward_flag_i == 1'b1) begin
            rdata2_o=ex_wdata_tem_i;      
        //访存阶段的数据前递：次高优先级：第三条指令译码依赖于第一条指令的结果。为了解决这个数据相关的问题，防止流水线暂停
        end else if (reg2_memforward_flag_i == 1'b1) begin
            rdata2_o=mem_wdata_tem_i;         
        //如果读地址等于写地址，并且正在写操作，则直接返回写数据
        end else if (raddr2_i == waddr_i && we_i == `WriteEnable) begin
            rdata2_o = wdata_i;
        end else begin
            rdata2_o = regs[raddr2_i];
        end
    end

    // jtag读寄存器
	//assign jtag_data_o = (jtag_addr_i == `ZeroReg) ? `ZeroWord : regs[jtag_addr_i]; 
    always @ (*) begin
        if (jtag_addr_i == `ZeroReg) begin
            jtag_data_o = `ZeroWord;
        end else begin
            jtag_data_o = regs[jtag_addr_i];
        end
  end

endmodule
