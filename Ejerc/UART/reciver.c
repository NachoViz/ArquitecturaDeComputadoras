// Verilog starter generated from this problem's VHDL interface.
module top_module (
        input wire clk,
    input wire reset,
    input wire sample_tick,
    input wire rx,
    output wire [7:0] data_out,
    output wire valid
);
localparam  IDLE = 1'd0,
            START = 1'd1,
            DATA = 1'd2,
            STOP = 1'd3,
            ERROR = 1'd4,
            DONE = 1'd5;

//registros de FSM
reg [2:0] state , next_state;

//Contador y shift_reg
reg [2:0] bit_count;
reg [7:0] shift_reg;

// 2_Logica de cambio de estado (SECUENCIAL)

always @(posedge clk) begin
    if(reset)begin
        state <= IDLE;
        bit_count <= 3'b0;
        shift_reg <= 8'b0;    
    end else begin
        state <= next_state;

        // Operaciones del Datapath según el estado actual

        if(sample_tick)begin  //señal de control de lectura
            if(state==START)
                bit_counter <= 3'b0;

            else if (state == DATA)begin

                shift_reg <= {rx , shift_reg[7:1]};
                bit_counter <= bit_counter + 3'b1;

            end 
        end
    end
end

// 3_Logica COMBINACIONAL

always @(*)begin

    if(sample_tick)begin
        case(state)
            IDLE :begin
                    if(!rx)
                        next_state = START;
                    else
                        next_state = IDLE
                    end

            START : next_state = DATA;

            DATA : begin
                        if(bit_counter==3'd7)
                            next_state=STOP;
                        else
                            next_state=DATA;
                    end

            STOP : begin
                    if(rx)
                        next_state = DONE;
                    else
                        next_state = ERROR;                    
                    end
            
            ERROR : begin
                        if(rx)
                            next_state = IDLE;
                        else
                            next_state = ERROR;                    
                    end

            DONE :  next_state = IDLE;                    

            default : next_state = IDLE;

        endcase
    end
end

// 4_ FINAL : SALIDAS

assign valid = (state == DONE);
assign data_out = shift_reg;

endmodule


