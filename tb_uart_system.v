`timescale 1ns/1ps
`include "uart_transmitter.v"
`include "uart_receiver.v"

module tb_uart_system;
    reg sys_clk;
    reg rst_n;
    reg tx_enable;
    reg [7:0] tx_data_in;
    reg even_odd;

    wire serial_line;
    wire tx_busy;
    wire rx_busy;
    wire rx_data_valid;
    wire [7:0] rx_parallel_out;

    uart_transmitter tx_inst (
        .sys_clk(sys_clk),
        .rst_n(rst_n),
        .tx_enable(tx_enable),
        .tx_data_in(tx_data_in),
        .even_odd(even_odd),
        .serial_out(serial_line),
        .busy(tx_busy)
    );

    uart_receiver rx_inst (
        .sys_clk(sys_clk),
        .rst_n(rst_n),
        .serial_data_in(serial_line),
        .parallel_data_out(rx_parallel_out),
        .data_valid(rx_data_valid),
        .busy(rx_busy)
    );

    // 64 MHz Clock Generator
    always #7.8125 sys_clk = ~sys_clk;

    initial begin
        $dumpfile("uart_simulation.vcd");
        $dumpvars(0, tb_uart_system);

        sys_clk    = 0;
        rst_n      = 0;
        tx_enable  = 0;
        tx_data_in = 8'b0;
        even_odd   = 1'b1; // Odd parity configuration

        #50;
        rst_n = 1; 
        #50;

        // Packet 1: 8'hAA
        tx_data_in = 8'hAA;
        tx_enable  = 1;
        #300;
        tx_enable  = 0;

        @(posedge rx_data_valid);
        $display("[TIME: %t] Captured: 0x%h (Expected: 0xAA)", $time, rx_parallel_out);
        
        #5000;
        
        // Packet 2: 8'hCC
        tx_data_in = 8'hCC;
        tx_enable  = 1;
        #300;
        tx_enable  = 0;

        @(posedge rx_data_valid);
        $display("[TIME: %t] Captured: 0x%h (Expected: 0xCC)", $time, rx_parallel_out);

        #10000;
        $finish;
    end
endmodule