# Guía de Exposición y Estudio: TP2 - UART + Interfaz + ALU en Basys 3

Documento de repaso técnico para la defensa oral del Trabajo Práctico N° 2 de **Arquitectura de Computadoras**.

---

## 1. Arquitectura General y Flujo de Datos

El sistema integra una **ALU combinacional de 8 bits** con un canal serie full-duplex asíncrono (**UART**) a través de una **FSM de Interfaz** y **memorias FIFO** circulares para desacoplar velocidades.

### Diagrama en Bloques del Sistema:
```text
  [ PC / Python ] 
         │ (Cable USB)
         ▼
  ┌──────────────┐      ┌──────────────┐      ┌──────────────┐      ┌──────────────┐
  │   uart_rx    │ ──►  │   fifo_rx    │ ──►  │    intf      │ ──►  │    ALU.v     │
  │ (Deserieador)│      │  (Cola RX)   │      │(FSM 4 pasos) │      │(Combinacional│
  └──────────────┘      └──────────────┘      └──────┬───────┘      └──────┬───────┘
         ▲                                           │ (w_data)            │ (o_result)
         │ (s_tick x16)                              ▼                     │
  ┌──────────────┐                            ┌──────────────┐             │
  │   baud_gen   │                            │   fifo_tx    │ ◄───────────┘
  │ (Divisor M)  │                            │  (Cola TX)   │
  └──────────────┘                            └──────┬───────┘
         │ (s_tick x16)                              ▼
         ▼                                    ┌──────────────┐
  ┌──────────────┐                            │   uart_tx    │ ──► [ PC / Python ]
  │   uart_tx    │                            │ (Serializador│
  └──────────────┘                            └──────────────┘
```

---

## 2. Parámetros Clave y Temporización (Los Números de la Placa)

| Parámetro | Valor | Justificación Técnica |
| :--- | :---: | :--- |
| **Reloj Maestro (`clk`)** | $100\text{ MHz}$ | Oscilador integrado de la Basys 3 (Pin W5, período $T = 10\text{ ns}$). |
| **Tasa de Baudios** | $19\,200\text{ baud}$ | Velocidad acordada del canal serie ($T_{bit} \approx 52.08\,\mu\text{s}$). |
| **Trama Serie** | **8N1** | 1 bit Start, 8 bits de datos (LSB first), **Sin paridad**, 1 bit Stop. |
| **Sobremuestreo** | **$16\times$** | Se generan 16 ticks por cada bit de transmisión/recepción. |
| **Divisor Baud Rate ($M$)** | **326** | $M = \frac{100\text{ MHz}}{16 \times 19\,200} = \frac{100\,000\,000}{307\,200} \approx 325.52 \to \mathbf{326}$. |
| **Ancho contador ($N$)** | **9 bits** | Para contar de 0 a 325 se requieren 9 bits ($\lceil\log_2(326)\rceil = 9$). |

---

## 3. Asignación de Pines y Monitoreo Físico (LEDs y Botones)

### Restricciones Físicas ([`Basys3_Master.xdc`](file:///home/nacho/TP2/src/Basys3_Master.xdc)):
* **Reloj (`clk`):** Pin `W5` (100 MHz).
* **Reset (`i_reset`):** Botón central **`btnC`** (Pin `U18`, activo en alto).
* **Entrada serie (`i_rx`):** Pin `B18` (recibe desde el chip puente USB-UART).
* **Salida serie (`o_tx`):** Pin `A18` (transmite hacia la PC).
* **Switches:** Desconectados (en TP2 los datos entran 100% por UART).

### Los 16 LEDs de la Basys 3:
```text
[ LD15     LD14      LD13     LD12 ]   [ LD11 LD10 LD9 ]   [  LD8  ]   [ LD7  LD6  LD5  LD4  LD3  LD2  LD1  LD0 ]
  SEND    LOAD_OP   LOAD_B   LOAD_A       (Apagados)         Carry                  Resultado ALU (8 bits)
```

1. **LEDs 15 a 12 (Estados de la FSM en One-Hot):**
   * **LD12 encendido (`0001` - `LOAD_A`):** En reposo, esperando el Operando A.
   * **LD13 encendido (`0010` - `LOAD_B`):** Operando A recibido; esperando Operando B.
   * **LD14 encendido (`0100` - `LOAD_OP`):** Operandos A y B recibidos; esperando el Opcode.
   * **LD15 (`1000` - `SEND`):** Pulso de 1 ciclo donde se escribe el resultado en la FIFO de TX (vuelve de inmediato a LD12).
2. **LED 8:** Flag de **Carry (Acarreo)** de la ALU.
3. **LEDs 7 a 0:** Resultado binario calculado por la ALU en tiempo real.

---

## 4. Máquinas de Estado: ¿Dónde hay Moore y dónde Mealy?

* **Máquina de Moore:** La salida depende **únicamente del estado actual** ($\text{Salida} = f(\text{Estado})$).
* **Máquina de Mealy:** La salida depende del **estado actual Y de las entradas externas** ($\text{Salida} = g(\text{Estado}, \text{Entradas})$).

### En la FSM de Interfaz ([`intf.v`](file:///home/nacho/TP2/src/intf.v)):
Es una **FSM Mixta (Híbrida)**:
1. **Salidas MEALY (`rd` y `wr`):**
   * $\text{rd} = (\text{state\_reg} \in \{\text{LOAD\_A}, \text{LOAD\_B}, \text{LOAD\_OP}\}) \;\&\; \sim\!\text{rx\_empty}$
   * $\text{wr} = (\text{state\_reg} == \text{SEND}) \;\&\; \sim\!\text{tx\_full}$
   * **Justificación de diseño:** **Cero latencia**. Apenas la FIFO avisa que tiene un dato disponible (`~rx_empty`), la FSM en ese mismo ciclo de reloj activa `rd = 1` y captura el dato sin desperdiciar ciclos de espera.
2. **Salidas MOORE (`o_state`, `o_alu_a`, `o_alu_b`, `o_alu_op`):**
   * Dependen exclusivamente de los flip-flops (`state_reg`, `a_reg`, `b_reg`, `op_reg`).
   * **Justificación de diseño:** **Inmunidad a glitches y estabilidad**. Los LEDs físicos y las entradas de la ALU reciben señales limpias y síncronas que solo cambian con los flancos de reloj.

### En la UART ([`uart_rx.v`](file:///home/nacho/TP2/src/uart_rx.v) y [`uart_tx.v`](file:///home/nacho/TP2/src/uart_tx.v)):
* **`tx` es MOORE:** Proviene directamente del biestable `tx_reg`, asegurando que la línea física no tenga ruido.
* **`rx_done_tick` / `tx_done_tick` son MEALY:** Se disparan cuando la FSM está en `STOP` y coincide el pulso de entrada `s_tick`.

---

## 5. Relación con las 5 Etapas del Pipeline Clásico

| Etapa RISC Clásica | Equivalente en este TP2 | Función en el Proyecto |
| :--- | :--- | :--- |
| **IF (Instruction Fetch)** | **UART RX + FIFO RX** | Búsqueda de la "trama": el módulo serie extrae del cable USB los 3 bytes enviados por la PC. |
| **ID (Instruction Decode)** | **FSM (`intf.v`)** | Decodificación: separa la trama en operando A (`a_reg`), operando B (`b_reg`) y Opcode (`op_reg`). *(Nota: los opcodes coinciden con el campo `funct` de MIPS)*. |
| **EX (Execute)** | **`ALU.v`** | Ejecución combinacional del cálculo aritmético/lógico (ADD, SUB, AND, OR, XOR, NOR, SRL, SRA). |
| **MEM (Memory Access)** | *(No Aplica / Bypass)* | Al ser operaciones de tipo registro a registro (Tipo-R), no hay memoria RAM de datos involucrada. |
| **WB (Write Back)** | **FIFO TX + UART TX + LEDs** | Escritura de resultados: el valor de salida se deposita en la cola TX para enviarlo a la PC y se congela en los LEDs físicos. |

> **Pregunta típica:** *¿Este TP es un pipeline?*  
> **Respuesta:** No, es una **arquitectura de control secuencial**. En un pipeline real varias instrucciones se solapan en ejecución simultánea; acá la FSM procesa una instrucción a la vez de forma secuencial.

---

## 6. Preguntas Clave de Examen (Cheat Sheet de Defensa)

#### P1: ¿Por qué hay dos flip-flops en serie en la entrada `i_rx`?
* **R:** Para mitigar la **metaestabilidad**. `i_rx` es una señal asíncrona proveniente del exterior (cable USB). Si commuta durante la ventana crítica de setup/hold del primer flip-flop, este puede oscilar o quedar en un nivel indefinido. El segundo flip-flop le da 1 ciclo de reloj (10 ns) adicional para estabilizarse a un `0` o `1` lógico antes de ingresar a la lógica interna.
* **Detalle:** Se resetean a `1` porque en reposo (*Idle*) la línea UART permanece en nivel alto.

#### P2: ¿Por qué se usa sobremuestreo $16\times$ y no se muestrea a $1\times$?
* **R:** Porque al no viajar una señal de reloj por el cable, el receptor debe sincronizarse con los flancos de los datos. El sobremuestreo $16\times$ permite detectar el flanco de bajada del Start y contar **8 ticks** (`s_reg == 7`) para posicionar la lectura en el **centro exacto del bit de Start** (descartando pulsos espurios de ruido). Luego se cuentan **16 ticks** (`s_reg == 15`) para caer exactamente en el centro de cada bit subsiguiente.

#### P3: ¿Por qué son necesarias las FIFOs si la ALU es combinacional e instantánea?
* **R:** Por el **desacoplamiento de dominios temporales y velocidades**. La FPGA corre a 100 MHz (10 ns/ciclo) y la UART corre a 19200 baudios (~52 µs/bit, ~520 µs/byte). Las FIFOs absorben ráfagas de datos rápidos enviados desde la PC evitando pérdidas (*buffer overrun*), y permiten que la interfaz deposite el resultado inmediatamente sin bloquearse a esperar que la UART termine de transmitir bit a bit.

#### P4: ¿Por qué es fundamental presionar Reset (`btnC`) al encender o programar la placa?
* **R:** Porque en la síntesis de la FPGA los registros de la FIFO (`empty_reg`) arrancan por defecto en `0` (la FIFO cree que NO está vacía). Sin el pulso de Reset físico, la FSM "lee" bytes fantasma no inicializados, arrojando resultados erróneos en los LEDs. Resetear inicializa `empty_reg <= 1`, limpia los punteros y pone la FSM en `LOAD_A`.

#### P5: ¿Cuál es la diferencia entre SRL y SRA en la ALU?
* **R:** **SRL** desplaza a la derecha rellenando con ceros (`0`) por la izquierda. **SRA** es un desplazamiento aritmético que **conserva el bit de signo** (rellena con unos si el número era negativo). En Verilog es obligatorio usar `$signed(in_a) >>> in_b`; de lo contrario, el operador `>>>` se comporta como un desplazamiento lógico normal.

#### P6: ¿Por qué la señal `s_tick` dura un solo ciclo de reloj de 100 MHz?
* **R:** Porque en FPGAs es una mala práctica generar relojes derivados por lógica (genera problemas de skew y glitches). Todo el circuito corre con el reloj sincrónico de 100 MHz (`clk`), y `s_tick` actúa como un **Clock Enable (habilitador)** de 1 ciclo.

---

## 7. Comandos de Terminal para la Demostración en Vivo

### 1. Dar permisos al puerto serie en Linux:
```bash
sudo chmod 666 /dev/ttyUSB1
```

### 2. Demostración Paso a Paso (Ideal para la exposición):
Permite enviar $A \to B \to OP$ byte por byte para ver cómo van cambiando los LEDs de la FSM (`LD12` $\to$ `LD13` $\to$ `LD14` $\to$ `LD12`):
```bash
python3 test_uart_alu.py -s
```

### 3. Modo Interactivo general:
```bash
python3 test_uart_alu.py -i
```
Ejemplos para ingresar:
* `5 3 ADD` $\to$ Resultado: `0x08` (Prende **LD3**).
* `255 1 ADD` $\to$ Resultado: `0x00` con **Carry = 1** (Prende **LD8**).
* `16 3 SUB` $\to$ Resultado: `0x0D` (Prenden **LD3, LD2, LD0**).
* `0x80 1 SRA` $\to$ Resultado: `0xC0` (Prenden **LD7 y LD6**, conservación de signo).

### 4. Batería de 66 pruebas automáticas:
```bash
python3 test_uart_alu.py
```

### 5. Simulación rápida en terminal con Icarus Verilog + GTKWave:
```bash
cd /home/nacho/TP2/src
iverilog -o sim_tp2 top_uart_alu_tb.v top_uart_alu.v uart.v baud_gen.v uart_rx.v uart_tx.v fifo.v intf.v ALU.v
vvp sim_tp2
gtkwave top_uart_alu_tb.vcd &
```

---

## 8. Cuestionario de Autoevaluación (Preguntas Clave de la Materia — Sin Respuestas)

Utilizá este cuestionario como simulacro de examen oral. Si podés explicar cada una con tus propias palabras frente al pizarrón o la placa, tenés la materia completamente dominada.

### Eje 1: Sincronismo, Tiempos y Metaestabilidad
1. ¿Qué son los tiempos de *setup* ($t_{su}$) y *hold* ($t_h$) de un flip-flop y qué fenómeno físico ocurre si se violan?
2. Si la probabilidad de falla por metaestabilidad nunca es cero, ¿qué métrica matemática (MTBF) se busca maximizar al colocar sincronizadores de 2 flip-flops?
3. ¿Por qué no se debe utilizar una señal generada combinacionalmente (como la salida de un contador) como señal de reloj conectada al pin `clk` de otros flip-flops?
4. ¿Qué diferencia existe entre un reloj derivado (*derived clock*) y una señal de habilitación de reloj (*clock enable*)?

### Eje 2: Comunicación Serie Asíncrona (UART)
5. En una comunicación UART donde emisor y receptor tienen relojes independientes con pequeñas tolerancias de frecuencia (ej. $\pm 2\%$), ¿por qué el bit de Stop es imprescindible para evitar la acumulación de error entre caracteres consecutivos?
6. ¿Por qué se opta por sobremuestreo de $16\times$ en lugar de $4\times$ o $64\times$? ¿Cuál es el compromiso (*trade-off*) entre resolución temporal, frecuencia del reloj y consumo de recursos?
7. ¿Cómo detecta el receptor un flanco de Start falso producido por un pulso espurio de ruido?
8. ¿Qué problema de sincronización de trama ocurre si el transmisor envía con paridad (8E1) y el receptor está configurado sin paridad (8N1)?

### Eje 3: Máquinas de Estados Finitas (FSM)
9. ¿Cuáles son las ventajas y desventajas de la codificación de estados *One-Hot* frente a la codificación *Binaria* o *Gray* en una arquitectura basada en FPGA (LUTs y Flip-Flops)?
10. ¿Por qué una salida de Mealy puede propagar *glitches* a etapas posteriores mientras que una de Moore es inherentemente más segura?
11. ¿En qué situación específica conviene pagar el costo de un diseño Mealy frente a uno de Moore?
12. En Verilog, ¿por qué la omisión de una asignación en una rama de un bloque combinacional `always @(*)` infiere un *latch*, y por qué los latches son indeseables en FPGAs?

### Eje 4: Almacenamiento y Control de Flujo (FIFOs)
13. En una memoria FIFO circular basada en punteros, ¿por qué la condición $w\_ptr == r\_ptr$ es ambigua y qué estrategias existen para discriminar si la cola está llena o vacía?
14. ¿Qué es un desbordamiento de búfer (*buffer overrun*) y qué bloque del sistema es el encargado de impedirlo mediante señales de contrapresión (*backpressure*)?
15. Si la ALU resuelve la operación en un solo ciclo de reloj de 10 ns, ¿por qué sigue siendo necesaria una FIFO de transmisión (TX FIFO)?

### Eje 5: Datapath, ALU y Representación Numérica
16. ¿Qué diferencia existe a nivel circuital entre el flag de *Carry* y el flag de *Overflow*? ¿En qué casos un resultado tiene Carry pero no Overflow, y viceversa?
17. ¿Cómo implementa internamente el operador de resta (`in_a - in_b`) una ALU utilizando un sumador convencional y compuertas lógicas?
18. En complemento a 2, ¿por qué desplazar aritméticamente a la derecha un número negativo impar (ej. $-5$) no da exactamente el cociente entero truncado a cero?
19. ¿Por qué el código de operación de la ALU utiliza 6 bits y cómo se vincula esto con el formato de instrucción Tipo-R de MIPS?

### Eje 6: Arquitectura de Procesadores y Pipeline
20. En un procesador segmentado de 5 etapas (IF, ID, EX, MEM, WB), ¿por qué una instrucción de salto condicional (*Branch*) o una dependencia de datos entre instrucciones consecutivas genera *hazards* (riesgos), y cómo se resuelven?
21. Si quisiéramos convertir este diseño del TP2 en un procesador real, ¿qué elementos del Datapath faltan agregar alrededor de la ALU y la Interfaz?
22. ¿Por qué la separación entre la memoria de instrucciones y la memoria de datos (arquitectura Harvard) es fundamental para poder segmentar el procesador sin conflictos estructurales?

