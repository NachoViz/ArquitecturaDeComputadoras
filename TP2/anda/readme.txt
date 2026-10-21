Opción 2: Simular con Icarus Verilog (iverilog) y GTKWave

La ventaja de iverilog es que compila y corre en 1 segundo, sin tener que esperar a que abra Vivado. Ya está instalado en tu máquina.

1. Compilar y ejecutar la simulación:

Abrí una terminal en la carpeta del proyecto y corré:

bash
cd /home/nacho/Documentos/ArquitecturaDeComputadoras/TP2/anda
iverilog -o sim_tp2 top_uart_alu_tb.v top_uart_alu.v uart.v baud_gen.v uart_rx.v uart_tx.v fifo.v intf.v ALU.v
vvp sim_tp2
iverilog: Compila todos los módulos Verilog juntos y genera el ejecutable sim_tp2.
vvp: Corre la simulación, imprime los resultados en la terminal y guarda las formas de onda en el archivo top_uart_alu_tb.vcd.
2. Ver las ondas gráficas en GTKWave:

Para abrir el visor visual de señales:

bash
gtkwave top_uart_alu_tb.vcd &

En la ventana de GTKWave:

En el panel superior izquierdo (SST), hacé clic sobre top_uart_alu_tb o desplegá dut (el top level).
Abajo te van a aparecer las señales (clk, reset, rx, tx, led, etc.).
Seleccionalas y hacé clic en Append (o arrastralas al visor central).
Apretá el botón con forma de lupa con un recuadro (o Ctrl + Shift + F) para ajustar el zoom y vas a ver cada bit serie viajando en el tiempo.
