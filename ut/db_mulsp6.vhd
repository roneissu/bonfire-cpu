--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   15:53:28 05/01/2017
-- Design Name:   
-- Module Name:   /home/thomas/riscv/lxp32-cpu/ut/db_mulsp6.vhd
-- Project Name:  bonfire
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: lxp32_mulsp6
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

library STD;
use STD.textio.all;

use work.txt_util.all;
 
ENTITY db_mulsp6 IS
END db_mulsp6;
 
ARCHITECTURE behavior OF db_mulsp6 IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT lxp32_mulsp6
    PORT(
         clk_i : IN  std_logic;
         rst_i : IN  std_logic;
         ce_i : IN  std_logic;
         op1_i : IN  std_logic_vector(31 downto 0);
         op2_i : IN  std_logic_vector(31 downto 0);
         ce_o : OUT  std_logic;
         result_o : OUT  std_logic_vector(31 downto 0);
         result_high_o : OUT  std_logic_vector(31 downto 0)
        );
    END COMPONENT;
    
    subtype xsigned is signed(31 downto 0);
    subtype xxsigned is signed(63 downto 0);
    subtype xxunsigned is unsigned(63 downto 0);
    

   --Inputs
   signal clk_i : std_logic := '0';
   signal rst_i : std_logic := '0';
   signal ce_i : std_logic := '0';
   signal op1_i : std_logic_vector(31 downto 0) := (others => '0');
   signal op2_i : std_logic_vector(31 downto 0) := (others => '0');

 	--Outputs
   signal ce_o : std_logic;
   signal result_o : std_logic_vector(31 downto 0);
   signal result_high_o : std_logic_vector(31 downto 0);

   -- Clock period definitions
   constant clk_i_period : time := 10 ns;
   
   
   function str64(int: xxsigned; base: integer) return string is

    variable temp:      string(1 to 30);
    variable num:       xxunsigned;
    variable abs_int:   xxunsigned;
    variable len:       integer := 1;
    variable power:     xxunsigned; 
    variable t:         unsigned(127 downto 0);

   begin

    -- bug fix for negative numbers
    abs_int := unsigned(abs(int));  --abs(int);
    num     := abs_int;
  
    while num >= to_unsigned(base,num'length) loop                     -- Determine how many 
      len := len + 1;                          -- characters required
      num := num / base;                       -- to represent the
    end loop ;                                 -- number.
    
    power := to_unsigned(1,xxunsigned'length);
    for i in len downto 1 loop                 -- Convert the number to
     
      temp(i) := chr(to_integer(abs_int/power mod base));  -- a string starting
      t:= power * base;
      power := t(63 downto 0);                  
    
    end loop ;                                 -- side.
   
    -- return result and add sign if required
    if int < 0 then
       return '-'& temp(1 to len);
     else
       return temp(1 to len);
    end if;

   end str64;
   
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: lxp32_mulsp6 PORT MAP (
          clk_i => clk_i,
          rst_i => rst_i,
          ce_i => ce_i,
          op1_i => op1_i,
          op2_i => op2_i,
          ce_o => ce_o,
          result_o => result_o,
          result_high_o => result_high_o
        );

   -- Clock process definitions
   clk_i_process :process
   begin
		clk_i <= '0';
		wait for clk_i_period/2;
		clk_i <= '1';
		wait for clk_i_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   variable res : xxsigned;
   
   procedure do_mul_s(a: integer;b: integer)  is
   begin
     op1_i <= std_logic_vector(to_signed(a,op1_i'length));
     op2_i <= std_logic_vector(to_signed(b,op2_i'length));
     wait until rising_edge(clk_i);
     ce_i <= '1';
     wait until rising_edge(clk_i);
     ce_i <= '0';
     wait until ce_o='1';
     
     res := signed(result_high_o & result_o);
     report str(a) & "*" & str(b) & "=" & str64(res,10) & " 0x" & hstr(result_high_o) & " " & hstr(result_o);
   
   end;
   
   
   
   begin		
      -- hold reset state for 100 ns.
     
      wait for 20 ns;	
      do_mul_s(5,5);
      do_mul_s(5000,5000);
      do_mul_s(10000000,500);
    
      report "finish";      
      wait;
   end process;

END;
