module uart_tx_datapath #(
    parameter NBIT = 8
) (
    input  wire       clk,
    input  wire       reset,
    input  wire [7:0] data_in,   // Byte a transmitir
    input  wire       s_tick,    // Pulso del Baud Rate Generator
    
    // Señales de control emitidas por la FSM
    input  wire       s_clr,     // Limpia el contador de ticks
    input  wire       n_clr,     // Limpia el contador de bits
    input  wire       n_incr,    // Incrementa el contador de bits
    input  wire       b_load,    // Carga el byte al shift register
    input  wire       b_shift,   // Desplaza el shift register 1 bit
    input  wire       p_load,    // Calcula y guarda la paridad

    // Señales de estado que van hacia la FSM
    output wire [3:0] s_reg,     // Valor actual del contador de ticks
    output wire [2:0] n_reg,     // Valor actual del contador de bits
    output wire       b0,        // Bit menos significativo (el que se transmite)
    output wire       p_reg      // Bit de paridad
);

    reg [3:0] s_count;
    reg [2:0] n_count;
    reg [7:0] shift_reg;
    reg       parity_bit;

    always @(posedge clk) begin
        if (reset) begin
            s_count    <= 4'b0;
            n_count    <= 3'b0;
            shift_reg  <= 8'b0;
            parity_bit <= 1'b0;
        end else begin
            // 1. Contador de Ticks (0 a 15)
            if (s_clr)
                s_count <= 4'b0;
            else if (s_tick)
                s_count <= s_count + 1'b1;

            // 2. Contador de Bits (0 a 7)
            if (n_clr)
                n_count <= 3'b0;
            else if (n_incr)
                n_count <= n_count + 1'b1;

            // 3. Registro de Desplazamiento
            if (b_load)
                shift_reg <= data_in;
            else if (b_shift)
                shift_reg <= {1'b0, shift_reg[7:1]};

            // 4. Cálculo de Paridad Par (XOR de todos los bits)
            if (p_load)
                parity_bit <= ^data_in; 
        end
    end

    // Asignación continua a los puertos de salida hacia la FSM
    assign s_reg = s_count;
    assign n_reg = n_count;
    assign b0    = shift_reg[0];
    assign p_reg = parity_bit;

endmodule