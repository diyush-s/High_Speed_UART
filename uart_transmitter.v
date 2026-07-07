`include "baud_gen.v"
`include "parity_gen.v"

module uart_transmitter (
    input wire sys_clk,
    input wire rst_n,
    input wire tx_enable,
    input wire [7:0] tx_data_in,
    input wire even_odd,
    output reg serial_out,
    output reg busy
);
    wire baud_clk;
    wire parity_bit;
    
    baud_gen b_gen (
        .sys_clk(sys_clk),
        .rst_n(rst_n),
        .baud_clk(baud_clk)
    );

    parity_gen p_gen (
        .tx_data_in(tx_data_in),
        .even_odd(even_odd),
        .parity_bit(parity_bit)
    );

    localparam IDLE  = 2'b00;
    localparam LOAD  = 2'b01;
    localparam SHIFT = 2'b10;
    localparam WAIT  = 2'b11;

    reg [1:0] state, next_state;
    reg [10:0] tx_shift_reg; 
    reg [3:0] bit_count;

    always @(posedge baud_clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    always @(*) begin
        case (state)
            IDLE:  next_state = tx_enable ? LOAD : IDLE;
            LOAD:  next_state = SHIFT;
            SHIFT: next_state = (bit_count >= 4'd11) ? WAIT : SHIFT;
            WAIT:  next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    always @(posedge baud_clk or negedge rst_n) begin
        if (!rst_n) begin
            serial_out   <= 1'b1;
            busy         <= 1'b0;
            bit_count    <= 4'd0;
            tx_shift_reg <= 11'h7FF;
        end else begin
            case (state)
                IDLE: begin
                    serial_out <= 1'b1;
                    busy       <= 1'b0;
                    bit_count  <= 4'd0;
                end
                LOAD: begin
                    busy         <= 1'b1;
                    tx_shift_reg <= {1'b1, parity_bit, tx_data_in, 1'b0}; 
                end
                SHIFT: begin
                    busy         <= 1'b1;
                    serial_out   <= tx_shift_reg[0];
                    tx_shift_reg <= {1'b1, tx_shift_reg[10:1]};
                    bit_count    <= bit_count + 1'b1;
                end
                WAIT: begin
                    busy      <= 1'b0;
                    bit_count <= 4'd0;
                end
            endcase
        end
    end
endmodule