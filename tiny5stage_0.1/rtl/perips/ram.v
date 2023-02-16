
`include "../core/defines.v"

// ram module
module ram(

    input wire clk,
    input wire rst,

    input wire we_i,                   // write enable
    input wire[`MemAddrBus] addr_i,    // addr
    input wire[`MemBus] data_i,

    output reg[`MemBus] data_o         // read data

    );

    reg[`MemBus] _ram[0:`MemNum - 1];

//写RAM
    always @ (posedge clk) begin
        if (we_i == `WriteEnable) begin
     //从内核中输入的地址，是以0，4，8，C间隔变化， 
     //为了将数据按顺序依次存放在RAM(0,1,2,3...)地址中， 
     //所以采用地址的高30位，作为输入地址。     
            _ram[addr_i[31:2]] <= data_i;
        end
    end
//读RAM
    always @ (*) begin
        if (rst == `RstEnable) begin
            data_o = `ZeroWord;
        end else begin
            data_o = _ram[addr_i[31:2]];//将RAM中地址addr_i[31:2]中的数据读出
        end
    end

endmodule
