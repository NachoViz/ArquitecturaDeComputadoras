# Historia de Usuario y Plan de Trabajo: Procesador MIPS Segmentado

## 📌 Historia de Usuario Principal
**Como** estudiante de Arquitectura de Computadoras, **Quiero** diseñar, implementar en Verilog y simular un procesador MIPS segmentado de 5 etapas con manejo de riesgos, unidad de *debug* UART y ensamblador propio, **Para** realizar la simulación post-síntesis y presentar el proyecto final en el plazo de 1 mes.

---

## 🎯 Criterios de Aceptación y Alcance

1. **Pipeline de 5 Etapas:** Instruction Fetch (IF), Instruction Decode (ID), Execution (EX), Memory Access (MEM) y Write Back (WB) con sus respectivos registros inter-etapa (`IF/ID`, `ID/EX`, `EX/MEM`, `MEM/WB`).
2. **Gestión de Riesgos (*Hazards*):**
   - Unidad de cortocircuito (*Forwarding Unit*) para riesgos de datos.
   - Unidad de detección de riesgos (*Hazard Detection Unit*) para detenciones (*stalls*) y limpiezas (*flushes*) ante riesgos de control (*branches/jumps*) y estructurales.
3. **Unidad de Debug (UART):**
   - Módulo UART para transmisión/recepción serie (19200 baudios, 8 bits datos, 1 bit parada, sin paridad).
   - FSM de control con soporte para carga de programa en memoria y dos modos de ejecución: **Continuo** (hasta hallar instrucción `HALT`) y **Paso a Paso** (*step-by-step*).
4. **Ensamblador (*Assembler*):** Toolchain propio en Python/C++ para traducir código assembly MIPS a binario machine code (incluyendo la instrucción `HALT`).
5. **Simulación y Síntesis:**
   - Integración con IP Core de Clock (MMCM/PLL).
   - Validación mediante simulación funcional y simulación post-síntesis con reporte de *timing* y frecuencia máxima ($f_{max}$).

---

## 📅 Roadmap de Tareas a 4 Semanas

### Semana 1: Arquitectura de Bloques y Ensamblador
* **Tarea 1.1: Diseño esquemático y diagrama de bloques detallado**
  * **Descripción:** Dibujar el esquema completo del pipeline de 5 etapas definiendo multiplexores, registros inter-etapa y señales internas de control y datos.
  * **Dificultad:** Media
  * **Tiempo estimado:** 8 – 10 horas
* **Tarea 1.2: Desarrollo del Ensamblador (*Assembler*)**
  * **Descripción:** Crear script para traducción 1-a-1 de assembly MIPS a binario machine code, incluyendo instrucción especial `HALT`.
  * **Dificultad:** Baja - Media
  * **Tiempo estimado:** 6 – 8 horas

---

### Semana 2: Ruta de Datos (*Datapath*) y Etapas del Pipeline
* **Tarea 2.1: Adaptación de la ALU y Banco de Registros**
  * **Descripción:** Reutilizar y adaptar la ALU agregando operaciones faltantes del set MIPS e implementar el banco de registros (*Register File*) y la memoria de datos/instrucciones.
  * **Dificultad:** Media
  * **Tiempo estimado:** 8 – 10 horas
* **Tarea 2.2: Implementación de las 5 Etapas y Registros de Segmentación**
  * **Descripción:** Codificar en Verilog los módulos de cada etapa (IF, ID, EX, MEM, WB) y los registros inter-etapa (IF/ID, ID/EX, EX/MEM, MEM/WB).
  * **Dificultad:** Alta
  * **Tiempo estimado:** 12 – 15 horas

---

### Semana 3: Detección de Riesgos y Unidad de Debug (UART)
* **Tarea 3.1: Unidad de Cortocircuito (*Forwarding*) y Detección de Riesgos**
  * **Descripción:** Implementar la lógica para resolver riesgos de datos, estructurales y de control (*branches/jumps*) mediante cortocircuito, *stalls* y *flushes*.
  * **Dificultad:** Alta
  * **Tiempo estimado:** 12 – 15 horas
* **Tarea 3.2: Unidad de Debug (*Debug Unit*) e Interfaz UART**
  * **Descripción:** Diseñar la FSM de control para recibir comandos UART, cargar el programa binario en la memoria de instrucciones y gestionar los modos Continuo y Paso a paso.
  * **Dificultad:** Alta
  * **Tiempo estimado:** 10 – 12 horas

---

### Semana 4: Integración, Simulación Post-Síntesis y Documentación
* **Tarea 4.1: Testbenches y Simulación Post-Síntesis**
  * **Descripción:** Ejecutar pruebas de simulación funcional y post-síntesis (usando IP core de clock), verificar tiempos y generar reporte de *timing* e informe de frecuencia máxima.
  * **Dificultad:** Alta
  * **Tiempo estimado:** 10 – 12 horas
* **Tarea 4.2: Informe Final y Documentación del Proyecto**
  * **Descripción:** Redactar la memoria del proyecto detallando la arquitectura de bloques, FSM de la Debug Unit, testbenches utilizados y reportes de síntesis/tiempo.
  * **Dificultad:** Media
  * **Tiempo estimado:** 6 – 8 horas

---

## 📊 Resumen General
* **Carga Horaria Total Estimada:** ~72 – 90 horas.
* **Plazo de Ejecución:** 4 Semanas (1 Mes).
