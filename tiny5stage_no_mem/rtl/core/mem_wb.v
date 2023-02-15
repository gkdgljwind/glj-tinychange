
//自写模块
`include "defines.v"
//访存部分中的mem_wb模块
// 将需要写回的内容向后传递

module mem_wb(


    input wire clk,
    input wire rst,

    input wire[2:0] hold_flag_i, // 流水线暂停标志 from ctrl 3位

    // from ex_mem
    input wire[31:0] reg_wdata_i,       // 写寄存器数据
    input wire reg_we_i,                   // 是否要写通用寄存器
    input wire[4:0] reg_waddr_i,   // 写通用寄存器地址

    input wire jump_flag_i,
    input wire[31:0]jump_addr_i,


    //from id
    input wire[`RegAddrBus ]  id_reg1_raddr_i,         // 从id阶段传过来的读通用寄存器1地址
    input wire[`RegAddrBus ]  id_reg2_raddr_i,         // 从id阶段传过来的读通用寄存器2地址

    // to wb

    output wire[31:0] reg_wdata_o,       // 写寄存器数据
    output wire reg_we_o,                   // 是否要写通用寄存器
    output wire[4:0] reg_waddr_o , // 写通用寄存器地址

    output wire jump_flag_o,
    output wire[31:0] jump_addr_o,

    // to regs
    output wire reg1_memforward_flag_o,
    output wire reg2_memforward_flag_o



    );

    wire hold_en = (hold_flag_i >= `Hold_Id); //Hold_Id   3'b011

    reg reg1_memforward_flag;
    reg reg2_memforward_flag;


    //处理RAW数据相关，间隔2条指令，如果译码阶段需要读取的数据在执行阶段已有结果，则将访存阶段数据前递标志置为1。
    always @ (*) begin
        if(reg_waddr_i == id_reg1_raddr_i) begin
            reg1_memforward_flag=1'b1;
        end else begin
            reg1_memforward_flag=1'b0;
        end

        if(reg_waddr_i == id_reg2_raddr_i) begin
            reg2_memforward_flag=1'b1;
        end else begin
            reg2_memforward_flag=1'b0;
        end
    end
    assign reg1_memforward_flag_o=reg1_memforward_flag;
    assign reg2_memforward_flag_o=reg2_memforward_flag;










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
    gen_pipe_dff #(32) reg_wdata2_ff(clk, rst, hold_en, 32'h0 ,reg_wdata_i, reg_wdata);
    assign reg_wdata_o = reg_wdata;

    wire reg_we;                  // 是否要写通用寄存器
    gen_pipe_dff #(1) reg_we2_ff(clk, rst, hold_en, 1'b0, reg_we_i, reg_we);
    assign reg_we_o = reg_we;

    wire[4:0] reg_waddr;  // 写通用寄存器地址
    gen_pipe_dff #(5) csr_waddr2_ff(clk, rst, hold_en, 5'b0, reg_waddr_i, reg_waddr);
    assign reg_waddr_o = reg_waddr;

    wire jump_flag;  // 跳转标志
    gen_pipe_dff #(1) jump_flag2_ff(clk, rst, hold_en, 1'b0, jump_flag_i, jump_flag);
    assign jump_flag_o=jump_flag;

    wire[31:0] jump_addr;  // 跳转地址
    gen_pipe_dff #(32) jump_addr2_ff(clk, rst, hold_en, 32'b0, jump_addr_i, jump_addr);
    assign jump_addr_o = jump_addr;

endmodule