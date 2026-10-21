#-----------------------------------------------------------------------------
# create_project.tcl - Arma el proyecto de Vivado para la carpeta "anda"
#
# Uso dentro de Vivado:
#   Tools > Run Tcl Script...  y elegir este archivo
#
# O desde consola de Linux:
#   /home/nacho/Documentos/Vivado/2024.2/bin/vivado -mode batch -source create_project.tcl
#-----------------------------------------------------------------------------

set project_name "TP2_anda"
set part_name    "xc7a35tcpg236-1"   ;# Digilent Basys 3

set origin_dir [file dirname [file normalize [info script]]]
set proj_dir   "$origin_dir/vivado"

create_project $project_name $proj_dir -part $part_name -force

# --- Fuentes de diseño (todos los .v menos el testbench) ---
set design_files [list \
    "$origin_dir/ALU.v" \
    "$origin_dir/baud_gen.v" \
    "$origin_dir/fifo.v" \
    "$origin_dir/intf.v" \
    "$origin_dir/top_uart_alu.v" \
    "$origin_dir/uart_rx.v" \
    "$origin_dir/uart_tx.v" \
    "$origin_dir/uart.v" \
]
add_files -fileset sources_1 $design_files

# --- Constraints (Basys3_Master.xdc) ---
add_files -fileset constrs_1 "$origin_dir/Basys3_Master.xdc"

# --- Simulación (top_uart_alu_tb.v) ---
add_files -fileset sim_1 "$origin_dir/top_uart_alu_tb.v"

# --- Tops ---
set_property top top_uart_alu    [get_filesets sources_1]
set_property top top_uart_alu_tb [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts ""
puts "==================================================================="
puts " Proyecto creado con éxito en: $proj_dir/$project_name.xpr"
puts " Top de síntesis   : top_uart_alu"
puts " Top de simulación : top_uart_alu_tb"
puts " Chip configurado  : $part_name (Basys 3)"
puts "==================================================================="
