module uart_rx_datapath (
    input  wire       clk,
    input  wire       reset,
    input  wire       rx,
    // Señales de control que vienen de la FSM
    input  wire       shift_en,    
    input  wire       clear_count, 
    input  wire       load_out,    
    // Señales de estado que van hacia la FSM y salida final
    output wire       count_done,  
    output wire [7:0] data_out
);

    reg [2:0] count;
    reg [7:0] shift_reg;
    reg [7:0] data_reg;

    always @(posedge clk) begin
        if (reset) begin
            count     <= 3'b0;
            shift_reg <= 8'b0;
            data_reg  <= 8'b0;
        end else begin
            // 1. Lógica del contador
            if (clear_count) begin
                count <= 3'b0;
            end else if (shift_en) begin
                count <= count + 3'b1;
                // 2. Desplazamiento LSB-first en el registro temporal
                shift_reg <= {rx, shift_reg[7:1]};
            end

            // 3. Carga del byte final estable
            if (load_out) begin
                data_reg <= shift_reg;
            end
        end
    end

    // Avisa a la FSM cuando ya se recibieron los 8 bits
    assign count_done = (count == 3'd7);
    assign data_out   = data_reg;

endmodule

/*Este módulo aloja tu shift_reg, el data_reg y el contador 
count. Elimina toda la lógica de los estados (IDLE, STOP, etc.) 
y la reemplaza por señales de habilitación que vendrán desde la FSM. 
A su vez, le envía una señal a la FSM (count_done) para avisarle que ya 
terminó de contar hasta 7. */