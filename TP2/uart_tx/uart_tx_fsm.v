module uart_tx_fsm #(
    parameter NBIT   = 8,  // Cantidad de bits de datos a enviar
    parameter N_TICK = 16  // Tasa de sobremuestreo: 16 ticks = 1 baudio[cite: 4]
) (
    input wire       clock,
    input wire       i_reset,
    input wire       i_tx_start, // Señal externa que ordena iniciar la transmisión
    input wire       i_s_tick,   // Pulso que llega del Baud Rate Generator[cite: 4]
    
    // Entradas que vienen del Datapath (Señales de Estado)
    input wire [3:0] i_s_reg,    // Cuenta de ticks actual (0 a 15)
    input wire [2:0] i_n_reg,    // Cuenta de bits actual (0 a 7)
    input wire       i_b0,       // El bit 0 del shift register (el que toca enviar)
    input wire       i_p_reg,    // El bit de paridad ya calculado por el Datapath

    // Salidas de control hacia el Datapath (Órdenes)
    output reg       o_s_clr,    // Orden: "Limpia el contador de ticks"
    output reg       o_n_clr,    // Orden: "Limpia el contador de bits"
    output reg       o_n_incr,   // Orden: "Suma 1 al contador de bits"
    output reg       o_b_load,   // Orden: "Atrapa el byte paralelo entrante"
    output reg       o_b_shift,  // Orden: "Desplaza el registro 1 bit a la derecha"
    output reg       o_p_load,   // Orden: "Calcula la paridad ahora"
    
    // Salidas hacia el exterior
    output reg       o_tx_done,  // Señal: "Ya terminé de enviar toda la trama"
    output reg       o_tx        // Señal: Salida física serial
);

    // Codificación de los estados de la FSM
    localparam [2:0] IDLE   = 3'b000, // Reposo
                     START  = 3'b001, // Enviando bit de inicio (0)[cite: 4]
                     DATA   = 3'b010, // Enviando los 8 bits de datos[cite: 4]
                     PARITY = 3'b011, // Enviando bit de paridad[cite: 4]
                     STOP   = 3'b100; // Enviando bit de parada (1)[cite: 4]

    reg [2:0] state_reg, state_next;

    // =======================================================
    // BLOQUE 1: Memoria de Estado (Secuencial)
    // Se actualiza únicamente en cada flanco de subida del reloj[cite: 4]
    // =======================================================
    always @(posedge clock) begin
        if (i_reset)
            state_reg <= IDLE;
        else
            state_reg <= state_next;
    end

    // =======================================================
    // BLOQUE 2: Lógica de Próximo Estado y Salidas (Combinacional)
    // Decide hacia dónde ir y qué señales activar según el estado actual[cite: 4]
    // =======================================================
    always @(*) begin
        // 1. Valores por defecto para evitar latches (Fault Recovery)[cite: 4]
        state_next = state_reg; // Si no hay cambios, me quedo en el mismo estado
        o_s_clr    = 1'b0;
        o_n_clr    = 1'b0;
        o_n_incr   = 1'b0;
        o_b_load   = 1'b0;
        o_b_shift  = 1'b0;
        o_p_load   = 1'b0;
        o_tx_done  = 1'b0;
        o_tx       = 1'b1;      // Por defecto, la línea UART en reposo es un '1'[cite: 4]

        // 2. Evaluación de transiciones según el estado actual
        case (state_reg)
            IDLE: begin
                // Esperamos la señal para empezar a transmitir
                if (i_tx_start) begin
                    state_next = START;
                    o_s_clr    = 1'b1;  // Reseteamos el contador de ticks para empezar en 0
                    o_b_load   = 1'b1;  // Le decimos al Datapath que guarde el byte
                    o_p_load   = 1'b1;  // Le decimos al Datapath que calcule la paridad
                end
            end
            
            START: begin
                o_tx = 1'b0; // Forzamos la salida física a '0' (Bit de Start)[cite: 4]
                
                // Esperamos a que pasen exactamente 16 ticks del generador de baudios[cite: 4]
                if (i_s_tick && i_s_reg == (N_TICK-1)) begin
                    state_next = DATA; // Ya pasó el tiempo de 1 baudio, pasamos a los datos
                    o_s_clr    = 1'b1; // Limpiamos el contador de ticks para el siguiente bit
                    o_n_clr    = 1'b1; // Limpiamos el contador de bits (empezamos en el bit 0)
                end
            end
            
            DATA: begin
                o_tx = i_b0; // Conectamos la salida física al bit actual del Datapath
                
                // Esperamos que pasen los 16 ticks de este bit[cite: 4]
                if (i_s_tick && i_s_reg == (N_TICK-1)) begin
                    o_s_clr   = 1'b1; // Limpiamos los ticks para el bit que sigue
                    o_b_shift = 1'b1; // Ordenamos al Datapath mover el registro 1 lugar
                    
                    // Verificamos si ya enviamos los 8 bits (del 0 al 7)
                    if (i_n_reg == (NBIT-1))
                        state_next = PARITY; // Si terminamos los 8, vamos a Paridad[cite: 4]
                    else
                        o_n_incr = 1'b1;     // Si no, sumamos 1 al contador de bits
                end
            end
            
            PARITY: begin
                o_tx = i_p_reg; // Conectamos la salida física al bit de paridad
                
                // Esperamos los 16 ticks para que el receptor lea la paridad
                if (i_s_tick && i_s_reg == (N_TICK-1)) begin
                    o_s_clr    = 1'b1;
                    state_next = STOP; // Pasamos al bit de parada[cite: 4]
                end
            end
            
            STOP: begin
                o_tx = 1'b1; // Forzamos la salida a '1' (Bit de Stop)[cite: 4]
                
                // Esperamos los últimos 16 ticks
                if (i_s_tick && i_s_reg == (N_TICK-1)) begin
                    state_next = IDLE;     // Terminó la trama, volvemos a reposo
                    o_tx_done  = 1'b1;     // Emitimos un pulso avisando que finalizamos
                end
            end
            
            default: state_next = IDLE; // Prevención de errores[cite: 4]
        endcase
    end
endmodule