module top_module (
    input clk,
    input reset,
    input in,
    output y
);

// 1 _ Parametros locales y registros de state
localparam  S0 = 3'd0,
            S1 = 3'd1,
            S2 = 3'd2,
            S3 = 3'd3,
            S4 = 3'd4;

reg [2:0] state , next_state;

// 2_ Reset, secuencia de reloj

    always @( posedge clk) begin 			//aca HDLbits no me dejo porque funciona con un reset asincrono = (or posedge reset)
        if(reset)
            state <= S0;
        else
            state <= next_state;
    end

// 3_ Logica de estados
    always @ ( * )begin
        case(state)
            S0 : begin
                    if(in)
                        next_state = S1;
                    else
                        next_state = S0;
                end

            S1 : begin
                    if(in)
                        next_state = S1;
                    else
                        next_state = S2;
                end

            S2 : begin
                    if(in)
                        next_state = S3;
                    else
                        next_state = S0;
                end

            S3 : begin
                    if(in)
                        next_state = S4;
                    else
                        next_state = S0;
                end

            S4 : begin
                    if(in)
                        next_state = S1;
                    else
                        next_state = S0;
                end

            default : next_state = S0;

        endcase


    end

 // 4 _ SALIDA LOGICA MOORE

 assign y = (state == S4) ;



endmodule
