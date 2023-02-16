
/*
`define CpuResetAddr 32'h0



*/
`define RstEnable 1'b0
`define RstDisable 1'b1
`define ZeroWord 32'h0
`define ZeroReg 5'h0
`define WriteEnable 1'b1
`define WriteDisable 1'b0
`define ReadEnable 1'b1
`define ReadDisable 1'b0
`define True 1'b1
`define False 1'b0
`define ChipEnable 1'b1
`define ChipDisable 1'b0
`define JumpEnable 1'b1
`define JumpDisable 1'b0
`define DivResultNotReady 1'b0
`define DivResultReady 1'b1
`define DivStart 1'b1
`define DivStop 1'b0
`define HoldEnable 1'b1
`define HoldDisable 1'b0
`define Stop 1'b1
`define NoStop 1'b0
`define RIB_ACK 1'b1
`define RIB_NACK 1'b0
`define RIB_REQ 1'b1
`define RIB_NREQ 1'b0
`define INT_ASSERT 1'b1
`define INT_DEASSERT 1'b0
`define INT_BUS 7:0
`define INT_NONE 8'h0
`define INT_RET 8'hff
`define INT_TIMER0 8'b00000001
`define INT_TIMER0_ENTRY_ADDR 32'h4

`define Hold_Flag_Bus   2:0
`define Hold_None 3'b000
`define Hold_Pc   3'b001
`define Hold_If   3'b010
`define Hold_Id   3'b011

// I type inst
`define INST_TYPE_I 7'b0010011     
`define INST_ADDI   3'b000			//立即数+寄存器
`define INST_SLTI   3'b010			//寄存器<立即数->则为1
`define INST_SLTIU  3'b011			//寄存器比较立即数，比较时视为无符号数，如果小则写入1
`define INST_XORI   3'b100			//寄存器与立即数按位异或
`define INST_ORI    3'b110			//立即数|寄存器
`define INST_ANDI   3'b111			//立即数&寄存器
`define INST_SLLI   3'b001			//寄存器<<立即数
`define INST_SRI    3'b101			//寄存器>>立即数

// L type inst								
`define INST_TYPE_L 7'b0000011
`define INST_LB     3'b000			//字节加载：从地址rs1+offset[7:0]中读取一个字节
`define INST_LH     3'b001			//半字节加载：从地址rs1+sext(offset)[15:0]读取两个字节
`define INST_LW     3'b010			//字加载：从地址rs1+sign-extend(offset)[31:0]读取四个字节
`define INST_LBU    3'b100			//无符号字节加载：从地址rs1+sign-extend(offset)[7:0]中读取一个字节
`define INST_LHU    3'b101			//无符号半字节加载：rs1+sign-extend(offset)[15:0]中读取两个字节

// S type inst
`define INST_TYPE_S 7'b0100011
`define INST_SB     3'b000			//存字节：将x[rs2]的低位字节存入地址x[rs1]+sign-extend(offset)
`define INST_SH     3'b001			//将 x[rs2]的低位 2 个字节存入内存地址 x[rs1]+sign-extend(offset)。
`define INST_SW     3'b010			//将 x[rs2]的低位 4 个字节存入内存地址 x[rs1]+sign-extend(offset)

// R and M type inst
`define INST_TYPE_R_M 7'b0110011	
// R type inst
`define INST_ADD_SUB 3'b000			//把寄存器 x[rs2]加到寄存器 x[rs1]上，结果写入 x[rd]。忽略算术溢出。
`define INST_SLL    3'b001			//把寄存器 x[rs1]左移 x[rs2]位，空出的位置填入 0，结果写入 x[rd]。 x[rs2]的低 5 位（如果是RV64I 则是低 6 位）代表移动位数，其高位则被忽略。	
`define INST_SLT    3'b010			//比较 x[rs1]和 x[rs2]中的数，如果 x[rs1]更小，向 x[rd]写入 1，否则写入 0。	
`define INST_SLTU   3'b011			//比较 x[rs1]和 x[rs2]，比较时视为无符号数。如果 x[rs1]更小，向 x[rd]写入 1，否则写入 0。
`define INST_XOR    3'b100          //x[rs1]和 x[rs2]按位异或，结果写入 x[rd]。
`define INST_SR     3'b101          //把寄存器 x[rs1]右移 x[rs2]位，空位用 x[rs1]的最高位填充，结果写入 x[rd]。 x[rs2]的低 5 位（如果是 RV64I 则是低 6 位）为移动位数，高位则被忽略。
`define INST_OR     3'b110          //
`define INST_AND    3'b111          //将寄存器 x[rs1]和寄存器 x[rs2]位与的结果写入 x[rd]。
// M type inst
`define INST_MUL    3'b000          //
`define INST_MULH   3'b001          //
`define INST_MULHSU 3'b010          //
`define INST_MULHU  3'b011          //
`define INST_DIV    3'b100			//用寄存器 x[rs1]的值除以寄存器 x[rs2]的值，向零舍入，将这些数视为二进制补码，把商写入 x[rd]
`define INST_DIVU   3'b101          //
`define INST_REM    3'b110          //
`define INST_REMU   3'b111          //

// J type inst
`define INST_JAL    7'b1101111
`define INST_JALR   7'b1100111

`define INST_LUI    7'b0110111
`define INST_AUIPC  7'b0010111
`define INST_NOP    32'h00000001
`define INST_NOP_OP 7'b0000001
`define INST_MRET   32'h30200073
`define INST_RET    32'h00008067

`define INST_FENCE  7'b0001111
`define INST_ECALL  32'h73
`define INST_EBREAK 32'h00100073

// J type inst
`define INST_TYPE_B 7'b1100011
`define INST_BEQ    3'b000
`define INST_BNE    3'b001
`define INST_BLT    3'b100
`define INST_BGE    3'b101
`define INST_BLTU   3'b110
`define INST_BGEU   3'b111

// CSR inst
`define INST_CSR    7'b1110011
`define INST_CSRRW  3'b001
`define INST_CSRRS  3'b010
`define INST_CSRRC  3'b011
`define INST_CSRRWI 3'b101
`define INST_CSRRSI 3'b110
`define INST_CSRRCI 3'b111

// CSR reg addr
`define CSR_CYCLE   12'hc00
`define CSR_CYCLEH  12'hc80
`define CSR_MTVEC   12'h305
`define CSR_MCAUSE  12'h342
`define CSR_MEPC    12'h341
`define CSR_MIE     12'h304
`define CSR_MSTATUS 12'h300
`define CSR_MSCRATCH 12'h340

`define RomNum 4096  // rom depth(how many words)

`define MemNum 4096  // memory depth(how many words)
`define MemBus 31:0
`define MemAddrBus 31:0

`define InstBus 31:0
`define InstAddrBus 31:0

// common regs
`define RegAddrBus 4:0
`define RegBus 31:0
`define DoubleRegBus 63:0
`define RegWidth 32
`define RegNum 32        // reg num
`define RegNumLog2 5
