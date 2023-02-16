
//自写模块
`include "defines.v"
//执行部分中的ex_mem模块
//将需要访存和写回的内容向后传递,
//通过判断当前执行到执行阶段指令的写地址，和之后执行到译码阶段指令的读地址是否一致，修改数据前递标志

module ex_mem(


    input wire clk,
    input wire rst,

    input wire[2:0] hold_flag_i, // 流水线暂停标志 from ctrl 3位
    input wire[2:0] hold_time_i,



    //内存处理需要的指令
    input wire[31:0] inst_i,
    input wire[31:0] op1_add_op2_res_i,
    input wire[31:0] reg1_rdata_i,
    input wire[31:0] reg2_rdata_i,

    output wire[31:0] inst_o,
    output wire[31:0] op1_add_op2_res_o,
    output wire[31:0] reg1_rdata_o,
    output wire[31:0] reg2_rdata_o,
    // 寄存器有关数据
    input wire[31:0] reg_wdata_i,       // 写寄存器数据
    input wire reg_we_i,                   // 是否要写通用寄存器
    input wire[4:0] reg_waddr_i,   // 写通用寄存器地址

    output wire[31:0] reg_wdata_o,       // 写寄存器数据
    output wire reg_we_o,                   // 是否要写通用寄存器
    output wire[4:0] reg_waddr_o , // 写通用寄存器地址

    //跳转有关数据


    //数据前递相关数据
    input wire[`RegAddrBus ]  id_reg1_raddr_i,         // 从id阶段传过来的读通用寄存器1地址
    input wire[`RegAddrBus ]  id_reg2_raddr_i,         // 从id阶段传过来的读通用寄存器2地址
    input wire ex_req_flag_i,//访问内存标志


    output wire[1:0] reg1_exforward_flag_o,             //3种情况，数据直接前递，等待一个指令周期再前递
    output wire[1:0] reg2_exforward_flag_o




    );
    reg[1:0] reg1_exforward_flag;
    reg[1:0] reg2_exforward_flag;


  wire hold_en = (hold_flag_i >= `Hold_Id); //Hold_Id   3'b011
/*
    reg[2:0] hold_time_reg ;
    reg hold_en;

    always @(posedge clk) begin
        if(hold_time_i == 3'b111) begin
            hold_time_reg = hold_time_i;
        end

    end

        always @(negedge clk) begin

        if(hold_time_reg[0] == 1'b1) begin
            hold_en = 1'b1;
            hold_time_reg[0] = ~hold_time_reg[0];
        end else if(hold_time_reg[1] == 1'b1) begin
            hold_en = 1'b1;
            hold_time_reg[1] = ~hold_time_reg[1];
        end else if(hold_time_reg[2] == 1'b1) begin
            hold_en = 1'b1;
            hold_time_reg[2] = ~hold_time_reg[2];
        end else begin
            hold_en = (hold_flag_i >= `Hold_Id); //Hold_Id   3'b011
        end

        
    end
*/
 
    //处理RAW数据相关，间隔1条指令，如果译码阶段需要读取的数据在执行阶段已有结果，则将执行阶段数据前推标志置为1。
    always @ (*) begin
        if(reg_waddr_i == id_reg1_raddr_i && ex_req_flag_i == 1'b0) begin
            reg1_exforward_flag=2'b11;
        end else if (reg_waddr_i == id_reg1_raddr_i && ex_req_flag_i == 1'b1) begin
            reg1_exforward_flag=2'b01;
        end else begin
            reg1_exforward_flag=2'b00;
        end

        if(reg_waddr_i == id_reg2_raddr_i && ex_req_flag_i == 1'b0) begin
            reg2_exforward_flag=2'b11;
        end else if (reg_waddr_i == id_reg2_raddr_i && ex_req_flag_i == 1'b1) begin
            reg2_exforward_flag=2'b01;
        end else begin
            reg2_exforward_flag=2'b00;
        end
    end

    assign reg1_exforward_flag_o=reg1_exforward_flag;
    assign reg2_exforward_flag_o=reg2_exforward_flag;


    //reg1_rdata
    wire[31:0] reg1_rdata;       
    gen_pipe_dff #(32) reg1_rdata1_ff(clk, rst, hold_en, 32'h0 ,reg1_rdata_i, reg1_rdata);
    assign reg1_rdata_o = reg1_rdata;

   //reg2_rdata
    wire[31:0] reg2_rdata;       
    gen_pipe_dff #(32) reg2_rdata1_ff(clk, rst, hold_en, 32'h0 ,reg2_rdata_i, reg2_rdata);
    assign reg2_rdata_o = reg2_rdata;

    //op1_add_op2_res
    wire[31:0] op1_add_op2_res;       
    gen_pipe_dff #(32) op1_add_op2_res1_ff(clk, rst, hold_en, 32'h0 ,op1_add_op2_res_i, op1_add_op2_res);
    assign op1_add_op2_res_o = op1_add_op2_res;


    //指令
    wire[31:0] inst;       
    gen_pipe_dff #(32) inst3_ff(clk, rst, hold_en, 32'h0 ,inst_i, inst);
    assign inst_o = inst;

    //寄存器相关数据
    wire[31:0] reg_wdata;       // 写寄存器数据
    gen_pipe_dff #(32) reg_wdata1_ff(clk, rst, hold_en, 32'h0 ,reg_wdata_i, reg_wdata);
    assign reg_wdata_o = reg_wdata;

    wire reg_we;                  // 是否要写通用寄存器
    gen_pipe_dff #(1) reg_we1_ff(clk, rst, hold_en, 1'b0, reg_we_i, reg_we);
    assign reg_we_o = reg_we;

    wire[4:0] reg_waddr;  // 写通用寄存器地址
    gen_pipe_dff #(5) csr_waddr1_ff(clk, rst, hold_en, 5'b0, reg_waddr_i, reg_waddr);
    assign reg_waddr_o = reg_waddr;


endmodule