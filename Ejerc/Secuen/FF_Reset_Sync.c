module top_module (
    input clk,
    input reset,
    input en,
    input d,
    output reg q
);
    always @(posedge clk) begin
            // Prioridad 1: Reset
            if (reset)
                q <= 0;
            // Prioridad 2: Enable
            else if (en)
                q <= d;
            // Si no hay reset ni enable, Verilog automáticamente
            // conserva el valor de 'q' (hold). No hace falta programarlo.
        end

endmodule
