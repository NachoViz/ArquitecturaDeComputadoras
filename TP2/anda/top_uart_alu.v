`timescale 1ns / 1ps

module top_uart_alu
#(
    parameter NB_DATA  = 8,     // Ancho de datos: 8 bits
    parameter NB_OP    = 6,     // Código de operación: 6 bits
    parameter DVSR     = 326,   // Divisor baud rate: 100 MHz / (19200 * 16)
    parameter DVSR_BIT = 9      // Bits para contar hasta 326
)
(
    // --- Puertos físicos de la placa Basys 3 ---
    input  wire         clk,     // Reloj de 100 MHz (Pin W5)
    input  wire         i_reset, // Botón central (Pin U18)
    input  wire         i_rx,    // Cable USB-UART: PC -> FPGA (Pin B18)
    output wire         o_tx,    // Cable USB-UART: FPGA -> PC (Pin A18)
    output wire [15:0]  o_led    // 16 LEDs (LD0 a LD15)
);

    // =========================================================================
    // 1. SINCRONIZADOR DE 2 FLIP-FLOPS (Antimetaestabilidad)
    // =========================================================================
    // La señal i_rx viene de la PC (asincrónica). La pasamos por dos flip-flops
    // para que entre limpia y sincronizada al reloj de 100 MHz de la FPGA.
    reg rx_meta, rx_sync;
    always @(posedge clk) begin
        if (i_reset) begin
            rx_meta <= 1'b1;  // La línea serie en reposo es 1
            rx_sync <= 1'b1;
        end
        else begin
            rx_meta <= i_rx;
            rx_sync <= rx_meta;
        end
    end

    // =========================================================================
    // 2. CABLES DE INTERCONEXIÓN INTERNA
    // =========================================================================
    // Cables entre la UART y la Interfaz (intf)
    wire [NB_DATA-1:0] r_data;      // Byte que sale de la FIFO RX hacia intf
    wire [NB_DATA-1:0] w_data;      // Byte que sale de intf hacia la FIFO TX
    wire               rd_uart;     // Pulso de intf: "ya leí el byte recibido"
    wire               wr_uart;     // Pulso de intf: "escribí este resultado en la cola TX"
    wire               rx_empty;    // Flag de UART: "no hay bytes recibidos"
    wire               tx_full;     // Flag de UART: "la cola de salida está llena"

    // Cables entre la Interfaz (intf) y la ALU
    wire [NB_DATA-1:0] alu_a;       // Operando A guardado en intf
    wire [NB_DATA-1:0] alu_b;       // Operando B guardado en intf
    wire [NB_OP-1:0]   alu_op;      // Operación guardada en intf
    wire [NB_DATA-1:0] alu_result;  // Resultado calculado por la ALU
    wire               alu_carry;   // Carry calculado por la ALU

    // Señales de diagnóstico para los LEDs
    wire               carry_flag;  // Carry registrado en intf
    wire [3:0]         intf_state;  // Estado actual de la FSM (one-hot)

    // =========================================================================
    // 3. INSTANCIACIÓN DE LOS 3 BLOQUES PRINCIPALES
    // =========================================================================

    // Bloque 1: UART (Baud Generator + RX + TX + FIFOs)
    uart #(
        .DBIT     (NB_DATA),
        .SB_TICK  (16),
        .DVSR     (DVSR),
        .DVSR_BIT (DVSR_BIT),
        .FIFO_W   (4)
    ) u_uart (
        .clk      (clk),
        .reset    (i_reset),
        .rd_uart  (rd_uart),    // Orden de lectura desde intf
        .wr_uart  (wr_uart),    // Orden de escritura desde intf
        .w_data   (w_data),     // Resultado de la ALU para transmitir
        .r_data   (r_data),     // Byte recibido para que lea intf
        .rx_empty (rx_empty),   // Avisa a intf si hay datos
        .tx_full  (tx_full),    // Avisa a intf si hay lugar
        .rx       (rx_sync),    // Viene del sincronizador
        .tx       (o_tx)        // Sale al pin físico hacia la PC
    );

    // Bloque 2: Circuito de Interfaz (FSM de 4 pasos)
    intf #(
        .NB_DATA (NB_DATA),
        .NB_OP   (NB_OP)
    ) u_intf (
        .clk          (clk),
        .reset        (i_reset),
        // Lado UART
        .r_data       (r_data),
        .rx_empty     (rx_empty),
        .rd           (rd_uart),
        .w_data       (w_data),
        .wr           (wr_uart),
        .tx_full      (tx_full),
        // Lado ALU
        .o_alu_a      (alu_a),
        .o_alu_b      (alu_b),
        .o_alu_op     (alu_op),
        .i_alu_result (alu_result),
        .i_alu_carry  (alu_carry),
        // Lado LEDs
        .o_carry_flag (carry_flag),
        .o_state      (intf_state)
    );

    // Bloque 3: Tu ALU del TP1 (Combinacional pura)
    ALU #(
        .N_BITS (NB_DATA),
        .N_OP   (NB_OP)
    ) u_alu (
        .in_a     (alu_a),
        .in_b     (alu_b),
        .in_op    (alu_op),
        .o_result (alu_result),
        .o_carry  (alu_carry)
    );

    // =========================================================================
    // 4. ASIGNACIÓN A LOS 16 LEDS
    // =========================================================================
    // [15:12] = Estado de la FSM (LOAD_A=0001, LOAD_B=0010, LOAD_OP=0100, SEND=1000)
    // [11:9]  = 3 bits apagados (separador)
    // [8]     = Bandera de Carry
    // [7:0]   = Resultado de la ALU en binario
    assign o_led = {intf_state, 3'b000, carry_flag, alu_result};

endmodule
