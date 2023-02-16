
//写回部分中的wb模块
//wb模块用于处理指令的写回部分，回写到寄存器

module wb(



    // to regs
    input wire[31:0] reg_wdata_i,       // 写寄存器数据
    input wire reg_we_i,                   // 是否要写通用寄存器
    input wire[4:0] reg_waddr_i,   // 写通用寄存器地址


    // to regs
    output wire[31:0] reg_wdata_o,       // 写寄存器数据
    output wire reg_we_o,                   // 是否要写通用寄存器
    output wire[4:0] reg_waddr_o   // 写通用寄存器地址



    );


    assign reg_wdata_o=reg_wdata_i;      // 写寄存器数据
    assign reg_we_o=reg_we_i;                   // 是否要写通用寄存器
    assign reg_waddr_o=reg_waddr_i ; // 写通用寄存器地址



endmodule
