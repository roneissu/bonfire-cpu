.section .text
.global _start
.extern monitor
_start:

li a0,3 // loop counter
la s0, monitor

loop:
addi a0,a0,-1
sw a0,4(s0)
bnez a0, loop
nop
// Forward branch test
beqz a0, forward
li a0, -1
sw a0,0(s0) // should not happen...
forward:
// jalr test and call return test
la s1, subroutine
jalr ra, s1
sw a0,4(s0) // should write #55aaffee

li a0,0
sw a0,0(s0) // write success to monitor result register
f0:
j f0

subroutine:
li a0, 0x55aaffee
ret

li a0, -1
sw a0,0(s0) // should not happen...
