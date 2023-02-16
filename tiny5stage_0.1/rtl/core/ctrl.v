
`include "defines.v"

// 控制模块
// 发出跳转、暂停流水线信号
module ctrl(

    input wire rst,

    // from ex
    input wire jump_flag_i, //跳转标志
    input wire[`InstAddrBus] jump_addr_i,
    input wire hold_flag_ex_i,  //暂停标志

    // from rib
    input wire hold_flag_rib_i,

    // from jtag
    input wire jtag_halt_flag_i,

    // from clint
    input wire hold_flag_clint_i,

    output reg[`Hold_Flag_Bus] hold_flag_o,
    output reg[2:0] hold_time_o,
    // to pc_reg
    output reg jump_flag_o,
    output reg[`InstAddrBus] jump_addr_o
	
    );
/*
`define Hold_None 3'b000
`define Hold_Pc   3'b001
`define Hold_If   3'b010
`define Hold_Id   3'b011
*/
    always @ (*) begin
        jump_addr_o = jump_addr_i;
        jump_flag_o = jump_flag_i;
        // 默认不暂停
        hold_flag_o = `Hold_None;
        hold_time_o=`Hold_None;
        // 按优先级处理不同模块的请求
        if (jump_flag_i == `JumpEnable || hold_flag_ex_i == `HoldEnable || hold_flag_clint_i == `HoldEnable) begin
            // 对于跳转操作、来自执行阶段的暂停、来自中断模块的暂停则暂停pc和id阶段，前两条指令的访存和写回，继续执行
            hold_flag_o =`Hold_Pc;
            hold_time_o=3'b111;

        end else if (hold_flag_rib_i == `HoldEnable) begin
            // 对于总线暂停，只需要暂停PC寄存器，让译码和执行阶段继续运行。
            hold_flag_o = `Hold_Pc;
        end else if (jtag_halt_flag_i == `HoldEnable) begin
            // 对于jtag模块暂停，则暂停整条流水线。
            hold_flag_o = `Hold_Id;
        end else begin
            hold_flag_o = `Hold_None;
        end
    end

endmodule
