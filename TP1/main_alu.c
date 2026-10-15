`timescale 1ns / 1ps

module alu
    (
        input wire [7 : 0]   A,
        input wire [7 : 0]   B,
        input wire [5 : 0]   OP,
        output reg   [7 : 0]  Out,
        output          	 Zero 
    );


        always@(* ) begin
            
            case(OP)
            
                6'b100000: Out = A + B;       // ADD [1]
                6'b100010: Out = A - B;       // SUB [1]
                6'b100100: Out = A & B;       // AND [1, 2]
                6'b100101: Out = A | B;       // OR [1, 2]
                6'b100110: Out = A ^ B;       // XOR [1, 2]
                6'b100111: Out = ~(A | B);    // NOR [1, 2]
                
                // SRA (Shift Right Arithmetic): Ojo, para que desplace con signo, 
                // los operandos deben interpretarse como firmados ($signed) [3]
                6'b000011: Out = $signed(A) >>> B;
                
                // SRL (Shift Right Logical) [1, 4]
                6'b000010: Out = A >> B; 
            
                default:   Out = {8{1'b0}};   // Default seguro
            endcase
        end

                           
        // Asignación condicional del flag Zero
        assign Zero = (Out == 0) ? 1'b1 : 1'b0;    
        
endmodule
