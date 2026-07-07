`ifndef PARITY_GEN_V
`define PARITY_GEN_V

module parity_gen (
    input wire [7:0] tx_data_in,
    input wire even_odd, 
    output reg parity_bit
);
    always @(*) begin
        if (even_odd) begin
            parity_bit = ~(^tx_data_in); // Odd parity bit calculation
        end else begin
            parity_bit = ^tx_data_in;   // Even parity bit calculation
        end
    end
endmodule

`endif