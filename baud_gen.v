`ifndef BAUD_GEN_V
`define BAUD_GEN_V

module baud_gen (
    input wire sys_clk,
    input wire rst_n,
    output reg baud_clk
);
    reg [3:0] counter;

    always @(posedge sys_clk or negedge rst_n) begin
        if (!rst_n) begin
            counter  <= 4'd0;
            baud_clk <= 1'b0;
        end else begin
            if (counter == 4'd7) begin // Toggles every 8 cycles for a divide-by-16 period
                counter  <= 4'd0;
                baud_clk <= ~baud_clk;
            end else begin
                counter <= counter + 1'b1;
            end
        end
    end
endmodule

`endif