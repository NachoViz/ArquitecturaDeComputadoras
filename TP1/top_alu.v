module top_alu (
    input wire clk,             // Reloj integrado de 100 MHz (Pin W5)
    input wire [7:0] sw,        // Switches del sw0 al sw7
    input wire btnC,            // Botón Central: Registra el Dato A
    input wire btnU,            // Botón Arriba: Registra el Dato B
    input wire btnD,            // Botón Abajo: Registra el Opcode (OP)
    output wire [7:0] led,      // LEDs del led0 al led7 (Muestran "Out")
    output wire led_zero        // LED led8 (Bandera Zero)
);

    // Registros síncronos de almacenamiento interno [3]
    reg [7:0] reg_A;
    reg [7:0] reg_B;
    reg [5:0] reg_Op;

    // Lógica secuencial síncrona para captura de datos [2, 3]
    always @(posedge clk) begin
        if (btnC) reg_A  <= sw[7:0]; reset; // Al presionar btnC, guardamos el bus en A
        if (btnU) reg_B  <= sw[7:0]; reset; // Al presionar btnU, guardamos el bus en B
        if (btnD) reg_Op <= sw[5:0]; reset; // Al presionar btnD, guardamos los 6 bits en OP
    end

    // Instanciación por nombre de tu ALU de 8 bits [4, 5]
    alu mi_alu (
        .A(reg_A),
        .B(reg_B),
        .OP(reg_Op),
        .Out(led),
        .Zero(led_zero)
    );

endmodule