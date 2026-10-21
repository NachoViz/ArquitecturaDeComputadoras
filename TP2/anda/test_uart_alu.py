#!/usr/bin/env python3
"""
Prueba de la ALU por UART en la Basys 3 (TP2).

Protocolo: se envian 3 bytes (A, B, OPCODE) y la placa responde 1 byte
con el resultado. Trama por defecto: 19200 baudios, 8 bits, sin paridad, 1 stop (8N1).
Soporta tambien paridad par (8E1) con el parametro --parity even.

Uso:
    python3 test_uart_alu.py                 # corre los casos de prueba (8N1)
    python3 test_uart_alu.py -i              # modo interactivo
    python3 test_uart_alu.py -p /dev/ttyUSB1 # cambiar puerto
    python3 test_uart_alu.py --parity even   # si el diseño hardware usa 8E1


Requiere pyserial:  pip install pyserial
"""

import argparse
import random
import sys

import serial

BAUDRATE = 19200
NBIT = 8
MASK = (1 << NBIT) - 1

OPS = {
    "ADD": 0b100000,
    "SUB": 0b100010,
    "AND": 0b100100,
    "OR": 0b100101,
    "XOR": 0b100110,
    "SRA": 0b000011,
    "SRL": 0b000010,
    "NOR": 0b100111,
}


def to_signed(x):
    """Interpreta un byte como entero con signo (complemento a 2)."""
    x &= MASK
    return x - (1 << NBIT) if x & (1 << (NBIT - 1)) else x


def modelo_alu(a, b, op):
    """Modelo de referencia de alu.v: devuelve el resultado esperado (0..255)."""
    a &= MASK
    b &= MASK
    if op == "ADD":
        r = a + b
    elif op == "SUB":
        r = a - b
    elif op == "AND":
        r = a & b
    elif op == "OR":
        r = a | b
    elif op == "XOR":
        r = a ^ b
    elif op == "SRA":
        # El desplazamiento usa B sin signo; i_a es signed -> arrastra el bit de signo
        r = to_signed(a) >> min(b, NBIT)
    elif op == "SRL":
        r = a >> b if b < NBIT else 0
    elif op == "NOR":
        r = ~(a | b)
    else:
        r = 0
    return r & MASK


def abrir_puerto(port, parity=serial.PARITY_NONE):
    return serial.Serial(
        port,
        BAUDRATE,
        bytesize=serial.EIGHTBITS,
        parity=parity,
        stopbits=serial.STOPBITS_ONE,
        timeout=1,
    )


def operar(ser, a, b, op):
    """Envia A, B y OPCODE; devuelve el byte recibido o None si hubo timeout."""
    ser.reset_input_buffer()
    ser.write(bytes([a & MASK, b & MASK, OPS[op]]))
    r = ser.read(1)
    return r[0] if r else None


def casos_de_prueba():
    """Casos de prueba para test automatico"""

    "16 casos escrito a mano"
    casos = [
        (5, 3, "ADD"),
        (127, 1, "ADD"),
        (0x80, 0x80, "ADD"),
        (0, 0, "ADD"),
        (5, 7, "SUB"),
        (0x80, 1, "SUB"),
        (10, 10, "SUB"),
        (0xF0, 0x3C, "AND"),
        (0xF0, 0x0F, "OR"),
        (0xAA, 0xFF, "XOR"),
        (0x80, 2, "SRA"),
        (0x40, 2, "SRA"),
        (0x80, 2, "SRL"),
        (0xFF, 7, "SRL"),
        (0x0F, 0xF0, "NOR"),
        (0, 0, "NOR"),
    ]

    "50 casos creados de manera aleatoria"
    rnd = random.Random(0)
    for _ in range(50):
        op = rnd.choice(list(OPS))
        b = rnd.randint(0, NBIT - 1) if op in ("SRA", "SRL") else rnd.randint(0, MASK)
        casos.append((rnd.randint(0, MASK), b, op))

    return casos


def correr_tests(ser):
    """Corre los tests automaticos y verifica los resultados"""
    fallas = 0
    casos = casos_de_prueba()
    for a, b, op in casos:
        esperado = modelo_alu(a, b, op)
        obtenido = operar(ser, a, b, op)
        ok = obtenido == esperado
        fallas += not ok
        obt_str = "timeout" if obtenido is None else f"0x{obtenido:02X}"
        print(
            f"{'OK ' if ok else 'ERR'}  {op:<3} A=0x{a:02X} B=0x{b:02X}"
            f"  esperado=0x{esperado:02X}  obtenido={obt_str}"
        )
    print(f"\n{len(casos) - fallas}/{len(casos)} casos correctos")
    return fallas == 0


def parse_num(s):
    """Acepta decimal (con signo), hex (0x..) o binario (0b..)."""
    return int(s, 0) & MASK


def modo_paso_a_paso(ser):
    """Permite enviar A, B y OP de a 1 byte por vez para ver la transicion de la FSM en los LEDs."""
    print("=== MODO PASO A PASO (Inspeccion de FSM intf.v en LEDs) ===")
    print("LEDs de estado de la FSM en la Basys 3:")
    print("  LD12 encendido -> Estado LOAD_A  (esperando operando A)")
    print("  LD13 encendido -> Estado LOAD_B  (esperando operando B)")
    print("  LD14 encendido -> Estado LOAD_OP (esperando Opcode)")
    print("  LD12 vuelve    -> Estado SEND -> LOAD_A (resultado listo)")
    print("-" * 58)
    print("Escribe 'q' en cualquier momento para salir.\n")

    ser.reset_input_buffer()

    while True:
        try:
            # 1. Enviar Byte A
            inp_a = input("[1/3] Ingresa A (ej: 5, 0x80) ['q' para salir]: ").strip()
            if inp_a.lower() in ("q", "quit", "exit"):
                break
            a = parse_num(inp_a)
            ser.write(bytes([a]))
            ser.flush()
            print(f"  -> Byte A (0x{a:02X} = {a}) enviado.")
            print("  -> ¡MIRA LA BASYS 3! Se apago LD12 y se ENCENDIO LD13 (Estado LOAD_B)\n")

            # 2. Enviar Byte B
            inp_b = input("[2/3] Ingresa B (ej: 3, 0x01) ['q' para salir]: ").strip()
            if inp_b.lower() in ("q", "quit", "exit"):
                break
            b = parse_num(inp_b)
            ser.write(bytes([b]))
            ser.flush()
            print(f"  -> Byte B (0x{b:02X} = {b}) enviado.")
            print("  -> ¡MIRA LA BASYS 3! Se apago LD13 y se ENCENDIO LD14 (Estado LOAD_OP)\n")

            # 3. Enviar Byte OP
            print(f"Operaciones validas: {', '.join(OPS)}")
            inp_op = input("[3/3] Ingresa OP (ej: ADD, SUB, SRA) ['q' para salir]: ").strip().upper()
            if inp_op.lower() in ("q", "quit", "exit"):
                break
            if inp_op not in OPS:
                print("  Opcode invalido. Pulsa el boton central (btnC) de la placa para reiniciar y reintenta.")
                continue

            ser.write(bytes([OPS[inp_op]]))
            ser.flush()
            print(f"  -> Opcode {inp_op} (0x{OPS[inp_op]:02X}) enviado.")
            print("  -> ¡MIRA LA BASYS 3! La FSM paso por SEND y VOLVIO A LD12 (LOAD_A).")
            print("  -> Los LEDs LD7:LD0 muestran el resultado y LD8 el Carry.\n")

            r = ser.read(1)
            if r:
                res = r[0]
                esperado = modelo_alu(a, b, inp_op)
                marca = " [OK]" if res == esperado else f" [ERROR: esperado 0x{esperado:02X}]"
                print(f"Resultado recibido en PC: 0x{res:02X} ({res} dec)  0b{res:08b}{marca}\n")
            else:
                print("Timeout: no se recibio respuesta de la placa (prueba reset con btnC)\n")
            print("=" * 58)

        except (EOFError, KeyboardInterrupt):
            print()
            break
        except ValueError:
            print("Numero invalido. Pulsa btnC en la placa para resetear si fue a medio camino.")


def modo_interactivo(ser):
    print(f"Operaciones: {', '.join(OPS)}")
    print("Formato: A B OP   (ej: 5 3 ADD, 0xF0 0x0F OR, -3 2 SRA).")
    print("Tip: escribe 'paso' para entrar al modo de envio dato por dato.")
    print("Escribe 'q' para salir.")
    while True:
        try:
            linea = input("> ").strip()
        except (EOFError, KeyboardInterrupt):
            print()
            break
        if linea.lower() in ("q", "quit", "exit"):
            break
        if linea.lower() in ("paso", "step"):
            modo_paso_a_paso(ser)
            continue
        partes = linea.split()
        if len(partes) != 3 or partes[2].upper() not in OPS:
            print("Formato invalido")
            continue
        try:
            a, b = parse_num(partes[0]), parse_num(partes[1])
        except ValueError:
            print("Numero invalido")
            continue
        op = partes[2].upper()
        r = operar(ser, a, b, op)
        if r is None:
            print("Timeout: no llego respuesta (probar reset con btnC)")
            continue
        esperado = modelo_alu(a, b, op)
        marca = "" if r == esperado else f"   <-- esperado 0x{esperado:02X}"
        print(f"= 0x{r:02X}  {r:3d}  (con signo: {to_signed(r):4d})  0b{r:08b}{marca}")


def main():
    parser = argparse.ArgumentParser(description="Prueba de la ALU por UART (TP2)")
    parser.add_argument(
        "-p",
        "--port",
        default="/dev/ttyUSB1",
        help="puerto serie de la Basys 3 (default: /dev/ttyUSB1)",
    )
    parser.add_argument(
        "-i",
        "--interactivo",
        action="store_true",
        help="modo interactivo en lugar de los casos de prueba",
    )
    parser.add_argument(
        "-s",
        "--paso-a-paso",
        action="store_true",
        help="envia dato por dato (A -> B -> OP) para ver la FSM en los LEDs",
    )
    parser.add_argument(
        "--parity",
        choices=["none", "even", "odd"],
        default="none",
        help="paridad UART: none (8N1, default para top_uart_alu) o even (8E1)",
    )
    args = parser.parse_args()

    parity_map = {
        "none": serial.PARITY_NONE,
        "even": serial.PARITY_EVEN,
        "odd": serial.PARITY_ODD,
    }

    try:
        ser = abrir_puerto(args.port, parity=parity_map[args.parity])
    except serial.SerialException as e:
        sys.exit(f"No se pudo abrir {args.port}: {e}")

    with ser:
        if args.paso_a_paso:
            modo_paso_a_paso(ser)
        elif args.interactivo:
            modo_interactivo(ser)
        else:
            sys.exit(0 if correr_tests(ser) else 1)


if __name__ == "__main__":
    main()
