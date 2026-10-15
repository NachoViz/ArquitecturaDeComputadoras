module tx_fsm #(
    parameter DBIT = 8,
    parameter N_TICKS = 16
)( 
    input  wire       clk, 
    input  wire       reset, 
    input  wire       tx_start,     // Indica el inicio de transmisión 
    input  wire       s_tick,       // Pulso de habilitación del Baud Rate Generator 
    input  wire       s_done,       // Indica que s_reg llegó a 15 (16 ticks completados) 
    input  wire       n_done,       // Indica que se enviaron los DBIT bits (n == DBIT - 1) 
    
    output reg        tx_done_tick, // Pulso de 1 ciclo que indica fin de transmisión 
    output reg        clr_s,        // Reinicia el contador de ticks 
    output reg        inc_s,        // Incrementa el contador de ticks 
    output reg        clr_n,        // Reinicia el contador de bits 
    output reg        inc_n,        // Incrementa el contador de bits 
    output reg        load_b,       // Carga el dato paralelo al registro de desplazamiento 
    output reg        shift_b,      // Desplaza el registro de transmisión (shift right) 
    output reg  [1:0] tx_src        // Control del multiplexor serie (0: Start '0', 1: Data LSB, 2: Stop '1') 
); 

    // Declaración simbólica de estados usando localparam 
    localparam [1:0] idle  = 2'b00, 
                     start = 2'b01, 
                     data  = 2'b10, 
                     stop  = 2'b11; 

    reg [1:0] state_reg, state_next; 

    // Registro de estado síncrono con reset asíncrono 
    always @(posedge clk or posedge reset) begin 
        if (reset) begin
            state_reg <= idle; 
        end else begin
            state_reg <= state_next; 
        end
    end 

    // Lógica de estado siguiente y generación de señales de control 
    always @(*) begin 
        // Valores por defecto para evitar latches
        state_next   = state_reg; 
        tx_done_tick = 1'b0; 
        clr_s        = 1'b0; 
        inc_s        = 1'b0; 
        clr_n        = 1'b0; 
        inc_n        = 1'b0; 
        load_b       = 1'b0; 
        shift_b      = 1'b0; 
        tx_src       = 2'b10; // Salida en nivel alto por defecto ('1') 

        case (state_reg) 
            
            idle: begin 
                tx_src = 2'b10; // Línea serie en reposo (1'b1) 
                if (tx_start) begin 
                    state_next = start; 
                    load_b     = 1'b1; 
                    clr_s      = 1'b1; 
                end 
            end 
            
            start: begin 
                tx_src = 2'b00; // Envía Bit de Start (1'b0) 
                if (s_tick && ) begin 
                    if (s_done) begin 
                        state_next = data; 
                        clr_s      = 1'b1; 
                        clr_n      = 1'b1; 
                    end else begin 
                        inc_s = 1'b1; 
                    end 
                end 
            end 
            
            data: begin 
                tx_src = 2'b01; // Envía bit actual del registro de datos (LSB) 
                if (s_tick) begin 
                    if (s_done) begin 
                        clr_s   = 1'b1; 
                        shift_b = 1'b1; 
                        if (n_done) begin
                            state_next = stop; 
                        end else begin
                            inc_n = 1'b1; 
                        end
                    end else begin 
                        inc_s = 1'b1; 
                    end 
                end 
            end 
            
            stop: begin 
                tx_src = 2'b10; // Envía Bit de Stop (1'b1) 
                if (s_tick) begin 
                    if (s_done) begin 
                        state_next   = idle; 
                        tx_done_tick = 1'b1; 
                    end else begin 
                        inc_s = 1'b1; 
                    end 
                end 
            end 
            
            default: state_next = idle; // Estado de recuperación ante fallos 
            
        endcase 
    end 

endmodule