#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

if (( $# > 1 )) || [[ ${1:-} != "" && ${1:-} != "--o1-only" ]]; then
  printf 'Uso: bash run_all.sh [--o1-only]\n' >&2
  exit 2
fi

somente_o1=false
if [[ ${1:-} == --o1-only ]]; then
  somente_o1=true
elif [[ ! -s o2/cpu_top_o2.vhd || ! -s o2/mem_wb.vhd ]]; then
  printf 'A simulação da O2 requer cpu_top_o2.vhd e mem_wb.vhd. Use --o1-only para testar a O1.\n' >&2
  exit 1
fi

ghdl="${GHDL:-ghdl}"
saida=build/validacao
o1="$saida/o1"
o2="$saida/o2"
metricas="$saida/metricas.csv"
mkdir -p "$o1" "$o2"
printf 'org;programa;ciclos;instrucoes;CPI;IPC;ocupacao;erros;ocupacao_IF_ou_O1;ocupacao_ID;ocupacao_EX;ocupacao_MEM;ocupacao_WB\n' > "$metricas"

# Ambas as organizações declaram cpu_top e usam bibliotecas separadas.
bash compilar_o1.sh "$o1"
"$ghdl" -a --std=08 --workdir="$o1" tb/{tb_cpu,tb_dmem,tb_pc,tb_sign_extend}.vhd
if ! "$somente_o1"; then
  "$ghdl" -a --std=08 --workdir="$o2" \
    o1/{alu,alu_control,control,dmem,imem,pc,regfile,sign_extend}.vhd \
    o2/{if_id,id_ex,ex_mem,mem_wb,hazard_unit,cpu_top_o2}.vhd tb/tb_cpu.vhd
fi

cd "$saida"
for unidade in dmem pc sign_extend; do
  "$ghdl" --elab-run --std=08 --workdir=o1 "tb_$unidade" --assert-level=error --stop-time=1us
done

simular() {
  local biblioteca="$1" org="$2" slots="$3" traco="$4"
  shift 4
  "$ghdl" --elab-run --std=08 --workdir="$biblioteca" tb_cpu \
    "-gORG_NOME=$org" "-gNUM_SLOTS=$slots" "-gPROG_FILE=../../tracos/$traco.hex" \
    "--wave=$biblioteca/$traco.ghw" \
    --assert-level=error --ieee-asserts=disable-at-0 "$@"
}

for tamanho in 36 5 10 20 50 100 200; do
  traco="s$tamanho"
  if [[ "$tamanho" == 36 ]]; then traco=t0; fi
  esperado="-gESPERADO_FILE=../../tracos/${traco}_esperado.txt"
  simular o1 O1 1 "$traco" "$esperado" \
    "-gINSTRUCOES_ESPERADAS=$tamanho" "-gCICLOS_ESPERADOS=$((tamanho + 1))"
  if ! "$somente_o1"; then
    simular o2 O2 5 "$traco" "$esperado" \
      "-gINSTRUCOES_ESPERADAS=$tamanho"
  fi
done

if ! "$somente_o1"; then
  simular o2 O2 5 td "-gESPERADO_FILE=../../tracos/td_esperado.txt" -gESPERA_ABORTO=true -gTIPO_ESPERADO=1 -gPC_ESPERADO=4
  simular o2 O2 5 te "-gESPERADO_FILE=../../tracos/te_esperado.txt" -gESPERA_ABORTO=true -gTIPO_ESPERADO=2 -gPC_ESPERADO=12 -gMEM_UNIFICADA=true
  simular o2 O2 5 tc "-gESPERADO_FILE=../../tracos/tc_esperado.txt" -gESPERA_ABORTO=true -gTIPO_ESPERADO=3 -gPC_ESPERADO=0
fi

# Atrasos do exemplo do livro em ps e overhead assumido para o pipeline.
memoria_ps=200
alu_ps=200
banco_ps=100
registrador_ps=20
periodo_o1=$((2 * memoria_ps + alu_ps + 2 * banco_ps))
periodo_o2=$((memoria_ps + registrador_ps))
periodo_meio_ciclo=$((2 * (banco_ps + registrador_ps)))
if (( periodo_meio_ciclo > periodo_o2 )); then
  periodo_o2=$periodo_meio_ciclo
fi

LC_ALL=C awk -F';' -v o1="$periodo_o1" -v o2="$periodo_o2" '
  BEGIN {
    print "programa;periodo_O1_ps;tempo_O1_ps;periodo_O2_ps;tempo_O2_ps;speedup_estimado;limite_modelo;ideal_5_estagios"
  }
  NR > 1 && $1 == "O1" {
    ciclos_o1[$2] = $3
  }
  NR > 1 && $1 == "O2" && $2 in ciclos_o1 {
    tempo_o1 = ciclos_o1[$2] * o1
    tempo_o2 = $3 * o2
    printf "%s;%d;%d;%d;%d;%.6f;%.6f;5\n", $2, o1, tempo_o1, o2, tempo_o2, tempo_o1 / tempo_o2, o1 / o2
  }
' metricas.csv > tempos_estimados.csv

printf 'Métricas em %s, estimativas em %s/tempos_estimados.csv e formas de onda em %s.\n'  "$metricas" "$saida" "$saida"
