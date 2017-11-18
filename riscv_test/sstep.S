.section .text
.global _start
_start:


la x1, trap_handler
csrw mtvec,x1

li x5,0
ebreak

li x2,0x100
li x1,25
sw x1,0(x2)

loop:
lw x1,0(x2)
addi x1,x1,1
sw x1, 0(x2)
sw x1, 4(x2)
j loop

trap_handler:
csrs 0x7c0,1 // set sstep flag
// check for first call (x5==0)
bne x5,x0, l1
// jump over hard coded break instruction
csrr x6,mepc
addi x6,x6,4
csrw mepc,x6
addi x5,x5,1

l1:
sret
