`timescale 1ns / 1ps

module top_system #(
    parameter NBIT   = 8,   // Cantidad de bits de datos
    parameter N_TICK = 16,  // Sobremuestreo de 16x ticks por bit
    parameter M      = 163, // Divisor para f_clk = 50 MHz y 19200 baudios
    parameter N      = 8    // Ancho en bits del contador de baud_gen
)(
    input  wire clock,
    input  wire reset,
    input  wire rx,         // Entrada serie desde el exterior (UART RX)
    output wire tx          // Salida serie hacia el exterior (UART TX)
);

    // =========================================================================
    // Cableado Interno de Interconexión
    // =========================================================================
    
    // Generador de baudios hacia RX y TX
    wire s_tick;

    // Receptor UART (uart_rx) -> Interfaz (interfaz)
    wire [NBIT-1:0] rx_dout;
    wire            rx_done;

    // Interfaz (interfaz) <-> ALU (alu)
    wire [7:0] alu_A;
    wire [7:0] alu_B;
    wire [5:0] alu_OP;
    wire [7:0] alu_out;
    wire       alu_zero;

    // Interfaz (interfaz) -> Transmisor UART (uart_tx)
    wire [NBIT-1:0] tx_din;
    wire            tx_start;

    // Transmisor UART (uart_tx) -> Interfaz (interfaz)
    wire tx_done;

    // =========================================================================
    // 1. Generador de Tasa de Baudios (Baud Rate Generator)
    // =========================================================================
    baud_gen #(
        .M(M),
        .N(N)
    ) baud_gen_unit (
        .clk    (clock),
        .reset  (reset),
        .s_tick (s_tick)
    );

    // =========================================================================
    // 2. Subsistema Receptor UART (uart_rx)
    // =========================================================================
    uart_rx #(
        .NBIT(NBIT),
        .N_TICK(N_TICK)
    ) rx_unit (
        .clock     (clock),
        .i_reset   (reset),
        .i_rx      (rx),
        .i_s_tick  (s_tick),
        .o_rx_done (rx_done),
        .o_dout    (rx_dout)
    );

    // =========================================================================
    // 3. Circuito de Interfaz y Control de Datos (interfaz)
    // =========================================================================
    interfaz intf_unit (
        .clock    (clock),
        .reset    (reset),
        .rx_dout  (rx_dout),
        .rx_done  (rx_done),
        .tx_din   (tx_din),
        .tx_start (tx_start),
        .tx_done  (tx_done),
        .alu_A    (alu_A),
        .alu_B    (alu_B),
        .alu_OP   (alu_OP),
        .alu_out  (alu_out),
        .alu_zero (alu_zero)
    );

    // =========================================================================
    // 4. Unidad Aritmético Lógica (alu)
    // =========================================================================
    alu alu_unit (
        .A    (alu_A),
        .B    (alu_B),
        .OP   (alu_OP),
        .Out  (alu_out),
        .Zero (alu_zero)
    );

    // =========================================================================
    // 5. Subsistema Transmisor UART (uart_tx)
    // =========================================================================
    uart_tx #(
        .DBIT(NBIT)             // Se cambió .NBIT por .DBIT y se eliminó .N_TICK
    ) tx_unit (
        .clk          (clock),    // Se cambió .clock por .clk
        .reset        (reset),    // Se cambió .i_reset por .reset
        .tx_start     (tx_start), // Se cambió .i_tx_start por .tx_start
        .s_tick       (s_tick),   // Se cambió .i_s_tick por .s_tick
        .din          (tx_din),   // (Se mantiene igual)
        .tx_done_tick (tx_done),  // Se cambió .o_tx_done por .tx_done_tick
        .tx           (tx)        // Se cambió .o_tx por .tx
    );
endmodule