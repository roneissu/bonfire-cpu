---------------------------------------------------------------------
-- Instruction fetch
--
-- Part of the LXP32 CPU
--
-- Copyright (c) 2016 by Alex I. Kuznetsov
--
-- The first stage of the Bonfire  pipeline.

-- The Bonfire Processor Project, (c) 2016,2017,2018 Thomas Hornschuh
--
-- License: See LICENSE or LICENSE.txt File in git project root.
---------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.riscv_decodeutil.all;

entity bonfire_fetch is
  generic(
    START_ADDR: std_logic_vector(29 downto 0)
  );
  port(
    clk_i: in std_logic;
    rst_i: in std_logic;

    lli_re_o: out std_logic;
    lli_adr_o: out std_logic_vector(29 downto 0);
    lli_dat_i: in std_logic_vector(31 downto 0);
    lli_busy_i: in std_logic;
    lli_cc_invalidate_o : out std_logic;

    word_o: out std_logic_vector(31 downto 0);
    next_ip_o: out std_logic_vector(29 downto 0);
    valid_o: out std_logic;
    ready_i: in std_logic;
    fence_i_i : in std_logic;

    jump_valid_i: in std_logic;
    jump_dst_i: in std_logic_vector(29 downto 0);
    jump_ready_o: out std_logic
  );
end entity;

architecture rtl of bonfire_fetch is

--signal init: std_logic:='1';
--signal init_cnt: unsigned(7 downto 0):=(others=>'0');

signal fetch_addr: std_logic_vector(29 downto 0):=START_ADDR;

signal next_word: std_logic;
signal suppress_re: std_logic:='0';
signal re: std_logic;
signal requested: std_logic:='0';

signal fifo_rst: std_logic;
signal fifo_we: std_logic;
signal fifo_din: std_logic_vector(61 downto 0);
signal fifo_re: std_logic;
signal fifo_dout: std_logic_vector(61 downto 0);
signal fifo_empty: std_logic;
signal fifo_full: std_logic;

signal jr: std_logic:='0';


signal op : t_riscv_op;
signal branch_offset : xsigned;
signal branch_target : std_logic_vector(31 downto 0);
signal fetch_branch_target : std_logic;
signal branch_target_fetched : std_logic := '0';
signal stall_re : std_logic;
--signal predict_success : std_logic;
signal predict_fail : std_logic;
signal target_address_buffer : std_logic_vector(fetch_addr'range) := (others=>'0');
signal target_valid : std_logic := '0';
signal target_match : std_logic;
signal wipe_fifo : std_logic := '0';

signal current_addr : std_logic_vector(fetch_addr'range);

signal debug_jump_dst_i : std_logic_vector(31 downto 0);

--type t_fetch_state is (s_fetch_next,s_fetch_target,s_target_fetched, s_mispredict);
--signal fetch_state : t_fetch_state := s_fetch_next;

signal debug_adr_o : std_logic_vector(31 downto 0);

begin

debug_adr_o <= fetch_addr&"00";

op <= decode_op(lli_dat_i(6 downto 2)) when fifo_we='1' else rv_invalid;
debug_jump_dst_i <= jump_dst_i&"00";

branch_target <= std_logic_vector(signed(current_addr&"00")+branch_offset);


branch_inspect: process (lli_dat_i,fetch_addr,op)
variable o : xsigned;
begin

  branch_offset <= (others => '-');
  fetch_branch_target <= '0';
  -- Allow only one level of prefetch
  if branch_target_fetched = '0' then
    if op = rv_jal  then
      o  := get_UJ_immediate(lli_dat_i);

      --if not (o = 0) then
        fetch_branch_target <= '1';
      --end if;
      branch_offset <= o;
    elsif op = rv_branch then
       o := get_SB_immediate(lli_dat_i);
      -- From RISCV ISA Spec:
      --Software should also assume that backward branches will be predicted
      --taken and forward branches as not taken.
      if o(o'high)='1' then
        fetch_branch_target <= '1';
        branch_offset <= o;
      end if;
    end if;
  end if;

end process;



valid_o<=not (fifo_empty or  predict_fail);
jump_ready_o<= jump_valid_i and  not ( fifo_empty or predict_fail );

target_match <= '1' when jump_dst_i=target_address_buffer and target_valid='1' else '0';
-- predict_success <= '1'  when  target_valid='1' and jump_valid_i='1'
--                                and target_match='1' and fifo_empty='0'
--                     else '0';

predict_fail <= '1' when ((target_match='0' and target_valid='1' and jump_valid_i='1')
                           or (target_valid='0' and jump_valid_i='1') )
                         and wipe_fifo='0' and fifo_empty='0'
                 else '0';

-- FETCH state machine

process (clk_i) is
begin
  if rising_edge(clk_i) then
    branch_target_fetched<='0';
    if rst_i='1' then
      fetch_addr<=START_ADDR;
      requested<='0';
      jr<='0';
      suppress_re<='0';
      wipe_fifo <= '0';
    else
      jr<='0';
      current_addr <= fetch_addr;
      if lli_busy_i='0' then
        requested<=re; --and not (jump_valid_i and not jr);
      end if;
      -- Set next fetch adr

       if fifo_empty='0' then
         wipe_fifo <= '0';
       end if;
       branch_target_fetched <= '0';
       if next_word = '1' then
         if fetch_branch_target='1' then
            fetch_addr <= branch_target(31 downto 2);
            target_address_buffer <= branch_target(31 downto 2);
            branch_target_fetched <= '1';
            target_valid <= '1';
         elsif  jump_valid_i='1' and  target_match='0' and wipe_fifo='0' then --misprecdict
              --report "Branch mispredict" severity note;
              fetch_addr <= jump_dst_i;
              wipe_fifo <= '1';
         else
           fetch_addr  <= std_logic_vector(unsigned(fetch_addr)+1);
         end if;
       end if;
       if jump_valid_i='1' then
         target_valid <= '0';
       end if;
    end if;
  end if;
end process;

next_word<=(fifo_empty or ready_i) and not lli_busy_i; -- and not fetch_branch_target;
stall_re <= (fetch_branch_target and not branch_target_fetched) or predict_fail;
re<=(fifo_empty or ready_i)  and  not (  suppress_re or stall_re ) ;
lli_re_o<=re;
lli_adr_o<=fetch_addr;



lli_cc_invalidate_o <= fence_i_i; -- currently only pass through

-- Small instruction buffer

fifo_rst<=  rst_i or predict_fail;
fifo_we<=requested and not lli_busy_i;
fifo_din<=fetch_addr&lli_dat_i;
fifo_re<=ready_i and not fifo_empty;


ubuf_inst: entity work.lxp32_ubuf(rtl)
  generic map(
    DATA_WIDTH=>62
  )
  port map(
    clk_i=>clk_i,
    rst_i=>fifo_rst,

    we_i=>fifo_we,
    d_i=>fifo_din,
    re_i=>fifo_re,
    d_o=>fifo_dout,

    empty_o=>fifo_empty,
    full_o=>fifo_full
  );

next_ip_o<=fifo_dout(61 downto 32);

word_o<=fifo_dout(31 downto 0) ;


end architecture;
