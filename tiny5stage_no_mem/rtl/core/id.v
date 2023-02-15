`include "defines.v"
// 译码模块
// 纯组合逻辑电路
module id(
    // from if_id
    input wire[`InstBus]     inst_i,              // 指令内容 32位
    input wire[`InstAddrBus] inst_addr_i,         // 指令地址 32位
    // from regs
    input wire[`RegBus]      reg1_rdata_i,        // 通用寄存器1输入数据
    input wire[`RegBus]      reg2_rdata_i,        // 通用寄存器2输入数据
    // from csr reg
    input wire[`RegBus]      csr_rdata_i,         // CSR寄存器输入数据
    // from ex
    input wire               ex_jump_flag_i,      // 跳转标志
 //----------------------------以上输入----------以下输出--------------------------------------------------
    // to regs
    output reg[`RegAddrBus ]  reg1_raddr_o,         // 读通用寄存器1地址
    output reg[`RegAddrBus ]  reg2_raddr_o,         // 读通用寄存器2地址
    // to csr 
    output reg[`MemAddrBus ]  csr_raddr_o ,          // reg读CSR寄存器地址
    // to ex
    output reg[`MemAddrBus ]  op1_o       ,
    output reg[`MemAddrBus ]  op2_o       ,
    output reg[`MemAddrBus ]  op1_jump_o  ,
    output reg[`MemAddrBus ]  op2_jump_o  ,
    
    output reg[`InstBus    ]  inst_o,             // 指令内容           与输入时内容相同
    output reg[`InstAddrBus]  inst_addr_o ,       // 指令地址           与输入时内容相同
    output reg[`RegBus     ]  reg1_rdata_o,       // 通用寄存器1数据    与输入时内容相同
    output reg[`RegBus     ]  reg2_rdata_o,       // 通用寄存器2数据    与输入时内容相同
                                                                        
    output reg                reg_we_o,           // 写通用寄存器标志   
    output reg[`RegAddrBus ]  reg_waddr_o,        // 写通用寄存器地址   
    output reg                csr_we_o,           // 写CSR寄存器标志    
    output reg[`RegBus     ]  csr_rdata_o,        // CSR寄存器数据      与输入时内容相同
    output reg[`MemAddrBus ]  csr_waddr_o         // 写CSR寄存器地址
    );

//将一条32位的指令分为6个部分，顺序如下
//   funct7 rs2 rs1 funct3 rd opcode
    wire[6:0] funct7 = inst_i[31:25]    ;        //功能2    （好像表示的是拓展指令的种类）
    wire[4:0] rs2    = inst_i[24:20]    ;        //源寄存器2、立即数
    wire[4:0] rs1    = inst_i[19:15]    ;        //源寄存器1、立即数
    wire[2:0] funct3 = inst_i[14:12]    ;        //功能1    （立即数：加法、无符号比较、有符号比较、、、）    
    wire[4:0] rd     = inst_i[11:7 ]    ;        //目标寄存器、立即数
    wire[6:0] opcode = inst_i[6 :0 ]    ;        //操作码   （立即数指令、寄存器指令、控制转移指令、、、）指出该指令需要完成操作的类型或性质；
    

    always @ (*) begin
        inst_o       = inst_i;                    
        inst_addr_o  = inst_addr_i;
        reg1_rdata_o = reg1_rdata_i;
        reg2_rdata_o = reg2_rdata_i;
        csr_rdata_o  = csr_rdata_i;
        csr_raddr_o  = `ZeroWord; //32'h0
        csr_waddr_o  = `ZeroWord;
        csr_we_o     = `WriteDisable;//1'b0
        op1_o        = `ZeroWord;
        op2_o        = `ZeroWord;
        op1_jump_o   = `ZeroWord;
        op2_jump_o   = `ZeroWord;

        case (opcode)//先判断操作码
            `INST_TYPE_I: begin      //短立即数和访存load操作   立即数类型  I type 
                case (funct3)
                //当多个条件选项下需要执行相同的语句时，多个条件选项可以用逗号分开，放在同一个语句块的候选项中。
                    `INST_ADDI, `INST_SLTI, `INST_SLTIU, `INST_XORI, `INST_ORI, `INST_ANDI, `INST_SLLI, `INST_SRI: begin//寄存器的值和立即数的值进行各种逻辑运算
                        reg_we_o = `WriteEnable;        // 写通用寄存器标志   
                        reg_waddr_o = rd;               //目标寄存器（写通用寄存器地址）
                        reg1_raddr_o = rs1;             //源寄存器1的地址，去通用寄存器模块中取reg1_rdata_i数据。
                        reg2_raddr_o = `ZeroReg;
                        op1_o = reg1_rdata_i;            //rs1地址从reg中取回的数据。
                        op2_o = {{20{inst_i[31]}}, inst_i[31:20]};  //指令中的立即数
                    end
                    default: begin
                        reg_we_o     = `WriteDisable;
                        reg_waddr_o  = `ZeroReg;
                        reg1_raddr_o = `ZeroReg;
                        reg2_raddr_o = `ZeroReg;
                    end
                endcase
            end
            `INST_TYPE_R_M: begin    // 寄存器类型——乘除法拓展型
                if ((funct7 == 7'b0000000) || (funct7 == 7'b0100000)) begin //R指令 寄存器类型        //基础寄存器型指令
                    case (funct3)
                        `INST_ADD_SUB, `INST_SLL, `INST_SLT, `INST_SLTU, `INST_XOR, `INST_SR, `INST_OR, `INST_AND: begin
                            reg_we_o = `WriteEnable;//设置写寄存器标志为1，表示执行模块结束后的下一个时钟需要写寄存器。
                            reg_waddr_o = rd;//设置写寄存器地址为rd，rd的值为指令编码里的第5部分内容。
                            reg1_raddr_o = rs1;//设置读寄存器1的地址为rs1，rs1的值为指令编码里的第3部分内容。
                            reg2_raddr_o = rs2;//设置读寄存器2的地址为rs2，rs2的值为指令编码里的第2部分内容。
                            op1_o = reg1_rdata_i;
                            op2_o = reg2_rdata_i;
                        end
                        default: begin
                            reg_we_o = `WriteDisable;
                            reg_waddr_o = `ZeroReg;
                            reg1_raddr_o = `ZeroReg;
                            reg2_raddr_o = `ZeroReg;
                        end
                    endcase
                end else if (funct7 == 7'b0000001) begin     //M指令 乘除法拓展指令           
                    case (funct3)
                        `INST_MUL, `INST_MULHU, `INST_MULH, `INST_MULHSU: begin
                            reg_we_o = `WriteEnable;
                            reg_waddr_o = rd;
                            reg1_raddr_o = rs1;
                            reg2_raddr_o = rs2;
                            op1_o = reg1_rdata_i;
                            op2_o = reg2_rdata_i;
                        end
                        `INST_DIV, `INST_DIVU, `INST_REM, `INST_REMU: begin
                            reg_we_o = `WriteDisable;
                            reg_waddr_o = rd;
                            reg1_raddr_o = rs1;
                            reg2_raddr_o = rs2;
                            op1_o = reg1_rdata_i;
                            op2_o = reg2_rdata_i;
                            op1_jump_o = inst_addr_i;
                            op2_jump_o = 32'h4;
                        end
                        default: begin
                            reg_we_o = `WriteDisable;
                            reg_waddr_o = `ZeroReg;
                            reg1_raddr_o = `ZeroReg;
                            reg2_raddr_o = `ZeroReg;
                        end
                    endcase
                end else begin
                    reg_we_o = `WriteDisable;
                    reg_waddr_o = `ZeroReg;
                    reg1_raddr_o = `ZeroReg;
                    reg2_raddr_o = `ZeroReg;
                end
            end
            //在译码阶段如果识别出是内存访问指令(lb、lh、lw、lbu、lhu、sb、sh、sw)，则向总线发出内存访问请求，
            `INST_TYPE_L: begin
                case (funct3)
                    `INST_LB, `INST_LH, `INST_LW, `INST_LBU, `INST_LHU: begin
                        reg_we_o = `WriteEnable;
                        reg1_raddr_o = rs1;
                        reg2_raddr_o = `ZeroReg;
                        reg_waddr_o = rd;
                        op1_o = reg1_rdata_i;
                        op2_o = {{20{inst_i[31]}}, inst_i[31:20]};
                    end
                    default: begin
                        reg1_raddr_o = `ZeroReg;
                        reg2_raddr_o = `ZeroReg;
                        reg_we_o = `WriteDisable;
                        reg_waddr_o = `ZeroReg;
                    end
                endcase
            end
            `INST_TYPE_S: begin
                case (funct3)
                    `INST_SB, `INST_SW, `INST_SH: begin
                        reg1_raddr_o = rs1;
                        reg2_raddr_o = rs2;
                        reg_we_o = `WriteDisable;
                        reg_waddr_o = `ZeroReg;
                        op1_o = reg1_rdata_i;
                        op2_o = {{20{inst_i[31]}}, inst_i[31:25], inst_i[11:7]};
                    end
                    default: begin
                        reg1_raddr_o = `ZeroReg;
                        reg2_raddr_o = `ZeroReg;
                        reg_we_o = `WriteDisable;
                        reg_waddr_o = `ZeroReg;
                    end
                endcase
            end
            `INST_TYPE_B: begin
                case (funct3)
                    `INST_BEQ, `INST_BNE, `INST_BLT, `INST_BGE, `INST_BLTU, `INST_BGEU: begin
                        reg1_raddr_o = rs1;
                        reg2_raddr_o = rs2;
                        reg_we_o = `WriteDisable;
                        reg_waddr_o = `ZeroReg;
                        op1_o = reg1_rdata_i;
                        op2_o = reg2_rdata_i;
                        op1_jump_o = inst_addr_i;
                        op2_jump_o = {{20{inst_i[31]}}, inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0};
                    end
                    default: begin
                        reg1_raddr_o = `ZeroReg;
                        reg2_raddr_o = `ZeroReg;
                        reg_we_o = `WriteDisable;
                        reg_waddr_o = `ZeroReg;
                    end
                endcase
            end
            `INST_JAL: begin
                reg_we_o = `WriteEnable;
                reg_waddr_o = rd;
                reg1_raddr_o = `ZeroReg;
                reg2_raddr_o = `ZeroReg;
                op1_o = inst_addr_i;
                op2_o = 32'h4;
                op1_jump_o = inst_addr_i;
                op2_jump_o = {{12{inst_i[31]}}, inst_i[19:12], inst_i[20], inst_i[30:21], 1'b0};
            end
            `INST_JALR: begin
                reg_we_o = `WriteEnable;
                reg1_raddr_o = rs1;
                reg2_raddr_o = `ZeroReg;
                reg_waddr_o = rd;
                op1_o = inst_addr_i;
                op2_o = 32'h4;
                op1_jump_o = reg1_rdata_i;
                op2_jump_o = {{20{inst_i[31]}}, inst_i[31:20]};
            end
            `INST_LUI: begin
                reg_we_o = `WriteEnable;
                reg_waddr_o = rd;
                reg1_raddr_o = `ZeroReg;
                reg2_raddr_o = `ZeroReg;
                op1_o = {inst_i[31:12], 12'b0};
                op2_o = `ZeroWord;
            end
            `INST_AUIPC: begin
                reg_we_o = `WriteEnable;
                reg_waddr_o = rd;
                reg1_raddr_o = `ZeroReg;
                reg2_raddr_o = `ZeroReg;
                op1_o = inst_addr_i;
                op2_o = {inst_i[31:12], 12'b0};
            end
             `INST_NOP_OP: begin //无操作
                reg_we_o = `WriteDisable;
                reg_waddr_o = `ZeroReg;
                reg1_raddr_o = `ZeroReg;
                reg2_raddr_o = `ZeroReg;
            end
            `INST_FENCE: begin
                reg_we_o = `WriteDisable;
                reg_waddr_o = `ZeroReg;
                reg1_raddr_o = `ZeroReg;
                reg2_raddr_o = `ZeroReg;
                op1_jump_o = inst_addr_i;
                op2_jump_o = 32'h4;  //可能是跳转指令的操作
            end
            `INST_CSR: begin
                reg_we_o = `WriteDisable;
                reg_waddr_o = `ZeroReg;
                reg1_raddr_o = `ZeroReg;
                reg2_raddr_o = `ZeroReg;
                csr_raddr_o = {20'h0, inst_i[31:20]};
                csr_waddr_o = {20'h0, inst_i[31:20]};
                case (funct3)
                    `INST_CSRRW, `INST_CSRRS, `INST_CSRRC: begin
                        reg1_raddr_o = rs1;
                        reg2_raddr_o = `ZeroReg;
                        reg_we_o = `WriteEnable;
                        reg_waddr_o = rd;
                        csr_we_o = `WriteEnable;
                    end
                    `INST_CSRRWI, `INST_CSRRSI, `INST_CSRRCI: begin
                        reg1_raddr_o = `ZeroReg;
                        reg2_raddr_o = `ZeroReg;
                        reg_we_o = `WriteEnable;
                        reg_waddr_o = rd;
                        csr_we_o = `WriteEnable;
                    end
                    default: begin
                        reg_we_o = `WriteDisable;
                        reg_waddr_o = `ZeroReg;
                        reg1_raddr_o = `ZeroReg;
                        reg2_raddr_o = `ZeroReg;
                        csr_we_o = `WriteDisable;
                    end
                endcase
            end
            default: begin
                reg_we_o = `WriteDisable;
                reg_waddr_o = `ZeroReg;
                reg1_raddr_o = `ZeroReg;
                reg2_raddr_o = `ZeroReg;
            end
        endcase
    end
endmodule
