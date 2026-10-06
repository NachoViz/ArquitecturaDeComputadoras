module top_module (
        input wire clk,
    input wire reset,
    input wire sample_tick,
    input wire rx,
    output wire [7:0] data_out,
    output wire valid
);

localparam 	IDLE = 2'd0,
		RECEIVER_DATA = 2'd1,
		STOP = 2'd2,
		ERROR = 2'd3;

reg [2:0] state = IDLE;
reg [2:0] count = 3'b0;;

reg [7:0] shift_reg;
reg [7:0] data_reg;

reg done = 1'b0;

//Logica Combinacional
always @(posedge clk) begin

	done <= 1'b0;

	if(reset) begin
		state <= IDLE;
		count <= 3'b0;
		//data_reg <= 8'b0;
	end else if(sample_tick)begin

		case(state)

			IDLE : begin
				if(!rx)begin
					state <= RECEIVER_DATA;
					count <= 3'b0;
					end
				end

			RECEIVER_DATA : begin
                		// Desplazamos bit a bit en el registro temporal
		                shift_reg <= {rx, shift_reg[7:1]};
				//data_reg <= {rx , data_reg[7:1]};

				if(count == 3'd7)begin
					state <= STOP;
				end else
					count <= count + 3'b1;
			     end

			STOP : begin
				if(rx)begin
					done <= 1'b1;
		                        data_reg <= shift_reg; //bit compl
					state <= IDLE;
				end else
					state <= ERROR;
			      end

			ERROR : begin
				if(!rx)
					state <= ERROR;
				else begin
					state <= IDLE;
				     end
			        end

			default : state <= IDLE;

		endcase
	end

end


assign valid = done;
assign data_out = data_reg;


endmodule
