`include "defines.v"
//访存部分中的mem模块
//mem模块用于处理访存的指令
module mem(


    //from ex about mem
    input wire[31:0] inst_i,
    input wire[31:0] op1_add_op2_res_i,
    input wire[31:0] reg1_rdata_i,
    input wire[31:0] reg2_rdata_i, 
    input wire inst_assert_i,

    // from me
    input wire[`MemBus] me_rdata_i,        // 内存输入数据
    input wire int_assert_i,


    // to me
    output reg[31:0] me_wdata_o,     // 写内存数据
    output reg[31:0] me_raddr_o,    // 读内存地址
    output reg[31:0] me_waddr_o,    // 写内存地址
    
    output wire me_we_flag_o,                   // 是否要写内存
    output wire me_req_flag_o,                  // 请求访问内存标志

    //to mem_wb
    output reg[31:0] reg_wdata_o

    );

    wire[6:0] opcode;
    wire[2:0] funct3;
    wire[6:0] funct7;
    wire[1:0] me_raddr_index;
    wire[1:0] me_waddr_index;

    assign opcode = inst_i[6:0];
    assign funct3 = inst_i[14:12];
    assign funct7 = inst_i[31:25];

    assign me_raddr_index = (reg1_rdata_i + {{20{inst_i[31]}}, inst_i[31:20]}) & 2'b11;
    assign me_waddr_index = (reg1_rdata_i + {{20{inst_i[31]}}, inst_i[31:25], inst_i[11:7]}) & 2'b11;
 
   // assign mem_raddr_index = (reg1_rdata_i + {{20{inst_i[31]}}, inst_i[31:20]}) & 2'b11;
    //assign mem_waddr_index = (reg1_rdata_i + {{20{inst_i[31]}}, inst_i[31:25], inst_i[11:7]}) & 2'b11;


    // 响应中断时不写内存
    assign me_we_flag_o = (int_assert_i == `INT_ASSERT)? `WriteDisable: me_we_flag;

    // 响应中断时不向总线请求访问内存
    assign me_req_flag_o = (int_assert_i == `INT_ASSERT)? `RIB_NREQ: me_req_flag;

    
    reg me_we_flag;                   // 是否要写内存
    reg me_req_flag;                 // 请求访问内存标志



    always @ (*) begin

        case (opcode)
            `INST_TYPE_L: begin
                case (funct3)
                    `INST_LB: begin
                        //jump_flag = `JumpDisable;
                        //hold_flag = `HoldDisable;
                        //jump_addr = `ZeroWord;
                        me_wdata_o = `ZeroWord;
                        me_waddr_o = `ZeroWord;
                        me_we_flag = `WriteDisable;
                        me_req_flag = `RIB_REQ;
                        me_raddr_o = op1_add_op2_res_i;
                        case (me_raddr_index)
                            2'b00: begin
                                reg_wdata_o = {{24{me_rdata_i[7]}}, me_rdata_i[7:0]};
                            end
                            2'b01: begin
                                reg_wdata_o = {{24{me_rdata_i[15]}}, me_rdata_i[15:8]};
                            end
                            2'b10: begin
                                reg_wdata_o = {{24{me_rdata_i[23]}}, me_rdata_i[23:16]};
                            end
                            default: begin
                                reg_wdata_o = {{24{me_rdata_i[31]}}, me_rdata_i[31:24]};
                            end
                        endcase
                    end
                    `INST_LH: begin
                        //jump_flag = `JumpDisable;
                        //hold_flag = `HoldDisable;
                        //jump_addr = `ZeroWord;
                        me_wdata_o = `ZeroWord;
                        me_waddr_o = `ZeroWord;
                        me_we_flag = `WriteDisable;
                        me_req_flag = `RIB_REQ;
                        me_raddr_o = op1_add_op2_res_i;
                        if (me_raddr_index == 2'b0) begin
                            reg_wdata_o = {{16{me_rdata_i[15]}}, me_rdata_i[15:0]};
                        end else begin
                            reg_wdata_o = {{16{me_rdata_i[31]}}, me_rdata_i[31:16]};
                        end
                    end
                    `INST_LW: begin
                        //jump_flag = `JumpDisable;
                        //hold_flag = `HoldDisable;
                        //jump_addr = `ZeroWord;
                        me_wdata_o = `ZeroWord;
                        me_waddr_o = `ZeroWord;
                        me_we_flag = `WriteDisable;
                        me_req_flag = `RIB_REQ;
                        me_raddr_o = op1_add_op2_res_i;
                        reg_wdata_o = me_rdata_i;
                    end
                    `INST_LBU: begin
                        //jump_flag = `JumpDisable;
                        //hold_flag = `HoldDisable;
                        //jump_addr = `ZeroWord;
                        me_wdata_o = `ZeroWord;
                        me_waddr_o = `ZeroWord;
                        me_we_flag = `WriteDisable;
                        me_req_flag = `RIB_REQ;
                        me_raddr_o = op1_add_op2_res_i;
                        case (me_raddr_index)
                            2'b00: begin
                                reg_wdata_o = {24'h0, me_rdata_i[7:0]};
                            end
                            2'b01: begin
                                reg_wdata_o = {24'h0, me_rdata_i[15:8]};
                            end
                            2'b10: begin
                                reg_wdata_o = {24'h0, me_rdata_i[23:16]};
                            end
                            default: begin
                                reg_wdata_o = {24'h0, me_rdata_i[31:24]};
                            end
                        endcase
                    end
                    `INST_LHU: begin
                        //jump_flag = `JumpDisable;
                        //hold_flag = `HoldDisable;
                        //jump_addr = `ZeroWord;
                        me_wdata_o = `ZeroWord;
                        me_waddr_o = `ZeroWord;
                        me_we_flag = `WriteDisable;
                        me_req_flag = `RIB_REQ;
                        me_raddr_o = op1_add_op2_res_i;
                        if (me_raddr_index == 2'b0) begin
                            reg_wdata_o = {16'h0, me_rdata_i[15:0]};
                        end else begin
                            reg_wdata_o = {16'h0, me_rdata_i[31:16]};
                        end
                    end
                    default: begin
                        //jump_flag = `JumpDisable;
                        //hold_flag = `HoldDisable;
                        //jump_addr = `ZeroWord;
                        me_wdata_o = `ZeroWord;
                        me_raddr_o = `ZeroWord;
                        me_waddr_o = `ZeroWord;
                        me_we_flag = `WriteDisable;
                        reg_wdata_o = `ZeroWord;
                    end
                endcase
            end
            `INST_TYPE_S: begin
                case (funct3)
                    `INST_SB: begin
                        //jump_flag = `JumpDisable;
                        //hold_flag = `HoldDisable;
                        //jump_addr = `ZeroWord;
                        reg_wdata_o = `ZeroWord;
                        me_we_flag = `WriteEnable;
                        me_req_flag = `RIB_REQ;
                        me_waddr_o = op1_add_op2_res_i;
                        me_raddr_o = op1_add_op2_res_i;
                        case (me_waddr_index)
                            2'b00: begin
                                me_wdata_o = {me_rdata_i[31:8], reg2_rdata_i[7:0]};
                            end
                            2'b01: begin
                                me_wdata_o = {me_rdata_i[31:16], reg2_rdata_i[7:0], me_rdata_i[7:0]};
                            end
                            2'b10: begin
                                me_wdata_o = {me_rdata_i[31:24], reg2_rdata_i[7:0], me_rdata_i[15:0]};
                            end
                            default: begin
                                me_wdata_o = {reg2_rdata_i[7:0], me_rdata_i[23:0]};
                            end
                        endcase
                    end
                    `INST_SH: begin
                        //jump_flag = `JumpDisable;
                        //hold_flag = `HoldDisable;
                        //jump_addr = `ZeroWord;
                        reg_wdata_o = `ZeroWord;
                        me_we_flag = `WriteEnable;
                        me_req_flag = `RIB_REQ;
                        me_waddr_o = op1_add_op2_res_i;
                        me_raddr_o = op1_add_op2_res_i;
                        if (me_waddr_index == 2'b00) begin
                            me_wdata_o = {me_rdata_i[31:16], reg2_rdata_i[15:0]};
                        end else begin
                            me_wdata_o = {reg2_rdata_i[15:0], me_rdata_i[15:0]};
                        end
                    end
                    `INST_SW: begin
                        //jump_flag = `JumpDisable;
                        //hold_flag = `HoldDisable;
                        //jump_addr = `ZeroWord;
                        reg_wdata_o = `ZeroWord;
                        me_we_flag = `WriteEnable;
                        me_req_flag = `RIB_REQ;
                        me_waddr_o = op1_add_op2_res_i;
                        me_raddr_o = op1_add_op2_res_i;
                        me_wdata_o = reg2_rdata_i;
                    end
                    default: begin
                        //jump_flag = `JumpDisable;
                        //hold_flag = `HoldDisable;
                        //jump_addr = `ZeroWord;
                        me_wdata_o = `ZeroWord;
                        me_raddr_o = `ZeroWord;
                        me_waddr_o = `ZeroWord;
                        me_we_flag = `WriteDisable;
                        reg_wdata_o = `ZeroWord;
                    end
                endcase
            end
            default: begin
                me_wdata_o = `ZeroWord;
                me_raddr_o = `ZeroWord;
                me_waddr_o = `ZeroWord;
                me_we_flag = `WriteDisable;
                reg_wdata_o = `ZeroWord;
                me_req_flag = `RIB_NREQ;
            end
        endcase
    end


        





endmodule
