TITLE Combinations Calculator (Program 6b.asm)

; Author: James Le
; OSU Email : lej@oregonstate.edu
; Class Number & Section:  CS 271 - 400
; Course / Project ID : Program # 6b
; Due Date : 12 / 06 / 2015


;Objectives:
; 1. Designing, implementing, and callign low-level I/O procedures
; 2. Implementing recursion
;	a. parameter passing on the system stack
;	b. maintaining activation records (stack frames)


; Problem Definition:
; A system is required for statistics students to use for drill and practice in combinatorics.
; In particular, the system will ask the student to calculate the number of combinations of r items
; taken from a set of n items(i.e.nCr).The system generates random problems with n in[3..12]
; and r in[1..n].The student enters his / her answer, and the system reports the correct answer.
; The system repeats until the student chooses to quit.


INCLUDE Irvine32.inc

RMIN = 1
MAXINPUT = 10
NMIN = 3
NMAX = 12

; Macro for typing out string display
displayString MACRO displayInfo
push	edx 
mov		edx, offset displayInfo 
call	writestring
pop		edx

ENDM

.data


displayIntro1         BYTE      "Combinatios Calculator        Programmed by James Le ", 0

giveInfo1			  BYTE      "I'll give you a combinations problem. You enter your answer, ", 0
giveInfo2             BYTE      "and I'll let you know if you're right.", 0


problem1			  BYTE      "Problem #: ", 0
problem2              BYTE      "Number of elements in the set: ", 0
problem3              BYTE      "Number of elements to choose from the set: ", 0

askforInfo1           BYTE       "How many ways can you choose? ", 0
askforInfo2           BYTE       "ERROR: Please enter intgers only.", 0


display1              BYTE       "There are ", 0
display2              BYTE        " combinations of ", 0
display3              BYTE        " items from a set of ", 0
display4              BYTE        ".", 0
display5              BYTE        "Your answer was: ", 0
display6              BYTE        "Number of correct answers: ", 0
display7              BYTE        "Number of incorrect answers: ", 0

displayIncorrect      BYTE        "You are incorrect. You need more practice!", 0
displayCorrect        BYTE        "You are correct!", 0

goodBye               BYTE         "Thakns for playing! Goodbye.", 0


newGame               BYTE        "Another problem? (y/n): ", 0
askforInfo3           BYTE        "ERROR: Invalid response. Please try again.", 0

probNum               DWORD 1
numCorrect            DWORD 0
numIncorrect          DWORD 0
r                     DWORD ?
n                     DWORD ?

userInput             BYTE   10 DUP(0)
userAnswer            DWORD ?
result                DWORD ?


.code
main PROC

call RANDOMIZE; Randomize Procedure from Irivine libaray that seeds the random generator

; introduction

call  introduction


nextGame:

push offset probNum
push offset r
push offset n
call displayProblem


; gather data
push offset userAnswer
push offset userInput
call getData


; calculations
push r
push n
push offset result
call combinations


; display results
push offset numCorrect
push offset numIncorrect
push r
push n
push result
push userAnswer
call displayResult

jmp  difGame; jump in order to avoid the invalid message 


invalidInput:
displayString  askforInfo3


; ask user if they want to play again
difGame: 

inc probNum
call crlf

displayString  newGame

mov ecx, sizeof userInput
mov edx, offset userInput

call readstring
cmp  eax, 1
jg invalidInput
mov   ecx, eax
mov  esi, offset userInput

cld
call  crlf



; validate user choice
lodsb
cmp	 al, 78    
je	 quit
cmp	 al, 110  
je   quit 

cmp  al, 89
je   nextGame
cmp  al, 121
je	 nextGame

jmp  invalidInput


quit:
displayString  display6
mov  eax, numCorrect
call writedec
call crlf

displayString display7
mov eax, numIncorrect
call writedec
call crlf

displayString goodBye
call crlf

exit
main ENDP

; ------------------------------------------------------------------------------------------------------------------
; Procedure to introduce the program
; receives: giveInfo1, giveInfo2, askforInfo1, askforInfo2
; returns: none
; preconditions: none
; registers changed : edx


introduction PROC

; display title

displayString displayIntro1
call crlf


displayString giveInfo1
call crlf

displayString giveInfo2

call crlf
call crlf


ret

introduction ENDP



; ----------------------------------------------------------------------------------------------------------------------
; Procedure to generate random numbers and display the problem
; receives: address of n and r
; returns: r and n with random number generation
; preconditions: constant ranges of n and r
; registers changed : ecx; ebx, eax


displayProblem PROC

push ebp
mov ebp, esp

mov edx, [ebp + 16]
mov ecx, [ebp + 12]
mov ebx, [ebp + 8]


; generate number for n

mov   eax, NMAX
sub   eax, NMIN
inc   eax

call    randomRange
add	   	eax, NMIN
mov[ebx], eax


; generate number for r
mov		eax, [ebx]
sub		eax, RMIN
inc		eax
call	 randomRange
add		 eax, RMIN
mov[ecx], eax


; display the problem to user
displayString problem1
mov		eax, [edx]
call	writedec
call	crlf



displayString problem2
mov		eax, [ebx]
call	writedec
call	crlf

displayString problem3
mov		eax, [ecx]
call	writedec
call	crlf


pop ebp
ret 12

displayProblem ENDP



; --------------------------------------------------------------------------------------------
; Procedure to prompt user to get answer and validate it
; receives: address of answer and user input
; returns: none
; preconditions: none
; registers changed: eax, ebx, ecx, edx, esi


getData PROC
push	ebp
mov		ebp, esp
jmp		getuserData


notValid:
displayString  askforInfo2 
call crlf 

getuserData:

displayString askforInfo1 
mov		 edx, [ebp+8]
mov		ecx, MAXINPUT 
call	 readstring


mov ecx, eax
mov esi, [ebp+8]
cld 


mov  edx, 0

checkLoop:
lodsb
cmp		al, 57
ja		notValid
cmp		 al, 48
jb		notValid

movzx	eax, al


push ecx


mov		ecx, eax
mov		ebx, 10
mov		eax, edx
mul		ebx
mov	    edx, eax


sub		ecx, 48
add		edx, ecx

pop  ecx

loop checkLoop

mov		ebx, [ebp + 12]
mov[ebx], edx


pop ebp
ret 8

getData ENDP

; ----------------------------------------------------------------------------------------------------------------
; Procedure to perform the calculations
; receives: n and r
; preconditions: n, r holding some values
; registers changed: eax, ebx, ecx, edx 


combinations PROC

push ebp
mov  ebp, esp

mov ebx, [ebp + 16]
mov eax, [ebp + 12]

cmp  eax, ebx

je equalNums

; calculate the value for r!
mov		ebx, [ebp + 16]
push	ebx
call  factorial

mov		ecx, eax


; calcualte(n - r)!
mov  eax, [ebp + 12]
sub  eax, [ebp + 16]
mov  ebx, eax

push ebx
call  factorial


; multiply the factorial for (n - r) with factorial of r
mul ecx
mov ecx, eax

; calculate the value for n!and store in eax
mov  ebx, [ebp + 12]
push ebx
call factorial


; calculate  n!/(r!(n-r)!) and store in result
mov edx, 0
div ecx 

mov	 ecx, [ebp+8]
mov	 [ecx] , eax 

jmp finished 


equalNums:
mov		ecx, [ebp+8]
mov		ebx, 1
mov		[ecx], ebx


finished:
pop ebp
ret 12

combinations ENDP

; ---------------------------------------------------------------------------------------------------- -
; Procedure to perform calculations of factorial of n!, r!, or (n - r)!
; receives: values of ebx, and eax
; returns: eax
; preconditions: ebx must hold a value
; registers changed: ebx, eax, esi 


factorial PROC
push	ebp
mov		ebp, esp

mov		eax, [ebp + 8]

cmp eax, 1
jle  finished

;recursion

dec		eax
push	 eax
call factorial

mov		esi, [ebp+8]
mul		 esi

finished:
pop ebp
ret 4

factorial ENDP


; --------------------------------------------------------------------------------------------------------------
; Procedure to display the user's answer , calculate result, and show number of correct/incorrect 
; receives:
; returns: prints strings and values to console
; preconditions: calculations performed
; registers changed: eax, ebx, ecx, edx, esi 


displayResult PROC
push ebp
mov ebp, esp


mov ebx, [ebp + 20]
mov ecx, [ebp + 16]
mov esi, [ebp + 12]
mov edx, [ebp + 8]



; display the problem
call crlf
call crlf

displayString display1
mov eax, esi
call writedec

displayString display2
mov eax, ebx
call writedec

displayString display3
mov eax, ecx
call writedec

displayString display4
call crlf


displayString display5
mov eax, edx
call writedec
call crlf



;compare user answer and result
cmp edx, esi
je correctChoice

displayString displayIncorrect 
call crlf

mov ebx, [ebp + 24]  
mov eax, [ebx] 
inc eax 

mov [ebx], eax


jmp finished 



correctChoice:
displayString displayCorrect
call crlf

mov ebx, [ebp+28]
mov eax, [ebx]
inc eax
mov  [ebx] , eax


finished:
pop ebp
ret 24

displayResult ENDP

END main
