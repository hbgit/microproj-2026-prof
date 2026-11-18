
library ieee;
use ieee.std_logic_1164.all;

entity mem_wb is
    port (
        clk : in std_logic;
        rst : in std_logic;

        valid_in      : in std_logic;
        read_data_in  : in std_logic_vector(31 downto 0);
        alu_result_in : in std_logic_vector(31 downto 0);
        write_reg_in  : in std_logic_vector(4 downto 0);
        reg_write_in  : in std_logic;
        mem_to_reg_in : in std_logic;
        halt_in       : in std_logic;

        valid_out      : out std_logic;
        read_data_out  : out std_logic_vector(31 downto 0);
        alu_result_out : out std_logic_vector(31 downto 0);
        write_reg_out  : out std_logic_vector(4 downto 0);
        reg_write_out  : out std_logic;
        mem_to_reg_out : out std_logic;
        halt_out       : out std_logic;
        freeze         : in std_logic := '0'
    );
end entity mem_wb;

architecture rtl of mem_wb is
begin

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                valid_out      <= '0';
                read_data_out  <= (others => '0');
                alu_result_out <= (others => '0');
                write_reg_out  <= (others => '0');
                reg_write_out  <= '0';
                mem_to_reg_out <= '0';
                halt_out       <= '0';
            elsif freeze = '0' then
                valid_out      <= valid_in;
                read_data_out  <= read_data_in;
                alu_result_out <= alu_result_in;
                write_reg_out  <= write_reg_in;
                reg_write_out  <= reg_write_in;
                mem_to_reg_out <= mem_to_reg_in;
                halt_out       <= halt_in;
            end if;
        end if;
    end process;

end architecture rtl;
