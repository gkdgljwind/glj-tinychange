

`include "defines.v"

// PC(program counter程序计数器)寄存器模块  
//用于产生PC寄存器的值，该值会被用作指令存储器的地址信号。
module pc_reg(

    input wire clk,
    input wire rst,

    input wire jump_flag_i,                 // 跳转标志
    input wire[`InstAddrBus] jump_addr_i,   // 跳转地址`define InstAddrBus 31:0
    input wire[`Hold_Flag_Bus] hold_flag_i, // 流水线暂停标志 `define Hold_Flag_Bus   2:0
    input wire jtag_reset_flag_i,           // 复位标志

    output reg[`InstAddrBus] pc_o           // PC指针 32位

    );

    always @ (posedge clk) begin
        // 复位   `define RstEnable 1'b0
        if (rst == `RstEnable || jtag_reset_flag_i == 1'b1) begin
            pc_o <= 32'h0; //`define CpuResetAddr 32'h0
        // 跳转   `define JumpEnable 1'b1
        end else if (jump_flag_i == `JumpEnable) begin
            pc_o <= jump_addr_i;
        // 暂停  `define Hold_Pc   3'b001
        end else if (hold_flag_i >= `Hold_Pc) begin
            pc_o <= pc_o;
        // 地址加4
        end else begin
            pc_o <= pc_o + 4'h4; //tinyriscv的取指地址是4字节对齐的，每条指令都是32位的。
        end
    end

endmodule

