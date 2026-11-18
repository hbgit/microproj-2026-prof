#!/usr/bin/env bash
# Compila a O1 em VHDL-2008, deixando o topo para depois das dependências.
set -euo pipefail
cd "$(dirname "$0")"

workdir="${1:-build/o1}"
ghdl="${GHDL:-ghdl}"
mkdir -p "$workdir"
"$ghdl" -a --std=08 --workdir="$workdir" \
  o1/{alu,alu_control,control,dmem,imem,pc,regfile,sign_extend,cpu_top}.vhd
echo "O1 compilada sem erros"
