module uart_tx #(
    parameter DBIT = 8  // Número de bits de datos (típicamente 8) 
) (
    input  wire            clk,
    input  wire            reset,
    input  wire            tx_start,      // Señal para iniciar una transmisión 
    input  wire            s_tick,        // Pulso de sincronización del Baud Rate Generator 
    input  wire [DBIT-1:0] din,           // Byte de datos de entrada en paralelo 
    output wire            tx_done_tick,  // Pulso indicador de fin de transmisión 
    output wire            tx             // Salida serie hacia el canal de comunicación 
);

  // =========================================================================
  // Señales internas de control (FSM -> Datapath) 
  // =========================================================================
  wire clr_s, inc_s;
  wire clr_n, inc_n;
  wire load_b, shift_b;
  wire [1:0] tx_src;

  // =========================================================================
  // Señales internas de estado (Datapath -> FSM) 
  // =========================================================================
  wire s_done, n_done;

  // =========================================================================
  // Instancia del Controlador (Máquina de Estados Finitos)
  // =========================================================================
  tx_fsm fsm_unit (
      .clk         (clk),
      .reset       (reset),
      .tx_start    (tx_start),
      .s_tick      (s_tick),
      .s_done      (s_done),
      .n_done      (n_done),
      .tx_done_tick(tx_done_tick),
      .clr_s       (clr_s),
      .inc_s       (inc_s),
      .clr_n       (clr_n),
      .inc_n       (inc_n),
      .load_b      (load_b),
      .shift_b     (shift_b),
      .tx_src      (tx_src)
  );

  // =========================================================================
  // Instancia de la Ruta de Datos (Datapath)
  // =========================================================================
  tx_datapath #(
      .DBIT(DBIT)
  ) datapath_unit (
      .clk    (clk),
      .reset  (reset),
      .din    (din),
      .clr_s  (clr_s),
      .inc_s  (inc_s),
      .clr_n  (clr_n),
      .inc_n  (inc_n),
      .load_b (load_b),
      .shift_b(shift_b),
      .tx_src (tx_src),
      .s_done (s_done),
      .n_done (n_done),
      .tx     (tx)
  );

endmodule
