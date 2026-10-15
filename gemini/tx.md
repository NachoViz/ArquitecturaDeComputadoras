### 1. Entradas y Salidas del Módulo TX (`uart_tx`)

* **Entradas**[3]:
  * `clk`, `reset`: Reloj principal y reinicio del sistema.
  * `tx_start`: Señal enviada por la interfaz para iniciar la transmisión de un nuevo dato.
  * `s_tick`: Pulso proveniente del generador de baudios (16 ticks = 1 tiempo de bit)[1][3].
  * `din[7:0]`: Byte de datos paralelo a transmitir (`DBIT = 8`)[3].
* **Salidas**[3]:
  * `tx`: Línea serie de salida[3].
  * `tx_done_tick`: Pulso de un ciclo de reloj que indica la finalización de la transmisión[2][3].