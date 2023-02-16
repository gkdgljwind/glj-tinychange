

`include "defines.v"
// 执行模块
// 纯组合逻辑电路
module ex(
    // from id
    input wire[`InstBus] inst_i,            // 指令内容
    input wire[`InstAddrBus] inst_addr_i,   // 指令地址
    input wire reg_we_i,                    // 是否写通用寄存器
    input wire[`RegAddrBus] reg_waddr_i,    // 写通用寄存器地址
    input wire[31:0] reg1_rdata_i,       // 通用寄存器1输入数据
    input wire[31:0] reg2_rdata_i,       // 通用寄存器2输入数据
    input wire csr_we_i,                    // 是否写CSR寄存器
    input wire[`MemAddrBus] csr_waddr_i,    // 写CSR寄存器地址
    input wire[31:0] csr_rdata_i,        // CSR寄存器输入数据
    input wire int_assert_i,                // 中断发生标志

    input wire[`InstAddrBus] int_addr_i,    // 中断跳转地址

    input wire[`MemAddrBus] op1_i,
    input wire[`MemAddrBus] op2_i,
    input wire[`MemAddrBus] op1_jump_i,
    input wire[`MemAddrBus] op2_jump_i,


    // from div
    input wire div_ready_i,                 // 除法运算完成标志
    input wire[31:0] div_result_i,       // 除法运算结果
    input wire div_busy_i,                  // 除法运算忙标志
    input wire[`RegAddrBus] div_reg_waddr_i,// 除法运算结束后要写的寄存器地址

    //处理内存数据直接递到执行阶段
    input wire rmem_data1_flag_i,
    input wire rmem_data2_flag_i,

    input wire[31:0] mem_data_return_i,

    // to wb then to regs
    output wire[31:0] reg_wdata_o,       // 写寄存器数据
    output wire reg_we_o,                   // 是否要写通用寄存器
    output wire[`RegAddrBus] reg_waddr_o,   // 写通用寄存器地址

    // to csr reg
    output reg[31:0] csr_wdata_o,        // 写CSR寄存器数据
    output wire csr_we_o,                   // 是否要写CSR寄存器
    output wire[`MemAddrBus] csr_waddr_o,   // 写CSR寄存器地址

    // to div
    output wire div_start_o,                // 开始除法运算标志
    output reg[31:0] div_dividend_o,     // 被除数
    output reg[31:0] div_divisor_o,      // 除数
    output reg[2:0] div_op_o,               // 具体是哪一条除法指令
    output reg[`RegAddrBus] div_reg_waddr_o,// 除法运算结束后要写的寄存器地址

    // to ctrl
    output wire hold_flag_o,                // 是否暂停标志
    output wire jump_flag_o,                // 是否跳转标志
    output wire[`InstAddrBus] jump_addr_o,   // 跳转目的地址

    // to mem
    output wire[31:0]inst_o,
    output wire[31:0]op1_add_op2_res_o,
    output wire[31:0]reg1_rdata_o,
    output wire[31:0]reg2_rdata_o,
    output wire ex_req_flag_o

    );

    wire[1:0] mem_raddr_index;
    wire[1:0] mem_waddr_index;
    wire[`DoubleRegBus] mul_temp;
    wire[`DoubleRegBus] mul_temp_invert;
    wire[31:0] sr_shift;
    wire[31:0] sri_shift;
    wire[31:0] sr_shift_mask;
    wire[31:0] sri_shift_mask;
    wire[31:0] op1_add_op2_res;
    wire[31:0] op1_jump_add_op2_jump_res;
    wire[31:0] reg1_data_invert;
    wire[31:0] reg2_data_invert;
    wire op1_ge_op2_signed;
    wire op1_ge_op2_unsigned;
    wire op1_eq_op2;
    reg[31:0] mul_op1;
    reg[31:0] mul_op2;
    wire[6:0] opcode;
    wire[2:0] funct3;
    wire[6:0] funct7;
    wire[4:0] rd;
    wire[4:0] uimm;
    reg[31:0] reg_wdata;
    reg reg_we;
    reg[`RegAddrBus] reg_waddr;

    reg[31:0] div_wdata;
    reg div_we;
    reg[`RegAddrBus] div_waddr;
    reg div_hold_flag;
    reg div_jump_flag;
    reg[`InstAddrBus] div_jump_addr;
    reg hold_flag;
    reg jump_flag;
    reg[`InstAddrBus] jump_addr;
    reg div_start;

    assign opcode = inst_i[6:0];
    assign funct3 = inst_i[14:12];
    assign funct7 = inst_i[31:25];
    assign rd     = inst_i[11:7];
    assign uimm   = inst_i[19:15];

    assign sr_shift = reg1_rdata >> reg2_rdata[4:0];
    assign sri_shift = reg1_rdata >> inst_i[24:20];
    assign sr_shift_mask = 32'hffffffff >> reg2_rdata[4:0];
    assign sri_shift_mask = 32'hffffffff >> inst_i[24:20];

    assign op1_add_op2_res = op1 + op2;
    assign op1_jump_add_op2_jump_res = op1_jump + op2_jump;


    assign reg1_data_invert = ~reg1_rdata + 1;
    assign reg2_data_invert = ~reg2_rdata + 1;


    // 有符号数比较
    assign op1_ge_op2_signed = $signed(op1) >= $signed(op2);
    // 无符号数比较
    assign op1_ge_op2_unsigned = op1 >= op2;
    assign op1_eq_op2 = (op1 == op2);

    assign mul_temp = mul_op1 * mul_op2;
    assign mul_temp_invert = ~mul_temp + 1;//将负数的补码取反加1



    assign div_start_o = (int_assert_i == `INT_ASSERT)? `DivStop: div_start;

    assign reg_wdata_o = reg_wdata | div_wdata;
    // 响应中断时不写通用寄存器
    assign reg_we_o = (int_assert_i == `INT_ASSERT)? `WriteDisable: (reg_we || div_we);
    assign reg_waddr_o = reg_waddr | div_waddr;


    assign hold_flag_o = hold_flag || div_hold_flag;
    assign jump_flag_o = jump_flag || div_jump_flag || ((int_assert_i == `INT_ASSERT)? `JumpEnable: `JumpDisable);
    assign jump_addr_o = (int_assert_i == `INT_ASSERT)? int_addr_i: (jump_addr | div_jump_addr);

    // 响应中断时不写CSR寄存器
    assign csr_we_o = (int_assert_i == `INT_ASSERT)? `WriteDisable: csr_we_i;
    assign csr_waddr_o = csr_waddr_i;

    assign inst_o = inst_i;
    assign op1_add_op2_res_o = op1_add_op2_res;
    assign reg1_rdata_o=reg1_rdata;
    assign reg2_rdata_o=reg2_rdata;
    reg ex_req_flag;
    assign ex_req_flag_o=ex_req_flag;

    reg[31:0] reg1_rdata;       // 通用寄存器1输入数据
    reg[31:0] reg2_rdata;      // 通用寄存器2输入数据

    reg[`MemAddrBus] op1;
    reg[`MemAddrBus] op2;
    reg[`MemAddrBus] op1_jump;
    reg[`MemAddrBus] op2_jump;

    wire[31:0]id_op1_o;
    wire[31:0]id_op2_o;
    wire[31:0]id_op1_jump_o;
    wire[31:0]id_op2_jump_o;

            id e_id(
            .inst_i(inst_i),
            .inst_addr_i(inst_addr_i),
            .reg1_rdata_i(reg1_rdata),
            .reg2_rdata_i(reg2_rdata),
            /*
            .reg1_raddr_o(id_reg1_raddr_o),
            .reg2_raddr_o(id_reg2_raddr_o),
            .inst_o(id_inst_o),
            .inst_addr_o(id_inst_addr_o),
            .reg1_rdata_o(id_reg1_rdata_o),
            .reg2_rdata_o(id_reg2_rdata_o),
            .reg_we_o(id_reg_we_o),
            .reg_waddr_o(id_reg_waddr_o),
            */
            .op1_o(id_op1_o),
            .op2_o(id_op2_o),
            .op1_jump_o(id_op1_jump_o),
            .op2_jump_o(id_op2_jump_o),
            .csr_rdata_i(32'h0)
            /*
            .csr_raddr_o(id_csr_raddr_o),
            .csr_we_o(id_csr_we_o),
            .csr_rdata_o(id_csr_rdata_o),
            .csr_waddr_o(id_csr_waddr_o)
            */
            );


    //判断是否将内存读到的数据直接传递到执行阶段
    always @(*) begin

        if (rmem_data1_flag_i == 1'b1) begin
            reg1_rdata= mem_data_return_i; 
        end else begin
            reg1_rdata= reg1_rdata_i; 
        end

        if (rmem_data2_flag_i == 1'b1) begin
            reg2_rdata= mem_data_return_i; 
        end else begin
            reg2_rdata= reg2_rdata_i; 
        end


        if (rmem_data1_flag_i == 1'b1 || rmem_data2_flag_i == 1'b1) begin


            op1 = id_op1_o;
            op2 = id_op2_o;
            op1_jump = id_op1_jump_o;
            op2_jump = id_op2_jump_o;


        end else begin
            op1 = op1_i;
            op2 = op2_i;
            op1_jump = op1_jump_i;
            op2_jump = op2_jump_i;

        end


    end




    // 处理乘法指令（硬件中所有数据，以补码的形式存储！！!）
    always @ (*) begin
        if ((opcode == `INST_TYPE_R_M) && (funct7 == 7'b0000001)) begin
            case (funct3)
                `INST_MUL, `INST_MULHU: begin
                    mul_op1 = reg1_rdata;
                    mul_op2 = reg2_rdata;
                end
				//mulhsu指令将操作数寄存器rsl与rs2中的32位整数相乘，
				//其中rsl当作有符号数、rs2当作无符号数，将结果的高32位写回寄存器rd中
				`INST_MULHSU: begin         //符号数乘无符号数，将符号数取反加1
                    mul_op1 = (reg1_rdata[31] == 1'b1)? (reg1_data_invert): reg1_rdata;
                    mul_op2 = reg2_rdata;
                end
				//mulh指令将操作数寄存器rsl与rs2中的32位整数当作有符号数相乘
				//结果的高32位写回寄存器rd中。
                `INST_MULH: begin           //无符号数乘法，将两个操作数都取反加1
                    mul_op1 = (reg1_rdata[31] == 1'b1)? (reg1_data_invert): reg1_rdata;
                    mul_op2 = (reg2_rdata[31] == 1'b1)? (reg2_data_invert): reg2_rdata;
                end
                default: begin
                    mul_op1 = reg1_rdata;
                    mul_op2 = reg2_rdata;
                end
            endcase
        end else begin
            mul_op1 = reg1_rdata;
            mul_op2 = reg2_rdata;
        end
    end

    // 处理除法指令
    always @ (*) begin
        div_dividend_o = reg1_rdata;                //被除数
        div_divisor_o = reg2_rdata;	              //除数
        div_op_o = funct3;				              //具体是哪一条除法指令
        div_reg_waddr_o = reg_waddr_i;
        if ((opcode   == `INST_TYPE_R_M) && (funct7 == 7'b0000001)) begin
             div_we    = `WriteDisable;
             div_wdata = `ZeroWord;
             div_waddr = `ZeroWord;
            case (funct3)
                `INST_DIV, `INST_DIVU, `INST_REM, `INST_REMU: begin
                    div_start = `DivStart;
                    div_jump_flag = `JumpEnable;
                    div_hold_flag = `HoldEnable;
                    div_jump_addr = op1_jump_add_op2_jump_res;
                end
                default: begin
                    div_start = `DivStop;
                    div_jump_flag = `JumpDisable;
                    div_hold_flag = `HoldDisable;
                    div_jump_addr = `ZeroWord;
                end
            endcase
        end else begin
            div_jump_flag = `JumpDisable;
            div_jump_addr = `ZeroWord;
            if (div_busy_i == `True) begin
                div_start = `DivStart;
                div_we = `WriteDisable;
                div_wdata = `ZeroWord;
                div_waddr = `ZeroWord;
                div_hold_flag = `HoldEnable;
            end else begin
                div_start = `DivStop;
                div_hold_flag = `HoldDisable;
                if (div_ready_i == `DivResultReady) begin
                    div_wdata = div_result_i;
                    div_waddr = div_reg_waddr_i;
                    div_we = `WriteEnable;
                end else begin
                    div_we = `WriteDisable;
                    div_wdata = `ZeroWord;
                    div_waddr = `ZeroWord;
                end
            end
        end
    end

    // 执行
    always @ (*) begin
        reg_we = reg_we_i;
        reg_waddr = reg_waddr_i;
        ex_req_flag = `RIB_NREQ;
        csr_wdata_o = `ZeroWord;

        case (opcode)
            `INST_TYPE_I: begin
                case (funct3)
                    `INST_ADDI: begin
                        jump_flag = `JumpDisable;
                        hold_flag = `HoldDisable;
                        jump_addr = `ZeroWord;
                        //me_wdata_o = `ZeroWord;
                        //me_raddr_o = `ZeroWord;
                        //me_waddr_o = `ZeroWord;
                        //me_we = `WriteDisable;
                        reg_wdata = op1_add_op2_res;
                    end
                    `INST_SLTI: begin
                        jump_flag = `JumpDisable;
                        hold_flag = `HoldDisable;
                        jump_addr = `ZeroWord;
                        //me_wdata_o = `ZeroWord;
                        //me_raddr_o = `ZeroWord;
                        //me_waddr_o = `ZeroWord;
                        //me_we = `WriteDisable;
                        reg_wdata = {32{(~op1_ge_op2_signed)}} & 32'h1;
                    end
                    `INST_SLTIU: begin
                        jump_flag = `JumpDisable;
                        hold_flag = `HoldDisable;
                        jump_addr = `ZeroWord;
                        //me_wdata_o = `ZeroWord;
                        //me_raddr_o = `ZeroWord;
                        //me_waddr_o = `ZeroWord;
                        //me_we = `WriteDisable;
                        reg_wdata = {32{(~op1_ge_op2_unsigned)}} & 32'h1;
                    end
                    `INST_XORI: begin
                        jump_flag = `JumpDisable;
                        hold_flag = `HoldDisable;
                        jump_addr = `ZeroWord;
                        //me_wdata_o = `ZeroWord;
                        //me_raddr_o = `ZeroWord;
                        //me_waddr_o = `ZeroWord;
                        //me_we = `WriteDisable;
                        reg_wdata = op1 ^ op2;
                    end
                    `INST_ORI: begin
                        jump_flag = `JumpDisable;
                        hold_flag = `HoldDisable;
                        jump_addr = `ZeroWord;
                        //me_wdata_o = `ZeroWord;
                        //me_raddr_o = `ZeroWord;
                        //me_waddr_o = `ZeroWord;
                        //me_we = `WriteDisable;
                        reg_wdata = op1 | op2;
                    end
                    `INST_ANDI: begin
                        jump_flag = `JumpDisable;
                        hold_flag = `HoldDisable;
                        jump_addr = `ZeroWord;
                        //me_wdata_o = `ZeroWord;
                        //me_raddr_o = `ZeroWord;
                        //me_waddr_o = `ZeroWord;
                        //me_we = `WriteDisable;
                        reg_wdata = op1 & op2;
                    end
                    `INST_SLLI: begin
                        jump_flag = `JumpDisable;
                        hold_flag = `HoldDisable;
                        jump_addr = `ZeroWord;
                        //me_wdata_o = `ZeroWord;
                        //me_raddr_o = `ZeroWord;
                        //me_waddr_o = `ZeroWord;
                        //me_we = `WriteDisable;
                        reg_wdata = reg1_rdata << inst_i[24:20];
                    end
                    `INST_SRI: begin
                        jump_flag = `JumpDisable;
                        hold_flag = `HoldDisable;
                        jump_addr = `ZeroWord;
                        //me_wdata_o = `ZeroWord;
                        //me_raddr_o = `ZeroWord;
                        //me_waddr_o = `ZeroWord;
                        //me_we = `WriteDisable;
                        if (inst_i[30] == 1'b1) begin
                            reg_wdata = (sri_shift & sri_shift_mask) | ({32{reg1_rdata[31]}} & (~sri_shift_mask));
                        end else begin
                            reg_wdata = reg1_rdata >> inst_i[24:20];
                        end
                    end
                    default: begin
                        jump_flag = `JumpDisable;
                        hold_flag = `HoldDisable;
                        jump_addr = `ZeroWord;
                        //me_wdata_o = `ZeroWord;
                        //me_raddr_o = `ZeroWord;
                        //me_waddr_o = `ZeroWord;
                        //me_we = `WriteDisable;
                        reg_wdata = `ZeroWord;
                    end
                endcase
            end
            `INST_TYPE_R_M: begin
                if ((funct7 == 7'b0000000) || (funct7 == 7'b0100000)) begin
                    case (funct3)
                        `INST_ADD_SUB: begin
                            jump_flag = `JumpDisable;
                            hold_flag = `HoldDisable;
                            jump_addr = `ZeroWord;
                            //me_wdata_o = `ZeroWord;
                            //me_raddr_o = `ZeroWord;
                            //me_waddr_o = `ZeroWord;
                            //me_we = `WriteDisable;
                            if (inst_i[30] == 1'b0) begin
                                reg_wdata = op1_add_op2_res;
                            end else begin
                                reg_wdata = op1 - op2;
                            end
                        end
                        `INST_SLL: begin
                            jump_flag = `JumpDisable;
                            hold_flag = `HoldDisable;
                            jump_addr = `ZeroWord;
                            //me_wdata_o = `ZeroWord;
                            //me_raddr_o = `ZeroWord;
                            //me_waddr_o = `ZeroWord;
                            //me_we = `WriteDisable;
                            reg_wdata = op1 << op2[4:0];
                        end
                        `INST_SLT: begin
                            jump_flag = `JumpDisable;
                            hold_flag = `HoldDisable;
                            jump_addr = `ZeroWord;
                            //me_wdata_o = `ZeroWord;
                            //me_raddr_o = `ZeroWord;
                            //me_waddr_o = `ZeroWord;
                            //me_we = `WriteDisable;
                            reg_wdata = {32{(~op1_ge_op2_signed)}} & 32'h1;
                        end
                        `INST_SLTU: begin
                            jump_flag = `JumpDisable;
                            hold_flag = `HoldDisable;
                            jump_addr = `ZeroWord;
                            //me_wdata_o = `ZeroWord;
                            //me_raddr_o = `ZeroWord;
                            //me_waddr_o = `ZeroWord;
                            //me_we = `WriteDisable;
                            reg_wdata = {32{(~op1_ge_op2_unsigned)}} & 32'h1;
                        end
                        `INST_XOR: begin
                            jump_flag = `JumpDisable;
                            hold_flag = `HoldDisable;
                            jump_addr = `ZeroWord;
                            //me_wdata_o = `ZeroWord;
                            //me_raddr_o = `ZeroWord;
                            //me_waddr_o = `ZeroWord;
                            //me_we = `WriteDisable;
                            reg_wdata = op1 ^ op2;
                        end
                        `INST_SR: begin
                            jump_flag = `JumpDisable;
                            hold_flag = `HoldDisable;
                            jump_addr = `ZeroWord;
                            //me_wdata_o = `ZeroWord;
                            //me_raddr_o = `ZeroWord;
                            //me_waddr_o = `ZeroWord;
                            //me_we = `WriteDisable;
                            if (inst_i[30] == 1'b1) begin
                                reg_wdata = (sr_shift & sr_shift_mask) | ({32{reg1_rdata[31]}} & (~sr_shift_mask));
                            end else begin
                                reg_wdata = reg1_rdata >> reg2_rdata[4:0];
                            end
                        end
                        `INST_OR: begin
                            jump_flag = `JumpDisable;
                            hold_flag = `HoldDisable;
                            jump_addr = `ZeroWord;
                            //me_wdata_o = `ZeroWord;
                            //me_raddr_o = `ZeroWord;
                            //me_waddr_o = `ZeroWord;
                            //me_we = `WriteDisable;
                            reg_wdata = op1 | op2;
                        end
                        `INST_AND: begin
                            jump_flag = `JumpDisable;
                            hold_flag = `HoldDisable;
                            jump_addr = `ZeroWord;
                            //me_wdata_o = `ZeroWord;
                            //me_raddr_o = `ZeroWord;
                            //me_waddr_o = `ZeroWord;
                            //me_we = `WriteDisable;
                            reg_wdata = op1 & op2;
                        end
                        default: begin
                            jump_flag = `JumpDisable;
                            hold_flag = `HoldDisable;
                            jump_addr = `ZeroWord;
                            //me_wdata_o = `ZeroWord;
                            //me_raddr_o = `ZeroWord;
                            //me_waddr_o = `ZeroWord;
                            //me_we = `WriteDisable;
                            reg_wdata = `ZeroWord;
                        end
                    endcase
                end else if (funct7 == 7'b0000001) begin
                    case (funct3)
                        `INST_MUL: begin
                            jump_flag = `JumpDisable;
                            hold_flag = `HoldDisable;
                            jump_addr = `ZeroWord;
                            //me_wdata_o = `ZeroWord;
                            //me_raddr_o = `ZeroWord;
                            //me_waddr_o = `ZeroWord;
                            //me_we = `WriteDisable;
                            reg_wdata = mul_temp[31:0];
                        end
                        `INST_MULHU: begin
                            jump_flag = `JumpDisable;
                            hold_flag = `HoldDisable;
                            jump_addr = `ZeroWord;
                            //me_wdata_o = `ZeroWord;
                            //me_raddr_o = `ZeroWord;
                            //me_waddr_o = `ZeroWord;
                            //me_we = `WriteDisable;
                            reg_wdata = mul_temp[63:32];
                        end
						//mulh指令将操作数寄存器rsl与rs2中的32位整数当作有符号数相乘
						//结果的高32位写回寄存器rd中。
                        `INST_MULH: begin
                            jump_flag = `JumpDisable;
                            hold_flag = `HoldDisable;
                            jump_addr = `ZeroWord;
                            //me_wdata_o = `ZeroWord;
                            //me_raddr_o = `ZeroWord;
                            //me_waddr_o = `ZeroWord;
                            //me_we = `WriteDisable;
                            case ({reg1_rdata[31], reg2_rdata[31]})
                                2'b00: begin
                                    reg_wdata = mul_temp[63:32];
                                end
                                2'b11: begin
                                    reg_wdata = mul_temp[63:32];
                                end
                                2'b10: begin
                                    reg_wdata = mul_temp_invert[63:32];
                                end
                                default: begin
                                    reg_wdata = mul_temp_invert[63:32];
                                end
                            endcase
                        end
                        `INST_MULHSU: begin
                            jump_flag = `JumpDisable;
                            hold_flag = `HoldDisable;
                            jump_addr = `ZeroWord;
                            //me_wdata_o = `ZeroWord;
                            //me_raddr_o = `ZeroWord;
                            //me_waddr_o = `ZeroWord;
                            //me_we = `WriteDisable;
                            if (reg1_rdata[31] == 1'b1) begin
                                reg_wdata = mul_temp_invert[63:32];
                            end else begin
                                reg_wdata = mul_temp[63:32];
                            end
                        end
                        default: begin
                            jump_flag = `JumpDisable;
                            hold_flag = `HoldDisable;
                            jump_addr = `ZeroWord;
                            //me_wdata_o = `ZeroWord;
                            //me_raddr_o = `ZeroWord;
                            //me_waddr_o = `ZeroWord;
                            //me_we = `WriteDisable;
                            reg_wdata = `ZeroWord;
                        end
                    endcase
                end else begin
                    jump_flag = `JumpDisable;
                    hold_flag = `HoldDisable;
                    jump_addr = `ZeroWord;
                    reg_wdata = `ZeroWord;
                    //me_wdata_o = `ZeroWord;
                    //me_raddr_o = `ZeroWord;
                    //me_waddr_o = `ZeroWord;
                    //me_we = `WriteDisable;
                    
                end
            end
            //和内存有关指令需要提前暂停-------------------------------------------------
            `INST_TYPE_L: begin
                case (funct3)
                    `INST_LB: begin
                        ex_req_flag = `RIB_REQ;
                        jump_flag = `JumpDisable;
                        hold_flag = `HoldDisable;
                        jump_addr = `ZeroWord;
                        reg_wdata = `ZeroWord;  
                    end
                    `INST_LH: begin
                        ex_req_flag = `RIB_REQ;
                        jump_flag = `JumpDisable;
                        hold_flag = `HoldDisable;
                        jump_addr = `ZeroWord;
                        reg_wdata = `ZeroWord;                          
                    end
                    `INST_LW: begin
                        ex_req_flag = `RIB_REQ;
                        jump_flag = `JumpDisable;
                        hold_flag = `HoldDisable;
                        jump_addr = `ZeroWord;
                        reg_wdata = `ZeroWord;  
                    end
                    `INST_LBU: begin
                        ex_req_flag = `RIB_REQ;
                        jump_flag = `JumpDisable;
                        hold_flag = `HoldDisable;
                        jump_addr = `ZeroWord;
                        reg_wdata = `ZeroWord;  
                    end
                    `INST_LHU: begin
                        ex_req_flag = `RIB_REQ;
                        jump_flag = `JumpDisable;
                        hold_flag = `HoldDisable;
                        jump_addr = `ZeroWord;
                        reg_wdata = `ZeroWord;  
                    end
                    default: begin
                        ex_req_flag = `RIB_REQ;
                        jump_flag = `JumpDisable;
                        hold_flag = `HoldDisable;
                        jump_addr = `ZeroWord;
                        reg_wdata = `ZeroWord;  
                    end
                endcase
            end
            `INST_TYPE_S: begin
                case (funct3)
                    `INST_SB: begin
                        ex_req_flag = `RIB_REQ;
                        jump_flag = `JumpDisable;
                        hold_flag = `HoldDisable;
                        jump_addr = `ZeroWord;
                        reg_wdata = `ZeroWord;  
                    end
                    `INST_SH: begin
                        ex_req_flag = `RIB_REQ;
                        jump_flag = `JumpDisable;
                        hold_flag = `HoldDisable;
                        jump_addr = `ZeroWord;
                        reg_wdata = `ZeroWord;  
                    end
                    `INST_SW: begin
                        ex_req_flag = `RIB_REQ;
                        jump_flag = `JumpDisable;
                        hold_flag = `HoldDisable;
                        jump_addr = `ZeroWord;
                        reg_wdata = `ZeroWord;  
                    end
                    default: begin
                        ex_req_flag = `RIB_REQ;
                        jump_flag = `JumpDisable;
                        hold_flag = `HoldDisable;
                        jump_addr = `ZeroWord;
                        reg_wdata = `ZeroWord;  
                    end
                endcase
            end
            //-------------------------------------------------------
            `INST_TYPE_B: begin
                case (funct3)
                    `INST_BEQ: begin
                        hold_flag = `HoldDisable;
                        //me_wdata_o = `ZeroWord;
                        //me_raddr_o = `ZeroWord;
                        //me_waddr_o = `ZeroWord;
                        //me_we = `WriteDisable;
                        reg_wdata = `ZeroWord;
                        jump_flag = op1_eq_op2 & `JumpEnable;
                        jump_addr = {32{op1_eq_op2}} & op1_jump_add_op2_jump_res;
                    end
                    `INST_BNE: begin
                        hold_flag = `HoldDisable;
                        //me_wdata_o = `ZeroWord;
                        //me_raddr_o = `ZeroWord;
                        //me_waddr_o = `ZeroWord;
                        //me_we = `WriteDisable;
                        reg_wdata = `ZeroWord;
                        jump_flag = (~op1_eq_op2) & `JumpEnable;
                        jump_addr = {32{(~op1_eq_op2)}} & op1_jump_add_op2_jump_res;
                    end
                    `INST_BLT: begin
                        hold_flag = `HoldDisable;
                        //me_wdata_o = `ZeroWord;
                        //me_raddr_o = `ZeroWord;
                        //me_waddr_o = `ZeroWord;
                        //me_we = `WriteDisable;
                        reg_wdata = `ZeroWord;
                        jump_flag = (~op1_ge_op2_signed) & `JumpEnable;
                        jump_addr = {32{(~op1_ge_op2_signed)}} & op1_jump_add_op2_jump_res;
                    end
                    `INST_BGE: begin
                        hold_flag = `HoldDisable;
                        //me_wdata_o = `ZeroWord;
                        //me_raddr_o = `ZeroWord;
                        //me_waddr_o = `ZeroWord;
                        //me_we = `WriteDisable;
                        reg_wdata = `ZeroWord;
                        jump_flag = (op1_ge_op2_signed) & `JumpEnable;
                        jump_addr = {32{(op1_ge_op2_signed)}} & op1_jump_add_op2_jump_res;
                    end
                    `INST_BLTU: begin
                        hold_flag = `HoldDisable;
                        //me_wdata_o = `ZeroWord;
                        //me_raddr_o = `ZeroWord;
                        //me_waddr_o = `ZeroWord;
                        //me_we = `WriteDisable;
                        reg_wdata = `ZeroWord;
                        jump_flag = (~op1_ge_op2_unsigned) & `JumpEnable;
                        jump_addr = {32{(~op1_ge_op2_unsigned)}} & op1_jump_add_op2_jump_res;
                    end
                    `INST_BGEU: begin
                        hold_flag = `HoldDisable;
                        //me_wdata_o = `ZeroWord;
                        //me_raddr_o = `ZeroWord;
                        //me_waddr_o = `ZeroWord;
                        //me_we = `WriteDisable;
                        reg_wdata = `ZeroWord;
                        jump_flag = (op1_ge_op2_unsigned) & `JumpEnable;
                        jump_addr = {32{(op1_ge_op2_unsigned)}} & op1_jump_add_op2_jump_res;
                    end
                    default: begin
                        jump_flag = `JumpDisable;
                        hold_flag = `HoldDisable;
                        jump_addr = `ZeroWord;
                        //me_wdata_o = `ZeroWord;
                        //me_raddr_o = `ZeroWord;
                        //me_waddr_o = `ZeroWord;
                        //me_we = `WriteDisable;
                        reg_wdata = `ZeroWord;
                    end
                endcase
            end
            `INST_JAL, `INST_JALR: begin
                hold_flag = `HoldDisable;
                //me_wdata_o = `ZeroWord;
                //me_raddr_o = `ZeroWord;
                //me_waddr_o = `ZeroWord;
                //me_we = `WriteDisable;
                jump_flag = `JumpEnable;
                jump_addr = op1_jump_add_op2_jump_res;
                reg_wdata = op1_add_op2_res;
            end
            `INST_LUI, `INST_AUIPC: begin
                hold_flag = `HoldDisable;
                //me_wdata_o = `ZeroWord;
                //me_raddr_o = `ZeroWord;
                //me_waddr_o = `ZeroWord;
                //me_we = `WriteDisable;
                jump_addr = `ZeroWord;
                jump_flag = `JumpDisable;
                reg_wdata = op1_add_op2_res;
            end
            `INST_NOP_OP: begin
                jump_flag = `JumpDisable;
                hold_flag = `HoldDisable;
                jump_addr = `ZeroWord;
                //me_wdata_o = `ZeroWord;
                //me_raddr_o = `ZeroWord;
                //me_waddr_o = `ZeroWord;
                //me_we = `WriteDisable;
                reg_wdata = `ZeroWord;
            end
            `INST_FENCE: begin
                hold_flag = `HoldDisable;
                //me_wdata_o = `ZeroWord;
                //me_raddr_o = `ZeroWord;
                //me_waddr_o = `ZeroWord;
                //me_we = `WriteDisable;
                reg_wdata = `ZeroWord;
                jump_flag = `JumpEnable;
                jump_addr = op1_jump_add_op2_jump_res;
            end
            `INST_CSR: begin
                jump_flag = `JumpDisable;
                hold_flag = `HoldDisable;
                jump_addr = `ZeroWord;
                //me_wdata_o = `ZeroWord;
                //me_raddr_o = `ZeroWord;
                //me_waddr_o = `ZeroWord;
                //me_we = `WriteDisable;
                case (funct3)
                    `INST_CSRRW: begin  //读/写指令
                        csr_wdata_o = reg1_rdata;
                        reg_wdata = csr_rdata_i; //csr_rdata_i 来自id译码模块 写通用寄存器
                    end
                    `INST_CSRRS: begin //读&置位指令
                        csr_wdata_o = reg1_rdata | csr_rdata_i;
                        reg_wdata = csr_rdata_i;  //csr_rdata_i 来自id译码模块 写通用寄存器
                    end
                    `INST_CSRRC: begin //读&清位
                        csr_wdata_o = csr_rdata_i & (~reg1_rdata);
                        reg_wdata = csr_rdata_i;
                    end
                    `INST_CSRRWI: begin //读/写立即数
                        csr_wdata_o = {27'h0, uimm};
                        reg_wdata = csr_rdata_i;
                    end
                    `INST_CSRRSI: begin //读&置位立即数
                        csr_wdata_o = {27'h0, uimm} | csr_rdata_i;
                        reg_wdata = csr_rdata_i;
                    end
                    `INST_CSRRCI: begin //读&清位立即数
                        csr_wdata_o = (~{27'h0, uimm}) & csr_rdata_i;
                        reg_wdata = csr_rdata_i;
                    end
                    default: begin
                        jump_flag = `JumpDisable;
                        hold_flag = `HoldDisable;
                        jump_addr = `ZeroWord;
                        //me_wdata_o = `ZeroWord;
                        //me_raddr_o = `ZeroWord;
                        //me_waddr_o = `ZeroWord;
                        //me_we = `WriteDisable;
                        reg_wdata = `ZeroWord;
                    end
                endcase
            end
            default: begin
                jump_flag = `JumpDisable;
                hold_flag = `HoldDisable;
                jump_addr = `ZeroWord;
                //me_wdata_o = `ZeroWord;
                //me_raddr_o = `ZeroWord;
                //me_waddr_o = `ZeroWord;
                //me_we = `WriteDisable;
                reg_wdata = `ZeroWord;
            end
        endcase
    end

endmodule
