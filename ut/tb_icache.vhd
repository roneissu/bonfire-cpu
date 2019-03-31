--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   20:52:22 11/16/2017
-- Design Name:   
-- Module Name:   /home/thomas/fusesoc_projects/bonfire/bonfire-cpu/ut/tb_icache.vhd
-- Project Name:  bonfire-soc_0
-- Target Device:  
-- Tool versions:  
-- Description:   This test bench currently only tests the invalidate mechanism
-- 
-- VHDL Test Bench Created by ISE for module: bonfire_dm_icache
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
USE ieee.numeric_std.ALL;

use work.txt_util.all;
 
ENTITY tb_icache IS
END tb_icache;
 
ARCHITECTURE behavior OF tb_icache IS 

constant  MASTER_DATA_WIDTH : natural := 32;
--constant  LINE_SIZE : natural := 1;
constant  LINE_SIZE : natural := 8;
--constant  LINE_SIZE : natural := 16;
constant  LINE_SIZE_BYTES : natural := MASTER_DATA_WIDTH/8 * LINE_SIZE;
constant  LINE_SIZE_WORDS : natural := LINE_SIZE_BYTES / 4;
constant  CACHE_SIZE : natural :=1024;
constant  CACHE_SIZE_BYTES : natural := CACHE_SIZE*MASTER_DATA_WIDTH/8;
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT bonfire_dm_icache
    GENERIC (
      LINE_SIZE : natural;
      CACHE_SIZE : natural;
      ADDRESS_BITS : natural
     );
    PORT(
         clk_i : IN  std_logic;
         rst_i : IN  std_logic;
         lli_re_i : IN  std_logic;
         lli_adr_i : IN  std_logic_vector(29 downto 0);
         lli_dat_o : OUT  std_logic_vector(31 downto 0);
         lli_busy_o : OUT  std_logic;
         wbm_cyc_o : OUT  std_logic;
         wbm_stb_o : OUT  std_logic;
         wbm_cti_o : OUT  std_logic_vector(2 downto 0);
         wbm_bte_o : OUT  std_logic_vector(1 downto 0);
         wbm_ack_i : IN  std_logic;
         wbm_adr_o : OUT  std_logic_vector(29 downto 0);
         wbm_dat_i : IN  std_logic_vector(31 downto 0);
         cc_invalidate_i : IN  std_logic;
         cc_invalidate_complete_o : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal clk_i : std_logic := '0';
   signal rst_i : std_logic := '0';
   signal lli_re_i : std_logic := '0';
   signal lli_adr_i : std_logic_vector(29 downto 0) := (others => '0');
   signal wbm_ack_i : std_logic := '0';
   signal wbm_dat_i : std_logic_vector(31 downto 0) := (others => '0');
   signal cc_invalidate_i : std_logic := '0';

 	--Outputs
   signal lli_dat_o : std_logic_vector(31 downto 0);
   signal lli_busy_o : std_logic;
   signal wbm_cyc_o : std_logic;
   signal wbm_stb_o : std_logic;
   signal wbm_cti_o : std_logic_vector(2 downto 0);
   signal wbm_bte_o : std_logic_vector(1 downto 0);
   signal wbm_adr_o : std_logic_vector(29 downto 0);
   signal cc_invalidate_complete_o : std_logic;

   -- Clock period definitions
   constant clk_i_period : time := 10 ns;
   
   subtype t_wbm_dat is std_logic_vector (wbm_dat_i'range);
   
   subtype t_lli_adr is unsigned(lli_adr_i'range);
   
   type t_mstate is (m_idle,m_readburst);
   signal mstate : t_mstate:=m_idle;
   
  
   signal adr_taken : std_logic_vector(lli_adr_i'range);
   signal re_reg : std_logic := '0';
   
   signal do_invalidate : boolean := false;
   signal clk_enabled : boolean := true;
   
   impure function get_pattern(adr : std_logic_vector(wbm_adr_o'range)) return t_wbm_dat is
    
    variable d : t_wbm_dat;
    begin
      d:=adr & "00";
      return d;
    end;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: bonfire_dm_icache 
   GENERIC MAP (
     LINE_SIZE => LINE_SIZE,
     CACHE_SIZE => CACHE_SIZE,
     ADDRESS_BITS => 30
   )
   
   PORT MAP (
          clk_i => clk_i,
          rst_i => rst_i,
          lli_re_i => lli_re_i,
          lli_adr_i => lli_adr_i,
          lli_dat_o => lli_dat_o,
          lli_busy_o => lli_busy_o,
          wbm_cyc_o => wbm_cyc_o,
          wbm_stb_o => wbm_stb_o,
          wbm_cti_o => wbm_cti_o,
          wbm_bte_o => wbm_bte_o,
          wbm_ack_i => wbm_ack_i,
          wbm_adr_o => wbm_adr_o,
          wbm_dat_i => wbm_dat_i,
          cc_invalidate_i => cc_invalidate_i,
          cc_invalidate_complete_o => cc_invalidate_complete_o
        );
        
        
   -- Clock process definitions
   clk_i_process :process
   begin
        if clk_enabled then
		  clk_i <= '0';
		  wait for clk_i_period/2;
		  clk_i <= '1';
		  wait for clk_i_period/2;
		end if;  
   end process;
   
   
   
   -- Main Memory simulation read

    process(wbm_adr_o,wbm_stb_o)
    begin
      if wbm_stb_o='1' then
         wbm_dat_i <= get_pattern(wbm_adr_o);
       else
         wbm_dat_i <=   (others=>'X');
       end if;

    end process;
    
    
    mem_simul: process(clk_i) -- Simulates the Main Memory slave
    begin

      if rising_edge(clk_i) then
          case mstate is
            when m_idle =>
              if wbm_cyc_o='1' and wbm_stb_o='1' then
                 mstate <= m_readburst;
                 wbm_ack_i <= '1'; -- Set ack signal
              end if;

            when m_readburst =>
                if wbm_cti_o="000" or wbm_cti_o="111" then
                  wbm_ack_i<= '0';
                  mstate<=m_idle;
                end if;
          end case;
      end if;
    end process;

   
   ll_read: process(clk_i)
   begin
   
      if rising_edge(clk_i) then
        if lli_re_i='1' and lli_busy_o='0' then
          adr_taken <= lli_adr_i;
          re_reg <= '1';
        else
          re_reg <= '0';        
        end if;
        if re_reg='1' then  
          print("Read from address " & hstr(adr_taken) & ": " & hstr(lli_dat_o));
          assert adr_taken&"00" = lli_dat_o 
            report "Error at address: " & hstr(adr_taken) 
            severity failure;
        end if;
      end if;
   
   end process;
   

   inval: process
   begin
   
     wait until rising_edge(clk_i) and do_invalidate;
     cc_invalidate_i<='1'; -- just invaidate in the midle of a read cycle
     wait until rising_edge(clk_i);
     cc_invalidate_i<='0';
   end process;
 

   -- Stimulus process
   stim_proc: process
   
   procedure read_lli(adr:t_lli_adr;len: natural) is
   begin
   
     lli_re_i <= '1';
     lli_adr_i <= std_logic_vector(adr);
     for i in 1 to len loop 
        wait until rising_edge(clk_i) and lli_busy_o='0';
        lli_adr_i <= std_logic_vector(adr+i); -- Pipeline next address  
     end loop;
     lli_re_i <= '0';
   
   end procedure; 
   
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	
    --  wait until rising_edge(clk_i);
      read_lli(to_unsigned(0,t_lli_adr'length),LINE_SIZE);
      read_lli(to_unsigned(LINE_SIZE,t_lli_adr'length),LINE_SIZE);
      read_lli(to_unsigned(0,t_lli_adr'length),LINE_SIZE); --s should be a hit
      read_lli(to_unsigned(CACHE_SIZE,t_lli_adr'length),LINE_SIZE); -- wrap over, must be a tag mismatch and miss
      
    
      read_lli(to_unsigned(0,t_lli_adr'length),LINE_SIZE);
      wait until rising_edge(clk_i);
      wait for 100ns;
      clk_enabled <= false;

   end process;

END;
