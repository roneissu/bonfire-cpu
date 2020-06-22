.section .text
.global _start
.extern monitor
_start:

#define check(_result) \
  li s2,_result; \
  jal store \


la gp, (monitor+4) // memory pointer



// Test loop with the "1*1" from 2 to 10
loop:
mv s1,gp // save pointer

li a1, -5
li a2, 2
mul t4,a1,a2 // Pipeline test
mulh t5,a1,a2
nop
slt t4,a1,a2 // true
sltu x0,a1,a2 // Pipeline  test
nop
check(1)  // 1
slt t4,a2,a1 // false
check(0) // 2

sltu t4,a1,a2 // false
check(0) //3
sltu t4,a2,a1 // true
check(1) // 4

slti t4,a1,-5 // false
check(0) // 5
slti t4,a2,3 // true
check(1) // 6

li a1,1
sw a1,-4(s1) // Store 1 in monitor result address

j loop

store: // store t4 to mem and increment
sw t4,0(gp) // save result
add gp,gp,4 // increment pointer
beq t4,s2,ok // check if t4 contains desired result
li s2,-1
sw s2,-4(s1)  // write -1 to monitor result address

ok:
ret
