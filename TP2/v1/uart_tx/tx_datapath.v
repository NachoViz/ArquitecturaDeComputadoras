module tx_datapath #(
    parameter DBIT = 8  // Número de bits de datos (típicamente 8) 
) (
    input wire            clk,
    input wire            reset,
    input wire [DBIT-1:0] din,    // Dato en paralelo de entrada a transmitir 

    // Señales de control recibidas desde tx_fsm 
    input wire       clr_s,    // Reinicia el contador de ticks s_reg 
    input wire       inc_s,    // Incrementa el contador de ticks s_reg 
    input wire       clr_n,    // Reinicia el contador de bits n_reg 
    input wire       inc_n,    // Incrementa el contador de bits n_reg 
    input wire       load_b,   // Carga din en el registro de desplazamiento 
    input wire       shift_b,  // Desplaza b_reg a la derecha (shift right) 
    input wire [1:0] tx_src,   // MUX de salida (00: Start '0', 01: Data LSB, 10/11: Stop/Idle '1') 

    // Banderas de estado enviadas hacia tx_fsm 
    output wire s_done,  // Indica que s_reg completó 16 ticks (s_reg == 15) 
    output wire n_done,  // Indica que se enviaron todos los bits (n_reg == DBIT - 1) 

    // Salida física serie 
    output wire tx  // Bit de salida transmitido hacia la línea serie 
);

  // Registros internos del Datapath 
  reg [3:0] s_reg, s_next;  // Contador de ticks (0 a 15) 
  reg [$clog2(DBIT)-1:0] n_reg, n_next;  // Contador de bits transmitidos (0 a DBIT-1) 
  reg [DBIT-1:0] b_reg, b_next;  // Registro de desplazamiento paralelo-serie 
  reg tx_reg, tx_next;  // Buffer de salida para evitar glitches 

  // Bloque secuencial: actualización de registros con clock y reset 
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      s_reg  <= 4'd0;
      n_reg  <= 0;
      b_reg  <= {DBIT{1'b0}};
      tx_reg <= 1'b1;  // Línea en nivel alto por defecto (reposo/idle) 
    end else begin
      s_reg  <= s_next;
      n_reg  <= n_next;
      b_reg  <= b_next;
      tx_reg <= tx_next;
    end
  end

  // Bloque combinacional: lógica de actualización de la ruta de datos 
  always @(*) begin
    // 1. Contador de ticks (s_reg) 
    if (clr_s) begin
      s_next = 4'd0;
    end else if (inc_s) begin
      s_next = s_reg + 1'b1;
    end else begin
      s_next = s_reg;
    end

    // 2. Contador de bits transmitidos (n_reg) 
    if (clr_n) begin
      n_next = 0;
    end else if (inc_n) begin
      n_next = n_reg + 1'b1;
    end else begin
      n_next = n_reg;
    end

    // 3. Registro de desplazamiento de datos (b_reg) 
    if (load_b) begin
      b_next = din;
    end else if (shift_b) begin
      b_next = b_reg >> 1;  // Desplazamiento a la derecha (envía primero el LSB) 
    end else begin
      b_next = b_reg;
    end

    // 4. Multiplexor de selección de la señal serie (tx_reg) 
    case (tx_src)
      2'b00:   tx_next = 1'b0;  // Bit de Start (lógica '0') 
      2'b01:   tx_next = b_reg[0];  // Bit de datos actual (LSB explícito) 
      default: tx_next = 1'b1;  // Bit de Stop / Reposo (lógica '1') 
    endcase
  end

  // Evaluación combinacional de banderas de fin de conteo 
  assign s_done = (s_reg == 4'd15);
  assign n_done = (n_reg == (DBIT - 1));

  // Conexión del buffer de salida 
  assign tx = tx_reg;

endmodule
