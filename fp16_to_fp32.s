.data
testcase:    .word 0x3C00, 0x7BFF, 0x0400
answer:    .word 0x3F800000, 0x477FE000, 0x38800000
true:    .string "true\n"
false:    .string "false\n"

.text
main:
    la    t0, testcase
    la    t1, answer
    li    t2, 3
test_loop:
    lw    a0, 0(t0)
    jal    ra, fp16_to_fp32
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
    
fp16_to_fp32:
    addi    sp, sp, -32
    sw    ra, 0(sp)
    sw    t0, 4(sp)
    sw    t1, 8(sp)
    sw    t2, 12(sp)
    sw    t3, 16(sp)
    sw    t4, 20(sp)
    sw    t5, 24(sp)
    sw    t6, 28(sp)
    
    mv    t0, a0            # t0: h
    slli    t0, t0, 16      # t0: w, w = (uint32_t) h << 16
    li    t1, 0x80000000    # t1: 0x80000000
    and    t1, t0, t1       # t1: sign, sign = w & UINT32_C(0x80000000)
    li    t2, 0x7FFFFFFF    # t2: 0x7FFFFFFF
    and    t2, t0, t2       # t2: nonsign, nonsign = w & UINT32_C(0x7FFFFFFF)
    mv    a0, t2
    jal    ra, my_clz       # call my_clz(nonsign)
    mv    t3, a0            # t3: renorm_shift
    addi    t4, x0, 6
    bge    t3, t4, sub_5
    mv    t3, x0            # renorm_shift = 0
    j    cont
sub_5:
    addi    t3, t3, -5      # renorm_shift = renorm_shift - 5
cont:
    li    t4, 0x04000000
    add    t4, t2, t4       # t4: nonsign + 0x04000000
    srli    t4, t4, 8       # t4: (nonsign + 0x04000000) >> 8
    li    t5, 0x7F800000
    and    t4, t4, t5       # t4: inf_nan_mask
    addi    t5, t2, -1      # t5: nonsign - 1
    srli    t5, t5, 31      # t5: zero_mask, zero_mask = (int32_t)(nonsign - 1) >> 31
    sll    t2, t2, t3       # t2: nonsign << renorm_shift
    srli    t2, t2, 3       # t2: nonsign << renorm_shift >> 3
    li    t6, 0x70          
    sub    t3, t6, t3       # t3: 0x70 - renorm_shift
    slli    t3, t3, 23      # t3: (0x70 - renorm_shift) << 23
    add    t2, t2, t3       # t2: ((nonsign << renorm_shift >> 3) + ((0x70 - renorm_shift) << 23))
    or    t2, t2, t4        # t2: (((nonsign << renorm_shift >> 3) + ((0x70 - renorm_shift) << 23)) | inf_nan_mask)
    not    t5, t5           # ~zero_mask
    and    t2, t2, t5       # t2: ((((nonsign << renorm_shift >> 3) + ((0x70 - renorm_shift) << 23)) | inf_nan_mask) & ~zero_mask)
    or    a0, t1, t2
    
    lw    ra, 0(sp)
    lw    t0, 4(sp)
    lw    t1, 8(sp)
    lw    t2, 12(sp)
    lw    t3, 16(sp)
    lw    t4, 20(sp)
    lw    t5, 24(sp)
    lw    t6, 28(sp)
    addi    sp, sp, 32
    ret

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