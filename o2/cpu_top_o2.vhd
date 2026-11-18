library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cpu_top is
  generic (
    PROG_FILE     : string  := "tracos/t0.hex";
    MEM_UNIFICADA : boolean := false
  );
  port (
    clk          : in  std_logic;
    rst          : in  std_logic;
    done         : out std_logic;
    hazard_abort : out std_logic;
    hazard_type  : out std_logic_vector(1 downto 0);
    hazard_pc    : out std_logic_vector(31 downto 0);
    hazard_cycle : out unsigned(31 downto 0);
    retired      : out unsigned(1 downto 0);
    stage_valid  : out std_logic_vector(9 downto 0);
    dbg_reg_addr : in  std_logic_vector(4 downto 0);
    dbg_reg_data : out std_logic_vector(31 downto 0)
  );
end entity;

architecture pipeline of cpu_top is
  subtype word is std_logic_vector(31 downto 0);
  subtype reg_addr is std_logic_vector(4 downto 0);

  signal pc_if, next_pc, instr_if : word;
  signal pc_id, instr_id, rs_id, rt_id, imm_id : word;
  signal pc_ex, rs_ex, rt_ex, imm_ex, operand_b, result_ex : word;
  signal pc_mem, result_mem, store_mem, read_mem_data, writeback_data : word;
  signal branch_target_ex, branch_target_mem : word;
  signal result_wb, read_wb_data : word;
  signal dest_id, dest_ex, dest_mem, dest_wb : reg_addr;
  signal aluop_id, aluop_ex : std_logic_vector(1 downto 0);
  signal alu_fn_ex : std_logic_vector(2 downto 0);
  signal reg_dst_id : std_logic;
  signal reg_write_id, reg_write_ex, reg_write_mem : std_logic;
  signal mem_to_reg_id, mem_to_reg_ex, mem_to_reg_mem : std_logic;
  signal mem_read_id, mem_read_ex, mem_read_mem : std_logic;
  signal mem_write_id, mem_write_ex, mem_write_mem : std_logic;
  signal branch_id, branch_ex, branch_mem, zero_ex, zero_mem : std_logic;
  signal alu_src_id, alu_src_ex : std_logic;
  signal halt_id, halt_ex, halt_mem, halt_wb : std_logic;
  signal valid_if, valid_id, valid_ex, valid_mem, valid_wb : std_logic;
  signal fetch_enabled, hazard_freeze, freeze, finished : std_logic;
  signal reg_write_wb, mem_to_reg_wb : std_logic;
  signal regfile_clk, reg_write_en, mem_write_en : std_logic;
begin
  finished <= valid_wb and halt_wb;
  done <= finished;
  freeze <= hazard_freeze or finished;

  -- IF: a busca para quando BREAK entra em ID. As instruções anteriores
  -- continuam pelo pipeline até o BREAK alcançar WB.
  valid_if <= fetch_enabled and not rst;
  -- Um conflito tem precedência sobre qualquer atualização do PC.
  next_pc <= pc_if when freeze = '1' else
             branch_target_mem when valid_mem = '1' and branch_mem = '1' and zero_mem = '1' else
             std_logic_vector(unsigned(pc_if) + 4) when valid_if = '1' else
             pc_if;

  fetch_pc : entity work.pc
    port map (clk => clk, rst => rst, next_pc => next_pc, pc_out => pc_if);

  instruction_memory : entity work.imem
    generic map (PROG_FILE => PROG_FILE)
    port map (addr => pc_if, instr => instr_if);

  -- IF/ID e unidade de conflitos de Davi/O2-hazard (5c4840f).
  fetch_decode : entity work.if_id
    port map (
      clk => clk, rst => rst, freeze => freeze,
      instr_in => instr_if, pc_in => pc_if, valid_in => valid_if,
      instr_out => instr_id, pc_out => pc_id, valid_out => valid_id
    );

  -- ID: decodifica a instrução e lê os operandos.
  decoder : entity work.control
    port map (
      opcode => instr_id(31 downto 26), funct => instr_id(5 downto 0),
      reg_dst => reg_dst_id, alu_src => alu_src_id, mem_to_reg => mem_to_reg_id,
      reg_write => reg_write_id, mem_read => mem_read_id, mem_write => mem_write_id,
      branch => branch_id, halt => halt_id, aluop => aluop_id
    );

  immediate_extender : entity work.sign_extend
    port map (imediato_16 => instr_id(15 downto 0), imediato_32 => imm_id);

  dest_id <= instr_id(15 downto 11) when reg_dst_id = '1' else instr_id(20 downto 16);

  -- Os registradores do pipeline avançam na subida. A O2 escreve no
  -- banco na descida e os operandos de ID estabilizam antes da próxima subida.
  regfile_clk <= not clk;
  registers : entity work.regfile
    port map (
      clk => regfile_clk, rst => rst, reg_write => reg_write_en,
      ra1 => instr_id(25 downto 21), ra2 => instr_id(20 downto 16),
      wa => dest_wb, wd => writeback_data, rd1 => rs_id, rd2 => rt_id,
      dbg_addr => dbg_reg_addr, dbg_data => dbg_reg_data
    );

  -- ID/EX de rian/o2 (407b686).
  decode_execute : entity work.id_ex
    port map (
      clk => clk, rst => rst, freeze => freeze,
      valid_in => valid_id, valid_out => valid_ex, pc_in => pc_id, pc_out => pc_ex,
      rs_val_in => rs_id, rs_val_out => rs_ex, rt_val_in => rt_id, rt_val_out => rt_ex,
      imm_in => imm_id, imm_out => imm_ex, dest_in => dest_id, dest_out => dest_ex,
      aluop_in => aluop_id, aluop_out => aluop_ex,
      reg_write_in => reg_write_id, reg_write_out => reg_write_ex,
      mem_to_reg_in => mem_to_reg_id, mem_to_reg_out => mem_to_reg_ex,
      mem_read_in => mem_read_id, mem_read_out => mem_read_ex,
      mem_write_in => mem_write_id, mem_write_out => mem_write_ex,
      branch_in => branch_id, branch_out => branch_ex,
      alu_src_in => alu_src_id, alu_src_out => alu_src_ex,
      halt_in => halt_id, halt_out => halt_ex
    );

  -- EX: executa a operação e compara os operandos do BEQ por subtração.
  operand_b <= imm_ex when alu_src_ex = '1' else rt_ex;
  branch_target_ex <= std_logic_vector(unsigned(pc_ex) + 4 + unsigned(shift_left(signed(imm_ex), 2)));

  alu_decoder : entity work.alu_control
    port map (aluop => aluop_ex, funct => imm_ex(5 downto 0), alu_op => alu_fn_ex);

  execute_alu : entity work.alu
    port map (a => rs_ex, b => operand_b, alu_op => alu_fn_ex, result => result_ex, zero => zero_ex);

  -- EX/MEM de rian/o2 (01dca8d). BEQ tomado é detectado em MEM.
  execute_memory : entity work.ex_mem
    port map (
      clk => clk, rst => rst, freeze => freeze, valid_in => valid_ex, valid_out => valid_mem,
      alu_result_in => result_ex, alu_result_out => result_mem,
      store_data_in => rt_ex, store_data_out => store_mem,
      dest_in => dest_ex, dest_out => dest_mem,
      reg_write_in => reg_write_ex, reg_write_out => reg_write_mem,
      mem_to_reg_in => mem_to_reg_ex, mem_to_reg_out => mem_to_reg_mem,
      mem_read_in => mem_read_ex, mem_read_out => mem_read_mem,
      mem_write_in => mem_write_ex, mem_write_out => mem_write_mem,
      pc_in => pc_ex, pc_out => pc_mem, zero_in => zero_ex, zero_out => zero_mem,
      branch_in => branch_ex, branch_out => branch_mem,
      branch_target_in => branch_target_ex, branch_target_out => branch_target_mem,
      halt_in => halt_ex, halt_out => halt_mem
    );

  mem_write_en <= valid_mem and mem_write_mem and not freeze and not rst;
  data_memory : entity work.dmem
    port map (
      clk => clk, endereco => result_mem, dado_entrada => store_mem,
      escrever => mem_write_en, ler => valid_mem and mem_read_mem, dado_saida => read_mem_data
    );

  -- WB usa exclusivamente o dado, o destino e os controles registrados.
  writeback_data <= read_wb_data when mem_to_reg_wb = '1' else result_wb;
  reg_write_en <= valid_wb and reg_write_wb and not freeze and not rst;

  memory_writeback : entity work.mem_wb
    port map (
      clk => clk, rst => rst, freeze => freeze, valid_in => valid_mem, valid_out => valid_wb,
      read_data_in => read_mem_data, read_data_out => read_wb_data,
      alu_result_in => result_mem, alu_result_out => result_wb,
      write_reg_in => dest_mem, write_reg_out => dest_wb,
      reg_write_in => reg_write_mem, reg_write_out => reg_write_wb,
      mem_to_reg_in => mem_to_reg_mem, mem_to_reg_out => mem_to_reg_wb,
      halt_in => halt_mem, halt_out => halt_wb
    );

  conflicts : entity work.hazard_unit
    generic map (MEM_UNIFICADA => MEM_UNIFICADA)
    port map (
      clk => clk, rst => rst,
      instr_IF_ID => instr_id, PC_IF_ID => pc_id, valid_IF_ID => valid_id,
      valid_ID_EX => valid_ex, valid_EX_MEM => valid_mem,
      regWrite_ID_EX => reg_write_ex, regWrite_EX_MEM => reg_write_mem,
      dest_ID_EX => dest_ex, dest_EX_MEM => dest_mem,
      memRead_EX_MEM => mem_read_mem, memWrite_EX_MEM => mem_write_mem,
      Branch_EX_MEM => branch_mem, zero_EX_MEM => zero_mem, PC_EX_MEM => pc_mem, PC => pc_if,
      hazard_abort => hazard_abort, hazard_type => hazard_type, hazard_PC => hazard_pc,
      hazard_cycle => hazard_cycle, freeze => hazard_freeze, if_busca => fetch_enabled
    );

  -- Uma instrução útil conclui em WB, na mesma borda usada pelo banco.
  process (clk)
  begin
    if falling_edge(clk) then
      if rst = '0' and freeze = '0' and valid_wb = '1' and halt_wb = '0' then
        retired <= to_unsigned(1, retired'length);
      else
        retired <= (others => '0');
      end if;
    end if;
  end process;

  stage_valid <= "00000" & valid_wb & valid_mem & valid_ex & valid_id & valid_if;
end architecture pipeline;
