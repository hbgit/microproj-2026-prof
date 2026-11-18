library ieee;
use ieee.std_logic_1164.all;

entity control is
    port (
        opcode     : in std_logic_vector(5 downto 0);
        funct      : in std_logic_vector(5 downto 0);
        reg_dst    : out std_logic;
        alu_src    : out std_logic;
        mem_to_reg : out std_logic;
        reg_write  : out std_logic;
        mem_read   : out std_logic;
        mem_write  : out std_logic;
        branch     : out std_logic;
        halt       : out std_logic;
        aluop     : out std_logic_vector(1 downto 0)
    );
end entity;

architecture control_arch of control is
begin
    process (opcode, funct)
    begin
        -- garantia de que todos os sinais de controle comecem com 0
        reg_dst    <= '0';
        alu_src    <= '0';
        mem_to_reg <= '0';
        reg_write  <= '0';
        mem_read   <= '0';
        mem_write  <= '0';
        branch     <= '0';
        halt       <= '0';
        aluop     <= "00";

        case opcode is
            when "000000" =>  --Tipo R
                if funct = "001101" then
                    halt <= '1';
                    aluop <= "10";
                else
                    reg_dst    <= '1';
                    reg_write  <= '1';
                    aluop     <= "10";
                end if;
            when "100011" =>  -- lw
                alu_src    <= '1';
                mem_to_reg <= '1';
                reg_write  <= '1';
                mem_read   <= '1';
            when "101011" =>  -- sw
                alu_src    <= '1';
                mem_write  <= '1';
            when "000100" =>  -- beq
                branch     <= '1';
                aluop     <= "01";
            when "001000" =>  -- addi
                alu_src    <= '1';
                reg_write  <= '1';
            when others =>
                null;
        end case;
    end process;

end architecture control_arch;