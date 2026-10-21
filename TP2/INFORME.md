# Informe Técnico: Sistema de Procesamiento Aritmético con Comunicación UART en FPGA

**Asignatura:** Arquitectura de Computadoras  
**Trabajo Práctico:** N° 2 — Sistema de Procesamiento Aritmético con Comunicación Serie Asíncrona (UART)  
**Autor:** Juan Ignacio Vizgarra  
**Plataforma de Hardware:** Digilent Basys 3 (FPGA Xilinx Artix-7 XC7A35T-1CPG236C)  
**Lenguaje:** Verilog HDL (IEEE 1364-2001)  
**Herramientas:** Xilinx Vivado, Icarus Verilog (`iverilog`), GTKWave, Python 3 (`pyserial`)

---

## 1. Introducción y Objetivos

El objetivo de este trabajo práctico es integrar la **Unidad Aritmético-Lógica (ALU)** combinacional desarrollada en el TP1 dentro de un sistema embebido digital completo sobre FPGA, capaz de comunicarse de forma bidireccional con una computadora personal a través de una interfaz serie asíncrona (**UART**).

El desafío central del proyecto radica en resolver el conflicto entre dos dominios temporales con disparidad de velocidades del orden de $5\,000$ a $1$:
* **Dominio interno de la FPGA:** Opera a **$100\text{ MHz}$** ($T_{clk} = 10\text{ ns}$), ejecutando transiciones lógicas en nanosegundos.
* **Dominio serie asíncrono (UART):** Opera a **$19\,200\text{ baudios}$** ($T_{bit} \approx 52.08\,\mu\text{s}$), transmitiendo datos bit a bit a través de una línea física.

Para vincular ambos mundos sin pérdida de información ni bloqueos de cómputo, se diseñó una arquitectura modular desacoplada mediante:
1. Un **generador de tasa de baudios** con técnica de sobremuestreo ($16\times$).
2. Un **sincronizador de 2 flip-flops** para inmunidad contra metaestabilidad en la línea de recepción.
3. Dos **memorias FIFO circulares** (una de recepción y otra de transmisión) como buffers de desacople temporal.
4. Una **máquina de estados finitos (FSM)** de interfaz que actúa como árbitro y decodificador del protocolo.

---

## 2. Marco Teórico

### 2.1. Comunicación Serie Asíncrona (Protocolo UART 8N1)
A diferencia de los protocolos síncronos (SPI, I2C) donde viaja una línea dedicada de reloj, la norma UART no transmite reloj. Ambos extremos deben acordar de antemano la velocidad (tasa de baudios) y el formato de la trama.

La trama implementada corresponde a la norma **8N1** (10 bits totales por byte):
1. **Línea en Reposo (*Idle / Marking*):** Nivel alto continuo (`1`, 3.3V).
2. **Bit de Inicio (*Start Bit / Spacing*):** Un flanco descendente a nivel bajo (`0`, 0V) durante 1 tiempo de bit, que notifica el inicio de una transmisión.
3. **Bits de Datos (*Data Bits*):** 8 bits transmitidos en orden **LSB first** (el bit menos significativo primero).
4. **Bit de Paridad:** **Sin paridad (*None*)**.
5. **Bit de Parada (*Stop Bit*):** Retorno obligatorio a nivel alto (`1`) durante al menos 1 tiempo de bit para delimitar el final de la palabra y permitir la detección del próximo Start.

```text
Línea Serie:  ───┐       ┌────┬────┬────┬────┬────┬────┬────┬────┬───────┬───
 (Reposo = 1)    │ START │ D0 │ D1 │ D2 │ D3 │ D4 │ D5 │ D6 │ D7 │ STOP  │
                 └───────┴────┴────┴────┴────┴────┴────┴────┴────┘       └───
                   (0)     <------ 8 bits de datos (LSB a MSB) ->   (1)
```

### 2.2. Técnica de Sobremuestreo ($16\times$ Oversampling)
Dado que emisor y receptor poseen osciladores independientes con pequeñas derivas de frecuencia ($\pm 2\%$) y desfases arbitrarios, muestrear en los bordes de la señal provocaría errores de lectura.

Se adopta la técnica estándar de sobremuestreo a **$16\times$**:
* El generador de baudios produce un tren de pulsos periódicos de un solo ciclo (`s_tick`) a una frecuencia $16$ veces mayor a la tasa de baudios:
  $$f_{\text{tick}} = 16 \times 19\,200\text{ Hz} = 307\,200\text{ Hz}$$
* **Cálculo del divisor de frecuencia ($M$):**
  $$M = \frac{f_{\text{FPGA}}}{16 \times \text{BaudRate}} = \frac{100\,000\,000\text{ Hz}}{307\,200\text{ Hz}} \approx 325.52 \to \mathbf{326}$$
  El contador cuenta cíclicamente de $0$ a $325$ (requiriendo un ancho de registro $N = \lceil\log_2(326)\rceil = 9\text{ bits}$).
* **Alineación y muestreo:**
  * Al detectar el flanco de bajada (Start), el receptor cuenta **8 ticks** (`s_reg == 7`), ubicándose en el **centro exacto del bit de Start** para verificar que no sea ruido.
  * Luego, avanza en intervalos de **16 ticks** (`s_reg == 15`), muestreando siempre en el centro geométrico de cada bit de datos, donde la señal posee la máxima estabilidad e inmunidad al ruido.

### 2.3. Metaestabilidad y Sincronizador de Dos Flip-Flops
La señal serie externa `i_rx` proviene del mundo exterior y puede conmutar en cualquier instante arbitrario, violando potencialmente los tiempos de establecimiento ($t_{setup}$) o retención ($t_{hold}$) del primer flip-flop de la FPGA. Si esto ocurre, el biestable puede entrar en **metaestabilidad** (un nivel analógico indefinido que oscila antes de resolverse).

Para evitar que este valor indeterminado se propague a la FSM interna, se coloca un **sincronizador de dos flip-flops en cascada**:
* El primer flip-flop absorbe el impacto de la metaestabilidad.
* El segundo flip-flop toma la señal un ciclo de reloj (10 ns) después, tiempo más que suficiente para que la salida haya colapsado a un nivel lógico seguro (`0` o `1`), aumentando el Tiempo Medio Entre Fallas (**MTBF**) a órdenes de magnitud superiores a la vida útil del chip.
* **Nota de diseño:** En el reset, ambos biestables se inicializan en `1` ya que ese es el nivel de reposo (*Idle*) de la línea serie UART.

### 2.4. Memorias FIFO Circulares (First-In, First-Out)
Las FIFOs actúan como pulmones elásticos de memoria:
* Permiten que la PC envíe ráfagas de bytes sin saturar el receptor (*buffer overrun*).
* Permiten que la interfaz deposite el resultado en un solo ciclo de reloj de 10 ns y quede libre para recibir un nuevo cálculo, mientras la FIFO de transmisión se encarga de serializar el byte lentamente hacia la PC.
* **Resolución de punteros:** Se utiliza un arreglo circular de $2^4 = 16$ bytes direccionado por dos punteros: `w_ptr` (escritura) y `r_ptr` (lectura). Para eliminar la ambigüedad de la condición $w\_ptr == r\_ptr$ (que ocurre tanto con la cola vacía como llena), se utilizan dos banderas biestables dedicadas: `empty_reg` y `full_reg`.

### 2.5. Paradigma de Máquinas de Estados (Moore vs Mealy)
* **Máquina de Moore:** Sus salidas dependen **únicamente del estado actual** ($\text{Salida} = f(\text{Estado})$). Se utiliza en `o_state` (LEDs) y en la línea física `tx` para asegurar que las señales sean perfectamente síncronas y libres de *glitches*.
* **Máquina de Mealy:** Sus salidas dependen del **estado actual y de las entradas externas** ($\text{Salida} = g(\text{Estado}, \text{Entradas})$). Se utiliza en las señales de control `rd` y `wr` de la interfaz para reaccionar inmediatamente en el mismo ciclo de reloj sin introducir estados de espera artificiales.

---

## 3. Arquitectura Global e Interconexión de Módulos

```text
 ┌────────────────────────────────────────────────────────────────────────────────────────┐
 │                                   top_uart_alu.v                                       │
 │                                                                                        │
 │                    ┌───────────────────────── uart.v ────────────────────────┐         │
 │                    │                                                         │         │
 │   i_rx             │  ┌──────────┐  s_tick   ┌─────────┐   dout   ┌────────┐ │         │
 │ ────────►[ 2-FF ]──┼─►│ baud_gen │──────────►│ uart_rx │─────────►│fifo_rx │ │         │
 │          Sync      │  └──────────┘           └─────────┘rx_done_tk└────┬───┘ │         │
 │                    │       │ s_tick                                    │r_data │
 │                    │       │                 ┌─────────┐   din    ┌────┴───┐ │         │
 │   o_tx             │       └────────────────►│ uart_tx │◄─────────│fifo_tx │ │         │
 │ ◄──────────────────┼─────────────────────────│         │tx_done_tk└────▲───┘ │         │
 │                    │                         └─────────┘               │w_data │
 │                    └───────────────────────────────────────────────────┼─────┘         │
 │                                                                        │               │
 │                                            ┌───────────────────────────┴──────────┐    │
 │                                            │               intf.v                 │    │
 │                                            │   FSM Coordinadora (4 Estados)       │    │
 │                                            └─────┬──────────────┬────────────┬────┘    │
 │                                                  │ alu_a        │ alu_b      │ alu_op  │
 │                                                  ▼              ▼            ▼         │
 │                                            ┌──────────────────────────────────────┐    │
 │                                            │               ALU.v                  │    │
 │                                            │  (ADD, SUB, AND, OR, XOR, NOR,       │    │
 │                                            │   SRL, SRA - Combinacional pura)     │    │
 │                                            └───────────────────┬──────────────────┘    │
 │                                                                │ alu_result, carry     │
 │   o_led[15:0]                                                  ▼                       │
 │ ◄────────────────────────────────────────────── {state[3:0], 3'b0, carry, result[7:0]}│
 └────────────────────────────────────────────────────────────────────────────────────────┘
```

### Tabla de Responsabilidades de los Módulos:

| Módulo | Tipo | Función Principal |
| :--- | :---: | :--- |
| [`baud_gen.v`](file:///home/nacho/TP2/src/baud_gen.v) | Secuencial | Genera el tick de habilitación a $16\times$ con divisor $M=326$. |
| [`uart_rx.v`](file:///home/nacho/TP2/src/uart_rx.v) | Secuencial (FSM) | Recibe la línea serie, detecta el Start, sobremuestrea y ensambla el byte. |
| [`uart_tx.v`](file:///home/nacho/TP2/src/uart_tx.v) | Secuencial (FSM) | Serializa el byte agregando bits de Start y Stop según la norma 8N1. |
| [`fifo.v`](file:///home/nacho/TP2/src/fifo.v) | Memoria / Sec. | Buffer circular de 16 posiciones para desacoplar tasas de transferencia. |
| [`uart.v`](file:///home/nacho/TP2/src/uart.v) | Estructural | Conecta el generador, el receptor, el transmisor y las dos FIFOs. |
| [`intf.v`](file:///home/nacho/TP2/src/intf.v) | FSM de Control | Coordina la recepción secuencial ($A \to B \to OP$) y dispara la transmisión. |
| [`ALU.v`](file:///home/nacho/TP2/src/ALU.v) | Combinacional | Unidad de cálculo de 8 bits con 8 operaciones aritmético-lógicas. |
| [`top_uart_alu.v`](file:///home/nacho/TP2/src/top_uart_alu.v) | Top Level | Sincronizador de entrada, mapeo a pines de Basys 3 y visualización en LEDs. |

---

## 4. Funcionamiento de la FSM de Control (`intf.v`)

Dado que la ALU necesita sus tres operandos ($A$, $B$ y $OP$) presentes en paralelo al mismo tiempo y la UART los entrega secuencialmente de a 1 byte por vez, la interfaz modela una FSM de 4 estados con codificación **One-Hot**:

1. **`LOAD_A (4'b0001)`:** Estado inicial de reposo. Espera que la FIFO de RX no esté vacía (`~rx_empty`). Al llegar el dato, activa `rd = 1`, almacena el byte en `a_reg` y transiciona a `LOAD_B`.
2. **`LOAD_B (4'b0010)`:** Espera el segundo byte. Activa `rd = 1`, almacena el byte en `b_reg` y transiciona a `LOAD_OP`.
3. **`LOAD_OP (4'b0100)`:** Espera el tercer byte. Activa `rd = 1`, extrae los 6 bits inferiores en `op_reg` y transiciona a `SEND`.
4. **`SEND (4'b1000)`:** Al ser la ALU combinacional, el resultado `alu_result` ya está calculado. Si la FIFO de TX tiene espacio (`~tx_full`), activa el pulso `wr = 1`, guarda el carry en `carry_reg` y vuelve inmediatamente a `LOAD_A`.

### Monitoreo en los LEDs de la Basys 3:
La salida se concatena directamente al bus de 16 LEDs:
$$\text{o\_led} = \{\text{intf\_state}[3:0],\; 3'b000,\; \text{carry\_flag},\; \text{alu\_result}[7:0]\}$$
* **LD15 a LD12:** Reflejan el estado de la FSM (`SEND`, `LOAD_OP`, `LOAD_B`, `LOAD_A`).
* **LD8:** Indicador luminoso de Carry (Acarreo).
* **LD7 a LD0:** Resultado en binario de la operación calculada por la ALU.

---

## 5. Verificación y Resultados

### 5.1. Simulación Funcional (Icarus Verilog + GTKWave)
Se desarrolló un testbench autochequeante de sistema ([`top_uart_alu_tb.v`](file:///home/nacho/TP2/src/top_uart_alu_tb.v)) con las siguientes características:
* **Escalado temporal:** Se redujo el divisor de baudios a `DVSR_SIM = 4` ($640\text{ ns}$ por bit) para acelerar los tiempos de cómputo en simulación sin alterar la lógica de las FSMs.
* **Modelo de Referencia Dorado (*Golden Model*):** Una función en Verilog computa en paralelo el resultado esperado y lo compara contra la trama recibida por `o_tx`.
* **Resultado:** Se verificaron satisfactoriamente **32 operaciones consecutivas con 0 errores** (operaciones aritméticas, lógicas, desplazamientos SRA/SRL y casos aleatorios con `$random`).

### 5.2. Verificación Física en la Placa Basys 3
Se desarrolló el script de control en Python ([`test_uart_alu.py`](file:///home/nacho/TP2/test_uart_alu.py)) para dialogar con la placa a través de `/dev/ttyUSB1`:
* **Modo Pruebas Automáticas:** Ejecuta 66 casos de prueba (16 manuales de borde + 50 aleatorios), comparando la respuesta del hardware contra un modelo de simulación en Python:
  ```text
  OK  ADD A=0x05 B=0x03  esperado=0x08  obtenido=0x08
  OK  SUB A=0x10 B=0x03  esperado=0x0D  obtenido=0x0D
  OK  SRA A=0x80 B=0x01  esperado=0xC0  obtenido=0xC0
  ...
  66/66 casos correctos
  ```
* **Modo Paso a Paso (`-s`):** Permite enviar $A \to B \to OP$ de a un byte por vez para inspeccionar visualmente en la placa cómo avanzan los LEDs de estado de la FSM (`LD12` $\to$ `LD13` $\to$ `LD14` $\to$ `LD12`), demostrando la capacidad de retención de estado del circuito ante pausas humanas arbitrarias.

---

## 6. Conclusiones

1. **Desacoplamiento de Dominios Temporales:** Se comprobó que el empleo conjunto de generadores de sobremuestreo ($16\times$) y memorias intermedias FIFO es un patrón arquitectónico indispensable para comunicar subsistemas síncronos de alta velocidad ($100\text{ MHz}$) con canales serie asíncronos lentos ($19\,200\text{ baudios}$).
2. **Robustez ante Metaestabilidad:** El uso de sincronizadores de 2 flip-flops demostró ser crítico en sistemas FPGA para aislar la lógica síncrona del ruido y asincronismo provenientes de líneas externas.
3. **Equilibrio entre Modelos FSM:** La combinación de salidas Mealy para control de flujo (`rd`, `wr`) minimiza la latencia a cero ciclos de penalización, mientras que las salidas Moore garantizan la estabilidad eléctrica en los pines de salida hacia los actuadores (LEDs y TX).
4. **Base para el Procesador Segmentado:** Este trabajo práctico sienta las bases estructurales del datapath y la unidad de control, donde la ALU y los códigos de operación aquí implementados (basados en el campo `funct` de MIPS) servirán como etapa de Ejecución (EX) para la construcción de una CPU completa.
