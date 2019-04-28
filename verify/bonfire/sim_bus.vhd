---------------------------------------------------------------------
-- Simple WISHBONE interconnect
--
-- Generated by wigen at Sun Apr 28 16:00:05 2019
--
-- Configuration:
--     Number of masters:     2
--     Number of slaves:      2
--     Master address width:  32
--     Slave address width:   28
--     Port size:             32
--     Port granularity:      8
--     Entity name:           sim_bus
--     Pipelined arbiter:     no
--     Registered feedback:   yes
--     Unsafe slave decoder:  no
--
-- Command line:
--     wigen -e sim_bus -r 2 2 32 28 32 8
---------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity sim_bus is
	port(
		clk_i: in std_logic;
		rst_i: in std_logic;

		s0_cyc_i: in std_logic;
		s0_stb_i: in std_logic;
		s0_we_i: in std_logic;
		s0_sel_i: in std_logic_vector(3 downto 0);
		s0_cti_i: in std_logic_vector(2 downto 0);
		s0_bte_i: in std_logic_vector(1 downto 0);
		s0_ack_o: out std_logic;
		s0_adr_i: in std_logic_vector(31 downto 2);
		s0_dat_i: in std_logic_vector(31 downto 0);
		s0_dat_o: out std_logic_vector(31 downto 0);

		s1_cyc_i: in std_logic;
		s1_stb_i: in std_logic;
		s1_we_i: in std_logic;
		s1_sel_i: in std_logic_vector(3 downto 0);
		s1_cti_i: in std_logic_vector(2 downto 0);
		s1_bte_i: in std_logic_vector(1 downto 0);
		s1_ack_o: out std_logic;
		s1_adr_i: in std_logic_vector(31 downto 2);
		s1_dat_i: in std_logic_vector(31 downto 0);
		s1_dat_o: out std_logic_vector(31 downto 0);

		m0_cyc_o: out std_logic;
		m0_stb_o: out std_logic;
		m0_we_o: out std_logic;
		m0_sel_o: out std_logic_vector(3 downto 0);
		m0_cti_o: out std_logic_vector(2 downto 0);
		m0_bte_o: out std_logic_vector(1 downto 0);
		m0_ack_i: in std_logic;
		m0_adr_o: out std_logic_vector(27 downto 2);
		m0_dat_o: out std_logic_vector(31 downto 0);
		m0_dat_i: in std_logic_vector(31 downto 0);

		m1_cyc_o: out std_logic;
		m1_stb_o: out std_logic;
		m1_we_o: out std_logic;
		m1_sel_o: out std_logic_vector(3 downto 0);
		m1_cti_o: out std_logic_vector(2 downto 0);
		m1_bte_o: out std_logic_vector(1 downto 0);
		m1_ack_i: in std_logic;
		m1_adr_o: out std_logic_vector(27 downto 2);
		m1_dat_o: out std_logic_vector(31 downto 0);
		m1_dat_i: in std_logic_vector(31 downto 0)
	);
end entity;

architecture rtl of sim_bus is

signal request: std_logic_vector(1 downto 0);
signal grant_next: std_logic_vector(1 downto 0);
signal grant: std_logic_vector(1 downto 0);
signal grant_reg: std_logic_vector(1 downto 0):=(others=>'0');

signal select_slave: std_logic_vector(2 downto 0);

signal cyc_mux: std_logic;
signal stb_mux: std_logic;
signal we_mux: std_logic;
signal sel_mux: std_logic_vector(3 downto 0);
signal cti_mux: std_logic_vector(2 downto 0);
signal bte_mux: std_logic_vector(1 downto 0);
signal adr_mux: std_logic_vector(31 downto 2);
signal wdata_mux: std_logic_vector(31 downto 0);

signal ack_mux: std_logic;
signal rdata_mux: std_logic_vector(31 downto 0);

begin

-- ARBITER
-- Selects the active master. Masters with lower port numbers
-- have higher priority. Ongoing cycles are not interrupted.

request<=s1_cyc_i&s0_cyc_i;

grant_next<="01" when request(0)='1' else
	"10" when request(1)='1' else
	(others=>'0');

grant<=grant_reg when (request and grant_reg)/="00" else grant_next;

process (clk_i) is
begin
	if rising_edge(clk_i) then
		if rst_i='1' then
			grant_reg<=(others=>'0');
		else
			grant_reg<=grant;
		end if;
	end if;
end process;

-- MASTER->SLAVE MUX

cyc_mux<=(s0_cyc_i and grant(0)) or
	(s1_cyc_i and grant(1));

stb_mux<=(s0_stb_i and grant(0)) or
	(s1_stb_i and grant(1));

we_mux<=(s0_we_i and grant(0)) or
	(s1_we_i and grant(1));

sel_mux_gen: for i in sel_mux'range generate
	sel_mux(i)<=(s0_sel_i(i) and grant(0)) or
		(s1_sel_i(i) and grant(1));
end generate;

cti_mux_gen: for i in cti_mux'range generate
	cti_mux(i)<=(s0_cti_i(i) and grant(0)) or
		(s1_cti_i(i) and grant(1));
end generate;

bte_mux_gen: for i in bte_mux'range generate
	bte_mux(i)<=(s0_bte_i(i) and grant(0)) or
		(s1_bte_i(i) and grant(1));
end generate;

adr_mux_gen: for i in adr_mux'range generate
	adr_mux(i)<=(s0_adr_i(i) and grant(0)) or
		(s1_adr_i(i) and grant(1));
end generate;

wdata_mux_gen: for i in wdata_mux'range generate
	wdata_mux(i)<=(s0_dat_i(i) and grant(0)) or
		(s1_dat_i(i) and grant(1));
end generate;

-- MASTER->SLAVE DEMUX

select_slave<="001" when adr_mux(31 downto 28)="0000" else
	"010" when adr_mux(31 downto 28)="0001" else
	"100"; -- fallback slave

m0_cyc_o<=cyc_mux and select_slave(0);
m0_stb_o<=stb_mux and select_slave(0);
m0_we_o<=we_mux;
m0_sel_o<=sel_mux;
m0_cti_o<=cti_mux;
m0_bte_o<=bte_mux;
m0_adr_o<=adr_mux(m0_adr_o'range);
m0_dat_o<=wdata_mux;

m1_cyc_o<=cyc_mux and select_slave(1);
m1_stb_o<=stb_mux and select_slave(1);
m1_we_o<=we_mux;
m1_sel_o<=sel_mux;
m1_cti_o<=cti_mux;
m1_bte_o<=bte_mux;
m1_adr_o<=adr_mux(m1_adr_o'range);
m1_dat_o<=wdata_mux;

-- SLAVE->MASTER MUX

ack_mux<=(m0_ack_i and select_slave(0)) or
	(m1_ack_i and select_slave(1)) or
	(cyc_mux and stb_mux and select_slave(2)); -- fallback slave

rdata_mux_gen: for i in rdata_mux'range generate
	rdata_mux(i)<=(m0_dat_i(i) and select_slave(0)) or
		(m1_dat_i(i) and select_slave(1));
end generate;

-- SLAVE->MASTER DEMUX

s0_ack_o<=ack_mux and grant(0);
s0_dat_o<=rdata_mux;

s1_ack_o<=ack_mux and grant(1);
s1_dat_o<=rdata_mux;

end architecture;
