`include "baud_gen.v"
`include "edge_detector.v"

module uart_receiver (
    input wire sys_clk,
    input wire rst_n,
    input wire serial_data_in,
    output reg [7:0] parallel_data_out,
    output reg data_valid,
    output reg busy
);
    wire baud_clk;
    wire start_detect_pulse;
    reg start_flag;

    // Baud rate generator block
    baud_gen b_gen (
        .sys_clk(sys_clk),
        .rst_n(rst_n),
        .baud_clk(baud_clk)
    );

    // Edge detector runs on the high-speed sys_clk to catch the exact edge transition
    edge_detector ed_det (
        .sys_clk(sys_clk),
        .rst_n(rst_n),
        .signal_in(serial_data_in),
        .neg_edge(start_detect_pulse)
    );

    // Catch the brief edge pulse and hold it high until the FSM leaves IDLE
    always @(negedge sys_clk or negedge rst_n) begin
        if (!rst_n) begin
            start_flag <= 1'b0;
        end else begin
            if (start_detect_pulse)
                start_flag <= 1'b1;
            else if (state != IDLE) // Clear the flag once the FSM acknowledges it
                start_flag <= 1'b0;
        end
    end

    // FSM States
    localparam IDLE  = 2'b00;
    localparam SHIFT = 2'b01;
    localparam LOAD  = 2'b10;
    localparam WAIT  = 2'b11;

    reg [1:0] state, next_state;
    reg [3:0] bit_count;
    reg [10:0] rx_shift_reg;

    // FSM State Register
    always @(posedge baud_clk or negedge rst_n) begin
        if (!rst_n) state <= IDLE;
        else        state <= next_state;
    end

    // Next State Logic
    always @(*) begin
        case (state)
            IDLE:  next_state = start_flag ? SHIFT : IDLE;
            SHIFT: next_state = (bit_count >= 4'd10) ? LOAD : SHIFT;
            LOAD:  next_state = WAIT;
            WAIT:  next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    // Datapath Output Logic
    always @(negedge baud_clk or negedge rst_n) begin
        if (!rst_n) begin
            parallel_data_out <= 8'b0;
            data_valid        <= 1'b0;
            busy              <= 1'b0;
            bit_count         <= 4'd0;
            rx_shift_reg      <= 11'b0;
        end else begin
            case (state)
                IDLE: begin
                    data_valid <= 1'b0;
                    busy       <= 1'b0;
                    bit_count  <= 4'd0;
                end
                SHIFT: begin
                    busy         <= 1'b1;
                    rx_shift_reg <= {serial_data_in, rx_shift_reg[10:1]};
                    bit_count    <= bit_count + 1'b1;
                end
                LOAD: begin
                    busy <= 1'b1;
                    // Check if the calculated odd parity of data bits matches the received parity bit
                    if (~(^rx_shift_reg[8:1]) == rx_shift_reg[9]) begin
                        parallel_data_out <= rx_shift_reg[8:1]; 
                        data_valid        <= 1'b1;
                    end
                end
                WAIT: begin
                    busy       <= 1'b0;
                    data_valid <= 1'b0;
                end
            endcase
        end
    end
endmodule