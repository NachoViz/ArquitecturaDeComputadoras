#!/usr/bin/env python3
"""
probar_placa.py - Script en Python para comunicarse con la FPGA Basys 3 (TP2)

Envía 3 bytes (A, B, OP) por el puerto serie y lee el byte de respuesta con el resultado.
Configuración UART: 19200 baudios, 8N1 (8 bits de datos, sin paridad, 1 bit de stop).

Uso:
    python3 probar_placa.py /dev/ttyUSB1
(o el puerto COM que corresponda en tu sistema)
"""

import sys
import time

try:
    import serial
    import serial.tools.list_ports
except ImportError:
    print("ERROR: Necesitas instalar pyserial.")
    print("Instalalo ejecutando: pip install pyserial")
    sys.exit(1)

# Diccionario de operaciones según ALU.v
OPERACIONES = {
    "ADD": 0b100000, # 0x20
    "SUB": 0b100010, # 0x22
    "AND": 0b100100, # 0x24
    "OR":  0b100101, # 0x25
    "XOR": 0b100110, # 0x26
    "NOR": 0b100111, # 0x27
    "SRL": 0b000010, # 0x02
    "SRA": 0b000011, # 0x03
}

def detectar_puerto():
    puertos = list(serial.tools.list_ports.comports())
    if not puertos:
        print("No se encontraron puertos serie conectados.")
        return None
    print("Puertos disponibles detectados:")
    for p in puertos:
        print(f"  - {p.device}: {p.description}")
    # Por defecto elegimos el primero con USB
    for p in puertos:
        if "USB" in p.device or "ttyUSB" in p.device:
            return p.device
    return puertos[0].device

def ejecutar_operacion(ser, a, b, op_nombre):
    if op_nombre not in OPERACIONES:
        print(f"Operación inválida: {op_nombre}")
        return
    
    op_code = OPERACIONES[op_nombre]
    paquete = bytes([a & 0xFF, b & 0xFF, op_code & 0x3F])
    
    print(f"\nEnviando: A=0x{a:02X} ({a}), B=0x{b:02X} ({b}), OP={op_nombre} (0x{op_code:02X})")
    
    # Limpiamos buffers previos
    ser.reset_input_buffer()
    
    # Enviamos los 3 bytes
    ser.write(paquete)
    ser.flush()
    
    # Esperamos 1 byte de respuesta (timeout de 1 segundo)
    respuesta = ser.read(1)
    
    if len(respuesta) == 1:
        res = respuesta[0]
        print(f"-> Respuesta recibida de la FPGA: 0x{res:02X} ({res} dec)")
    else:
        print("-> ERROR: Tiempo de espera agotado (timeout). La FPGA no respondió.")

def main():
    puerto = sys.argv[1] if len(sys.argv) > 1 else detectar_puerto()
    if not puerto:
        print("Por favor especifica el puerto, por ejemplo: python3 probar_placa.py /dev/ttyUSB1")
        return

    print(f"Conectando a {puerto} a 19200 baudios (8N1)...")
    try:
        ser = serial.Serial(
            port=puerto,
            baudrate=19200,
            bytesize=serial.EIGHTBITS,
            parity=serial.PARITY_NONE,
            stopbits=serial.STOPBITS_ONE,
            timeout=1.0
        )
    except Exception as e:
        print(f"No se pudo abrir el puerto {puerto}: {e}")
        return

    time.sleep(0.5) # Pausa breve para estabilizar la conexión

    print("==================================================")
    print(" Probando operaciones en la FPGA Basys 3")
    print("==================================================")
    
    # Pruebas automáticas iniciales
    ejecutar_operacion(ser, 5, 3, "ADD")       # 5 + 3 = 8
    ejecutar_operacion(ser, 16, 3, "SUB")      # 16 - 3 = 13 (0x0D)
    ejecutar_operacion(ser, 0xAA, 0x55, "OR")  # AA | 55 = FF
    ejecutar_operacion(ser, 0x80, 1, "SRA")    # 0x80 >> 1 con signo = 0xC0

    # Modo interactivo
    print("\n--------------------------------------------------")
    print(" Modo interactivo: Ingresa tus propias operaciones")
    print(" Operaciones válidas: ADD, SUB, AND, OR, XOR, NOR, SRL, SRA")
    print(" Escribe 'salir' para terminar")
    print("--------------------------------------------------")

    while True:
        try:
            linea = input("\nIngresa [A B OP] (ej: 10 5 ADD): ").strip()
            if not linea or linea.lower() == 'salir':
                break
            partes = linea.split()
            if len(partes) != 3:
                print("Formato incorrecto. Debe ser: <num_A> <num_B> <OPERACION>")
                continue
            
            # Acepta formato decimal o hexadecimal con prefijo 0x
            val_a = int(partes[0], 16) if partes[0].startswith("0x") else int(partes[0])
            val_b = int(partes[1], 16) if partes[1].startswith("0x") else int(partes[1])
            op = partes[2].upper()
            
            ejecutar_operacion(ser, val_a, val_b, op)
        except ValueError:
            print("Número inválido.")
        except KeyboardInterrupt:
            break

    ser.close()
    print("\nConexión cerrada.")

if __name__ == "__main__":
    main()
