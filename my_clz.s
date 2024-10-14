.data
testcase:    .word 0x00000000, 0x00000001, 0x80000000
answer:    .word 32, 31, 0
true:    .string "true\n"
false:    .string "false\n"

.text
main:
    la    t0, testcase
    la    t1, answer
    li    t2, 3
test_loop:
    lw    a0, 0(t0)
    jal    ra, my_clz
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

my_clz:
    addi    sp, sp, -16           # Allocate space for ra, t0, t1
    sw      ra, 0(sp)             # Save return address
    sw      t0, 4(sp)             # Save t0
    sw      t1, 8(sp)             # Save t1
    sw      t2, 12(sp)            # Save t2

    mv      t0, a0                # t0: x (input value)
    li      t1, 0                 # t1: count (leading zeros)
    li      t3, 0x80000000        # t3: starting bitmask (1 << 31)

clz_loop:
    and     t4, t0, t3            # t4: x & (1 << i)
    bne     t4, x0, exit_clz      # If x & (1 << i) is not 0, exit the loop
    addi    t1, t1, 1             # Increment leading zero count
    srli     t3, t3, 1             # Right shift the bitmask (t3 >>= 1)
    bnez    t3, clz_loop          # If the bitmask is non-zero, continue looping

exit_clz:
    mv      a0, t1                # Move count to return value (a0)
    lw      ra, 0(sp)             # Restore return address
    lw      t0, 4(sp)             # Restore t0
    lw      t1, 8(sp)             # Restore t1
    lw      t2, 12(sp)            # Restore t2
    addi    sp, sp, 16            # Deallocate stack space
    ret                           # Return from function