###############
# Seccion de datos
    .data
$str1:
    .asciiz  "Inicio del programa\n"
$str2:
    .asciiz  "a"
$str3:
    .asciiz  "\n"
$str4:
    .asciiz  "No a y b\n"
$str5:
    .asciiz  "c = "
$str6:
    .asciiz  "\n"
$str7:
    .asciiz  "Final"
$str8:
    .asciiz  "\n"
_a : 
 .word 0
_b : 
 .word 0
_c : 
 .word 0

###################
# Seccion de codigo
   .text
   .globl main
main:
    li $t0,0
    sw $t0,_a
    li $t0,0
    sw $t0,_b
    li $t0,5
    li $t1,2
    add $t2,$t0,$t1
    li $t0,2
    sub $t1,$t2,$t0
    sw $t1,_c
    la $a0,$str1
    li $v0,4
    syscall
    lw $t0,_a
    beqz $t0,$et4
    la $a0,$str2
    li $v0,4
    syscall
    la $a0,$str3
    li $v0,4
    syscall
    b $et5
     $et4:
    lw $t1,_b
    beqz $t1,$et2
    la $a0,$str4
    li $v0,4
    syscall
    b $et3
     $et2:
     $et1:
    la $a0,$str5
    li $v0,4
    syscall
    lw $t2,_c
    move $a0,$t2
    li $v0,1
    syscall
    la $a0,$str6
    li $v0,4
    syscall
    lw $t3,_c
    li $t4,2
    sub $t5,$t3,$t4
    li $t3,1
    add $t4,$t5,$t3
    sw $t4,_c
    lw $t3,_c
    bnez $t3,$et1
     $et3:
     $et5:
    la $a0,$str7
    li $v0,4
    syscall
    la $a0,$str8
    li $v0,4
    syscall

################
# Fin
    li $v0, 10
    syscall
