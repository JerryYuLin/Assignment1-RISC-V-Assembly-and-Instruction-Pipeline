.data
testcase:    .word 0xC048F5C3, 0x00000000, 0xC7F1202E
answer:    .word 0x4048F5C3, 0x00000000, 0x47F1202E
true:    .string "true\n"
false:    .string "false\n"

.text
main:
    la    t0, testcase
    la    t1, answer
    li    t2, 3
test_loop:
    lw    a0, 0(t0)
    jal    ra, fabsf
    lw    s0, 0(t1)
    beq    a0, s0, print_true
    j    print_false
print_true:
    li    a7, 4
    la    a0, true
    ecall
    j    check_test_loop
print_false:
    li    a7, 4
    la    a0, false
    ecall
    j    check_test_loop
check_test_loop:
    addi    t0, t0, 4
    addi    t1, t1, 4
    addi    t2, t2, -1
    bne    t2, x0, test_loop
    
    li    a7, 10
    ecall
    
fabsf:
    addi    sp, sp, -8        # Allocate space for saving ra and t0
    sw      ra, 0(sp)         # Save return address
    sw      t0, 4(sp)         # Save t0
    
    li      t0, 0x7FFFFFFF    # Load mask to clear the sign bit
    and     a0, a0, t0        # Clear the sign bit of the float in a0 (absolute value)
    
    lw      ra, 0(sp)         # Restore return address
    lw      t0, 4(sp)         # Restore t0
    addi    sp, sp, 8         # Deallocate stack space
    ret                       # Return from function