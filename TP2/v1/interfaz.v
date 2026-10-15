`timescale 1ns / 1ps

module interfaz (
    input wire clock,
    input wire reset,

    // --- Conexiones con el Receptor UART (uart_rx) --- 
    input wire [7:0] rx_dout,  // Byte de datos recibido (o_dout) 
    input wire       rx_done,  // Pulso de recepción completa (o_rx_done) 

    // --- Conexiones con el Transmisor UART (uart_tx) --- 
    output reg  [7:0] tx_din,    // Byte a transmitir (din) 
    output reg        tx_start,  // Pulso para iniciar transmisión 
    input  wire       tx_done,   // Pulso de fin de transmisión (o_tx_done) 

    // --- Conexiones con la ALU --- 
    output reg  [7:0] alu_A,    // Entregado a la entrada A de la ALU 
    output reg  [7:0] alu_B,    // Entregado a la entrada B de la ALU 
    output reg  [5:0] alu_OP,   // Entregado al opcode OP de la ALU 
    input  wire [7:0] alu_out,  // Salida Out calculada por la ALU 
    input  wire       alu_zero  // Flag Zero de la ALU 
);

  // =========================================================================
  // Estados de la máquina de control de la Interfaz
  // =========================================================================
  localparam [2:0] WAIT_A = 3'b000,  // Espera el 1er byte (Operando A) 
  WAIT_B = 3'b001,  // Espera el 2do byte (Operando B) 
  WAIT_OP = 3'b010,  // Espera el 3er byte (Opcode) 
  START_TX = 3'b011,  // Carga el resultado de la ALU y dispara TX 
  WAIT_TX = 3'b100;  // Espera que el transmisor termine de enviar 

  reg [2:0] state_reg, state_next;
  reg [7:0] a_reg, a_next;
  reg [7:0] b_reg, b_next;
  reg [5:0] op_reg, op_next;

  // =========================================================================
  // Registro de estado y almacenamiento de operandos (Secuencial)
  // =========================================================================
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      state_reg <= WAIT_A;
      a_reg     <= 8'h00;
      b_reg     <= 8'h00;
      op_reg    <= 6'b000000;
    end else begin
      state_reg <= state_next;
      a_reg     <= a_next;
      b_reg     <= b_next;
      op_reg    <= op_next;
    end
  end

  // =========================================================================
  // Lógica de estado siguiente y salidas de control (Combinacional)
  // =========================================================================
  always @(*) begin
    // Valores por defecto para evitar latches
    state_next = state_reg;
    a_next     = a_reg;
    b_next     = b_reg;
    op_next    = op_reg;
    tx_start   = 1'b0;
    tx_din     = alu_out;

    case (state_reg)
      WAIT_A: begin
        if (rx_done) begin
          a_next     = rx_dout;
          state_next = WAIT_B;
        end
      end

      WAIT_B: begin
        if (rx_done) begin
          b_next     = rx_dout;
          state_next = WAIT_OP;
        end
      end

      WAIT_OP: begin
        if (rx_done) begin
          op_next    = rx_dout[5:0]; // Extrae los 6 bits de operación 
          state_next = START_TX;
        end
      end

      START_TX: begin
        tx_din     = alu_out;  // Toma el resultado generado por la ALU 
        tx_start   = 1'b1;  // Inicia la transmisión serie 
        state_next = WAIT_TX;
      end

      WAIT_TX: begin
        if (tx_done) begin
          state_next = WAIT_A;  // Vuelve al inicio a esperar un nuevo cálculo 
        end
      end

      default: state_next = WAIT_A;
    endcase
  end

  // =========================================================================
  // Conexión continua de los registros hacia las entradas de la ALU
  // =========================================================================
  always @(*) begin
    alu_A  = a_reg;
    alu_B  = b_reg;
    alu_OP = op_reg;
  end

endmodule
