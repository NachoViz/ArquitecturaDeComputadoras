module uart_rx_fsm (
    input  wire clk,
    input  wire reset,
    input  wire sample_tick,
    input  wire rx,
    input  wire count_done,  // Bandera de estado que viene del Datapath
    
    output reg  shift_en,    // Ordena al Datapath desplazar un bit
    output reg  clear_count, // Ordena al Datapath reiniciar el contador
    output reg  load_out,    // Ordena al Datapath guardar el byte final
    output reg  valid        // Salida final
);

    localparam IDLE          = 2'd0,
               RECEIVER_DATA = 2'd1,
               STOP          = 2'd2,
               ERROR         = 2'd3;

    reg [1:0] state, next_state;

    // Bloque 1: Memoria de estado (Secuencial)
    always @(posedge clk) begin
        if (reset)
            state <= IDLE;
        else
            state <= next_state;
    end

    // Bloque 2: Próximo estado y salidas de control (Combinacional)
    always @(*) begin
        // Valores por defecto para evitar latches indeseados
        next_state  = state;
        shift_en    = 1'b0;
        clear_count = 1'b0;
        load_out    = 1'b0;
        valid       = 1'b0;

        case (state)
            IDLE : begin
                if (sample_tick && !rx) begin
                    next_state = RECEIVER_DATA;
                    clear_count = 1'b1; // Mandamos a limpiar el contador
                end
            end

            RECEIVER_DATA : begin
                if (sample_tick) begin
                    shift_en = 1'b1; // Ordenamos capturar un bit
                    if (count_done)  // Leemos si el datapath ya llegó a 7
                        next_state = STOP;
                end
            end

            STOP : begin
                if (sample_tick) begin
                    if (rx) begin
                        load_out = 1'b1; // Trama correcta, volcamos el dato
                        valid    = 1'b1;
                        next_state = IDLE;
                    end else begin
                        next_state = ERROR;
                    end
                end
            end

            ERROR : begin
                if (sample_tick && rx)
                    next_state = IDLE;
            end
            
            default: next_state = IDLE;
        endcase
    end
endmodule

/*Este módulo dicta las transiciones de estado. Está diseñado siguiendo
 las buenas prácticas de tus filminas: un bloque secuencial para la memoria del 
 estado actual y un bloque combinacional para decidir el próximo estado y las señales 
 de salida. */