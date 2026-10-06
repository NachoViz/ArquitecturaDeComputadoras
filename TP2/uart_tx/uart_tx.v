module uart_tx #(
    parameter NBIT   = 8,
    parameter N_TICK = 16
) (
    input  wire       clk,
    input  wire       reset,
    input  wire       tx_start,    // Orden externa para transmitir
    input  wire       s_tick,      // Pulso constante del Generador de Baudios[cite: 3]
    input  wire [7:0] data_in,     // Byte de 8 bits que viene de la ALU/Interfaz[cite: 4]
    
    output wire       tx,          // Salida serial física hacia el exterior (Serial Out)[cite: 4]
    output wire       tx_done      // Aviso de que la transmisión culminó
);

    // =======================================================
    // CABLES INTERNOS DE INTERCONEXIÓN
    // Sirven para comunicar las órdenes de la FSM hacia el Datapath
    // y los estados del Datapath hacia la FSM.
    // =======================================================
    
    // Cables de Control (FSM -> Datapath)
    wire       s_clr, n_clr, n_incr;
    wire       b_load, b_shift, p_load;
    
    // Cables de Estado (Datapath -> FSM)
    wire [3:0] s_reg; // Avisa cuántos ticks pasaron
    wire [2:0] n_reg; // Avisa cuántos bits se enviaron
    wire       b0;    // Pasa el bit actual a transmitir
    wire       p_reg; // Pasa el bit de paridad calculado

    // =======================================================
    // INSTANCIA DEL DATAPATH (El empleado que procesa los datos)
    // =======================================================
    uart_tx_datapath #(
        .NBIT(NBIT)
    ) u_datapath (
        .clk(clk),
        .reset(reset),
        .data_in(data_in),   // Recibe el byte de afuera
        .s_tick(s_tick),     // Escucha el reloj de baudios externo
        
        // Conexión de puertos de control recibidos de la FSM
        .s_clr(s_clr),
        .n_clr(n_clr),
        .n_incr(n_incr),
        .b_load(b_load),
        .b_shift(b_shift),
        .p_load(p_load),
        
        // Conexión de puertos de estado enviados a la FSM
        .s_reg(s_reg),
        .n_reg(n_reg),
        .b0(b0),
        .p_reg(p_reg)
    );

    // =======================================================
    // INSTANCIA DE LA FSM (El jefe que da las órdenes)
    // =======================================================
    uart_tx_fsm #(
        .NBIT(NBIT),
        .N_TICK(N_TICK)
    ) u_fsm (
        .clock(clk),
        .i_reset(reset),
        .i_tx_start(tx_start), // Escucha la orden externa de inicio
        .i_s_tick(s_tick),     // Escucha el reloj de baudios externo
        
        // Conexión de puertos de estado recibidos del Datapath
        .i_s_reg(s_reg),
        .i_n_reg(n_reg),
        .i_b0(b0),
        .i_p_reg(p_reg),
        
        // Conexión de puertos de control enviados al Datapath
        .o_s_clr(s_clr),
        .o_n_clr(n_clr),
        .o_n_incr(n_incr),
        .o_b_load(b_load),
        .o_b_shift(b_shift),
        .o_p_load(p_load),
        
        // Salidas hacia el exterior
        .o_tx_done(tx_done),   
        .o_tx(tx)              // El bit serial sale físicamente del sistema
    );

endmodule