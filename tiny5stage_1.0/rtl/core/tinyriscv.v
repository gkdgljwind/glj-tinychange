//修改接口架构
`include "defines.v"
`include "ex_mem.v"
`include "mem.v"
`include "mem_wb.v"
`include "wb.v"
// tinyriscv处理器核顶层模块
module tinyriscv(

    input wire clk,
    input wire rst,

    output wire[`MemAddrBus] rib_ex_addr_o,    // 读、写外设的地址
    input wire[`MemBus] rib_ex_data_i,         // 从外设读取的数据
    output wire[`MemBus] rib_ex_data_o,        // 写入外设的数据
    output wire rib_ex_req_o,                  // 访问外设请求
    output wire rib_ex_we_o,                   // 写外设标志

    output wire[`MemAddrBus] rib_pc_addr_o,    // 取指地址
    input wire[`MemBus] rib_pc_data_i,         // 取到的指令内容

    input wire[`RegAddrBus] jtag_reg_addr_i,   // jtag模块读、写寄存器的地址
    input wire[31:0] jtag_reg_data_i,       // jtag模块写寄存器数据
    input wire jtag_reg_we_i,                  // jtag模块写寄存器标志
    output wire[31:0] jtag_reg_data_o,      // jtag模块读取到的寄存器数据

    input wire rib_hold_flag_i,                // 总线暂停标志
    input wire jtag_halt_flag_i,               // jtag暂停标志
    input wire jtag_reset_flag_i,              // jtag复位PC标志

    input wire[`INT_BUS] int_i                 // 中断信号

    // output wire regs_26,
    // output wire regs_27
    );

    // pc_reg模块输出信号------------------------------
	wire[`InstAddrBus] pc_pc_o;

    // if_id模块输出信号------------------------------
	wire[`InstBus] if_inst_o;
    wire[`InstAddrBus] if_inst_addr_o;
    wire[`INT_BUS] if_int_flag_o;

    // id模块输出信号------------------------------
    wire[`RegAddrBus] id_reg1_raddr_o;
    wire[`RegAddrBus] id_reg2_raddr_o;
    wire[`InstBus] id_inst_o;
    wire[`InstAddrBus] id_inst_addr_o;
    wire[31:0] id_reg1_rdata_o;
    wire[31:0] id_reg2_rdata_o;
    wire id_reg_we_o;
    wire[`RegAddrBus] id_reg_waddr_o;
    wire[`MemAddrBus] id_csr_raddr_o;
    wire id_csr_we_o;
    wire[31:0] id_csr_rdata_o;
    wire[`MemAddrBus] id_csr_waddr_o;
    wire[`MemAddrBus] id_op1_o;
    wire[`MemAddrBus] id_op2_o;
    wire[`MemAddrBus] id_op1_jump_o;
    wire[`MemAddrBus] id_op2_jump_o;

    // id_ex模块输出信号------------------------------
    wire[`InstBus] ie_inst_o;
    wire[`InstAddrBus] ie_inst_addr_o;
    wire ie_reg_we_o;
    wire[`RegAddrBus] ie_reg_waddr_o;
    wire[31:0] ie_reg1_rdata_o;
    wire[31:0] ie_reg2_rdata_o;
    wire ie_csr_we_o;
    wire[`MemAddrBus] ie_csr_waddr_o;
    wire[31:0] ie_csr_rdata_o;
    wire[`MemAddrBus] ie_op1_o;
    wire[`MemAddrBus] ie_op2_o;
    wire[`MemAddrBus] ie_op1_jump_o;
    wire[`MemAddrBus] ie_op2_jump_o;


    wire id_ex_rmem_data1_flag;
    wire id_ex_rmem_data2_flag;


    // ex模块输出信号------------------------------
    wire[31:0] ex_inst_o;
    wire[31:0] ex_op1_add_op2_res_o;
    wire[31:0] ex_reg1_rdata_o;
    wire[31:0] ex_reg2_rdata_o;

    wire[31:0] ex_reg_wdata_o;
    wire ex_reg_we_o;
    wire[`RegAddrBus] ex_reg_waddr_o;

    wire ex_hold_flag_o;

    wire ex_jump_flag_o;
    wire[`InstAddrBus] ex_jump_addr_o;

    wire ex_div_start_o;
    wire[31:0] ex_div_dividend_o;
    wire[31:0] ex_div_divisor_o;
    wire[2:0] ex_div_op_o;
    wire[`RegAddrBus] ex_div_reg_waddr_o;
    wire[31:0] ex_csr_wdata_o;
    wire ex_csr_we_o;
    wire[`MemAddrBus] ex_csr_waddr_o;

    wire ex_req_flag_o;

    //ex_mem模块输出信号------------------------------
    wire[1:0] reg1_exforward_flag;
    wire[1:0] reg2_exforward_flag;
    
    //往后传的
    wire[31:0] ex_mem_reg_wdata_o;
    wire ex_mem_reg_we_o;
    wire[`RegAddrBus] ex_mem_reg_waddr_o;
    wire ex_mem_jump_flag_o;
    wire[`InstAddrBus] ex_mem_jump_addr_o;

    wire[`MemBus] ex_mem_me_wdata_o;
    wire[`MemAddrBus] ex_mem_me_raddr_o;
    wire[`MemAddrBus] ex_mem_me_waddr_o;
    wire ex_mem_me_we_o;
    wire ex_mem_me_req_o;

    wire[31:0] ex_mem_inst_o;
    wire[31:0] ex_mem_op1_add_op2_res_o;
    wire[31:0] ex_mem_reg1_rdata_o;
    wire[31:0] ex_mem_reg2_rdata_o;
    //mem模块输出信号------------------------------
    wire[`MemBus] mem_me_wdata_o;
    wire[`MemAddrBus] mem_me_raddr_o;
    wire[`MemAddrBus] mem_me_waddr_o;
    wire mem_me_we_flag_o;
    wire mem_me_req_flag_o;
    wire[31:0] mem_reg_wdata_o;


    //mem_wb模块输出信号------------------------------
    wire reg1_memforward_flag;
    wire reg2_memforward_flag;
    //往后传的
    wire[31:0] mem_wb_reg_wdata_o;
    wire mem_wb_reg_we_o;
    wire[`RegAddrBus] mem_wb_reg_waddr_o;

    wire mem_wb_jump_flag_o;
    wire[`InstAddrBus] mem_wb_jump_addr_o;




    //wb模块输出信号------------------------------
    wire[31:0] wb_reg_wdata_o;
    wire wb_reg_we_o;
    wire[`RegAddrBus] wb_reg_waddr_o;




    // regs模块输出信号------------------------------
    wire[31:0] regs_rdata1_o;
    wire[31:0] regs_rdata2_o;

    wire rmem_data1_flag;
    wire rmem_data2_flag;


    // csr_reg模块输出信号------------------------------
    wire[31:0] csr_data_o;
    wire[31:0] csr_clint_data_o;
    wire csr_global_int_en_o;
    wire[31:0] csr_clint_csr_mtvec;
    wire[31:0] csr_clint_csr_mepc;
    wire[31:0] csr_clint_csr_mstatus;

    // ctrl模块输出信号------------------------------
    wire[`Hold_Flag_Bus] ctrl_hold_flag_o;
    wire[`Hold_Flag_Bus] ctrl_hold_jump_idex2_o;

    wire ctrl_jump_flag_o;
    wire[`InstAddrBus] ctrl_jump_addr_o;

    // div模块输出信号------------------------------
    wire[31:0] div_result_o;
	wire div_ready_o;
    wire div_busy_o;
    wire[`RegAddrBus] div_reg_waddr_o;

    // clint模块输出信号------------------------------
    wire clint_we_o;
    wire[`MemAddrBus] clint_waddr_o;
    wire[`MemAddrBus] clint_raddr_o;
    wire[31:0] clint_data_o;
    wire[`InstAddrBus] clint_int_addr_o;
    wire clint_int_assert_o;
    wire clint_hold_flag_o;



    //------------------------------

    assign rib_ex_addr_o = (mem_me_we_flag_o == `WriteEnable)? mem_me_waddr_o: mem_me_raddr_o;
    assign rib_ex_data_o = mem_me_wdata_o;
    assign rib_ex_req_o = (mem_me_req_flag_o|ex_req_flag_o);
    assign rib_ex_we_o = mem_me_we_flag_o;

    assign rib_pc_addr_o = pc_pc_o;


    // pc_reg模块例化
    pc_reg u_pc_reg(
        .clk(clk),
        .rst(rst),
        .jtag_reset_flag_i(jtag_reset_flag_i),
        .pc_o(pc_pc_o),
        .hold_flag_i(ctrl_hold_flag_o),
        .jump_flag_i(ctrl_jump_flag_o),
        .jump_addr_i(ctrl_jump_addr_o)
    );

    // ctrl模块例化
    ctrl u_ctrl(
        .rst(rst),
        .jump_flag_i(ex_jump_flag_o),
        .jump_addr_i(ex_jump_addr_o),

        .hold_flag_ex_i(ex_hold_flag_o),
        .hold_flag_rib_i(rib_hold_flag_i),
        
        .jtag_halt_flag_i(jtag_halt_flag_i),
        //.reg1_exforward_flag_i(reg1_exforward_flag),
        //.reg2_exforward_flag_i(reg2_exforward_flag),

        .hold_flag_o(ctrl_hold_flag_o),
        .hold_jump_idex2_o(ctrl_hold_jump_idex2_o),
        .hold_flag_clint_i(clint_hold_flag_o),
        .jump_flag_o(ctrl_jump_flag_o),
        .jump_addr_o(ctrl_jump_addr_o)
        
    );

    
    // regs模块例化
    //wire regs_26;
    //wire regs_27;
    regs u_regs(
        .clk(clk),
        .rst(rst),
        .we_i(wb_reg_we_o ),
        .waddr_i(wb_reg_waddr_o),
        .wdata_i(wb_reg_wdata_o),
        .raddr1_i(id_reg1_raddr_o),
        .rdata1_o(regs_rdata1_o),
        .raddr2_i(id_reg2_raddr_o),
        .rdata2_o(regs_rdata2_o),
        .jtag_we_i(jtag_reg_we_i),
        .jtag_addr_i(jtag_reg_addr_i),
        .jtag_data_i(jtag_reg_data_i),
        
        .jtag_data_o(jtag_reg_data_o),

        .reg1_exforward_flag_i(reg1_exforward_flag),
        .reg2_exforward_flag_i(reg2_exforward_flag),
        .reg1_memforward_flag_i(reg1_memforward_flag),
        .reg2_memforward_flag_i(reg2_memforward_flag),

        .ex_wdata_tem_i(ex_reg_wdata_o),       //执行暂存数据
        .mem_wdata_tem_i(ex_mem_reg_wdata_o),    //访存暂存数据

        .rmem_data1_flag_o(rmem_data1_flag),     //执行阶段取访存时数据标志
        .rmem_data2_flag_o(rmem_data2_flag)


        // .regs_26(regs_26),
        // .regs_27(regs_27)
    );



    // if_id模块例化
    if_id u_if_id(
        .clk(clk),
        .rst(rst),
        .inst_i(rib_pc_data_i),
        .inst_addr_i(pc_pc_o),
        .int_flag_i(int_i),  //int_i 定时器timer中断输入
        .int_flag_o(if_int_flag_o),
        .hold_flag_i(ctrl_hold_flag_o),
        .inst_o(if_inst_o),
        .inst_addr_o(if_inst_addr_o)
    );

    // id模块例化
    id u_id(
        .inst_i(if_inst_o),
        .inst_addr_i(if_inst_addr_o),
        .reg1_rdata_i(regs_rdata1_o),
        .reg2_rdata_i(regs_rdata2_o),
        .reg1_raddr_o(id_reg1_raddr_o),
        .reg2_raddr_o(id_reg2_raddr_o),
        .inst_o(id_inst_o),
        .inst_addr_o(id_inst_addr_o),
        .reg1_rdata_o(id_reg1_rdata_o),
        .reg2_rdata_o(id_reg2_rdata_o),
        .reg_we_o(id_reg_we_o),
        .reg_waddr_o(id_reg_waddr_o),
        .op1_o(id_op1_o),
        .op2_o(id_op2_o),
        .op1_jump_o(id_op1_jump_o),
        .op2_jump_o(id_op2_jump_o),
        .csr_rdata_i(csr_data_o),
        .csr_raddr_o(id_csr_raddr_o),
        .csr_we_o(id_csr_we_o),
        .csr_rdata_o(id_csr_rdata_o),
        .csr_waddr_o(id_csr_waddr_o)
    );

    // id_ex模块例化
    id_ex u_id_ex(
        .clk(clk),
        .rst(rst),
        .inst_i(id_inst_o),
        .inst_addr_i(id_inst_addr_o),

        .reg_we_i(id_reg_we_o),
        .reg_waddr_i(id_reg_waddr_o),
        .reg1_rdata_i(id_reg1_rdata_o),
        .reg2_rdata_i(id_reg2_rdata_o),

        .hold_flag_i(ctrl_hold_flag_o),
        .hold_jump_idex2_i(ctrl_hold_jump_idex2_o),
        .inst_o(ie_inst_o),
        .inst_addr_o(ie_inst_addr_o),
        .reg_we_o(ie_reg_we_o),
        .reg_waddr_o(ie_reg_waddr_o),
        .reg1_rdata_o(ie_reg1_rdata_o),
        .reg2_rdata_o(ie_reg2_rdata_o),
        .op1_i(id_op1_o),
        .op2_i(id_op2_o),
        .op1_jump_i(id_op1_jump_o),
        .op2_jump_i(id_op2_jump_o),
        .op1_o(ie_op1_o),
        .op2_o(ie_op2_o),
        .op1_jump_o(ie_op1_jump_o),
        .op2_jump_o(ie_op2_jump_o),
        .csr_we_i(id_csr_we_o),
        .csr_waddr_i(id_csr_waddr_o),
        .csr_rdata_i(id_csr_rdata_o),
        .csr_we_o(ie_csr_we_o),
        .csr_waddr_o(ie_csr_waddr_o),
        .csr_rdata_o(ie_csr_rdata_o),


        .rmem_data1_flag_i(rmem_data1_flag),
        .rmem_data2_flag_i(rmem_data2_flag),

        .rmem_data1_flag_o(id_ex_rmem_data1_flag),
        .rmem_data2_flag_o(id_ex_rmem_data2_flag)
    );

    // ex模块例化
    ex u_ex(
        .inst_i(ie_inst_o),
        .inst_addr_i(ie_inst_addr_o),
        .reg_we_i(ie_reg_we_o),
        .reg_waddr_i(ie_reg_waddr_o),
        .reg1_rdata_i(ie_reg1_rdata_o),
        .reg2_rdata_i(ie_reg2_rdata_o),
        .op1_i(ie_op1_o),
        .op2_i(ie_op2_o),
        .op1_jump_i(ie_op1_jump_o),
        .op2_jump_i(ie_op2_jump_o),
 
        .ex_req_flag_o(ex_req_flag_o),
        //内存处理放到mem模块，所以这里传输指令
        .inst_o(ex_inst_o),
        .op1_add_op2_res_o(ex_op1_add_op2_res_o),
        .reg1_rdata_o(ex_reg1_rdata_o),
        .reg2_rdata_o(ex_reg2_rdata_o),
        //寄存器数据后传
        .reg_wdata_o(ex_reg_wdata_o),
        .reg_we_o(ex_reg_we_o),
        .reg_waddr_o(ex_reg_waddr_o),

        //跳转数据后传
        .jump_flag_o(ex_jump_flag_o),
        .jump_addr_o(ex_jump_addr_o),

        //-----------------------------
        .hold_flag_o(ex_hold_flag_o),
        .int_assert_i(clint_int_assert_o),
        .int_addr_i(clint_int_addr_o),
        .div_ready_i(div_ready_o),
        .div_result_i(div_result_o),
        .div_busy_i(div_busy_o),
        .div_reg_waddr_i(div_reg_waddr_o),
        .div_start_o(ex_div_start_o),
        .div_dividend_o(ex_div_dividend_o),
        .div_divisor_o(ex_div_divisor_o),
        .div_op_o(ex_div_op_o),
        .div_reg_waddr_o(ex_div_reg_waddr_o),
        .csr_we_i(ie_csr_we_o),
        .csr_waddr_i(ie_csr_waddr_o),
        .csr_rdata_i(ie_csr_rdata_o),
        .csr_wdata_o(ex_csr_wdata_o),
        .csr_we_o(ex_csr_we_o),
        .csr_waddr_o(ex_csr_waddr_o),

        //访存模块返回数据直递到执行模块
        .rmem_data1_flag_i(id_ex_rmem_data1_flag),
        .rmem_data2_flag_i(id_ex_rmem_data2_flag),

        .mem_data_return_i(mem_reg_wdata_o)



    );

    ex_mem u_ex_mem(

        .clk(clk),
        .rst(rst),
        .hold_flag_i(ctrl_hold_flag_o),   
        .hold_time_i(ctrl_hold_jump_idex2_o),
        //和内存相关指令传输
        .inst_i(ex_inst_o),
        .inst_o(ex_mem_inst_o),

        .op1_add_op2_res_i(ex_op1_add_op2_res_o),
        .op1_add_op2_res_o(ex_mem_op1_add_op2_res_o),

        .reg1_rdata_i(ex_reg1_rdata_o),
        .reg1_rdata_o(ex_mem_reg1_rdata_o),

        .reg2_rdata_i(ex_reg2_rdata_o),
        .reg2_rdata_o(ex_mem_reg2_rdata_o),


        //寄存器数据
        .reg_wdata_i(ex_reg_wdata_o),
        .reg_we_i(ex_reg_we_o),
        .reg_waddr_i(ex_reg_waddr_o),

        .reg_wdata_o(ex_mem_reg_wdata_o),
        .reg_we_o(ex_mem_reg_we_o),
        .reg_waddr_o(ex_mem_reg_waddr_o),


        //-----------------------------------------------
        .id_reg1_raddr_i(id_reg1_raddr_o),         // 从id阶段传过来的读通用寄存器1地址
        .id_reg2_raddr_i(id_reg2_raddr_o),        // 从id阶段传过来的读通用寄存器2地址

        .reg1_exforward_flag_o(reg1_exforward_flag),
        .reg2_exforward_flag_o(reg2_exforward_flag),
        //---------------------------------原有ex输出到内存和寄存器的数据经过一拍后再处理
        
        .ex_req_flag_i(ex_req_flag_o)

    );

    //例化mem模块
    mem u_mem(

        .int_assert_i(clint_int_assert_o),
        .inst_i(ex_mem_inst_o),
        .op1_add_op2_res_i(ex_mem_op1_add_op2_res_o),

        .reg1_rdata_i(ex_mem_reg1_rdata_o),
        .reg2_rdata_i(ex_mem_reg2_rdata_o),

        .me_rdata_i(rib_ex_data_i),

        //---------------------------------
        
        .me_wdata_o(mem_me_wdata_o),
        .me_raddr_o(mem_me_raddr_o),
        .me_waddr_o(mem_me_waddr_o),
        .me_we_flag_o(mem_me_we_flag_o),
        .me_req_flag_o(mem_me_req_flag_o),

        .reg_wdata_o(mem_reg_wdata_o)
    );


//例化mem_wb模块
    mem_wb u_mem_wb(
        .clk(clk),
        .rst(rst),

        .hold_flag_i(ctrl_hold_flag_o),   

        .me_req_flag_i(mem_me_req_flag_o),
        //跳转数据

        .mem_reg_wdata_i(mem_reg_wdata_o),

        //寄存器数据
        .reg_wdata_i(ex_mem_reg_wdata_o),
        .reg_we_i(ex_mem_reg_we_o),
        .reg_waddr_i(ex_mem_reg_waddr_o),


        .reg_wdata_o(mem_wb_reg_wdata_o),
        .reg_we_o(mem_wb_reg_we_o),
        .reg_waddr_o(mem_wb_reg_waddr_o),


        //-----------------------------------------------
        .id_reg1_raddr_i(id_reg1_raddr_o),         // 从id阶段传过来的读通用寄存器1地址
        .id_reg2_raddr_i(id_reg2_raddr_o),        // 从id阶段传过来的读通用寄存器2地址

        .reg1_memforward_flag_o(reg1_memforward_flag),
        .reg2_memforward_flag_o(reg2_memforward_flag)
        //-----------------------------------------------
        //---------------------------------需要写回的数据经过一拍后再处理


    );

//例化wb模块
    wb u_wb(

        .reg_wdata_i(mem_wb_reg_wdata_o),
        .reg_we_i(mem_wb_reg_we_o),
        .reg_waddr_i(mem_wb_reg_waddr_o),

        //---------------------------------
        .reg_wdata_o(wb_reg_wdata_o),
        .reg_we_o(wb_reg_we_o),
        .reg_waddr_o(wb_reg_waddr_o)

    );






    // div模块例化
    div u_div(
        .clk(clk),
        .rst(rst),
        .dividend_i(ex_div_dividend_o),
        .divisor_i(ex_div_divisor_o),
        .start_i(ex_div_start_o),
        .op_i(ex_div_op_o),
        .reg_waddr_i(ex_div_reg_waddr_o),
        .result_o(div_result_o),
        .ready_o(div_ready_o),
        .busy_o(div_busy_o),
        .reg_waddr_o(div_reg_waddr_o)
    );

    // csr_reg模块例化
    csr_reg u_csr_reg(
        .clk(clk),
        .rst(rst),
        .we_i(ex_csr_we_o),
        .raddr_i(id_csr_raddr_o),
        .waddr_i(ex_csr_waddr_o),
        .data_i(ex_csr_wdata_o),
        .data_o(csr_data_o),
        .global_int_en_o(csr_global_int_en_o),
        .clint_we_i(clint_we_o),
        .clint_raddr_i(clint_raddr_o),
        .clint_waddr_i(clint_waddr_o),
        .clint_data_i(clint_data_o),
        .clint_data_o(csr_clint_data_o),
        .clint_csr_mtvec(csr_clint_csr_mtvec),
        .clint_csr_mepc(csr_clint_csr_mepc),
        .clint_csr_mstatus(csr_clint_csr_mstatus)
    );

    // clint模块例化
    clint u_clint(
        .clk(clk),
        .rst(rst),
        .int_flag_i(if_int_flag_o),  //if_id 定时器timer中断输入
        .inst_i(id_inst_o),
        .inst_addr_i(id_inst_addr_o),
                                    //针对跳转指令接口的处理
        .jump_flag_i(ex_jump_flag_o), 
        .jump_addr_i(ex_jump_addr_o),


        .hold_flag_i(ctrl_hold_flag_o),  //模块中未使用
        .div_started_i(ex_div_start_o),
        .data_i(csr_clint_data_o),
        .csr_mtvec(csr_clint_csr_mtvec),
        .csr_mepc(csr_clint_csr_mepc),
        .csr_mstatus(csr_clint_csr_mstatus),
        .we_o(clint_we_o),
        .waddr_o(clint_waddr_o),
        .raddr_o(clint_raddr_o),
        .data_o(clint_data_o),
        .hold_flag_o(clint_hold_flag_o),  //暂停流水线
        .global_int_en_i(csr_global_int_en_o),
        .int_addr_o(clint_int_addr_o),
        .int_assert_o(clint_int_assert_o)
    );

endmodule
