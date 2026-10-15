Para conectar tu módulo ALU con la UART, la Interfaz (interfaz.v) debe actuar como la FSM de control del sistema completo12
Dado que la ALU requiere tres datos de entrada (A, B y OP) y la UART recibe los datos de a 1 byte por vez3, la función de la 

Interfaz es:Capturar 3 bytes consecutivos recibidos desde uart_rx:

Byte 1 $\rightarrow$ Operando A
Byte 2 $\rightarrow$ Operando B
Byte 3 $\rightarrow$ Código de operación OP

Alimentar la ALU con esos tres valores.

Tomar el resultado Out de la ALU y enviarlo al transmisor uart_tx activando la señal de inicio (tx_start).

Esperar a que termine la transmisión (tx_done) para quedar lista ante una nueva operación.