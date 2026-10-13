### Historia de Usuario y Plan de Trabajo: Procesador MIPS Segmentado

#### 📌 Historia de Usuario Principal
**Como** estudiante de Arquitectura de Computadoras, **Quiero** diseñar, implementar en Verilog y simular un procesador MIPS segmentado de 5 etapas con manejo de riesgos, unidad de *debug* UART (`debugInterface`) y ensamblador propio en Python (`PyMips`), **Para** realizar la simulación post-síntesis y presentar el proyecto final en el plazo de 1 mes.

---

#### 🎯 Criterios de Aceptación y Alcance

1. **Pipeline de 5 Etapas:** Instruction Fetch (IF), Instruction Decode (ID), Execution (EX), Memory Access (MEM) y Write Back (WB) con sus respectivos registros inter-etapa (IF/ID, ID/EX, EX/MEM, MEM/WB).
2. **Gestión de Riesgos (Hazards):**
   * **Unidad de Cortocircuito (*Forwarding Unit*):** Control de los multiplexores de operandos (`MUXD1F` / `MUXD2F`) para resolver riesgos de datos.
   * **Unidad de Detección de Riesgos (*Hazard Detector*):** Inserción de burbujas (*stalls*) mediante `MUXD1` y limpiezas (*flushes*) ante riesgos de control e instrucciones de carga (*Load-Use*).
   * **Control de Saltos en ID (`BranchControl`):** Cálculo de dirección de salto y evaluación de condición anticipada en la etapa ID para minimizar la penalización por *branch*.
3. **Unidad de Debug (`debugInterface` + UART):**
   * Módulo transceptor UART (19200 baudios, 8N1).
   * Módulo `debugInterface` que interpreta comandos UART para:
     * Carga de programa ejecutable en la memoria de instrucciones.
     * Gestión de modo **Continuo** (ejecución hasta hallar la instrucción `HALT`) y modo **Paso a Paso** (*step-by-step*).
     * Envío/Dump del estado interno del procesador (PC final y registros) de regreso a la PC.
4. **Ensamblador (*PyMips*):** Toolchain propio en Python para traducción 1-a-1 de código *assembly* MIPS a binario/hexadecimal machine code, incluyendo soporte para la instrucción especial `HALT` y prueba rápida desde línea de comandos (CLI).
5. **Simulación y Síntesis:**
   * Integración con IP Core de Clock (MMCM/PLL).
   * Validación mediante simulación funcional y simulación post-síntesis con reporte de *timing* y frecuencia máxima ($f_{max}$).

---

#### 📅 Roadmap de Tareas a 4 Semanas

##### Semana 1: Arquitectura de Bloques y Ensamblador (`PyMips`)
* **Tarea 1.1: Esquema detallado del Datapath y Control**
  * **Descripción:** Dibujar la arquitectura completa especificando los submódulos por etapa (IF, ID, EX, MEM, WB), unidades de riesgo y la `debugInterface`.
  * **Dificultad:** Media | **Tiempo estimado:** 8 – 10 horas
* **Tarea 1.2: Desarrollo del Ensamblador (`PyMips`)**
  * **Descripción:** Desarrollar el script de Python para traducir instrucciones MIPS a formato hexadecimal, agregando la instrucción `HALT` y programas de prueba (`lui.asm`, `fact.asm`).
  * **Dificultad:** Baja - Media | **Tiempo estimado:** 6 – 8 horas

##### Semana 2: Etapas del Pipeline y Módulos de Decodificación
* **Tarea 2.1: Adapta la ALU, Banco de Registros y Módulos de ID**
  * **Descripción:** Reutilizar la ALU del TP1, implementar el `RegisterFile`, `SignExtend` y el módulo `BranchControl` para evaluación de saltos en ID.
  * **Dificultad:** Media | **Tiempo estimado:** 8 – 10 horas
* **Tarea 2.2: Implementación de las 5 Etapas y Registros de Segmentación**
  * **Descripción:** Codificar en Verilog los módulos de cada etapa y los registros inter-etapa (IF/ID, ID/EX, EX/MEM, MEM/WB).
  * **Dificultad:** Alta | **Tiempo estimado:** 12 – 15 horas

##### Semana 3: Unidades de Riesgos y Debug Unit (`debugInterface`)
* **Tarea 3.1: Implementación de Forwarding Unit y Hazard Detector**
  * **Descripción:** Lógica de cortocircuito (`ForwardingUnit` + multiplexores `MUXD1F`/`MUXD2F`) e inyección de *stalls*/*flushes* (`HazardDetector` + `MUXD1`).
  * **Dificultad:** Alta | **Tiempo estimado:** 12 – 15 horas
* **Tarea 3.2: Unidad de Debug (`debugInterface` + UART)**
  * **Descripción:** FSM de control en `debugInterface` para parsear comandos UART, escribir la memoria de programa, controlar paso a paso/continuo y transmitir el dump de registros.
  * **Dificultad:** Alta | **Tiempo estimado:** 10 – 12 horas

##### Semana 4: Integración, Simulación Post-Síntesis e Informe
* **Tarea 4.1: Testbenches e Integración con IP Core de Clock**
  * **Descripción:** Simulación funcional completa, síntesis en Vivado con MMCM/PLL y análisis de reporte de *timing* ($f_{max}$).
  * **Dificultad:** Alta | **Tiempo estimado:** 10 – 12 horas
* **Tarea 4.2: Informe Final y Documentación**
  * **Descripción:** Redacción de la memoria técnica del proyecto, diagramas de bloques y guía de uso de `PyMips` y la `debugInterface`.
  * **Dificultad:** Media | **Tiempo estimado:** 6 – 8 horas
