.386
.model flat, stdcall
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;includem biblioteci, si declaram ce functii vrem sa importam
includelib msvcrt.lib
extern exit: proc
extern malloc: proc
extern memset: proc

includelib canvas.lib
extern BeginDrawing: proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;declaram simbolul start ca public - de acolo incepe executia
public start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;sectiunile programului, date, respectiv cod
.data
;aici declaram date
ok db 0
window_title DB "Pac-Man",0
area_width EQU 640
area_height EQU 480
area DD 0
labirint_width EQU 48
labirint_height EQU 48
coin_width EQU 10
coin_height EQU 20
pac_width equ 25
pac_height equ 25
scor DD ?
x_pacman DD 320
y_pacman dd 240
culoare dd 0000000h
move dd 0

counter DD 0 ; numara evenimentele de tip timer

arg1 EQU 8
arg2 EQU 12
arg3 EQU 16
arg4 EQU 20

symbol_width EQU 10
symbol_height EQU 20
include digits.inc
include letters.inc
include Pac_Man_Pixel.inc

include coin.inc

.code
; procedura make_text afiseaza o litera sau o cifra la coordonatele date
; arg1 - simbolul de afisat (litera sau cifra)
; arg2 - pointer la vectorul de pixeli
; arg3 - pos_x
; arg4 - pos_y

; make_labirint proc
; push ebp
	; mov ebp, esp
	; pusha
; lea esi, Lab	
; draw_text:
	; mov ebx, labirint_width
	; mul ebx
	; mov ebx, labirint_height
	; mul ebx
	; add esi, eax
	; mov ecx, labirint_height
; bucla_simbol_linii:
	; mov edi, [ebp+arg2] ; pointer la matricea de pixeli
	; mov eax, [ebp+arg4] ; pointer la coord y
	; add eax, labirint_height
	; sub eax, ecx
	; mov ebx, area_width
	; mul ebx
	; add eax, [ebp+arg3] ; pointer la coord x
	; shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	; add edi, eax
	; push ecx
	; mov ecx, labirint_width
; bucla_simbol_coloane:
	; mov eax, dword ptr [esi]
	; mov dword ptr [edi], eax
	
; simbol_pixel_next:
	; inc esi
	; add edi, 4
	; loop bucla_simbol_coloane
	; pop ecx
	; loop bucla_simbol_linii
	; popa
	; mov esp, ebp
	; pop ebp
	; ret
	; make_labirint endp

	make_pac proc
push ebp
	mov ebp, esp
	pusha
	mov eax, [ebp+arg1]
lea esi, Pac_Man_Pixel
draw_text:
	mov ebx, pac_width
	mul ebx
	mov ebx, pac_height
	mul ebx
	mov ebx, 4
	mul ebx
	add esi, eax
	mov ecx, pac_height
bucla_simbol_linii:
	mov edi, [ebp+arg2] ; pointer la matricea de pixeli
	mov eax, [ebp+arg4] ; pointer la coord y
	add eax, pac_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	add edi, eax
	push ecx
	mov ecx, pac_width
bucla_simbol_coloane:
cmp dword ptr[esi], 0
je simbol_pixel_next
	mov eax, dword ptr [esi]
	mov dword ptr [edi], eax
	jmp simbol_pixel_next

simbol_pixel_next:
	add esi, 4
	add edi, 4
	loop bucla_simbol_coloane
	pop ecx
	loop bucla_simbol_linii
	popa
	mov esp, ebp
	pop ebp
	ret
	make_pac endp
	
make_pac_macro macro symbol, drawArea, x, y


	push y
	push x
	push drawArea
	push symbol
	call make_pac
	add esp, 16
endm
	
make_coin proc
push ebp
	mov ebp, esp
	pusha
	mov eax, [ebp+arg1]
lea esi, coin	
draw_text:
	mov ebx, coin_width
	mul ebx
	mov ebx, coin_height
	mul ebx
	mov ebx, 4
	mul ebx
	add esi, eax
	mov ecx, coin_height
bucla_simbol_linii:
	mov edi, [ebp+arg2] ; pointer la matricea de pixeli
	mov eax, [ebp+arg4] ; pointer la coord y
	add eax, coin_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	add edi, eax
	push ecx
	mov ecx, coin_width
bucla_simbol_coloane:
cmp dword ptr[esi], 0
je simbol_pixel_next
	mov eax, dword ptr [esi]
	mov dword ptr [edi], eax
	jmp simbol_pixel_next

simbol_pixel_next:
	add esi, 4
	add edi, 4
	loop bucla_simbol_coloane
	pop ecx
	loop bucla_simbol_linii
	popa
	mov esp, ebp
	pop ebp
	ret
	make_coin endp
	
	make_coin_macro macro symbol, drawArea, x, y


	push y
	push x
	push drawArea
	push symbol
	call make_coin
	add esp, 16
endm


negru macro x, y, culoare
	local bucla1, bucla2
	mov eax, y
	mov ebx, area_width
	mul ebx
	add eax, x
	shl eax, 2
	add eax, area
	
	mov ebx, 25
bucla1:
mov ecx, 25
bucla2:
mov dword ptr[eax+4*ecx], culoare
loop bucla2
add eax, 4*area_width
dec ebx
cmp ebx, 0
jne bucla1
endm


make_text proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1] ; citim simbolul de afisat
	cmp eax, 'A'
	jl make_digit
	cmp eax, 'Z'
	jg make_digit
	sub eax, 'A'
	lea esi, letters
	jmp draw_text
make_digit:
	cmp eax, '0'
	jl make_space
	cmp eax, '9'
	jg make_space
	sub eax, '0'
	lea esi, digits
	jmp draw_text
make_space:	
	mov eax, 26 ; de la 0 pana la 25 sunt litere, 26 e space
	lea esi, letters
	
draw_text:
	mov ebx, symbol_width
	mul ebx
	mov ebx, symbol_height
	mul ebx
	add esi, eax
	mov ecx, symbol_height
bucla_simbol_linii:
	mov edi, [ebp+arg2] ; pointer la matricea de pixeli
	mov eax, [ebp+arg4] ; pointer la coord y
	add eax, symbol_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	
	add edi, eax
	
	
	push ecx
	
	mov ecx, symbol_width
	
bucla_simbol_coloane:
	cmp byte ptr [esi], 0
	je simbol_pixel_alb
	mov dword ptr [edi], 0ffffffh
	jmp simbol_pixel_next
simbol_pixel_alb:
	mov dword ptr [edi], 00000ffh
simbol_pixel_next:
	inc esi
	add edi, 4
	loop bucla_simbol_coloane
	pop ecx
	loop bucla_simbol_linii
	popa
	mov esp, ebp
	pop ebp
	ret
make_text endp

; un macro ca sa apelam mai usor desenarea simbolului
make_text_macro macro symbol, drawArea, x, y
	push y
	push x
	push drawArea
	push symbol
	call make_text
	add esp, 16
endm



	; make_labirint_macro macro symbol, drawArea, x, y


	; push y
	; push x
	; push drawArea
	; push symbol
	; call make_text
	; add esp, 16
; endm

; functia de desenare - se apeleaza la fiecare click
; sau la fiecare interval de 200ms in care nu s-a dat click
; arg1 - evt (0 - initializare, 1 - click, 2 - s-a scurs intervalul fara click)
; arg2 - x
; arg3 - y

line_horizontal macro x, y, len, color
local bucla_line
mov eax, y ; EAX = y
	mov ebx, area_width
	mul ebx ; eax = y*area_width
	add eax, x ; EAX = y*area_width+x
	shl eax, 2 ;  EAX = (y*area_width+x) * 4
	add eax, area
	mov ecx, len
	bucla_line: 
	mov dword ptr[eax], color
	add eax, 4
	loop bucla_line

endm

line_vertical macro x, y, len, color
local bucla_line
mov eax, y ; EAX = y
	mov ebx, area_width
	mul ebx ; eax = y*area_width
	add eax, x ; EAX = y*area_width+x
	shl eax, 2 ;  EAX = (y*area_width+x) * 4
	add eax, area
	mov ecx, len
	bucla_line: 
	mov dword ptr[eax], color
	add eax, 4*area_width
	loop bucla_line

endm

miscare proc
push ebp
mov ebp, esp
pusha

	
line_vertical  80 , 30, 120, 0FFh
line_vertical  80 , 270, 150, 0FFh
line_horizontal 80, 30, 500, 0FFh
line_vertical  580 , 30, 120, 0FFh	
line_vertical  580 , 270, 150, 0FFh
line_horizontal 80, 420, 500, 0FFh

line_horizontal 80, 270, 95, 0FFh
line_horizontal 270, 270, 120, 0FFh
line_horizontal 485, 270, 95, 0FFh

line_horizontal 80, 150, 95, 0FFh
line_horizontal 270, 90, 120, 0FFh
line_horizontal 485, 150, 95, 0FFh

line_vertical  175 , 150, 120, 0FFh
line_vertical  485 , 150, 120, 0FFh
line_horizontal 270, 240, 120, 0FFh
line_horizontal 270, 180, 120, 0FFh

line_vertical 270 , 180, 60, 0FFh
line_vertical 390 , 180, 60, 0FFh
line_vertical 330 , 270, 60, 0FFh
line_vertical 330 , 90, 60, 0FFh
line_vertical 330 , 30, 30, 0FFh
	
line_horizontal 110, 60, 130, 0FFh
line_horizontal 110, 120, 130, 0FFh
line_vertical 110 , 60, 60, 0FFh
line_vertical 240 , 60, 60, 0FFh

line_horizontal 420, 60, 130, 0FFh
line_horizontal 420, 120, 130, 0FFh
line_vertical 420 , 60, 60, 0FFh
line_vertical 550 , 60, 60, 0FFh
line_horizontal 420, 180, 35, 0FFh
line_vertical 420 , 180, 60, 0FFh
line_vertical 455 , 180, 60, 0FFh
line_horizontal 420, 270, 35, 0FFh
line_horizontal 360, 150, 95, 0FFh
line_horizontal 205, 150, 95, 0FFh
line_horizontal 205, 180, 35, 0FFh
line_vertical 205 , 180, 60, 0FFh
line_vertical 240 , 180, 60, 0FFh
line_horizontal 205, 270, 35, 0FFh
line_horizontal 270, 60, 30, 0FFh
line_horizontal 360, 60, 30, 0FFh
line_horizontal 270, 120, 30, 0FFh
line_horizontal 360, 120, 30, 0FFh

line_horizontal 110, 300, 60, 0FFh
line_vertical 170 , 300, 60, 0FFh
line_horizontal 110, 330, 30, 0FFh
line_vertical 140 , 330, 60, 0FFh
line_vertical 110 , 360, 60, 0FFh
line_horizontal 140, 390, 60, 0FFh
line_horizontal 200, 360, 90, 0FFh
line_vertical 230 , 300, 60, 0FFh
line_vertical 260 , 300, 60, 0FFh
line_horizontal 230, 390, 60, 0FFh
line_vertical 260 , 390, 30, 0FFh
line_horizontal 490, 300, 60, 0FFh
line_vertical 490 , 300, 60, 0FFh
line_horizontal 520, 330, 30, 0FFh
line_vertical 520 , 330, 60, 0FFh
line_horizontal 460, 390, 60, 0FFh
line_horizontal 370, 390, 60, 0FFh
line_vertical 400 , 390, 30, 0FFh
line_horizontal 370, 360, 90, 0FFh
line_vertical 400 , 300, 60, 0FFh
line_vertical 430 , 300, 60, 0FFh
line_horizontal 320, 390, 20, 0FFh
line_horizontal 320, 360, 20, 0FFh
line_vertical 320 , 360, 30, 0FFh
line_vertical 340 , 360, 30, 0FFh
line_horizontal 290, 300, 10, 0FFh
line_horizontal 290, 330, 40, 0FFh
line_vertical 290 , 300, 30, 0FFh
line_horizontal 330, 330, 40, 0FFh
line_vertical 370 , 300, 30, 0FFh
line_horizontal 360, 300, 10, 0FFh
line_vertical 550 , 360, 60, 0FFh



cmp ok, 0
jne sari
mov ok, 1
make_coin_macro 0, area, 90, 125
make_coin_macro 0, area, 110, 125
make_coin_macro 0, area, 130, 125
make_coin_macro 0, area, 150, 125

make_coin_macro 0, area, 190, 125
make_coin_macro 0, area, 210, 125
make_coin_macro 0, area, 230, 125
make_coin_macro 0, area, 250, 125
make_coin_macro 0, area, 270, 125
make_coin_macro 0, area, 290, 125
make_coin_macro 0, area, 310, 125
make_coin_macro 0, area, 340, 125
make_coin_macro 0, area, 310, 125
make_coin_macro 0, area, 340, 125
make_coin_macro 0, area, 360, 125
make_coin_macro 0, area, 380, 125
make_coin_macro 0, area, 400, 125
make_coin_macro 0, area, 420, 125
make_coin_macro 0, area, 440, 125
make_coin_macro 0, area, 460, 125
make_coin_macro 0, area, 400, 125
make_coin_macro 0, area, 420, 125
make_coin_macro 0, area, 440, 125
make_coin_macro 0, area, 460, 125

make_coin_macro 0, area, 500, 125
make_coin_macro 0, area, 520, 125
make_coin_macro 0, area, 540, 125
make_coin_macro 0, area, 560, 125
make_coin_macro 0, area, 560, 100
make_coin_macro 0, area, 560, 80
make_coin_macro 0, area, 560, 60
make_coin_macro 0, area, 560, 35
make_coin_macro 0, area, 540, 35
make_coin_macro 0, area, 520, 35
make_coin_macro 0, area, 500, 35
make_coin_macro 0, area, 480, 35
make_coin_macro 0, area, 460, 35
make_coin_macro 0, area, 440, 35
make_coin_macro 0, area, 420, 35
make_coin_macro 0, area, 400, 35

make_coin_macro 0, area, 380, 35
make_coin_macro 0, area, 360, 35
make_coin_macro 0, area, 340, 35
make_coin_macro 0, area, 310, 35
make_coin_macro 0, area, 290, 35
make_coin_macro 0, area, 270, 35
make_coin_macro 0, area, 250, 35
make_coin_macro 0, area, 230, 35
make_coin_macro 0, area, 210, 35
make_coin_macro 0, area, 190, 35
make_coin_macro 0, area, 170, 35
make_coin_macro 0, area, 150, 35
make_coin_macro 0, area, 130, 35
make_coin_macro 0, area, 110, 35
make_coin_macro 0, area, 90, 35

make_coin_macro 0, area, 90, 125
make_coin_macro 0, area, 90, 100
make_coin_macro 0, area, 90, 80
make_coin_macro 0, area, 90, 60


make_coin_macro 0, area, 250, 95

make_coin_macro 0, area, 250, 65
make_coin_macro 0, area, 270, 95
make_coin_macro 0, area, 290, 95
make_coin_macro 0, area, 310, 95

make_coin_macro 0, area, 270, 65
make_coin_macro 0, area, 290, 65
make_coin_macro 0, area, 310, 65
make_coin_macro 0, area, 340, 65
make_coin_macro 0, area, 360, 65
make_coin_macro 0, area, 380, 65
make_coin_macro 0, area, 400, 65
make_coin_macro 0, area, 340, 95
make_coin_macro 0, area, 360, 95
make_coin_macro 0, area, 380, 95
make_coin_macro 0, area, 400, 95
make_coin_macro 0, area, 405, 155
make_coin_macro 0, area, 425, 155
make_coin_macro 0, area, 445, 155
make_coin_macro 0, area, 465, 155
make_coin_macro 0, area, 385, 155
make_coin_macro 0, area, 365, 155
make_coin_macro 0, area, 345, 155

make_coin_macro 0, area, 305, 155
make_coin_macro 0, area, 285, 155

make_coin_macro 0, area, 245, 155
make_coin_macro 0, area, 225, 155
make_coin_macro 0, area, 205, 155
make_coin_macro 0, area, 185, 155
make_coin_macro 0, area, 185, 180
make_coin_macro 0, area, 185, 200
make_coin_macro 0, area, 185, 220
make_coin_macro 0, area, 185, 245
make_coin_macro 0, area, 405, 245
make_coin_macro 0, area, 425, 245
make_coin_macro 0, area, 445, 245
make_coin_macro 0, area, 465, 245
make_coin_macro 0, area, 385, 245
make_coin_macro 0, area, 365, 245
make_coin_macro 0, area, 345, 245


make_coin_macro 0, area, 305, 245
make_coin_macro 0, area, 285, 245
make_coin_macro 0, area, 265, 245
make_coin_macro 0, area, 245, 245
make_coin_macro 0, area, 225, 245
make_coin_macro 0, area, 205, 245
make_coin_macro 0, area, 465, 220
make_coin_macro 0, area, 465, 200
make_coin_macro 0, area, 465, 180
make_coin_macro 0, area, 400, 180
make_coin_macro 0, area, 400, 200
make_coin_macro 0, area, 400, 220
make_coin_macro 0, area, 90, 275
make_coin_macro 0, area, 110, 275
make_coin_macro 0, area, 130, 275
make_coin_macro 0, area, 150, 275

make_coin_macro 0, area, 190, 275
make_coin_macro 0, area, 210, 275
make_coin_macro 0, area, 230, 275
make_coin_macro 0, area, 250, 275
make_coin_macro 0, area, 270, 275
make_coin_macro 0, area, 290, 275
make_coin_macro 0, area, 310, 275
make_coin_macro 0, area, 340, 275
make_coin_macro 0, area, 360, 275
make_coin_macro 0, area, 380, 275
make_coin_macro 0, area, 400, 275
make_coin_macro 0, area, 420, 275
make_coin_macro 0, area, 440, 275
make_coin_macro 0, area, 460, 275

make_coin_macro 0, area, 500, 275
make_coin_macro 0, area, 520, 275
make_coin_macro 0, area, 540, 275
make_coin_macro 0, area, 560, 275
make_coin_macro 0, area, 560, 305
make_coin_macro 0, area, 560, 335
make_coin_macro 0, area, 560, 355
make_coin_macro 0, area, 560, 375
make_coin_macro 0, area, 560, 395
make_coin_macro 0, area, 530, 335
make_coin_macro 0, area, 530, 355

make_coin_macro 0, area, 530, 395
make_coin_macro 0, area, 530, 305
make_coin_macro 0, area, 500, 305
make_coin_macro 0, area, 500, 325
make_coin_macro 0, area, 500, 345
make_coin_macro 0, area, 500, 365

make_coin_macro 0, area, 460, 365
make_coin_macro 0, area, 440, 365
make_coin_macro 0, area, 420, 365
make_coin_macro 0, area, 400, 365
make_coin_macro 0, area, 380, 365
make_coin_macro 0, area, 350, 365
make_coin_macro 0, area, 300, 365
make_coin_macro 0, area, 270, 365
make_coin_macro 0, area, 250, 365
make_coin_macro 0, area, 230, 365
make_coin_macro 0, area, 210, 365
make_coin_macro 0, area, 190, 365

make_coin_macro 0, area, 150, 365
make_coin_macro 0, area, 150, 345
make_coin_macro 0, area, 150, 325
make_coin_macro 0, area, 150, 305
make_coin_macro 0, area, 120, 305
make_coin_macro 0, area, 90, 295
make_coin_macro 0, area, 90, 315
make_coin_macro 0, area, 90, 335
make_coin_macro 0, area, 90, 355
make_coin_macro 0, area, 90, 375
make_coin_macro 0, area, 90, 395
make_coin_macro 0, area, 120, 335
make_coin_macro 0, area, 120, 355

make_coin_macro 0, area, 120, 395
make_coin_macro 0, area, 140, 395
make_coin_macro 0, area, 160, 395
make_coin_macro 0, area, 180, 395

make_coin_macro 0, area, 220, 395
make_coin_macro 0, area, 240, 395
make_coin_macro 0, area, 270, 395
make_coin_macro 0, area, 300, 395
make_coin_macro 0, area, 325, 395
make_coin_macro 0, area, 350, 395
make_coin_macro 0, area, 380, 395
make_coin_macro 0, area, 410, 395

make_coin_macro 0, area, 450, 395
make_coin_macro 0, area, 470, 395
make_coin_macro 0, area, 490, 395
make_coin_macro 0, area, 510, 395
make_coin_macro 0, area, 300, 335
make_coin_macro 0, area, 325, 335
make_coin_macro 0, area, 270, 335
make_coin_macro 0, area, 350, 335
make_coin_macro 0, area, 380, 335
make_coin_macro 0, area, 270, 305
make_coin_macro 0, area, 340, 305
make_coin_macro 0, area, 310, 305
make_coin_macro 0, area, 380, 305
make_coin_macro 0, area, 410, 305
make_coin_macro 0, area, 440, 305


make_coin_macro 0, area, 380, 305
make_coin_macro 0, area, 410, 335
make_coin_macro 0, area, 440, 335
make_coin_macro 0, area, 460, 335

make_coin_macro 0, area, 210, 335
make_coin_macro 0, area, 240, 335
make_coin_macro 0, area, 240, 305
make_coin_macro 0, area, 210, 305


make_coin_macro 0, area, 210, 335
make_coin_macro 0, area, 190, 335

make_coin_macro 0, area, 215, 180
make_coin_macro 0, area, 215, 200
make_coin_macro 0, area, 215, 220
make_coin_macro 0, area, 250, 180
make_coin_macro 0, area, 250, 200
make_coin_macro 0, area, 250, 220
make_coin_macro 0, area, 435, 180
make_coin_macro 0, area, 435, 200
make_coin_macro 0, area, 435, 220
sari:
  
                     ; 
negru x_pacman, y_pacman, 0000000h
cmp move, 1
je sus_pac_man
cmp move,2
je stanga_pac_man
cmp move, 3
je dreapta_pac_man
cmp move, 4
je jos_pac_man
jmp final
;make_pac_macro 0, area,320, 240
negrut:   

negru 290, 275, 0000000h
negru 260,275, 0000000h

negru 230,275, 0000000h
negru 200, 275, 0000000h
negru 165,275, 0000000h
negru 140, 275, 0000000h
negru 110,275, 0000000h



stanga_pac_man:
cmp x_pacman, 175
je comparare_y_175
cmp x_pacman, 85
je comparare_y_85
cmp x_pacman, 115
je comparare_y_110
cmp x_pacman, 145
je comparare_y_140
cmp x_pacman, 205
je comparare_y_208
cmp x_pacman, 235
je comparare_y_235
cmp x_pacman, 245
je comparare_y_245
cmp x_pacman, 265
je comparare_y_265
cmp x_pacman, 295
je comparare_y_295

cmp x_pacman, 335
je comparare_y_335
cmp x_pacman, 375
je comparare_y_375
cmp x_pacman, 395
je comparare_y_395
cmp x_pacman, 405
je comparare_y_405
cmp x_pacman, 425
je comparare_y_425
cmp x_pacman, 345
je comparare_y_345
cmp x_pacman, 435
je comparare_y_435
cmp x_pacman, 460
je comparare_y_455
cmp x_pacman, 495
je comparare_y_490
cmp x_pacman, 525
je comparare_y_525
cmp x_pacman, 555
je comparare_y_555

continua:
cmp ok , 0
je negrut
sub x_pacman, 5
jmp desen


dreapta_pac_man:
cmp x_pacman, 85
je comparare_110
cmp x_pacman, 115
je comparare_140
cmp x_pacman, 145
je comparare_170
cmp x_pacman, 175
je comparare_200
cmp x_pacman, 205
je comparare_230
cmp x_pacman, 215
je comparare_240
cmp x_pacman, 235
je comparare_260
cmp x_pacman, 245
je comparare_270
cmp x_pacman, 265
je comparare_290
cmp x_pacman, 295
je comparare_320
cmp x_pacman, 305
je comparare_330
cmp x_pacman, 335
je comparare_370
cmp x_pacman, 375
je comparare_400
cmp x_pacman, 395
je comparare_420
cmp x_pacman, 405
je comparare_430
cmp x_pacman, 425
je comparare_455
cmp x_pacman, 430
je comparare_455
cmp x_pacman, 435
je comparare_455
cmp x_pacman, 460
je comparare_485
cmp x_pacman, 495
je comparare_520
cmp x_pacman, 525
je comparare_550
cmp x_pacman, 555
je desen
continua_dreapta:
add x_pacman, 5
jmp desen



jos_pac_man:
cmp y_pacman, 390
je comparare_x_390
cmp y_pacman, 360
je comparare_x_360
cmp y_pacman, 330
je comparare_x_330
cmp y_pacman, 300
je comparare_x_300
cmp y_pacman, 270
je comparare_x_270
cmp y_pacman, 240
je comparare_x_240
cmp y_pacman, 150
je comparare_x_150
cmp y_pacman, 120
je comparare_x_120
cmp y_pacman, 90
je comparare_x_90
cmp y_pacman, 60
je comparare_x_60
cmp y_pacman, 30
je comparare_x_30
continua_jos:
add y_pacman, 5
jmp desen


sus_pac_man:
cmp y_pacman, 30
je comparare_sus_30
cmp y_pacman, 60
je comparare_sus_60
cmp y_pacman, 90
je comparare_sus_90
cmp y_pacman, 120
je comparare_sus_120
cmp y_pacman, 150
je comparare_sus_150
cmp y_pacman, 180
je comparare_sus_180
cmp y_pacman, 240
je comparare_sus_240
cmp y_pacman, 270
je comparare_sus_270
cmp y_pacman, 300
je comparare_sus_300
cmp y_pacman, 330
je comparare_sus_330
cmp y_pacman, 360
je comparare_sus_360
cmp y_pacman, 390
je comparare_sus_390
continua_sus:
sub y_pacman, 5
jmp desen





comparare_sus_30:
je desen
comparare_sus_60:
cmp x_pacman, 85
je continua_sus
cmp x_pacman, 245
je continua_sus
cmp x_pacman, 305
je continua_sus
cmp x_pacman, 335
je continua_sus
cmp x_pacman, 395
je continua_sus
cmp x_pacman, 555
je continua_sus
cmp x_pacman, 275
je desen
cmp x_pacman, 295
je desen
cmp x_pacman, 365
je desen
cmp x_pacman, 345
je desen
cmp x_pacman, 265
je desen



comparare_sus_90:
cmp x_pacman, 85
je continua_sus
cmp x_pacman, 245
je continua_sus
cmp x_pacman, 395
je continua_sus
cmp x_pacman, 555
je continua_sus
cmp x_pacman, 275
je desen
cmp x_pacman, 295
je desen
cmp x_pacman,305
je desen
cmp x_pacman, 325
je desen
cmp x_pacman, 345
je desen
cmp x_pacman, 365
je desen
cmp x_pacman, 385
je desen
cmp x_pacman, 335
je desen
cmp x_pacman, 265
je desen


comparare_sus_120:
cmp x_pacman, 85
je continua_sus
cmp x_pacman, 245
je continua_sus
cmp x_pacman, 305
je continua_sus
cmp x_pacman, 335
je continua_sus
cmp x_pacman, 395
je continua_sus
cmp x_pacman, 555
je continua_sus
cmp x_pacman, 115
je desen
cmp x_pacman, 135
je desen
cmp x_pacman, 155
je desen
cmp x_pacman, 175
je desen
cmp x_pacman, 195
je desen
cmp x_pacman, 215
je desen
cmp x_pacman, 235
je desen
cmp x_pacman, 345
je desen
cmp x_pacman, 275
je desen
cmp x_pacman, 365
je desen
cmp x_pacman, 360
je desen
cmp x_pacman, 405
je desen
cmp x_pacman, 425
je desen
cmp x_pacman, 445
je desen
cmp x_pacman, 465
je desen
cmp x_pacman, 485
je desen
cmp x_pacman,505
je desen
cmp x_pacman, 525
je desen
cmp x_pacman, 545
je desen
cmp x_pacman, 295
je desen
cmp x_pacman, 210
je desen
cmp x_pacman, 215
je desen
cmp x_pacman, 220
je desen
cmp x_pacman, 435
je desen
cmp x_pacman, 205
je desen
cmp x_pacman, 460
je desen
cmp x_pacman, 405
je desen
cmp x_pacman, 265
je desen

comparare_sus_150:
cmp x_pacman, 175
je continua_sus
cmp x_pacman, 305
je continua_sus
cmp x_pacman, 335
je continua_sus
cmp x_pacman, 460
je continua_sus
cmp x_pacman, 210
je desen
cmp x_pacman, 235
je desen
cmp x_pacman, 260
je desen
cmp x_pacman, 285
je desen
cmp x_pacman, 365
je desen
cmp x_pacman, 390
je desen
cmp x_pacman, 415
je desen
cmp x_pacman, 205
je desen
cmp x_pacman, 300
je desen
cmp x_pacman, 340
je desen
cmp x_pacman, 345
je desen
cmp x_pacman, 435
je desen
cmp x_pacman, 295
je desen
cmp x_pacman, 245
je desen
cmp x_pacman, 405
je desen
cmp x_pacman, 395
je desen
cmp x_pacman, 265
je desen

comparare_sus_180:
cmp x_pacman, 175
je continua_sus
cmp x_pacman, 245
je continua_sus
cmp x_pacman, 395
je continua_sus
cmp x_pacman, 460
je continua_sus
cmp x_pacman, 210
je desen
cmp x_pacman, 205
je desen
cmp x_pacman, 425
je desen
cmp x_pacman, 405
je desen


comparare_sus_240:
cmp x_pacman, 175
je continua_sus
cmp x_pacman, 205
je continua_sus
cmp x_pacman, 245
je continua_sus
cmp x_pacman, 395
je continua_sus
cmp x_pacman, 425
je continua_sus
cmp x_pacman, 460
je continua_sus
cmp x_pacman, 425
je desen
cmp x_pacman, 275
je desen
cmp x_pacman, 295
je desen
cmp x_pacman, 315
je desen
cmp x_pacman, 335
je desen
cmp x_pacman, 430
je desen
cmp x_pacman, 435
je desen
cmp x_pacman, 340
je desen
cmp x_pacman, 345
je desen
cmp x_pacman, 350
je desen
cmp x_pacman, 355
je desen
cmp x_pacman, 405
je desen
cmp x_pacman, 265
je desen

comparare_sus_270:
cmp x_pacman, 175
je continua_sus
cmp x_pacman, 245
je continua_sus
cmp x_pacman, 395
je continua_sus
cmp x_pacman, 460
je continua_sus
cmp x_pacman, 205
je desen
cmp x_pacman, 210
je desen
cmp x_pacman, 215
je desen
cmp x_pacman, 220
je desen
cmp x_pacman, 225
je desen
cmp x_pacman, 230
je desen
cmp x_pacman, 235
je desen
cmp x_pacman, 240
je desen
cmp x_pacman, 270
je desen
cmp x_pacman, 275
je desen
cmp x_pacman, 280
je desen
cmp x_pacman, 285
je desen
cmp x_pacman, 290
je desen
cmp x_pacman, 295
je desen
cmp x_pacman, 300
je desen
cmp x_pacman, 305
je desen
cmp x_pacman, 310
je desen
cmp x_pacman, 315
je desen
cmp x_pacman, 320
je desen
cmp x_pacman, 325
je desen
cmp x_pacman, 330
je desen
cmp x_pacman, 335
je desen
cmp x_pacman, 340
je desen
cmp x_pacman, 345
je desen
cmp x_pacman, 350
je desen
cmp x_pacman, 355
je desen
cmp x_pacman, 360
je desen
cmp x_pacman, 365
je desen
cmp x_pacman, 370
je desen
cmp x_pacman, 375
je desen
cmp x_pacman, 380
je desen
cmp x_pacman, 385
je desen
cmp x_pacman, 420
je desen
cmp x_pacman, 425
je desen
cmp x_pacman, 430
je desen
cmp x_pacman, 435
je desen
cmp x_pacman, 440
je desen
cmp x_pacman, 265
je desen
cmp x_pacman, 445
je desen
cmp x_pacman, 450
je desen
cmp x_pacman, 455
je desen
cmp x_pacman, 85
je desen
cmp x_pacman, 95
je desen
cmp x_pacman, 105
je desen
cmp x_pacman, 115
je desen
cmp x_pacman, 125
je desen
cmp x_pacman, 135
je desen
cmp x_pacman, 145
je desen
cmp x_pacman, 155
je desen
cmp x_pacman, 165
je desen
cmp x_pacman, 490
je desen
cmp x_pacman, 500
je desen
cmp x_pacman, 510
je desen
cmp x_pacman, 520
je desen
cmp x_pacman, 525
je desen
cmp x_pacman, 535
je desen
cmp x_pacman, 545
je desen
cmp x_pacman, 530
je desen
cmp x_pacman, 540
je desen
cmp x_pacman, 550
je desen
cmp x_pacman, 555
je desen
cmp x_pacman, 560
je desen
cmp x_pacman, 565
je desen
cmp x_pacman, 570
je desen
cmp x_pacman, 405
je desen

comparare_sus_300:
cmp x_pacman, 85
je continua_sus
cmp x_pacman, 175
je continua_sus
cmp x_pacman, 205
je continua_sus
cmp x_pacman, 235
je continua_sus
cmp x_pacman, 265
je continua_sus
cmp x_pacman, 305
je continua_sus
cmp x_pacman, 335
je continua_sus
cmp x_pacman, 375
je continua_sus
cmp x_pacman, 405
je continua_sus
cmp x_pacman, 435
je continua_sus
cmp x_pacman, 460
je continua_sus
cmp x_pacman, 555
je continua_sus
cmp x_pacman, 115
je desen
cmp x_pacman, 140
je desen
cmp x_pacman, 145
je desen
cmp x_pacman, 165
je desen
cmp x_pacman, 495
je desen
cmp x_pacman, 520
je desen
cmp x_pacman, 525
je desen
cmp x_pacman, 535
je desen
cmp x_pacman, 530
je desen
cmp x_pacman, 540
je desen
cmp x_pacman, 545
je desen

comparare_sus_330:
cmp x_pacman, 85
je continua_sus
cmp x_pacman, 145
je continua_sus
cmp x_pacman, 175
je continua_sus
cmp x_pacman, 205
je continua_sus
cmp x_pacman, 235
je continua_sus
cmp x_pacman, 265
je continua_sus
cmp x_pacman, 375
je continua_sus
cmp x_pacman, 405
je continua_sus
cmp x_pacman, 435
je continua_sus
cmp x_pacman, 460
je continua_sus
cmp x_pacman, 495
je continua_sus
cmp x_pacman, 555
je continua_sus
cmp x_pacman, 115
je desen
cmp x_pacman, 295
je desen
cmp x_pacman, 320
je desen
cmp x_pacman, 345
je desen
cmp x_pacman, 370
je desen
cmp x_pacman, 525
je desen


comparare_sus_360:
cmp x_pacman, 85
je continua_sus
cmp x_pacman, 115
je continua_sus
cmp x_pacman, 145
je continua_sus
cmp x_pacman, 175
je continua_sus
cmp x_pacman, 295
je continua_sus
cmp x_pacman, 345
je continua_sus
cmp x_pacman, 460
je continua_sus
cmp x_pacman, 495
je continua_sus
cmp x_pacman, 525
je continua_sus
cmp x_pacman, 555
je continua_sus
cmp x_pacman, 205
je desen
cmp x_pacman, 230
je desen
cmp x_pacman, 255
je desen
cmp x_pacman, 375
je desen
cmp x_pacman, 400
je desen
cmp x_pacman, 425
je desen
cmp x_pacman, 450
je desen
cmp x_pacman, 430
je desen
cmp x_pacman, 435
je desen
cmp x_pacman, 440
je desen
cmp x_pacman, 445
je desen
cmp x_pacman, 455
je desen
cmp x_pacman, 460
je desen


comparare_sus_390:
cmp x_pacman, 85
je continua_sus
cmp x_pacman, 115
je continua_sus
cmp x_pacman, 205
je continua_sus
cmp x_pacman, 295
je continua_sus
cmp x_pacman, 345
je continua_sus
cmp x_pacman, 435
je continua_sus
cmp x_pacman, 525
je continua_sus
cmp x_pacman, 555
je continua_sus
cmp x_pacman, 145
je desen
cmp x_pacman, 170
je desen
cmp x_pacman, 195
je desen
cmp x_pacman, 235
je desen
cmp x_pacman, 265
je desen
cmp x_pacman, 320
je desen
cmp x_pacman, 325
je desen
cmp x_pacman, 330
je desen
cmp x_pacman, 335
je desen
cmp x_pacman, 375
je desen
cmp x_pacman, 405
je desen
cmp x_pacman, 465
je desen
cmp x_pacman, 495
je desen



comparare_x_390:
je desen

comparare_x_360:
cmp x_pacman, 85
je continua_jos
cmp x_pacman, 115
je continua_jos
cmp x_pacman, 295
je continua_jos
cmp x_pacman, 205
je continua_jos
cmp x_pacman, 345
je continua_jos
cmp x_pacman, 435
je continua_jos
cmp x_pacman, 525
je continua_jos
cmp x_pacman, 555
je continua_jos
cmp x_pacman, 145
je desen
cmp x_pacman, 175
je desen
cmp x_pacman, 185
je desen
cmp x_pacman, 195
je desen

cmp x_pacman, 235
je desen
cmp x_pacman, 265
je desen
cmp x_pacman, 375
je desen
cmp x_pacman, 405
je desen
cmp x_pacman, 400
je desen
cmp x_pacman, 460
je desen
cmp x_pacman, 495
je desen




comparare_x_330:
cmp x_pacman, 85
je continua_jos
cmp x_pacman, 145
je continua_jos
cmp x_pacman, 175
je continua_jos
cmp x_pacman, 85
je continua_jos
cmp x_pacman, 115
je continua_jos
cmp x_pacman, 295
je continua_jos
cmp x_pacman, 345
je continua_jos
cmp x_pacman, 460
je continua_jos
cmp x_pacman, 525
je continua_jos
cmp x_pacman, 495
je continua_jos
cmp x_pacman, 555
je continua_jos
cmp x_pacman, 205
je desen
cmp x_pacman, 235
je desen
cmp x_pacman, 265
je desen
cmp x_pacman, 375
je desen
cmp x_pacman, 405
je desen
cmp x_pacman, 435
je desen
cmp x_pacman, 325
je desen
cmp x_pacman, 330
je desen


comparare_x_300:
cmp x_pacman, 85
je continua_jos
cmp x_pacman, 145
je continua_jos
cmp x_pacman, 175
je continua_jos
cmp x_pacman, 205
je continua_jos
cmp x_pacman, 235
je continua_jos
cmp x_pacman, 265
je continua_jos
cmp x_pacman, 375
je continua_jos
cmp x_pacman, 405
je continua_jos
cmp x_pacman, 435
je continua_jos
cmp x_pacman, 460
je continua_jos
cmp x_pacman, 495
je continua_jos
cmp x_pacman, 555
je continua_jos
cmp x_pacman, 115
je desen
cmp x_pacman, 305
je desen
cmp x_pacman, 335
je desen
cmp x_pacman, 525
je desen



comparare_x_270:
cmp x_pacman, 85
je continua_jos
cmp x_pacman, 175
je continua_jos
cmp x_pacman, 205
je continua_jos
cmp x_pacman, 235
je continua_jos
cmp x_pacman, 265
je continua_jos
cmp x_pacman, 305
je continua_jos
cmp x_pacman, 335
je continua_jos
cmp x_pacman, 375
je continua_jos
cmp x_pacman, 405
je continua_jos
cmp x_pacman, 435
je continua_jos
cmp x_pacman, 460
je continua_jos
cmp x_pacman, 555
je continua_jos
cmp x_pacman, 115
je desen
cmp x_pacman, 145
je desen
cmp x_pacman, 495
je desen
cmp x_pacman, 525
je desen
cmp x_pacman, 395
je desen
cmp x_pacman, 245
je desen


comparare_x_240:
cmp x_pacman, 175
je continua_jos
cmp x_pacman, 245
je continua_jos
cmp x_pacman, 395
je continua_jos
cmp x_pacman, 460
je continua_jos
cmp x_pacman, 180
je desen
cmp x_pacman, 210
je desen
cmp x_pacman, 275
je desen
cmp x_pacman, 305
je desen
cmp x_pacman, 335
je desen
cmp x_pacman, 365
je desen
cmp x_pacman, 425
je desen



comparare_x_150:
cmp x_pacman, 175
je continua_jos
cmp x_pacman, 245
je continua_jos
cmp x_pacman, 395
je continua_jos

cmp x_pacman, 460
je continua_jos
cmp x_pacman, 210
je desen
cmp x_pacman, 275
je desen
cmp x_pacman, 305
je desen
cmp x_pacman, 335
je desen
cmp x_pacman, 365
je desen
cmp x_pacman, 425
je desen


comparare_x_120:
cmp x_pacman, 175
je continua_jos
cmp x_pacman, 305
je continua_jos
cmp x_pacman, 335
je continua_jos
cmp x_pacman, 460
je continua_jos
cmp x_pacman, 85
je desen
cmp x_pacman, 115
je desen
cmp x_pacman, 145
je desen
cmp x_pacman, 210
je desen
cmp x_pacman, 245
je desen
cmp x_pacman, 270
je desen
cmp x_pacman, 275
je desen
cmp x_pacman, 365
je desen
cmp x_pacman, 395
je desen
cmp x_pacman, 425
je desen
cmp x_pacman, 445
je desen
cmp x_pacman, 485
je desen
cmp x_pacman, 515
je desen
cmp x_pacman, 545
je desen
cmp x_pacman, 555
je desen

comparare_x_90:
cmp x_pacman, 85
je continua_jos
cmp x_pacman, 245
je continua_jos
cmp x_pacman, 395
je continua_jos
cmp x_pacman, 555
je continua_jos
cmp x_pacman, 305
je continua_jos
cmp x_pacman, 335
je continua_jos
cmp x_pacman, 275
je desen
cmp x_pacman, 365
je desen

comparare_x_60:
cmp x_pacman, 85
je continua_jos
cmp x_pacman, 245
je continua_jos
cmp x_pacman, 395
je continua_jos
cmp x_pacman, 555
je continua_jos
cmp x_pacman, 275
je desen
cmp x_pacman, 305
je desen
cmp x_pacman, 335
je desen
cmp x_pacman, 365
je desen
cmp x_pacman, 295
je desen

comparare_x_30:
cmp x_pacman, 85
je continua_jos
cmp x_pacman, 245
je continua_jos
cmp x_pacman, 305
je continua_jos
cmp x_pacman, 335
je continua_jos
cmp x_pacman, 395
je continua_jos
cmp x_pacman, 555
je continua_jos
cmp x_pacman, 115
je desen
cmp x_pacman, 145
je desen
cmp x_pacman, 175
je desen
cmp x_pacman, 205
je desen
cmp x_pacman, 235
je desen
cmp x_pacman, 275
je desen
cmp x_pacman, 365
je desen
cmp x_pacman, 425
je desen
cmp x_pacman, 455
je desen
cmp x_pacman, 485
je desen
cmp x_pacman, 515
je desen
cmp x_pacman, 545
je desen



comparare_110:
cmp y_pacman, 30
je continua_dreapta
cmp y_pacman, 120
je continua_dreapta
cmp y_pacman, 270
je continua_dreapta
cmp y_pacman, 300
je continua_dreapta
cmp y_pacman, 330
je continua_dreapta
cmp y_pacman, 60
je desen
cmp y_pacman, 90
je desen
cmp y_pacman, 360
je desen
cmp y_pacman, 390
je desen

comparare_140:

cmp y_pacman, 120
je continua_dreapta
cmp y_pacman, 270
je continua_dreapta
cmp y_pacman, 300
je continua_dreapta
cmp y_pacman, 390
je continua_dreapta
cmp y_pacman, 330
je desen
cmp y_pacman, 360
je desen

comparare_170:
cmp y_pacman, 120
je continua_dreapta
cmp y_pacman, 270
je continua_dreapta
cmp y_pacman, 360
je continua_dreapta
cmp y_pacman, 390
je continua_dreapta
cmp y_pacman, 30
je continua_dreapta
cmp y_pacman, 330
je desen
cmp y_pacman, 300
je desen

comparare_200:
cmp y_pacman, 120
je continua_dreapta
cmp y_pacman, 30
je continua_dreapta
cmp y_pacman, 150
je continua_dreapta
cmp y_pacman, 240
je continua_dreapta
cmp y_pacman, 270
je continua_dreapta
cmp y_pacman, 300
je continua_dreapta
cmp y_pacman, 330
je continua_dreapta
cmp y_pacman, 360
je continua_dreapta
cmp y_pacman, 390
je continua_dreapta
cmp y_pacman, 180
je desen
cmp y_pacman, 210
je desen

comparare_230:
cmp y_pacman, 30
je continua_dreapta
cmp y_pacman, 120
je continua_dreapta
cmp y_pacman, 150
je continua_dreapta
cmp y_pacman, 240
je continua_dreapta
cmp y_pacman, 270
je continua_dreapta
cmp y_pacman, 360
je continua_dreapta
cmp y_pacman, 390
je continua_dreapta
cmp y_pacman, 300
je desen
cmp y_pacman, 330
je desen


comparare_240:
cmp y_pacman, 30
je continua_dreapta
cmp y_pacman, 120
je continua_dreapta
cmp y_pacman, 150
je continua_dreapta
cmp y_pacman, 240
je continua_dreapta
cmp y_pacman, 270
je continua_dreapta
cmp y_pacman, 360
je continua_dreapta
cmp y_pacman, 390
je continua_dreapta
cmp y_pacman, 180
je desen
cmp y_pacman, 210
je desen



comparare_260:
cmp y_pacman, 30
je continua_dreapta
cmp y_pacman, 60
je continua_dreapta
cmp y_pacman, 90
je continua_dreapta
cmp y_pacman, 120
je continua_dreapta
cmp y_pacman, 150
je continua_dreapta
cmp y_pacman, 240
je continua_dreapta
cmp y_pacman, 270
je continua_dreapta
cmp y_pacman, 360
je continua_dreapta
cmp y_pacman, 300
je desen
cmp y_pacman, 330
je desen
cmp y_pacman, 390
je desen

comparare_270:
cmp y_pacman, 30
je continua_dreapta
cmp y_pacman, 60
je continua_dreapta
cmp y_pacman, 90
je continua_dreapta
cmp y_pacman, 120
je continua_dreapta
cmp y_pacman, 150
je continua_dreapta
cmp y_pacman, 240
je continua_dreapta
cmp y_pacman, 270
je continua_dreapta
cmp y_pacman, 360
je continua_dreapta
cmp y_pacman, 390
je continua_dreapta
cmp y_pacman, 180
je desen
cmp y_pacman, 210
je desen

comparare_290:
cmp y_pacman, 30
je continua_dreapta
cmp y_pacman, 60
je continua_dreapta
cmp y_pacman, 90
je continua_dreapta
cmp y_pacman, 120
je continua_dreapta
cmp y_pacman, 150
je continua_dreapta
cmp y_pacman, 240
je continua_dreapta
cmp y_pacman, 270
je continua_dreapta
cmp y_pacman, 330
je continua_dreapta
cmp y_pacman, 360
je continua_dreapta
cmp y_pacman, 390
je continua_dreapta
cmp y_pacman, 300
je desen


comparare_320:
cmp y_pacman, 30
je continua_dreapta
cmp y_pacman, 60
je continua_dreapta
cmp y_pacman, 90
je continua_dreapta
cmp y_pacman, 120
je continua_dreapta
cmp y_pacman, 150
je continua_dreapta
cmp y_pacman, 240
je continua_dreapta
cmp y_pacman, 270
je continua_dreapta
cmp y_pacman, 330
je continua_dreapta
cmp y_pacman, 390
je continua_dreapta
cmp y_pacman, 360
je desen

comparare_330:
cmp y_pacman, 60
je continua_dreapta
cmp y_pacman, 150
je continua_dreapta
cmp y_pacman, 240
je continua_dreapta
cmp y_pacman, 330
je continua_dreapta
cmp y_pacman, 390
je continua_dreapta
cmp y_pacman, 30
je desen
cmp y_pacman, 90
je desen
cmp y_pacman, 120
je desen
cmp y_pacman, 270
je desen
cmp y_pacman, 300
je desen


comparare_370:
cmp y_pacman, 30
je continua_dreapta
cmp y_pacman, 60
je continua_dreapta
cmp y_pacman, 90
je continua_dreapta
cmp y_pacman, 120
je continua_dreapta
cmp y_pacman, 150
je continua_dreapta
cmp y_pacman, 240
je continua_dreapta
cmp y_pacman, 270
je continua_dreapta
cmp y_pacman, 330
je continua_dreapta
cmp y_pacman, 360
je continua_dreapta
cmp y_pacman, 390
je continua_dreapta
cmp y_pacman, 300
je desen

comparare_400:
cmp y_pacman, 30
je continua_dreapta
cmp y_pacman, 60
je continua_dreapta
cmp y_pacman, 90
je continua_dreapta
cmp y_pacman, 120
je continua_dreapta
cmp y_pacman, 150
je continua_dreapta
cmp y_pacman, 240
je continua_dreapta
cmp y_pacman, 270
je continua_dreapta
cmp y_pacman, 360
je continua_dreapta
cmp y_pacman, 300
je desen
cmp y_pacman, 330
je desen
cmp y_pacman, 390
je desen

comparare_420:
cmp y_pacman, 30
je continua_dreapta
cmp y_pacman, 120
je continua_dreapta
cmp y_pacman, 150
je continua_dreapta
cmp y_pacman, 240
je continua_dreapta
cmp y_pacman, 270
je continua_dreapta
cmp y_pacman, 360
je continua_dreapta
cmp y_pacman, 390
je continua_dreapta
cmp y_pacman, 180
je desen
cmp y_pacman, 210
je desen
cmp y_pacman, 60
je desen
cmp y_pacman, 90
je desen

comparare_430:
cmp y_pacman, 30
je continua_dreapta
cmp y_pacman, 120
je continua_dreapta
cmp y_pacman, 150
je continua_dreapta
cmp y_pacman, 240
je continua_dreapta
cmp y_pacman, 270
je continua_dreapta
cmp y_pacman, 360
je continua_dreapta
cmp y_pacman, 390
je continua_dreapta
cmp y_pacman, 300
je desen
cmp y_pacman, 330
je desen



comparare_455:
cmp y_pacman, 120
je continua_dreapta
cmp y_pacman, 30
je continua_dreapta
cmp y_pacman, 150
je continua_dreapta
cmp y_pacman, 240
je continua_dreapta
cmp y_pacman, 270
je continua_dreapta
cmp y_pacman, 300
je continua_dreapta
cmp y_pacman, 330
je continua_dreapta
cmp y_pacman, 360
je continua_dreapta
cmp y_pacman, 390
je continua_dreapta
cmp y_pacman, 180
je desen
cmp y_pacman, 210
je desen

comparare_485:
cmp y_pacman, 120
je continua_dreapta
cmp y_pacman, 30
je continua_dreapta
cmp y_pacman, 270
je continua_dreapta
cmp y_pacman, 360
je continua_dreapta
cmp y_pacman, 390
je continua_dreapta
cmp y_pacman, 180
je desen
cmp y_pacman, 210
je desen
cmp y_pacman, 240
je desen
cmp y_pacman, 150
je desen
cmp y_pacman, 300
je desen
cmp y_pacman, 330
je desen



comparare_520:
cmp y_pacman, 120
je continua_dreapta
cmp y_pacman, 30
je continua_dreapta
cmp y_pacman, 270
je continua_dreapta
cmp y_pacman, 390
je continua_dreapta
cmp y_pacman, 300
je continua_dreapta
cmp y_pacman, 360
je desen
cmp y_pacman, 330
je desen



comparare_550:
cmp y_pacman, 120
je continua_dreapta
cmp y_pacman, 30
je continua_dreapta
cmp y_pacman, 270
je continua_dreapta
cmp y_pacman, 300
je continua_dreapta
cmp y_pacman, 330
je continua_dreapta
cmp y_pacman, 360
je desen
cmp y_pacman, 390
je desen




comparare_y_85:
jmp desen

comparare_y_110:
cmp y_pacman, 330
je continua
cmp y_pacman, 300
je continua
cmp y_pacman, 270
je continua
cmp y_pacman, 120
je continua
cmp y_pacman, 30
je continua
cmp y_pacman, 390
je desen
cmp y_pacman, 360
je desen

comparare_y_140:
cmp y_pacman, 300
je continua
cmp y_pacman, 270
je continua
cmp y_pacman, 30
je continua
cmp y_pacman, 120
je continua
cmp y_pacman, 330
je desen
cmp y_pacman, 360
je desen


comparare_y_175:
cmp y_pacman, 120
je continua
cmp y_pacman, 270
je continua
cmp y_pacman, 360
je continua
cmp y_pacman, 390
je continua
cmp y_pacman, 30
je continua
cmp y_pacman, 240
je desen
cmp y_pacman, 300
je desen
cmp y_pacman, 330
je desen
cmp y_pacman, 150
je desen

comparare_y_208:
cmp y_pacman, 240
je continua
cmp y_pacman, 150
je continua
cmp y_pacman, 30
je continua
cmp y_pacman, 120
je continua
cmp y_pacman, 270
je continua
cmp y_pacman, 300
je continua
cmp y_pacman, 330
je continua
cmp y_pacman, 360
je continua
cmp y_pacman, 390
je continua
cmp y_pacman, 180
je desen
cmp y_pacman, 185
je desen
cmp y_pacman, 190
je desen
cmp y_pacman, 195
je desen

comparare_y_235:
cmp y_pacman, 270
je continua
cmp y_pacman, 240
je continua
cmp y_pacman, 360
je continua
cmp y_pacman, 150
je continua
cmp y_pacman, 190
je continua
cmp y_pacman, 30
je continua
cmp y_pacman, 390
je continua
cmp y_pacman, 120
je continua
cmp y_pacman, 330
je desen


comparare_y_245:
cmp y_pacman, 30
je continua
cmp y_pacman, 120
je continua
cmp y_pacman, 150
je continua
cmp y_pacman, 240
je continua
cmp y_pacman, 270
je continua
cmp y_pacman, 360
je continua
cmp y_pacman, 390
je continua
cmp y_pacman, 60
je desen
cmp y_pacman, 90
je desen
cmp y_pacman, 190
je desen

comparare_y_265:
cmp y_pacman, 30
je continua
cmp y_pacman, 60
je continua
cmp y_pacman, 90
je continua
cmp y_pacman, 120
je continua
cmp y_pacman, 150
je continua
cmp y_pacman, 240
je continua
cmp y_pacman, 270
je continua
cmp y_pacman, 360
je continua
cmp y_pacman, 330
je desen
cmp y_pacman, 390
je desen


comparare_y_295:
cmp y_pacman, 30
je continua
cmp y_pacman, 60
je continua
cmp y_pacman, 90
je continua
cmp y_pacman, 120
je continua
cmp y_pacman, 150
je continua
cmp y_pacman, 240
je continua
cmp y_pacman, 270
je continua
cmp y_pacman, 330
je continua
cmp y_pacman, 360
je continua
cmp y_pacman, 390
je continua

comparare_y_335:
cmp y_pacman, 60
je continua
cmp y_pacman, 150
je continua
cmp y_pacman, 240
je continua
cmp y_pacman, 330
je continua
cmp y_pacman, 390
je continua
cmp y_pacman, 30
je desen
cmp y_pacman, 90
je desen
cmp y_pacman, 120
je desen
cmp y_pacman, 270
je desen
cmp y_pacman, 300
je desen
comparare_y_345:
cmp y_pacman, 360
je desen

comparare_y_375:
cmp y_pacman, 30
je continua
cmp y_pacman, 60
je continua
cmp y_pacman, 90
je continua
cmp y_pacman, 120
je continua
cmp y_pacman, 150
je continua
cmp y_pacman, 240
je continua
cmp y_pacman, 270
je continua
cmp y_pacman, 330
je continua
cmp y_pacman, 360
je continua
cmp y_pacman, 390
je continua
cmp y_pacman, 300
je desen



comparare_y_395:
cmp y_pacman, 30
je continua
cmp y_pacman, 90
je continua
cmp y_pacman, 60
je continua
cmp y_pacman, 120
je continua
cmp y_pacman, 150
je continua
cmp y_pacman, 240
je continua
cmp y_pacman, 270
je continua
cmp y_pacman, 360
je continua
cmp y_pacman, 390
je continua
cmp y_pacman, 190
je desen

comparare_y_405:
cmp y_pacman, 30
je continua
cmp y_pacman, 60
je continua
cmp y_pacman, 90
je continua
cmp y_pacman, 120
je continua
cmp y_pacman, 150
je continua
cmp y_pacman, 240
je continua
cmp y_pacman, 270
je continua
cmp y_pacman, 360
je continua
cmp y_pacman, 390
je desen
cmp y_pacman, 300
je desen

comparare_y_425:
cmp y_pacman, 30
je continua
cmp y_pacman, 120
je continua
cmp y_pacman, 150
je continua
cmp y_pacman, 240
je continua
cmp y_pacman, 270
je continua
cmp y_pacman, 360
je continua
cmp y_pacman, 390
je continua
cmp y_pacman,190
je desen

comparare_y_435:
cmp y_pacman, 270
je continua
cmp y_pacman, 240
je continua
cmp y_pacman, 360
je continua
cmp y_pacman, 150
je continua
cmp y_pacman, 190
je continua
cmp y_pacman, 30
je continua
cmp y_pacman, 390
je continua
cmp y_pacman, 120
je continua
cmp y_pacman, 330
je desen
cmp y_pacman, 300
je desen

comparare_y_455:
cmp y_pacman, 240
je continua
cmp y_pacman, 150
je continua
cmp y_pacman, 30
je continua
cmp y_pacman, 120
je continua
cmp y_pacman, 270
je continua
cmp y_pacman, 300
je continua
cmp y_pacman, 330
je continua
cmp y_pacman, 360
je continua
cmp y_pacman, 390
je continua
cmp y_pacman, 180
je desen
cmp y_pacman, 185
je desen
cmp y_pacman, 190
je desen
cmp y_pacman, 195
je desen

comparare_y_490:
cmp y_pacman, 120
je continua
cmp y_pacman, 270
je continua
cmp y_pacman, 360
je continua
cmp y_pacman, 390
je continua
cmp y_pacman, 30
je continua
cmp y_pacman, 240
je desen
cmp y_pacman, 300
je desen
cmp y_pacman, 330
je desen
cmp y_pacman, 150
je desen

comparare_y_525:
cmp y_pacman, 300
je continua
cmp y_pacman, 270
je continua
cmp y_pacman, 30
je continua
cmp y_pacman, 120
je continua
cmp y_pacman, 390
je continua
cmp y_pacman, 330
je desen
cmp y_pacman, 360
je desen

comparare_y_555:
cmp y_pacman, 330
je continua
cmp y_pacman, 300
je continua
cmp y_pacman, 270
je continua
cmp y_pacman, 120
je continua
cmp y_pacman, 30
je continua
cmp y_pacman, 390
je desen
cmp y_pacman, 360
je desen



desen:
make_pac_macro 0, area,x_pacman, y_pacman
	
line_vertical  80 , 30, 120, 0FFh
line_vertical  80 , 270, 150, 0FFh
line_horizontal 80, 30, 500, 0FFh
line_vertical  580 , 30, 120, 0FFh	
line_vertical  580 , 270, 150, 0FFh
line_horizontal 80, 420, 500, 0FFh

line_horizontal 80, 270, 95, 0FFh
line_horizontal 270, 270, 120, 0FFh
line_horizontal 485, 270, 95, 0FFh

line_horizontal 80, 150, 95, 0FFh
line_horizontal 270, 90, 120, 0FFh
line_horizontal 485, 150, 95, 0FFh

line_vertical  175 , 150, 120, 0FFh
line_vertical  485 , 150, 120, 0FFh
line_horizontal 270, 240, 120, 0FFh
line_horizontal 270, 180, 120, 0FFh

line_vertical 270 , 180, 60, 0FFh
line_vertical 390 , 180, 60, 0FFh
line_vertical 330 , 270, 60, 0FFh
line_vertical 330 , 90, 60, 0FFh
line_vertical 330 , 30, 30, 0FFh
	
line_horizontal 110, 60, 130, 0FFh
line_horizontal 110, 120, 130, 0FFh
line_vertical 110 , 60, 60, 0FFh
line_vertical 240 , 60, 60, 0FFh

line_horizontal 420, 60, 130, 0FFh
line_horizontal 420, 120, 130, 0FFh
line_vertical 420 , 60, 60, 0FFh
line_vertical 550 , 60, 60, 0FFh
line_horizontal 420, 180, 35, 0FFh
line_vertical 420 , 180, 60, 0FFh
line_vertical 455 , 180, 60, 0FFh
line_horizontal 420, 270, 35, 0FFh
line_horizontal 360, 150, 95, 0FFh
line_horizontal 205, 150, 95, 0FFh
line_horizontal 205, 180, 35, 0FFh
line_vertical 205 , 180, 60, 0FFh
line_vertical 240 , 180, 60, 0FFh
line_horizontal 205, 270, 35, 0FFh
line_horizontal 270, 60, 30, 0FFh
line_horizontal 360, 60, 30, 0FFh
line_horizontal 270, 120, 30, 0FFh
line_horizontal 360, 120, 30, 0FFh

line_horizontal 110, 300, 60, 0FFh
line_vertical 170 , 300, 60, 0FFh
line_horizontal 110, 330, 30, 0FFh
line_vertical 140 , 330, 60, 0FFh
line_vertical 110 , 360, 60, 0FFh
line_horizontal 140, 390, 60, 0FFh
line_horizontal 200, 360, 90, 0FFh
line_vertical 230 , 300, 60, 0FFh
line_vertical 260 , 300, 60, 0FFh
line_horizontal 230, 390, 60, 0FFh
line_vertical 260 , 390, 30, 0FFh
line_horizontal 490, 300, 60, 0FFh
line_vertical 490 , 300, 60, 0FFh
line_horizontal 520, 330, 30, 0FFh
line_vertical 520 , 330, 60, 0FFh
line_horizontal 460, 390, 60, 0FFh
line_horizontal 370, 390, 60, 0FFh
line_vertical 400 , 390, 30, 0FFh
line_horizontal 370, 360, 90, 0FFh
line_vertical 400 , 300, 60, 0FFh
line_vertical 430 , 300, 60, 0FFh
line_horizontal 320, 390, 20, 0FFh
line_horizontal 320, 360, 20, 0FFh
line_vertical 320 , 360, 30, 0FFh
line_vertical 340 , 360, 30, 0FFh
line_horizontal 290, 300, 10, 0FFh
line_horizontal 290, 330, 40, 0FFh
line_vertical 290 , 300, 30, 0FFh
line_horizontal 330, 330, 40, 0FFh
line_vertical 370 , 300, 30, 0FFh
line_horizontal 360, 300, 10, 0FFh
line_vertical 550 , 360, 60, 0FFh
; make_coin_macro 0, area, 110, 275
final:
popa 
mov esp, ebp
pop ebp
ret
miscare endp





draw proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1]
	cmp eax, 1
	jz evt_click
	cmp eax, 2
	jz evt_timer
	cmp eax, 3
	je event_butoane
	; nu s-a efectuat click pe nimic
	;mai jos e codul care intializeaza area cu pixeli albi
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	push 0
	push area
	call memset
	add esp, 12
	
	jmp afisare_litere
	
evt_click:


	



	jmp afisare_litere
	

	
evt_timer:

	inc counter
	call miscare
	
	jmp afisare_litere

	
event_butoane:
mov edx, [ebp+arg2]; se apasa tasta
cmp edx, 'W'
je miscare_sus
cmp edx, 'D'
je miscare_dreapta
cmp edx, 'A'
je miscare_stanga
cmp edx, 'S'
je miscare_jos

miscare_sus:
mov move,1
jmp afisare_litere


miscare_stanga:
mov move,2
jmp afisare_litere

miscare_dreapta:
mov move,3
jmp afisare_litere

miscare_jos:
mov move,4
jmp afisare_litere
	
	
afisare_litere:
	;afisam valoarea counter-ului curent (sute, zeci si unitati)
	mov ebx, 10
	mov eax, counter
	;cifra unitatilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 30, 10
	;cifra zecilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 20, 10
	;cifra sutelor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 10, 10
	


	;mapaaaaaaaaaaaaaa

	
; line_vertical  80 , 30, 120, 0FFh
; line_vertical  80 , 270, 150, 0FFh
; line_horizontal 80, 30, 500, 0FFh
; line_vertical  580 , 30, 120, 0FFh	
; line_vertical  580 , 270, 150, 0FFh
; line_horizontal 80, 420, 500, 0FFh

; line_horizontal 80, 270, 95, 0FFh
; line_horizontal 270, 270, 120, 0FFh
; line_horizontal 485, 270, 95, 0FFh
; make_coin_macro 0, area, 290, 275
; line_horizontal 80, 150, 95, 0FFh
; line_horizontal 270, 90, 120, 0FFh
; line_horizontal 485, 150, 95, 0FFh
; make_coin_macro 0, area, 110, 275
; line_vertical  175 , 150, 120, 0FFh
; line_vertical  485 , 150, 120, 0FFh
; line_horizontal 270, 240, 120, 0FFh
; line_horizontal 270, 180, 120, 0FFh

; line_vertical 270 , 180, 60, 0FFh
; line_vertical 390 , 180, 60, 0FFh
; line_vertical 330 , 270, 60, 0FFh
; line_vertical 330 , 90, 60, 0FFh
; line_vertical 330 , 30, 30, 0FFh
	
; line_horizontal 110, 60, 130, 0FFh
; line_horizontal 110, 120, 130, 0FFh
; line_vertical 110 , 60, 60, 0FFh
; line_vertical 240 , 60, 60, 0FFh

; line_horizontal 420, 60, 130, 0FFh
; line_horizontal 420, 120, 130, 0FFh
; line_vertical 420 , 60, 60, 0FFh
; line_vertical 550 , 60, 60, 0FFh
; line_horizontal 420, 180, 35, 0FFh
; line_vertical 420 , 180, 60, 0FFh
; line_vertical 455 , 180, 60, 0FFh
; line_horizontal 420, 270, 35, 0FFh
; line_horizontal 360, 150, 95, 0FFh
; line_horizontal 205, 150, 95, 0FFh
; line_horizontal 205, 180, 35, 0FFh
; line_vertical 205 , 180, 60, 0FFh
; line_vertical 240 , 180, 60, 0FFh
; line_horizontal 205, 270, 35, 0FFh
; line_horizontal 270, 60, 30, 0FFh
; line_horizontal 360, 60, 30, 0FFh
; line_horizontal 270, 120, 30, 0FFh
; line_horizontal 360, 120, 30, 0FFh

; line_horizontal 110, 300, 60, 0FFh
; line_vertical 170 , 300, 60, 0FFh
; line_horizontal 110, 330, 30, 0FFh
; line_vertical 140 , 330, 60, 0FFh
; line_vertical 110 , 360, 60, 0FFh
; line_horizontal 140, 390, 60, 0FFh
; line_horizontal 200, 360, 90, 0FFh
; line_vertical 230 , 300, 60, 0FFh
; line_vertical 260 , 300, 60, 0FFh
; line_horizontal 230, 390, 60, 0FFh
; line_vertical 260 , 390, 30, 0FFh
; line_horizontal 490, 300, 60, 0FFh
; line_vertical 490 , 300, 60, 0FFh
; line_horizontal 520, 330, 30, 0FFh
; line_vertical 520 , 330, 60, 0FFh
; line_horizontal 460, 390, 60, 0FFh
; line_horizontal 370, 390, 60, 0FFh
; line_vertical 400 , 390, 30, 0FFh
; line_horizontal 370, 360, 90, 0FFh
; line_vertical 400 , 300, 60, 0FFh
; line_vertical 430 , 300, 60, 0FFh
; line_horizontal 320, 390, 20, 0FFh
; line_horizontal 320, 360, 20, 0FFh
; line_vertical 320 , 360, 30, 0FFh
; line_vertical 340 , 360, 30, 0FFh
; line_horizontal 290, 300, 10, 0FFh
; line_horizontal 290, 330, 40, 0FFh
; line_vertical 290 , 300, 30, 0FFh
; line_horizontal 330, 330, 40, 0FFh
; line_vertical 370 , 300, 30, 0FFh
; line_horizontal 360, 300, 10, 0FFh
; line_vertical 550 , 360, 60, 0FFh


;mapaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa

; make_coin_macro 0, area, 90, 125
; make_coin_macro 0, area, 110, 125
; make_coin_macro 0, area, 130, 125
; make_coin_macro 0, area, 150, 125
; make_coin_macro 0, area, 170, 125
; make_coin_macro 0, area, 190, 125
; make_coin_macro 0, area, 210, 125
; make_coin_macro 0, area, 230, 125
; make_coin_macro 0, area, 250, 125
; make_coin_macro 0, area, 270, 125
; make_coin_macro 0, area, 290, 125
; make_coin_macro 0, area, 310, 125
; make_coin_macro 0, area, 340, 125
; make_coin_macro 0, area, 310, 125
; make_coin_macro 0, area, 340, 125
; make_coin_macro 0, area, 360, 125
; make_coin_macro 0, area, 380, 125
; make_coin_macro 0, area, 400, 125
; make_coin_macro 0, area, 420, 125
; make_coin_macro 0, area, 440, 125
; make_coin_macro 0, area, 460, 125
; make_coin_macro 0, area, 400, 125
; make_coin_macro 0, area, 420, 125
; make_coin_macro 0, area, 440, 125
; make_coin_macro 0, area, 460, 125
; make_coin_macro 0, area, 480, 125
; make_coin_macro 0, area, 500, 125
; make_coin_macro 0, area, 520, 125
; make_coin_macro 0, area, 540, 125
; make_coin_macro 0, area, 560, 125
; make_coin_macro 0, area, 560, 100
; make_coin_macro 0, area, 560, 80
; make_coin_macro 0, area, 560, 60
; make_coin_macro 0, area, 560, 35
; make_coin_macro 0, area, 540, 35
; make_coin_macro 0, area, 520, 35
; make_coin_macro 0, area, 500, 35
; make_coin_macro 0, area, 480, 35
; make_coin_macro 0, area, 460, 35
; make_coin_macro 0, area, 440, 35
; make_coin_macro 0, area, 420, 35
; make_coin_macro 0, area, 400, 35

; make_coin_macro 0, area, 380, 35
; make_coin_macro 0, area, 360, 35
; make_coin_macro 0, area, 340, 35
; make_coin_macro 0, area, 310, 35
; make_coin_macro 0, area, 290, 35
; make_coin_macro 0, area, 270, 35
; make_coin_macro 0, area, 250, 35
; make_coin_macro 0, area, 230, 35
; make_coin_macro 0, area, 210, 35
; make_coin_macro 0, area, 190, 35
; make_coin_macro 0, area, 170, 35
; make_coin_macro 0, area, 150, 35
; make_coin_macro 0, area, 130, 35
; make_coin_macro 0, area, 110, 35
; make_coin_macro 0, area, 90, 35

; make_coin_macro 0, area, 90, 125
; make_coin_macro 0, area, 90, 100
; make_coin_macro 0, area, 90, 80
; make_coin_macro 0, area, 90, 60


; make_coin_macro 0, area, 250, 95

; make_coin_macro 0, area, 250, 65
; make_coin_macro 0, area, 270, 95
; make_coin_macro 0, area, 290, 95
; make_coin_macro 0, area, 310, 95

; make_coin_macro 0, area, 270, 65
; make_coin_macro 0, area, 290, 65
; make_coin_macro 0, area, 310, 65
; make_coin_macro 0, area, 340, 65
; make_coin_macro 0, area, 360, 65
; make_coin_macro 0, area, 380, 65
; make_coin_macro 0, area, 400, 65
; make_coin_macro 0, area, 340, 95
; make_coin_macro 0, area, 360, 95
; make_coin_macro 0, area, 380, 95
; make_coin_macro 0, area, 400, 95
; make_coin_macro 0, area, 405, 155
; make_coin_macro 0, area, 425, 155
; make_coin_macro 0, area, 445, 155
; make_coin_macro 0, area, 465, 155
; make_coin_macro 0, area, 385, 155
; make_coin_macro 0, area, 365, 155
; make_coin_macro 0, area, 345, 155
; make_coin_macro 0, area, 325, 155
; make_coin_macro 0, area, 305, 155
; make_coin_macro 0, area, 285, 155
; make_coin_macro 0, area, 265, 155
; make_coin_macro 0, area, 245, 155
; make_coin_macro 0, area, 225, 155
; make_coin_macro 0, area, 205, 155
; make_coin_macro 0, area, 185, 155
; make_coin_macro 0, area, 185, 180
; make_coin_macro 0, area, 185, 200
; make_coin_macro 0, area, 185, 220
; make_coin_macro 0, area, 185, 245
; make_coin_macro 0, area, 405, 245
; make_coin_macro 0, area, 425, 245
; make_coin_macro 0, area, 445, 245
; make_coin_macro 0, area, 465, 245
; make_coin_macro 0, area, 385, 245
; make_coin_macro 0, area, 365, 245
; make_coin_macro 0, area, 345, 245


; make_coin_macro 0, area, 305, 245
; make_coin_macro 0, area, 285, 245
; make_coin_macro 0, area, 265, 245
; make_coin_macro 0, area, 245, 245
; make_coin_macro 0, area, 225, 245
; make_coin_macro 0, area, 205, 245
; make_coin_macro 0, area, 465, 220
; make_coin_macro 0, area, 465, 200
; make_coin_macro 0, area, 465, 180
; make_coin_macro 0, area, 400, 180
; make_coin_macro 0, area, 400, 200
; make_coin_macro 0, area, 400, 220
; make_coin_macro 0, area, 90, 275
; make_coin_macro 0, area, 110, 275
; make_coin_macro 0, area, 130, 275
; make_coin_macro 0, area, 150, 275
; make_coin_macro 0, area, 170, 275
; make_coin_macro 0, area, 190, 275
; make_coin_macro 0, area, 210, 275
; make_coin_macro 0, area, 230, 275
; make_coin_macro 0, area, 250, 275
; make_coin_macro 0, area, 270, 275
; make_coin_macro 0, area, 290, 275
; make_coin_macro 0, area, 310, 275
; make_coin_macro 0, area, 340, 275
; make_coin_macro 0, area, 360, 275
; make_coin_macro 0, area, 380, 275
; make_coin_macro 0, area, 400, 275
; make_coin_macro 0, area, 420, 275
; make_coin_macro 0, area, 440, 275
; make_coin_macro 0, area, 460, 275
; make_coin_macro 0, area, 480, 275
; make_coin_macro 0, area, 500, 275
; make_coin_macro 0, area, 520, 275
; make_coin_macro 0, area, 540, 275
; make_coin_macro 0, area, 560, 275
; make_coin_macro 0, area, 560, 295
; make_coin_macro 0, area, 560, 315
; make_coin_macro 0, area, 560, 335
; make_coin_macro 0, area, 560, 355
; make_coin_macro 0, area, 560, 375
; make_coin_macro 0, area, 560, 395
; make_coin_macro 0, area, 530, 335
; make_coin_macro 0, area, 530, 355
; make_coin_macro 0, area, 530, 375
; make_coin_macro 0, area, 530, 395
; make_coin_macro 0, area, 530, 305
; make_coin_macro 0, area, 500, 305
; make_coin_macro 0, area, 500, 325
; make_coin_macro 0, area, 500, 345
; make_coin_macro 0, area, 500, 365
; make_coin_macro 0, area, 480, 365
; make_coin_macro 0, area, 460, 365
; make_coin_macro 0, area, 440, 365
; make_coin_macro 0, area, 420, 365
; make_coin_macro 0, area, 400, 365
; make_coin_macro 0, area, 380, 365
; make_coin_macro 0, area, 350, 365
; make_coin_macro 0, area, 300, 365
; make_coin_macro 0, area, 270, 365
; make_coin_macro 0, area, 250, 365
; make_coin_macro 0, area, 230, 365
; make_coin_macro 0, area, 210, 365
; make_coin_macro 0, area, 190, 365
; make_coin_macro 0, area, 170, 365
; make_coin_macro 0, area, 150, 365
; make_coin_macro 0, area, 150, 345
; make_coin_macro 0, area, 150, 325
; make_coin_macro 0, area, 150, 305
; make_coin_macro 0, area, 120, 305
; make_coin_macro 0, area, 90, 295
; make_coin_macro 0, area, 90, 315
; make_coin_macro 0, area, 90, 335
; make_coin_macro 0, area, 90, 355
; make_coin_macro 0, area, 90, 375
; make_coin_macro 0, area, 90, 395
; make_coin_macro 0, area, 120, 335
; make_coin_macro 0, area, 120, 355
; make_coin_macro 0, area, 120, 375
; make_coin_macro 0, area, 120, 395
; make_coin_macro 0, area, 140, 395
; make_coin_macro 0, area, 160, 395
; make_coin_macro 0, area, 180, 395
; make_coin_macro 0, area, 200, 395
; make_coin_macro 0, area, 220, 395
; make_coin_macro 0, area, 240, 395
; make_coin_macro 0, area, 270, 395
; make_coin_macro 0, area, 300, 395
; make_coin_macro 0, area, 325, 395
; make_coin_macro 0, area, 350, 395
; make_coin_macro 0, area, 380, 395
; make_coin_macro 0, area, 410, 395
; make_coin_macro 0, area, 430, 395
; make_coin_macro 0, area, 450, 395
; make_coin_macro 0, area, 470, 395
; make_coin_macro 0, area, 490, 395
; make_coin_macro 0, area, 510, 395
; make_coin_macro 0, area, 300, 335
; make_coin_macro 0, area, 325, 335
; make_coin_macro 0, area, 270, 335
; make_coin_macro 0, area, 350, 335
; make_coin_macro 0, area, 380, 335
; make_coin_macro 0, area, 270, 305
; make_coin_macro 0, area, 340, 305
; make_coin_macro 0, area, 310, 305
; make_coin_macro 0, area, 380, 305
; make_coin_macro 0, area, 410, 305
; make_coin_macro 0, area, 440, 305
; make_coin_macro 0, area, 460, 305
; make_coin_macro 0, area, 480, 305
; make_coin_macro 0, area, 380, 305
; make_coin_macro 0, area, 410, 335
; make_coin_macro 0, area, 440, 335
; make_coin_macro 0, area, 460, 335
; make_coin_macro 0, area, 480, 335
; make_coin_macro 0, area, 210, 335
; make_coin_macro 0, area, 240, 335
; make_coin_macro 0, area, 240, 305
; make_coin_macro 0, area, 210, 305
; make_coin_macro 0, area, 190, 305
; make_coin_macro 0, area, 170, 305
; make_coin_macro 0, area, 210, 335
; make_coin_macro 0, area, 190, 335
; make_coin_macro 0, area, 170, 335
; make_coin_macro 0, area, 215, 180
; make_coin_macro 0, area, 215, 200
; make_coin_macro 0, area, 215, 220
; make_coin_macro 0, area, 250, 180
; make_coin_macro 0, area, 250, 200
; make_coin_macro 0, area, 250, 220
; make_coin_macro 0, area, 435, 180
; make_coin_macro 0, area, 435, 200
; make_coin_macro 0, area, 435, 220

;make_pac_macro 0, area,320, 240
final_draw:
	popa
	mov esp, ebp
	pop ebp
	ret
draw endp

start:
	;alocam memorie pentru zona de desenat
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	call malloc
	add esp, 4
	mov area, eax
	;apelam functia de desenare a ferestrei
	; typedef void (*DrawFunc)(int evt, int x, int y);
	; void __cdecl BeginDrawing(const char *title, int width, int height, unsigned int *area, DrawFunc draw);
	push offset draw
	push area
	push area_height
	push area_width
	push offset window_title

	call BeginDrawing
	add esp, 20
	
	;terminarea programului
	push 0
	call exit
end start
