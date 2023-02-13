
//访存部分中的mem模块
//mem模块用于处理访存的指令
module mem(


    input wire jump_flag_i,
    input wire[31:0]jump_addr_i,

/*
    // 至内存
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

    //以上输入，以下输出

    /*
    output reg[31:0] mem_wdata_o,        // 写内存数据
    output reg[31:0] mem_raddr_o,    // 读内存地址
    output reg[31:0] mem_waddr_o,    // 写内存地址
    output wire mem_we_o,                   // 是否要写内存
    output wire mem_req_o,                  // 请求访问内存标志
    //
    */
    // to regs
    output wire[31:0] reg_wdata_o,       // 写寄存器数据
    output wire reg_we_o,                   // 是否要写通用寄存器
    output wire[4:0] reg_waddr_o,   // 写通用寄存器地址


    output wire jump_flag_o,
    output wire[31:0] jump_addr_o

    );

    /*reg men_we;
    reg mem_req;
    reg reg_wdata;
    reg reg_we;
    reg reg_waddr;

    assign mem_we_o=mem_we_i;                   // 是否要写内存
    assign mem_req_o=mem_req_i;                 // 请求访问内存标志
*/


    assign reg_wdata_o=reg_wdata_i;      // 写寄存器数据
    assign reg_we_o=reg_we_i;                   // 是否要写通用寄存器
    assign reg_waddr_o=reg_waddr_i ; // 写通用寄存器地址
    assign jump_flag_o=jump_flag_i;
    assign jump_addr_o=jump_addr_i;
/*

always @ (*) begin
    mem_wdata_o=mem_wdata_i;       // 写内存数据
    mem_raddr_o=mem_raddr_i;    // 读内存地址
    mem_waddr_o=mem_waddr_i;    // 写内存地址

  

end

 */ 


endmodule
