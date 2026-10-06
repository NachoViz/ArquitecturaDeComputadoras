module top_module (
    input wire clk,
    input wire reset,
    input wire sample_tick,
    input wire rx,
    output wire [7:0] data_out,
    output wire valid
);
    localparam [1:0] idle = 2'd0;
    localparam [1:0] receive_data = 2'd1;
    localparam [1:0] stop = 2'd2;

    reg [1:0] state = 2'd0;
    reg [2:0] index = {3{1'b0}};
    reg [7:0] data_reg = {8{1'b0}};
    reg done = 1'b0;

    assign data_out = data_reg;
    assign valid = done;

    always @(posedge clk) begin
        done <= 1'b0;
        if (reset == 1'b1) begin
            state <= idle;
            index <= {3{1'b0}};
            data_reg <= {8{1'b0}};
        end
        else if (sample_tick == 1'b1) begin
            case (state)

            idle: begin
                if (rx == 1'b0) begin
                    state <= receive_data;
                    index <= {3{1'b0}};
                end
            end

            receive_data: begin
                data_reg[index ] <= rx;
                if (index == 7) begin
                    state <= stop;
                end
                else begin
                    index <= index + 1;
                end
            end

            stop: begin
                if (rx == 1'b1) begin
                    done <= 1'b1;
                end
                state <= idle;
            end
            endcase
        end
    end
endmodule
