module baud_gen #(
    parameter M = 163, // Valor divisor (M = clk_freq / (16 * baud_rate))
    parameter N = 8    // Número de bits del contador (N >= $clog2(M))
)(
    input  wire clk,
    input  wire reset,
    output wire s_tick // Pulso de sobremuestreo (16x Baud Rate)
);

    // Registro del contador interno
    reg  [N-1:0] r_reg;
    wire [N-1:0] r_next;

    // Actualización síncrona del registro de conteo con reset asíncrono
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            r_reg <= {N{1'b0}};
        end else begin
            r_reg <= r_next;
        end
    end

    // Lógica de estado siguiente del contador
    assign r_next = (r_reg == (M - 1)) ? {N{1'b0}} : (r_reg + 1'b1);

    // Salida: se activa en nivel alto durante un ciclo de reloj cuando r_reg alcanza M-1
    assign s_tick = (r_reg == (M - 1));

endmodule