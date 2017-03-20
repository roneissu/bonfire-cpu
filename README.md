# Bonfire-CPU

Bonfire is a implementation of RISC-V (RV32IM subset) optimized for FPGAs.

It is based on the LXP32 CPU [https://lxp32.github.io/](https://lxp32.github.io/)

The datapath/pipeline is basically still from LXP32. The main difference is in the instruction decoder which was completly rewritten to implement the RV32IM instruction set. See [https://riscv.org/specifications/]

The implementation also supports a subset of the RISC-V supervisor specification. The processor works only in M-mode. It is not fully compliant yet, because not all mandatory CSR registers are implemented. In addition to the orignal lxp-32 design a "true" instruction cache (16KB, direct-mapped) was implemented. The design works on a Xilinx Spartan-6 LX9 FPGA with about 100Mhz. The fully configured CPU with divider and instruction cache requires about 711 slices, 4 DSP48 blocks (for the multiplier), 2 RAMB8BWER (for the CPU register file) and 9 RAMB16BWER (for the Cache).  The design can be adjusted with various generics, but currently only the full configuration is tested. 

The design is intented to work still also as lxp-32 CPU when the generic parameter RISCV is set to false, but currently I don't test this setting. There is no automated test bench yet, I'm preparing to run the RISC-V test suite on it. But there are several test programs in C and assembler which, together with the surrounding bonfire-soc, allow to test the CPU interactivly in a simulator. 

The bus specification and also the timing of most cpu operations are still the same as in the LXP32:
 * Most simple arithmetic and logic instructions map 1:1 from RISC-V to the corresponding LXP32 instruction, regardless if they are an RISC-V immediate or register instruction. 
 * Shifts take 2 cycle like shifts in LXP32
 * Branches and jumps also keep the same latency
 * SLT/SLTU have two cycle latency (because the LXP32 comparator takes two cycles)
 * CSR instructions also have two cycle latency
 * Load/Store latency is also the same as in LXP32
 * When generic MUL_ARCH is set to spartandsp the latency for multiplication operations is 4 instead of 2 (but slice utilisation is much better, because the adders of the DSP48 blocks are used).

The CPU supports the mtime and mtimecmp timer similar to the RISC-V privilege spec, but both registers are currently limited to 32Bit length.

The following interrupts are supported:
* Timer as defined in RISC-V privileged spec (MT bit in mie mip)
* 8 local external interupts, for this the mie and mip CSRs are extented to contain eight eie and eip bits.
 
In addition the following traps are supported:
 * Invalid Opcode
 * Misaligned access
 * ebreak
 * ecall 
 
I have included a  Xilinx ISE project unter the subdirectory ise to allow an easy simulation of the CPU core as starting point.
For convenince there are pre-compiled hex-files for the some CPU test programs in the subdirectory ise/tb_bonfire_cpu/compiled_tests.
So the tests can be run without a RISC-V toolchain installed. 



