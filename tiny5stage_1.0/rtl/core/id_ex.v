`include "defines.v"

// 将译码结果向执行模块传递
module id_ex(

    input wire clk,
    input wire rst,

    input wire[`InstBus] inst_i,            // 指令内容
    input wire[`InstAddrBus] inst_addr_i,   // 指令地址
    input wire reg_we_i,                    // 写通用寄存器标志
    input wire[`RegAddrBus] reg_waddr_i,    // 写通用寄存器地址
    input wire[31:0] reg1_rdata_i,       // 通用寄存器1读数据
    input wire[31:0] reg2_rdata_i,       // 通用寄存器2读数据
    input wire csr_we_i,                    // 写CSR寄存器标志
    input wire[`MemAddrBus] csr_waddr_i,    // 写CSR寄存器地址
    input wire[31:0] csr_rdata_i,        // CSR寄存器读数据
    input wire[`MemAddrBus] op1_i,
    input wire[`MemAddrBus] op2_i,
    input wire[`MemAddrBus] op1_jump_i,
    input wire[`MemAddrBus] op2_jump_i,

    input wire[`Hold_Flag_Bus] hold_flag_i, // 流水线暂停标志
    input wire[`Hold_Flag_Bus] hold_jump_idex2_i,//针对id阶段暂停标志


    output wire[`MemAddrBus] op1_o,
    output wire[`MemAddrBus] op2_o,
    output wire[`MemAddrBus] op1_jump_o,
    output wire[`MemAddrBus] op2_jump_o,
    output wire[`InstBus] inst_o,            // 指令内容
    output wire[`InstAddrBus] inst_addr_o,   // 指令地址
    output wire reg_we_o,                    // 写通用寄存器标志
    output wire[`RegAddrBus] reg_waddr_o,    // 写通用寄存器地址
    output wire[31:0] reg1_rdata_o,       // 通用寄存器1读数据
    output wire[31:0] reg2_rdata_o,       // 通用寄存器2读数据
    output wire csr_we_o,                    // 写CSR寄存器标志
    output wire[`MemAddrBus] csr_waddr_o,    // 写CSR寄存器地址
    output wire[31:0] csr_rdata_o,         // CSR寄存器读数据


    input wire rmem_data1_flag_i,
    input wire rmem_data2_flag_i,

    output wire rmem_data1_flag_o,
    output wire rmem_data2_flag_o

    );

    reg[2:0] hold_jump_idex2_reg ;
    reg hold_en;

    always @(negedge clk) begin
        if(hold_jump_idex2_i == 2'b11) begin
            hold_jump_idex2_reg = hold_jump_idex2_i;
        end
        if(hold_jump_idex2_reg[0] == 1'b1) begin
            hold_en = 1'b1;
            hold_jump_idex2_reg[0] = ~hold_jump_idex2_reg[0];
        end else if(hold_jump_idex2_reg[1] == 1'b1) begin
            hold_en = 1'b1;
            hold_jump_idex2_reg[1] = ~hold_jump_idex2_reg[1];
        end else begin
            hold_en = (hold_flag_i >= `Hold_Id); //Hold_Id   3'b011
        end
    end
/*
        always @(negedge clk) begin

        

        
    end

*/



    //传递数据打拍

    wire rmem_data1_flag; 
    //rmem_data1_flag
    gen_pipe_dff #(1) rmem_data1_flag_1ff(clk, rst, hold_en, 1'b0, rmem_data1_flag_i, rmem_data1_flag);
    assign rmem_data1_flag_o = rmem_data1_flag;


    wire rmem_data2_flag; 
    //rmem_data1_flag
    gen_pipe_dff #(1) rmem_data2_flag_1ff(clk, rst, hold_en, 1'b0, rmem_data2_flag_i, rmem_data2_flag);
    assign rmem_data2_flag_o = rmem_data2_flag;





    wire[`InstBus] inst; //32位
    gen_pipe_dff #(32) inst_ff(clk, rst, hold_en, `INST_NOP, inst_i, inst);
    assign inst_o = inst;

    wire[`InstAddrBus] inst_addr;
    gen_pipe_dff #(32) inst_addr_ff(clk, rst, hold_en, `ZeroWord, inst_addr_i, inst_addr);
    assign inst_addr_o = inst_addr;

    wire reg_we;
    gen_pipe_dff #(1) reg_we_ff(clk, rst, hold_en, `WriteDisable, reg_we_i, reg_we);
    assign reg_we_o = reg_we;

    wire[`RegAddrBus] reg_waddr;
    gen_pipe_dff #(5) reg_waddr_ff(clk, rst, hold_en, `ZeroReg, reg_waddr_i, reg_waddr);
    assign reg_waddr_o = reg_waddr;

    wire[31:0] reg1_rdata;
    gen_pipe_dff #(32) reg1_rdata_ff(clk, rst, hold_en, `ZeroWord, reg1_rdata_i, reg1_rdata);
    assign reg1_rdata_o = reg1_rdata;

    wire[31:0] reg2_rdata;
    gen_pipe_dff #(32) reg2_rdata_ff(clk, rst, hold_en, `ZeroWord, reg2_rdata_i, reg2_rdata);
    assign reg2_rdata_o = reg2_rdata;

    wire csr_we;
    gen_pipe_dff #(1) csr_we_ff(clk, rst, hold_en, `WriteDisable, csr_we_i, csr_we);
    assign csr_we_o = csr_we;

    wire[`MemAddrBus] csr_waddr;
    gen_pipe_dff #(32) csr_waddr_ff(clk, rst, hold_en, `ZeroWord, csr_waddr_i, csr_waddr);
    assign csr_waddr_o = csr_waddr;

    wire[31:0] csr_rdata;
    gen_pipe_dff #(32) csr_rdata_ff(clk, rst, hold_en, `ZeroWord, csr_rdata_i, csr_rdata);
    assign csr_rdata_o = csr_rdata;

    wire[`MemAddrBus] op1;
    gen_pipe_dff #(32) op1_ff(clk, rst, hold_en, `ZeroWord, op1_i, op1);
    assign op1_o = op1;

    wire[`MemAddrBus] op2;
    gen_pipe_dff #(32) op2_ff(clk, rst, hold_en, `ZeroWord, op2_i, op2);
    assign op2_o = op2;

    wire[`MemAddrBus] op1_jump;
    gen_pipe_dff #(32) op1_jump_ff(clk, rst, hold_en, `ZeroWord, op1_jump_i, op1_jump);
    assign op1_jump_o = op1_jump;

    wire[`MemAddrBus] op2_jump;
    gen_pipe_dff #(32) op2_jump_ff(clk, rst, hold_en, `ZeroWord, op2_jump_i, op2_jump);
    assign op2_jump_o = op2_jump;

endmodule
