`timescale 1ns / 1ps

module tb_main1; // Módulo del testbench (sin puertos de entrada ni salida)

    // 1. Declaración de las señales del banco de pruebas
    parameter N = 8;
    reg [N-1:0] A;       // Las entradas a estimular se declaran como reg
    reg [N-1:0] B;
    reg [5:0]   Op;
    wire [N-1:0] Out;    // Las salidas a monitorear se declaran como wire
    wire         Zero;

    // 2. Instanciación del módulo de diseño de la ALU (DUT - Device Under Test)
    // 2. Instanciación del módulo de diseño de la ALU (DUT - Device Under Test)
    alu dut (
        .A(A),
        .B(B),
        .OP(Op),   // <- 'OP' en mayúscula para coincidir con tu archivo fuente
        .Out(Out),
        .Zero(Zero)
    );

    // 3. Bloque initial para inyección de estímulos y verificación automática
    initial begin
        // Inicializamos las señales en un punto de partida
        A = 0; B = 0; Op = 0;
        #10; // Esperamos 10 ns de estabilización inicial

        // Caso de prueba 1: Verificación de ADD (Suma combinacional)
        A = 8'd15;
        B = 8'd10;
        Op = 6'b100000; // ADD
        #10; // Esperamos que se propague el retardo del circuito combinacional
        if (Out === 8'd25) 
            $display("[%d ns] OK ADD: %d + %d = %d (Zero = %b)", $time, A, B, Out, Zero);
        else 
            $display("[%d ns] ERROR ADD: Esperado 25, Obtenido %d", $time, Out);

        // Caso de prueba 2: Verificación de SUB (Resta que genere cero para verificar flag)
        A = 8'd42;
        B = 8'd42;
        Op = 6'b10010; // SUB
        #10;
        if (Out === 8'd0 && Zero === 1'b1) 
            $display("[%d ns] OK SUB: %d - %d = %d (Zero = %b)", $time, A, B, Out, Zero);
        else 
            $display("[%d ns] ERROR SUB: Esperado 0 con Zero=1, Obtenido %d con Zero=%b", $time, Out, Zero);

        // Caso de prueba 3: Verificación de operación lógica AND
        A = 8'b10101010;
        B = 8'b11001100;
        Op = 6'b100100; // AND
        #10;
        if (Out === 8'b10001000)
            $display("[%d ns] OK AND: %b & %b = %b", $time, A, B, Out);
        else
            $display("[%d ns] ERROR AND: Esperado 10001000, Obtenido %b", $time, Out);

        // Caso de prueba 4: Envío de valores aleatorios con $random para verificar robustez
        repeat(5) begin
            A = $random;
            B = $random;
            Op = 6'b100000; // ADD
            #10;
            if (Out === (A + B))
                $display("[%d ns] OK ADD Aleatorio: %d + %d = %d", $time, A, B, Out);
            else
                $display("[%d ns] ERROR ADD Aleatorio: %d + %d = %d (Esperado %d)", $time, A, B, Out, (A + B));
        end

        // Finalizar la simulación automáticamente
        $finish;
    end

endmodule
