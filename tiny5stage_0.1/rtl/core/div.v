
`include "defines.v"
// 除法模块（硬件中所有数据，以补码的形式存储！！!）
// 试商法实现32位整数除法
// 每次除法运算至少需要33个时钟周期才能完成
module div(
    input wire clk,
    input wire rst,
    // from ex
    input wire[`RegBus] dividend_i,      // 被除数
    input wire[`RegBus] divisor_i,       // 除数
    input wire start_i,                  // 开始信号，运算期间这个信号需要一直保持有效
    input wire[2:0] op_i,                // 具体是哪一条指令
    input wire[`RegAddrBus] reg_waddr_i, // 运算结束后需要写的寄存器
    // to ex
    output reg[`RegBus] result_o,        // 除法结果，高32位是余数，低32位是商
    output reg ready_o,                  // 运算结束信号
    output reg busy_o,                   // 正在运算信号
    output reg[`RegAddrBus] reg_waddr_o  // 运算结束后需要写的寄存器
    );
    // 状态定义
    localparam STATE_IDLE  = 4'b0001;//localparam不能在外部修改
    localparam STATE_START = 4'b0010;
    localparam STATE_CALC  = 4'b0100;
    localparam STATE_END   = 4'b1000;

    reg[`RegBus] dividend_r;
    reg[`RegBus] divisor_r;
    reg[2:0] op_r;
    reg[3:0] state;
    reg[31:0] count;
    reg[`RegBus] div_result; //商的结果
    reg[`RegBus] div_remain;//余数的结果
    reg[`RegBus] minuend;
    reg invert_result;

    wire op_div = (op_r == `INST_DIV); //有符号除法，结果为商
    wire op_divu = (op_r == `INST_DIVU);//无符号除法，结果为商
    wire op_rem = (op_r == `INST_REM);//有符号余数
    wire op_remu = (op_r == `INST_REMU);//无符号余数

    wire[31:0] dividend_invert = (-dividend_r); //等效于将数据取反加一  
    wire[31:0] divisor_invert = (-divisor_r);
    wire minuend_ge_divisor = (minuend >= divisor_r);
    wire[31:0] minuend_sub_res = minuend - divisor_r;
    //每一个步骤的结果：如果被减数大于除数，则该结果位为1。
    wire[31:0] div_result_tmp = minuend_ge_divisor? ({div_result[30:0], 1'b1}): ({div_result[30:0], 1'b0});
    //每一个步骤的减数的高31位：如果被减数大于除数，则保留差值的低31位。
    wire[31:0] minuend_tmp = minuend_ge_divisor? minuend_sub_res[30:0]: minuend[30:0];

    // 状态机实现
    always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            state <= STATE_IDLE;
            ready_o <= `DivResultNotReady;
            result_o <= `ZeroWord;
            div_result <= `ZeroWord;
            div_remain <= `ZeroWord;
            op_r <= 3'h0;
            reg_waddr_o <= `ZeroWord;
            dividend_r <= `ZeroWord;
            divisor_r <= `ZeroWord;
            minuend <= `ZeroWord;
            invert_result <= 1'b0;
            busy_o <= `False;
            count <= `ZeroWord;
        end else begin
            case (state)
                STATE_IDLE: begin //给寄存器赋初值
                    if (start_i == `DivStart) begin
                        op_r <= op_i;
                        dividend_r <= dividend_i;
                        divisor_r <= divisor_i;
                        reg_waddr_o <= reg_waddr_i;
                        state <= STATE_START;
                        busy_o <= `True;
                    end else begin
                        op_r <= 3'h0;
                        reg_waddr_o <= `ZeroWord;
                        dividend_r <= `ZeroWord;
                        divisor_r <= `ZeroWord;
                        ready_o <= `DivResultNotReady;
                        result_o <= `ZeroWord;
                        busy_o <= `False;
                    end
                end

                STATE_START: begin //
                    if (start_i == `DivStart) begin
                      // 1.除数为0，直接输出结果
                        if (divisor_r == `ZeroWord) begin// 如果除数为0
                            if (op_div | op_divu) begin
                                result_o <= 32'hffffffff;
                            end else begin
                                result_o <= dividend_r;
                            end
                            ready_o <= `DivResultReady;// 表示运算结束
                            state <= STATE_IDLE;
                            busy_o <= `False;
                      // 2.除数不为0（将有符号除法等式两边的负数转化为近似补码的形式）
                        end else begin
                            busy_o <= `True;
                            count <= 32'h40000000;
                            state <= STATE_CALC;
                            div_result <= `ZeroWord;
                            div_remain <= `ZeroWord;

                            // DIV和REM这两条指令是有符号数运算指令
                            if (op_div | op_rem) begin
                                // 被除数求补码（将数据取反加一  ）
                                if (dividend_r[31] == 1'b1) begin
                                    dividend_r <= dividend_invert;
                                    minuend <= dividend_invert[31];//0
                                end else begin
                                    minuend <= dividend_r[31];//0
                                end
                                // 除数求补码（将数据取反加一  ）
                                if (divisor_r[31] == 1'b1) begin
                                    divisor_r <= divisor_invert;
                                end
                            end else begin
                                minuend <= dividend_r[31];
                            end

                            // 运算结束后是否要对结果取补码（将数据取反加一  ）
                            if ((op_div && (dividend_r[31] ^ divisor_r[31] == 1'b1))
                                || (op_rem && (dividend_r[31] == 1'b1))) begin //运算结果为负数
                                invert_result <= 1'b1;
                            end else begin
                                invert_result <= 1'b0;
                            end
                        end
                    end else begin//未进行除法操作
                        state <= STATE_IDLE;
                        result_o <= `ZeroWord;
                        ready_o <= `DivResultNotReady;
                        busy_o <= `False;
                    end
                end

                STATE_CALC: begin//试商法的过程，需要31个时钟
                    if (start_i == `DivStart) begin
                        dividend_r <= {dividend_r[30:0], 1'b0};//逻辑左移
                        div_result <= div_result_tmp;
                        count <= {1'b0, count[31:1]};//逻辑右移
                        if (|count) begin //逻辑右移31次后，计算完成
                            minuend <= {minuend_tmp[30:0], dividend_r[30]};
                        end else begin
                            state <= STATE_END;
                            if (minuend_ge_divisor) begin
                                div_remain <= minuend_sub_res;//正好除尽
                            end else begin
                                div_remain <= minuend;//没有除尽
                            end
                        end
                    end else begin
                        state <= STATE_IDLE;
                        result_o <= `ZeroWord;
                        ready_o <= `DivResultNotReady;
                        busy_o <= `False;
                    end
                end

                STATE_END: begin //结束除法运算，并给出最后的计算结果。
                    if (start_i == `DivStart) begin
                        ready_o <= `DivResultReady;
                        state <= STATE_IDLE;
                        busy_o <= `False;
                        if (op_div | op_divu) begin
                            if (invert_result) begin
                                result_o <= (-div_result);////等效于将数据取反加一  
                            end else begin
                                result_o <= div_result;
                            end
                        end else begin
                            if (invert_result) begin
                                result_o <= (-div_remain);
                            end else begin
                                result_o <= div_remain;
                            end
                        end
                    end else begin
                        state <= STATE_IDLE;
                        result_o <= `ZeroWord;
                        ready_o <= `DivResultNotReady;
                        busy_o <= `False;
                    end
                end
            endcase
        end
    end

endmodule
