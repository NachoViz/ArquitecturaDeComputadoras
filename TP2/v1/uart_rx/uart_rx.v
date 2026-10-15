/*Este es el archivo principal del receptor que el mundo exterior ve.
 Su única función es instanciar los dos módulos anteriores y unirlos internamente 
 mediante cables (wire).*/

module uart_rx (
    input  wire       clk,
    input  wire       reset,
    input  wire       sample_tick,
    input  wire       rx,
    output wire [7:0] data_out,
    output wire       valid
);

    // Cables internos para comunicar el Jefe (FSM) con el Empleado (Datapath)
    wire shift_en;
    wire clear_count;
    wire load_out;
    wire count_done;

    // Instancia del Datapath
    uart_rx_datapath u_datapath (
        .clk(clk),
        .reset(reset),
        .rx(rx),
        .shift_en(shift_en),       // Recibe control
        .clear_count(clear_count), // Recibe control
        .load_out(load_out),       // Recibe control
        .count_done(count_done),   // Envía estado
        .data_out(data_out)
    );

    // Instancia de la Máquina de Estados
    uart_rx_fsm u_fsm (
        .clk(clk),
        .reset(reset),
        .sample_tick(sample_tick),
        .rx(rx),
        .count_done(count_done),   // Recibe estado
        .shift_en(shift_en),       // Emite control
        .clear_count(clear_count), // Emite control
        .load_out(load_out),       // Emite control
        .valid(valid)
    );

endmodule