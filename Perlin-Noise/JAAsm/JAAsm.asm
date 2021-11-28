.data
result real8 -1.0, -1.0
minusOnes real8 -1.0, -1.0
ones real8 1.0, 1.0
twoOnes DWORD 1, 1, 0, 0
zeroOne real8 1.0, 0.0
zeroTwo real8 2.0, 0.0
twoZeroes real8 0.0, 0.0
twoTwo real8 2.0, 2.0

.code

;unsigned short getIndexY(int y, unsigned char* hashTable, unsigned short hashTableSize)
;y in xmm5, hashTable in rsi, hashTableSize in r9w (zero extended)
getIndexYValue PROC ;USES rax, r10, rdx, xmm0
MOVD eax, xmm5				;load y to eax
CDQ							;eax:edx <- sign extend of eax
IDIV r9d					;y/hashTableSize, eax<-quotient of division, edx<-remainder of division
TEST dx, dx					;set sign flag of remainder
JNS indexYPositive			
ADD dx, r9w				;if remainder was negatvie, add table size
MOVZX rdx, dx
indexYPositive:
MOVZX r10, BYTE PTR [rsi+rdx];move hashTable[indexY] (zero extended) to r10
RET
getIndexYValue ENDP

;unsigned short getIndexX(int x, unsigned char indexYValue, unsigned char* hashTable, unsigned short hashTableSize)
;x in xmm5,indexYValue in r10, hashTable in rsi, hashTableSize in r9w (zero extended)
getIndexXValue PROC ;USES rax, rbx, rdx
MOVD eax, xmm5				;load x to eax (zero extended)
ADD rax, r10				;rax <- x + indexYValue
CDQ							;rax:rdx <- sign extend of rax
IDIV r9d					;(x + indexYValue)/hashTableSize, eax<-quotient of division, edx<-remainder of division
TEST dx, dx					;set sign flag of remainder
JNS indexXPositive			
ADD dx, r9w				;if remainder was negatvie, add table size
MOVZX rdx, dx
indexXPositive:
MOVZX rax, BYTE PTR [rsi+rdx];move hashTable[indexX] (zero extended) to rax
RET
getIndexXValue ENDP

;xmmword getGradient(unsigned char seed)
;seed in rax
getGradient PROC ;USES rax, rdx, xmm5, xmm6
MOV rdx, rax				;save the seed
AND rax, 2					;extract older bit of seed
SHL rax, 62					;move it to most significant position
AND rdx, 1					;extract younger bit of seed
SHL rdx, 63					;move it to most significant position
MOVQ xmm6, rax				;move the older bit of seed to lower quadword of xmm1
PSLLDQ xmm6, 8				;shift it to uper quadword
PINSRQ xmm6, rdx, 0			;move the younger bit of seed to lower quadword of xmm1
MOVUPD xmm5, minusOnes		
MOVUPD XMMWORD PTR[rsp-16], xmm5			;store (-1.0,-1.0) in temporary variable
MOVUPD xmm5, ones
VMASKMOVPD XMMWORD PTR[rsp-16], xmm6, xmm5	;store 1.0 in temporary variable, in appropirate quadwords
MOVUPD xmm5, XMMWORD PTR[rsp-16]			;load result to xmm0
RET
getGradient ENDP

;double perlinNoise(double pointX, double pointY, unsigned char* hashTable, unsigned short hashTableSize)
;pointX in upper quadword of xmm15/xmm0, pointY in lower quadword of xmm15/xmm1, hashTable in rsi/r8, hashTableSize in r15w/r9
perlinNoise PROC
PUSH rbp
MOV rbp, rsp 

VROUNDPD xmm14, xmm15, 249			;1111_1001b	;round (pointX, pointY) towards -inf and store in xmm14
VCVTPD2DQ xmm14, xmm14				;convert double to dword in xmm14
VPADDD xmm13, xmm14, twoOnes		;add (0,0,1,1) to rounded (0,0,pointX,pointY) and store in xmm13
;so now (0,0,x0,y0) is in xmm4 and (0,0,x1,y1) is in xmm3
VBLENDPS xmm12, xmm13, xmm14, 2		;load (x0,y1) into xmm12
VBLENDPS xmm11, xmm14, xmm13, 2		;load (x1,y0) into xmm11
PSLLDQ xmm14, 8						;shift (x0,y0) to upper qword
VBLENDPD xmm10, xmm14, xmm13, 1		;load (x0,y0,x1,y1) into xmm10
PSRLDQ xmm14, 8						;shift (x0,y0) to lower qword
SUB rsp, 16
VMOVDQU XMMWORD PTR[rbp-16], xmm10	;store (x0,y0,x1,y1) on stack

;convert dwords to doubles
VCVTDQ2PD ymm14, xmm14
VCVTDQ2PD ymm13, xmm13
VCVTDQ2PD ymm12, xmm12
VCVTDQ2PD ymm11, xmm11

;STATE OF RAGISTERS:
;+------+------+------+------+------+------+------+------+------+------+-------+-------+-------+-------+-------+-------+
;| xmm0 | xmm1 | xmm2 | xmm3 | xmm4 | xmm5 | xmm6 | xmm7 | xmm8 | xmm9 | xmm10 | xmm11 | xmm12 | xmm13 | xmm14 | xmm15 |
;+------+------+------+------+------+------+------+------+------+------+-------+-------+-------+-------+-------+-------+
;|      |      |      |      |      |      |      |      |      |      |       | x1,y0 | x0,y1 | x1,y1 | x0,y0 | pX,pY |
;+------+------+------+------+------+------+------+------+------+------+-------+-------+-------+-------+-------+-------+


MOVD xmm5, DWORD PTR[rbp-8]			;load y0 to xmm5
CALL getIndexYValue					;load hashTable[indexY] to rcx
MOVD xmm5, DWORD PTR[rbp-4]			;load x0 to xmm5
CALL getIndexXValue					;load hashTable[indexX] to rax
CALL getGradient					;calculate gradient(x0, y0) and load it into xmm5
MOVUPD xmm10, xmm5					;load gradient(x0, y0) into xmm10
MOVD xmm5, DWORD PTR[rbp-12]		;load x1 to xmm5
CALL getIndexXValue					;load hashTable[indexX] to rax
CALL getGradient					;calculate (x1, y0) gradient and load it into xmm5
MOVUPD xmm7, xmm5					;load gradient(x1,y0) into xmm7

MOVD xmm5, DWORD PTR[rbp-16]		;load y1 to xmm5
CALL getIndexYValue					;load hashTable[indexY] to rcx
MOVD xmm5, DWORD PTR[rbp-4]			;load x0 to xmm5
CALL getIndexXValue					;load hashTable[indexX] to rax
CALL getGradient					;calculate gradient(x0, y1) and load it into xmm5
MOVUPD xmm8, xmm5					;load (x0, y1) gradient into xmm8
MOVD xmm5, DWORD PTR[rbp-12]		;load x1 to xmm5
CALL getIndexXValue					;load hashTable[indexX] to rax
CALL getGradient					;calculate (x1, y1) gradient and load it into xmm5
MOVUPD xmm9, xmm5					;load gradient(x1,y1) into xmm9

;VINSERTF128 ymm15, ymm15, xmm15, 1	;load (pointX,pointY,pointX,pointY) into ymm15


;STATE OF RAGISTERS:
;+------+------+------+------+------+------+------+-------------+-------------+-------------+-------------+-------+-------+-------+-------+-------+
;| xmm0 | xmm1 | xmm2 | xmm3 | xmm4 | xmm5 | xmm6 | xmm7        | xmm8        | xmm9        | xmm10       | xmm11 | xmm12 | xmm13 | xmm14 | xmm15 |
;+------+------+------+------+------+------+------+-------------+-------------+-------------+-------------+-------+-------+-------+-------+-------+
;|      |      |      |      |      |      |      | grad(x1,y0) | grad(x0,y1) | grad(x1,y1) | grad(x0,y0) | x1,y0 | x0,y1 | x1,y1 | x0,y0 | pX,pY |
;+------+------+------+------+------+------+------+-------------+-------------+-------------+-------------+-------+-------+-------+-------+-------+


VSUBPD xmm14, xmm15, xmm14			;load dx0, dy0 into xmm14 (weightX, weightY)
VSUBPD xmm13, xmm15, xmm13			;load dx1, dy1 into xmm13
VSUBPD xmm12, xmm15, xmm12			;load dx0, dy1 into xmm12
VSUBPD xmm11, xmm15, xmm11			;load dx1, dy0 into xmm11

;STATE OF RAGISTERS:
;+------+------+------+------+------+------+------+-------------+-------------+-------------+-------------+---------+---------+---------+---------------------------+-------+
;| xmm0 | xmm1 | xmm2 | xmm3 | xmm4 | xmm5 | xmm6 | xmm7        | xmm8        | xmm9        | xmm10       | xmm11   | xmm12   | xmm13   | xmm14                     | xmm15 |
;+------+------+------+------+------+------+------+-------------+-------------+-------------+-------------+---------+---------+---------+---------------------------+-------+
;|      |      |      |      |      |      |      | grad(x1,y0) | grad(x0,y1) | grad(x1,y1) | grad(x0,y0) | dx1,dy0 | dx0,dy1 | dx1,dy1 | dx0(weightX),dy0(weightY) | pX,pY |
;+------+------+------+------+------+------+------+-------------+-------------+-------------+-------------+---------+---------+---------+---------------------------+-------+


VDPPD xmm10, xmm10, xmm14, 49		;0011_0001b ;load (dx0 * grad(x0,y0).x + dy0 * grad(x0,y0).y) into xmm10
VDPPD xmm9, xmm9, xmm13, 49			;0011_0001b ;load (dx1 * grad(x1,y1).x + dy1 * grad(x1,y1).y) into xmm9
VDPPD xmm8, xmm8, xmm12, 49			;0011_0001b ;load (dx0 * grad(x0,y1).x + dy1 * grad(x0,y1).y) into xmm8
VDPPD xmm7, xmm7, xmm11, 49			;0011_0001b ;load (dx1 * grad(x1,y0).x + dy0 * grad(x1,y0).y) into xmm7

;STATE OF RAGISTERS:
;+------+------+------+------+------+------+------+-------------------------------------------+-------------------------------------------+-------------------------------------------+-------------------------------------------+---------+---------+---------+---------------------------+-------+
;| xmm0 | xmm1 | xmm2 | xmm3 | xmm4 | xmm5 | xmm6 | xmm7                                      | xmm8                                      | xmm9                                      | xmm10                                     | xmm11   | xmm12   | xmm13   | xmm14                     | xmm15 |
;+------+------+------+------+------+------+------+-------------------------------------------+-------------------------------------------+-------------------------------------------+-------------------------------------------+---------+---------+---------+---------------------------+-------+
;|      |      |      |      |      |      |      | dx1 * grad(x1,y0).x + dy0 * grad(x1,y0).y | dx0 * grad(x0,y1).x + dy1 * grad(x0,y1).y | dx1 * grad(x1,y1).x + dy1 * grad(x1,y1).y | dx0 * grad(x0,y0).x + dy0 * grad(x0,y0).y | dx1,dy0 | dx0,dy1 | dx1,dy1 | dx0(weightX),dy0(weightY) | pX,pY |
;+------+------+------+------+------+------+------+-------------------------------------------+-------------------------------------------+-------------------------------------------+-------------------------------------------+---------+---------+---------+---------------------------+-------+

VMOVUPD xmm13, xmm14
PSRLDQ xmm13, 8					;load weightX into xmm13

;interpolate dot products of (x0,y0) and (x1,y0)
SUBSD xmm7, xmm10				;xmm7 -= xmm10
VFMADD231SD xmm10, xmm13, xmm7	;xmm10 += (xmm7 * xmm13)

;interpolate dot products of (x0,y1) and (x1,y1)
SUBSD xmm9, xmm8				;xmm9 -= xmm8
VFMADD231SD xmm8, xmm13, xmm9	;xmm8 += (xmm9 * xmm13)

;MOVUPD xmm0, xmm10				;load first interpolated value to xmm0

;interpolate interpolated values
SUBSD xmm8, xmm10				;xmm8 -= xmm10
VFMADD231SD xmm10, xmm14, xmm8	;xmm10 += (xmm14 * xmm8)

MOV rsp, rbp					;restore rsp and rbp
POP rbp
RET								;value in xmm10
perlinNoise ENDP

;double fractalPerlinNoise(double pointX, double pointY, double frequency, unsigned short hashTableSize, unsigned char* hashTable, unsigned char numberOfOctaves)

fractalPerlinNoise PROC

PUSH rbp							;save rbp
MOV rbp, rsp 
PUSH rsi							;save rsi

SUB rsp, 144						;allocate stack for xmm registers
MOVUPD XMMWORD PTR[rbp-144], xmm7
MOVUPD XMMWORD PTR[rbp-128], xmm8
MOVUPD XMMWORD PTR[rbp-112], xmm9
MOVUPD XMMWORD PTR[rbp-96], xmm10
MOVUPD XMMWORD PTR[rbp-80], xmm11
MOVUPD XMMWORD PTR[rbp-64], xmm12
MOVUPD XMMWORD PTR[rbp-48], xmm13
MOVUPD XMMWORD PTR[rbp-32], xmm14
MOVUPD XMMWORD PTR[rbp-16], xmm15


PSLLDQ xmm0, 8						;shift pointX to upper quadword
VBLENDPD xmm15, xmm0, xmm1, 1		;blend pointX and pointY to xmm15
VMOVUPD xmm1, xmm15					;store copy of (pointX, pointY) to xmm1
MOVZX r9,r9w						;load hashTableSize(zero extended) to r9
MOV rsi, QWORD PTR[rbp+48]			;load hashTable to rsi
MOVZX rcx, BYTE PTR[rbp+56]			;load numberOfOctaves to rcx

;REGISTRY LAYOUT:
;+--------------------------+------+-----------------------------------+-----------+-------------------+------+------+------+------+------+-------+-------+-------+-------+-------+-------+
;| xmm0                     | xmm1 | xmm2                              | xmm3      | xmm4              | xmm5 | xmm6 | xmm7 | xmm8 | xmm9 | xmm10 | xmm11 | xmm12 | xmm13 | xmm14 | xmm15 |
;+--------------------------+------+-----------------------------------+-----------+-------------------+------+------+------+------+------+-------+-------+-------+-------+-------+-------+
;| perlinNoise return value | sum  | frequency (in both halves of reg) | amplitude | sum of amplitudes | not used    | used by perlinNoise procedure                              | pX,pY |
;+--------------------------+------+-----------------------------------+-----------+-------------------+-------------+------------------------------------------------------------+-------+

;+-------------------------------+----------+-----------------+-------------------------------+----------+----------------------+-----+-----+-----+-----+-----+-----+-----+------------------+---------------+---------------+-----+
;| rax                           | rbx      | rcx             | rdx                           | r8       | r9                   | r10 | r11 | r12 | r13 | r14 | r15 | rdi | rsi              | rbp           | rsp           | rbx |
;+-------------------------------+----------+-----------------+-------------------------------+----------+----------------------+-----+-----+-----+-----+-----+-----+-----+------------------+---------------+---------------+-----+
;| used by perlinNoise procedure | not used | octaves counter | used by perlinNoise procedure | not used | stores hashTableSize | not used                                | stores hashTable | used by perlinNoise procedure |     |
;+-------------------------------+----------+-----------------+-------------------------------+----------+----------------------+-----------------------------------------+------------------+-------------------------------+-----+

VBROADCASTSD ymm2, xmm2				;broadcast frequency to all qwords in ymm2
VMOVUPD xmm0, twoZeroes				;load 0.0 as initial sum
VMOVUPD xmm3, zeroOne				;load 1.0 as initial amplitude
VMOVUPD xmm4, twoZeroes				;load 0.0 as initial sumOfAmplitudes

octaveLoop:
VMULPD xmm15, xmm1, xmm2			;(pointX, pointY) *= frequency
CALL perlinNoise					;calculate perlinNoise for (pointX, pointY), store result in xmm10
MULSD xmm10, xmm3					;multiply result by amplitude
ADDSD xmm0, xmm10					;add rsult to sum
ADDSD xmm4, xmm3					;sumOfAmplitudes += amplitude
MULPD xmm2, twoTwo					;frequency *= 2.0
DIVSD xmm3, zeroTwo					;amplitude /= 2.0
LOOP octaveLoop

VDIVSD xmm0, xmm0, xmm4				;xmm0 = sum/sumOfAmplitudes



MOVUPD xmm7, XMMWORD PTR[rbp-144]
MOVUPD xmm8, XMMWORD PTR[rbp-128]
MOVUPD xmm9, XMMWORD PTR[rbp-112]
MOVUPD xmm10, XMMWORD PTR[rbp-96]
MOVUPD xmm11, XMMWORD PTR[rbp-80]
MOVUPD xmm12, XMMWORD PTR[rbp-64]
MOVUPD xmm13, XMMWORD PTR[rbp-48]
MOVUPD xmm14, XMMWORD PTR[rbp-32]
MOVUPD xmm15, XMMWORD PTR[rbp-16]


POP rsi							;restore rsi
MOV rsp, rbp						;restore rsp
POP rbp							;restore rbp


RET									;return result in xmm0
fractalPerlinNoise ENDP

end ; End of ASM file