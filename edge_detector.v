`ifndef EDGE_DETECTOR_V
`define EDGE_DETECTOR_V

module edge_detector (
    input wire sys_clk,
    input wire rst_n,
    input wire signal_in,
    output wire neg_edge
);
    reg delay_reg;

    always @(posedge sys_clk or negedge rst_n) begin
        if (!rst_n) begin
            delay_reg <= 1'b1;
        end else begin
            delay_reg <= signal_in;
        end
    end
    
    assign neg_edge = delay_reg & ~signal_in;
endmodule

`endif