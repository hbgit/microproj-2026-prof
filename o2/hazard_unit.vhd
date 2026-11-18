library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity hazard_unit is
    generic (
        MEM_UNIFICADA : boolean := false
    );
    port (
        clk   : in std_logic;
        rst : in std_logic;
        instr_IF_ID : in std_logic_vector(31 downto 0);
        PC_IF_ID    : in std_logic_vector(31 downto 0);
        valid_IF_ID : in std_logic;
        valid_ID_EX : in std_logic;
        valid_EX_MEM : in std_logic;
        regWrite_ID_EX : in std_logic;
        regWrite_EX_MEM : in std_logic;
        dest_ID_EX : in std_logic_vector(4 downto 0);
        dest_EX_MEM : in std_logic_vector(4 downto 0);
        memRead_EX_MEM : in std_logic;
        memWrite_EX_MEM : in std_logic;
        Branch_EX_MEM : in std_logic;
        zero_EX_MEM : in std_logic;
        PC_EX_MEM : in std_logic_vector(31 downto 0);
        PC : in std_logic_vector(31 downto 0);
        hazard_abort : out std_logic;
        hazard_type : out std_logic_vector(1 downto 0);
        hazard_PC : out std_logic_vector(31 downto 0);
        hazard_cycle : out unsigned(31 downto 0);
        freeze : out std_logic;
        if_busca : out std_logic
        );

end entity;
architecture hazard_unit_arch of hazard_unit is
    signal opcode : std_logic_vector(5 downto 0);
    signal rs : std_logic_vector(4 downto 0);
    signal rt : std_logic_vector(4 downto 0);
    signal funct : std_logic_vector(5 downto 0);
    signal le_rs : std_logic;
    signal le_rt : std_logic;
    signal haz_dados_ID_EX : std_logic;
    signal haz_dados_EX_MEM : std_logic;
    signal haz_dados : std_logic;
    signal haz_controle : std_logic;
    signal haz_estrutural : std_logic;
    signal break_ID : std_logic;
    signal busca : std_logic;
    signal break_visto : std_logic;
    signal haz_detectado : std_logic;
    signal tipo_atual  : std_logic_vector(1 downto 0);
    signal pc_atual  : std_logic_vector(31 downto 0);
    signal ciclo_contador : unsigned(31 downto 0);
    signal abortado : std_logic;
    signal tipo_guardado : std_logic_vector(1 downto 0);
    signal PC_guardado : std_logic_vector(31 downto 0);
    signal ciclo_guardado : unsigned(31 downto 0);

begin
    --decodificacao da consumidora--
    opcode <= instr_IF_ID(31 downto 26);
    rs <= instr_IF_ID(25 downto 21);
    rt <= instr_IF_ID(20 downto 16);
    funct <= instr_IF_ID(5 downto 0);
    break_ID <= '1' when (opcode = "000000" and funct = "001101" and valid_IF_ID = '1') else '0';
    busca <= not(break_ID or break_visto);
    if_busca <= busca;

    le_rs <= '0' when (opcode = "000000" and funct = "001101") else '1';
    le_rt <= '1' when ((opcode = "000000" and funct /= "001101") or opcode = "101011" or opcode = "000100") else '0';
    

    --deteccao de hazards--
    --conflito de dados com a instrucao no estagio ID_EX
    haz_dados_ID_EX <= '1' when (valid_ID_EX = '1' and valid_IF_ID = '1' and regWrite_ID_EX = '1' and dest_ID_EX /= "00000" and ((le_rs = '1' and rs = dest_ID_EX) or (le_rt = '1' and rt = dest_ID_EX))) else '0';
    
    --conflito de dados com a instrucao no estagio EX_MEM
    haz_dados_EX_MEM <= '1' when (valid_EX_MEM = '1' and valid_IF_ID = '1' and regWrite_EX_MEM = '1' and dest_EX_MEM /= "00000" and ((le_rs = '1' and rs = dest_EX_MEM) or (le_rt = '1' and rt = dest_EX_MEM))) else '0';
    
    --conflito de dados
    haz_dados <= '1' when (haz_dados_ID_EX = '1' or haz_dados_EX_MEM = '1') else '0';
    
    --conflito de controle
    haz_controle <= '1' when (valid_EX_MEM = '1' and 
    (valid_IF_ID = '1' or valid_ID_EX = '1' or busca = '1') and 
    Branch_EX_MEM = '1' and 
    zero_EX_MEM = '1') else '0';
    
    --conflito estrutural
    haz_estrutural <= '1' when MEM_UNIFICADA and 
    valid_EX_MEM = '1' and 
    (memRead_EX_MEM = '1' or memWrite_EX_MEM = '1') 
    and busca = '1' else '0';
    

    --Prioridade de hazard--
    haz_detectado <= haz_controle or haz_dados or haz_estrutural;
    prioridades: process(all) is
    begin
        if haz_controle = '1' then
            pc_atual <= PC_EX_MEM;
            tipo_atual <= "11";
        elsif haz_dados = '1' then
            pc_atual <= PC_IF_ID;
            tipo_atual <= "01";
        elsif haz_estrutural = '1' then
            pc_atual <= PC;
            tipo_atual <= "10";
        else 
            pc_atual <= (others => '0');
            tipo_atual <= "00";
        end if;
    end process;


    --contador e registro do aborto--
    registros: process(clk) is
    begin
        if rising_edge(clk) then
            if rst = '1' then
                ciclo_contador <= to_unsigned(1,32);
                abortado <= '0';
                break_visto <= '0';
                tipo_guardado  <= "00";
                PC_guardado  <= (others => '0');
                ciclo_guardado <= (others => '0');
            else
                if (haz_detectado = '1' and abortado = '0') then
                    abortado <= '1';
                    tipo_guardado <= tipo_atual;
                    PC_guardado <= pc_atual;
                    ciclo_guardado <= ciclo_contador;
                end if;
                if break_ID = '1' then
                    break_visto <= '1';
                end if;
                ciclo_contador <= ciclo_contador + 1 ;
            end if;
        end if;
    end process;


    --saidas--
    hazard_type <= tipo_guardado when abortado = '1' else tipo_atual;
    hazard_PC <= PC_guardado when abortado = '1' else pc_atual;
    hazard_cycle <= ciclo_guardado when abortado = '1' else ciclo_contador;
    hazard_abort <= '1' when abortado = '1' else haz_detectado;
    freeze <= '1' when abortado = '1' else haz_detectado;
end architecture;