
`include "defines.v"

// 将指令向译码模块传递
// if_id：取指到译码之间的模块，用于将指令存储器输出的指令打一拍后送到译码模块。
module if_id(

    input wire clk,
    input wire rst,

    input wire[`InstBus] inst_i,            // 指令内容   32位
    input wire[`InstAddrBus] inst_addr_i,   // 指令地址   32位

    input wire[`Hold_Flag_Bus] hold_flag_i, // 流水线暂停标志 from ctrl 3位

    input wire[`INT_BUS] int_flag_i,        // 外设（timer）中断输入信号  8位
    output wire[`INT_BUS] int_flag_o,

    output wire[`InstBus] inst_o,           // 指令内容  32位
    output wire[`InstAddrBus] inst_addr_o   // 指令地址  32位

    );

    wire hold_en = (hold_flag_i >= `Hold_If);  //Hold_If  3'b010

    wire[`InstBus] inst;   //32位
    //`define INST_NOP    32'h00000001
    //例化 gen_pipe_dff 模块  如果没有复位或者暂停流水线，则指令内容inst_i被打一拍。
    gen_pipe_dff #(32) inst_ff(clk, rst, hold_en, `INST_NOP, inst_i, inst);
    assign inst_o = inst;

    wire[`InstAddrBus] inst_addr;  //32位
    //`define ZeroWord 32'h0
    //例化 gen_pipe_dff 模块  如果没有复位或者暂停流水线，则指令地址inst_addr_i被打一拍。
    gen_pipe_dff #(32) inst_addr_ff(clk, rst, hold_en, `ZeroWord, inst_addr_i, inst_addr);
    assign inst_addr_o = inst_addr;

    wire[`INT_BUS] int_flag;  //8位
    //`define INT_NONE 8'h0
    //例化 gen_pipe_dff 模块  如果没有复位或者暂停流水线，则外设（timer）中断输入信号int_flag_i被打一拍。
    gen_pipe_dff #(8) int_ff(clk, rst, hold_en, `INT_NONE, int_flag_i, int_flag);
    assign int_flag_o = int_flag;

endmodule
