.data
result real8 -1.0,-1.0
minusOnes real8 -1.0,-1.0
ones real8 1.0,1.0
twoOnes DWORD 1,1,0,0

.code
;double interpolate(double firstValue, double secondValue, double weight)
;(secondValue - firstValue) * weight + firstValue
;first Value in xmm0, secondValue in xmm1, weight in xmm2
;all in lower QWORDS
interpolate PROC
SUBSD xmm1,xmm0				;xmm1-=xmm0
VFMADD231SD xmm0,xmm1,xmm2	;xmm0+=(xmm1*xmm2)
RET ;result in XMM0
interpolate ENDP

;unsigned short getIndexY(int y, unsigned char* hashTable, unsigned short hashTableSize)
;y in xmm0, hashTable in rsi, hashTableSize in r15w (zero extended)
getIndexYValue PROC ;USES rax, rcx, rdx, xmm0
MOVD eax, xmm0				;load y to eax
CDQ							;eax:edx <- sign extend of eax
IDIV r15d					;y/hashTableSize, eax<-quotient of division, edx<-remainder of division
TEST dx, dx					;set sign flag of remainder
JNS indexYPositive			
ADD dx, r15w				;if remainder was negatvie, add table size
MOVZX rdx, dx
indexYPositive:
MOVZX rcx, BYTE PTR [rsi+rdx];move hashTable[indexY] (zero extended) to rcx
RET
getIndexYValue ENDP

;unsigned short getIndexX(int x, unsigned char indexYValue, unsigned char* hashTable, unsigned short hashTableSize)
;x in xmm0,indexYValue in rcx, hashTable in rsi, hashTableSize in r15w (zero extended)
getIndexXValue PROC ;USES rax, rcx, rdx
MOVD eax, xmm0				;load x to eax (zero extended)
ADD rax, rcx				;rax <- x + indexYValue
CDQ							;rax:rdx <- sign extend of rax
IDIV r15d					;(x + indexYValue)/hashTableSize, eax<-quotient of division, edx<-remainder of division
TEST dx, dx					;set sign flag of remainder
JNS indexXPositive			
ADD dx, r15w				;if remainder was negatvie, add table size
MOVZX rdx, dx
indexXPositive:
MOVZX rax, BYTE PTR [rsi+rdx];move hashTable[indexX] (zero extended) to rax
RET
getIndexXValue ENDP

;xmmword getGradient(unsigned char seed)
;seed in rax
getGradient PROC ;USES rax, rdx, xmm0, xmm1
MOV rdx, rax				;save the seed
AND rax, 2					;extract older bit of seed
SHL rax, 62					;move it to most significant position
AND rdx, 1					;extract younger bit of seed
SHL rdx, 63					;move it to most significant position
MOVQ xmm1, rax				;move the older bit of seed to lower quadword of xmm1
PSLLDQ xmm1, 8				;shift it to uper quadword
PINSRQ xmm1, rdx, 0			;move the younger bit of seed to lower quadword of xmm1
MOVUPD xmm0, minusOnes		
MOVUPD XMMWORD PTR[rsi-16], xmm0			;store (-1.0,-1.0) in temporary variable
MOVUPD xmm0, ones
VMASKMOVPD XMMWORD PTR[rsi-16], xmm1, xmm0	;store 1.0 in temporary variable, in appropirate quadwords
MOVUPD xmm0, XMMWORD PTR[rsi-16]			;load result to xmm0
RET
getGradient ENDP

;double perlinNoise(double pointX, double pointY, unsigned char* hashTable, unsigned short hashTableSize)
;pointX in upper quadword of xmm15/xmm0, pointY in lower quadword of xmm15/xmm1, hashTable in rsi/r8, hashTableSize in r15w/r9
perlinNoise PROC
PUSH rbp
MOV rbp, rsp 
PSLLDQ xmm0, 8 ;shift pointX to upper quadword
VBLENDPD xmm15, xmm0, xmm1, 1 ;pack pointX and pointY to xmm15
MOV rsi, r8		;hashTable to rsi
MOVZX r15,r9w		;hashTableSize to r15(w)
VROUNDPD xmm4, xmm15, 249; 1111_1001b	;round (pointX, pointY) towards -inf and store in xmm4
VCVTPD2DQ xmm4, xmm4		;convert double to dword in xmm4
VPADDD xmm3, xmm4, twoOnes			;add (0,0,1,1) to rounded (0,0,pointX,pointY) and store in xmm3
;so now (0,0,x0,y0) is in xmm4 and (0,0,x1,y1) is in xmm3
VBLENDPS xmm2, xmm3, xmm4, 2		;load (x0,y1) into xmm2
VBLENDPS xmm1, xmm4, xmm3, 2		;load (x1,y0) into xmm1
PSLLDQ xmm4, 8						;shift (x0,y0) to upper qword
VBLENDPD xmm14, xmm4, xmm3, 1		;load (x0,y0,x1,y1) into xmm14
SUB rsp, 16
VMOVDQU XMMWORD PTR[rbp-16], xmm14	;store (x0,y0,x1,y1) on stack

;convert dwords to doubles
VCVTDQ2PD ymm4, xmm4
VCVTDQ2PD ymm3, xmm3
VCVTDQ2PD ymm2, xmm2
VCVTDQ2PD ymm1, xmm1

VINSERTF128 ymm13, ymm4, xmm1, 0	;load (x0,y0,x1,y0) into ymm13
VINSERTF128 ymm14, ymm3, xmm2, 1	;load (x0,y1,x1,y1) into ymm14

MOVD xmm0, DWORD PTR[rbp-8]			;load y0 to xmm0
CALL getIndexYValue					;load hashTable[indexY] to rcx
MOVD xmm0, DWORD PTR[rbp-4]			;load x0 to xmm0
CALL getIndexXValue					;load hashTable[indexX] to rax
CALL getGradient					;calculate (x0, y0) gradient and load it into xmm0
MOVUPD xmm12, xmm0					;load (x0, y0) gradient into xmm14
MOVD xmm0, DWORD PTR[rbp-12]		;load x1 to xmm0
CALL getIndexXValue					;load hashTable[indexX] to rax
CALL getGradient					;calculate (x1, y0) gradient and load it into xmm0
VINSERTF128 ymm12, ymm0, xmm12, 1	;load (gradient(x0,y0),gradient(x1,y0)) into ymm12

MOVD xmm0, DWORD PTR[rbp-16]		;load y1 to xmm0
CALL getIndexYValue					;load hashTable[indexY] to rcx
MOVD xmm0, DWORD PTR[rbp-4]			;load x0 to xmm0
CALL getIndexXValue					;load hashTable[indexX] to rax
CALL getGradient					;calculate (x0, y1) gradient and load it into xmm0
MOVUPD xmm11, xmm0					;load (x0, y1) gradient into xmm13
MOVD xmm0, DWORD PTR[rbp-12]		;load x1 to xmm0
CALL getIndexXValue					;load hashTable[indexX] to rax
CALL getGradient					;calculate (x1, y1) gradient and load it into xmm0
VINSERTF128 ymm11, ymm0, xmm11, 1	;load (gradient(x0,y1),gradient(x1,y1)) into ymm11

VINSERTF128 ymm15, ymm15, xmm15, 1	;load (pointX,pointY,pointX,pointY) into ymm15

MOV rsp, rbp						;restore rsp and rbp
POP rbp
RET
perlinNoise ENDP

end ; End of ASM file