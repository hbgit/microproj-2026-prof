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

architecture cpu_top_arch of cpu_top is
  --sinais de interconexao entre os modulos--

  --Busca(PC e memoria de instrucoes)
  signal pc          : std_logic_vector(31 downto 0);
  signal pc_plus4    : std_logic_vector(31 downto 0);
  signal instr       : std_logic_vector(31 downto 0);

  --Decodificacao(banco de registradores e extensao de imediato)
  signal reg_data1    : std_logic_vector(31 downto 0);
  signal reg_data2    : std_logic_vector(31 downto 0);
  signal imm_out      : std_logic_vector(31 downto 0);

  --Unidade de controle
  signal reg_dst     : std_logic;
  signal alu_src     : std_logic;
  signal mem_to_reg  : std_logic;
  signal reg_write   : std_logic;
  signal mem_read    : std_logic;
  signal mem_write   : std_logic;
  signal branch      : std_logic;
  signal halt        : std_logic;
  signal aluop       : std_logic_vector(1 downto 0);

  --Execucao(ULA e controle da ULA)
  signal alu_result    : std_logic_vector(31 downto 0);
  signal alu_b      : std_logic_vector(31 downto 0);
  signal alu_op     : std_logic_vector(2 downto 0);
  signal alu_zero   : std_logic;
  
  --Memoria de dados
  signal mem_read_data : std_logic_vector(31 downto 0);

  --Escrita no banco de registradores
  signal reg_write_data : std_logic_vector(31 downto 0);
  signal write_reg  : std_logic_vector(4 downto 0);
    
  --Desvio e proximo PC
  signal branch_target : std_logic_vector(31 downto 0);
  signal next_pc    : std_logic_vector(31 downto 0);
  signal imm_sll    : std_logic_vector(31 downto 0);
  signal PCSrc      : std_logic;

begin
  --INSTANCIACAO DOS MODULOS--

  --program counter
  pc_reg : entity work.pc
    port map (
      clk      => clk,
      rst      => rst,
      next_pc  => next_pc,
      pc_out   => pc
    );
  --memoria de instrucoes
  imem_inst : entity work.imem
    generic map (
      PROG_FILE => PROG_FILE
    )
    port map (
      addr  => pc,
      instr => instr
    );

  --modulo de registradores
  regfile_inst : entity work.regfile
    port map (
      clk          => clk,
      rst          => rst,
      reg_write    => reg_write,
      ra1          => instr(25 downto 21),
      ra2          => instr(20 downto 16),
      wa           => write_reg,
      wd           => reg_write_data,
      rd1          => reg_data1,
      rd2          => reg_data2,
      dbg_addr     => dbg_reg_addr,
      dbg_data     => dbg_reg_data
      );
    
  --modulo de extensao de sinal de imediato
  sign_extend_inst: entity work.sign_extend
    port map (
      imediato_16  => instr(15 downto 0),
      imediato_32  => imm_out
      );
    
  --modulo de controle
  control_inst : entity work.control
    port map (
      opcode     => instr(31 downto 26),
      funct      => instr(5 downto 0),
      reg_dst    => reg_dst,
      alu_src    => alu_src,
      mem_to_reg => mem_to_reg,
      reg_write  => reg_write,
      mem_read   => mem_read,
      mem_write  => mem_write,
      branch     => branch,
      halt       => halt,
      aluop      => aluop
    );
        
  --modulo ALU
  alu_inst : entity work.alu
    port map (
      alu_op   => alu_op,
      a        => reg_data1,
      b        => alu_b,
      result   => alu_result,
      zero     => alu_zero
    );

  --modulo de controle da ALU
  alu_control_inst : entity work.alu_control
    port map (
      aluop      => aluop,
      funct      => instr(5 downto 0),
      alu_op     => alu_op
    );

  --memoria de dados
  dmem_inst : entity work.dmem
    port map (
      clk          => clk,
      endereco     => alu_result,
      dado_entrada => reg_data2,
      escrever     => mem_write,
      ler          => mem_read,
      dado_saida   => mem_read_data
    );

  --Conexao dos sinais de controle com os modulos--

  --somador PC+4
  pc_plus4 <= std_logic_vector(unsigned(pc) + 4);
  
  --shift left 2
  imm_sll <= std_logic_vector(shift_left(signed(imm_out), 2));

  --somador branch target
  branch_target <= std_logic_vector(unsigned(pc_plus4) + unsigned(imm_sll));
  
  --AND desvio
  PCSrc <= branch and alu_zero;

  --mux proximo PC
  process (all)
  begin
    case halt is
      when '1' => next_pc <= pc;
      when others  =>
        if PCSrc = '1' then
          next_pc <= branch_target;
        else
          next_pc <= PC_plus4;
        end if;
    end case;
  end process;

  --mux RegDst
  write_reg <= instr(15 downto 11) when reg_dst = '1' else instr(20 downto 16);
  
  --mux AluSrc
  alu_b <= imm_out when alu_src = '1' else reg_data2;
  
  --mux MemToReg
  reg_write_data <= mem_read_data when mem_to_reg = '1' else alu_result;

  --atribuicao de done
  done <= halt;

  --atribuicao de retired
  retired <= "01" when halt = '0' else "00";
  
  --atribuicao de hazards
  hazard_abort <= '0';
  hazard_type  <= "00";
  hazard_pc    <= (others => '0');
  hazard_cycle <= (others => '0');

  --atribuicao de stage_valid
  stage_valid <= "0000000001";

end architecture;