
//自写模块
`include "defines.v"
//执行部分中的ex_mem模块
//将需要访存和写回的内容向后传递,
//通过判断当前执行到执行阶段指令的写地址，和之后执行到译码阶段指令的读地址是否一致，修改数据前递标志

module ex_mem(


    input wire clk,
    input wire rst,

    input wire[2:0] hold_flag_i, // 流水线暂停标志 from ctrl 3位
/*
    // to mem
    input wire[31:0] mem_wdata_i,        // 写内存数据
    input wire[31:0] mem_raddr_i,    // 读内存地址
    input wire[31:0] mem_waddr_i,    // 写内存地址
    input wire mem_we_i,                   // 是否要写内存
    input wire mem_req_i,                  // 请求访问内存标志
    //
*/
    // to regs
    input wire[31:0] reg_wdata_i,       // 写寄存器数据
    input wire reg_we_i,                   // 是否要写通用寄存器
    input wire[4:0] reg_waddr_i,   // 写通用寄存器地址
    input wire[`RegAddrBus ]  id_reg1_raddr_i,         // 从id阶段传过来的读通用寄存器1地址
    input wire[`RegAddrBus ]  id_reg2_raddr_i,         // 从id阶段传过来的读通用寄存器2地址

    input wire jump_flag_i,
    input wire[31:0]jump_addr_i,


/*
    // to mem
    output wire[31:0] mem_wdata_o,        // 写内存数据
    output wire[31:0] mem_raddr_o,    // 读内存地址
    output wire[31:0] mem_waddr_o,    // 写内存地址
    output wire mem_we_o,                   // 是否要写内存
    output wire mem_req_o,                  // 请求访问内存标志
    //
*/
    // to regs
    output wire reg1_exforward_flag_o,
    output wire reg2_exforward_flag_o,

    output wire[31:0] reg_wdata_o,       // 写寄存器数据
    output wire reg_we_o,                   // 是否要写通用寄存器
    output wire[4:0] reg_waddr_o , // 写通用寄存器地址

    output wire jump_flag_o,
    output wire[31:0] jump_addr_o

    

/*
    input wire[7:0] int_flag_i,        // 外设（timer）中断输入信号  8位
    output wire[7:0] int_flag_o,  // 外设（timer）中断输出信号  8位

    input wire[31:0] inst_i,        // 指令内容   32位
    input wire[31:0] inst_addr_i,   // 指令地址   32位

    output wire[31:0] inst_o,           // 指令内容  32位
    output wire[31:0] inst_addr_o   // 指令地址  32位
*/
    /*写csr寄存器不必要打拍往后传
    // to csr 
    input wire[31:0] csr_wdata_i,        // 写CSR寄存器数据
    input wire csr_we_i,                   // 是否要写CSR寄存器
    input wire[31:0] csr_waddr_i,   // 写CSR寄存器地址

    // to div
    input wire div_start_o,                // 开始除法运算标志
    input wire[31:0] div_dividend_o,     // 被除数
    input wire[31:0] div_divisor_o,      // 除数
    input wire[2:0] div_op_o,               // 具体是哪一条除法指令
    input wire[4:0] div_reg_waddr_o,// 除法运算结束后要写的寄存器地址

    // to ctrl
    input wire hold_flag_o,                // 是否暂停标志
    input wire jump_flag_o,                // 是否跳转标志
    input wire[31:0] jump_addr_o   // 跳转目的地址
   */

    );
    reg reg1_exforward_flag;
    reg reg2_exforward_flag;


    wire hold_en = (hold_flag_i >= `Hold_Id); //Hold_Id   3'b011
    //处理RAW数据相关，间隔1条指令，如果译码阶段需要读取的数据在执行阶段已有结果，则将执行阶段数据前推标志置为1。
    always @ (*) begin
        if(reg_waddr_i == id_reg1_raddr_i) begin
            reg1_exforward_flag=1'b1;
        end else begin
            reg1_exforward_flag=1'b0;
        end

        if(reg_waddr_i == id_reg2_raddr_i) begin
            reg2_exforward_flag=1'b1;
        end else begin
            reg2_exforward_flag=1'b0;
        end
    end
    assign reg1_exforward_flag_o=reg1_exforward_flag;
    assign reg2_exforward_flag_o=reg2_exforward_flag;


    //`define INST_NOP    32'h00000001
    //例化 gen_pipe_dff 模块  如果没有复位或者暂停流水线，则输入内容被打一拍传递到执行模块
    /*
    wire[31:0] mem_wdata;        // 写内存数据
    gen_pipe_dff #(32) mem_wdata1_ff(clk, rst, hold_en, 32'h0, mem_wdata_i, mem_wdata);
    assign mem_wdata_o = mem_wdata;

    wire[31:0] mem_raddr;    // 读内存地址
    gen_pipe_dff #(32) mem_raddr1_ff(clk, rst, hold_en, 32'h0, mem_raddr_i, mem_raddr);
    assign mem_raddr_o = mem_raddr;

    wire[31:0] mem_waddr;    // 写内存地址
    gen_pipe_dff #(32) mem_waddr1_ff(clk, rst, hold_en, 32'h0, mem_waddr_i, mem_waddr);
    assign mem_waddr_o = mem_waddr;

    wire mem_we;                   // 是否要写内存
    gen_pipe_dff #(1) mem_we1_ff(clk, rst, hold_en, 1'b0, mem_we_i, mem_we);
    assign mem_we_o = mem_we;

    wire mem_req;                // 请求访问内存标志
    gen_pipe_dff #(1) mem_req1_ff(clk, rst, hold_en, 1'b0, mem_req_i, mem_req);
    assign mem_req_o = mem_req;
*/
    wire[31:0] reg_wdata;       // 写寄存器数据
    gen_pipe_dff #(32) reg_wdata1_ff(clk, rst, hold_en, 32'h0 ,reg_wdata_i, reg_wdata);
    assign reg_wdata_o = reg_wdata;

    wire reg_we;                  // 是否要写通用寄存器
    gen_pipe_dff #(1) reg_we1_ff(clk, rst, hold_en, 1'b0, reg_we_i, reg_we);
    assign reg_we_o = reg_we;

    wire[4:0] reg_waddr;  // 写通用寄存器地址
    gen_pipe_dff #(5) csr_waddr1_ff(clk, rst, hold_en, 5'b0, reg_waddr_i, reg_waddr);
    assign reg_waddr_o = reg_waddr;

    wire jump_flag;  // 跳转标志
    gen_pipe_dff #(1) jump_flag1_ff(clk, rst, hold_en, 1'b0, jump_flag_i, jump_flag);
    assign jump_flag_o=jump_flag;

    wire[31:0] jump_addr;  // 跳转地址
    gen_pipe_dff #(32) jump_addr1_ff(clk, rst, hold_en, 32'b0, jump_addr_i, jump_addr);
    assign jump_addr_o = jump_addr;

endmodule