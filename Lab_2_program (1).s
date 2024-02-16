;*----------------------------------------------------------------------------
;* Name:    Lab_2_program.s 
;* Purpose: This code template is for Lab 2
;* Author: Eric Praetzel and Rasoul Keshavarzi 
;*----------------------------------------------------------------------------*/
		THUMB 		; Declare THUMB instruction set 
                AREA 		My_code, CODE, READONLY 	; 
                EXPORT 		__MAIN 		; Label __MAIN is used externally q
		ENTRY 
__MAIN
; The following lines are similar to Lab-1 but use an address, in r4, to make it easier.
; Note that one still needs to use the offsets of 0x20 and 0x40 to access the ports
;
; Turn off all LEDs 
		MOV 		R2, #0xC000
		MOV 		R3, #0xB0000000	
		MOV 		R4, #0x0
		MOVT 		R4, #0x2009
		ADD 		R4, R4, R2 		; 0x2009C000 - the base address for dealing with the ports
		STR 		R3, [r4, #0x20]		; Turn off the three LEDs on port 1
		MOV 		R3, #0x0000007C
		STR 		R3, [R4, #0x40] 	; Turn off five LEDs on port 2

ResetLUT
        LDR         R5, =InputLUT            ; assign R5 to the address at label LUT

; Start processing the characters

NextChar
        LDRB        R0, [R5]		; Read a character to convert to Morse Code. R0 stores the character from the string
        ADD         R5, #1              ; point to next value for number of delays, jump by 1 byte
		TEQ         R0, #0              ; If we hit 0 (null at end of the string) then reset to the start of lookup table
		BNE		ProcessChar	; If we have a character process it
		MOV		R0, #4		; delay 4 extra spaces (7 total) between words delay of 4 dots
		BL		DELAY
		BEQ         ResetLUT

ProcessChar	
        BL		CHAR2MORSE	; convert ASCII to Morse pattern in R1
        CLZ     R8, R1;count the number of leading 0s in R1 and store in R8
        LSL     R1, R8;shrifts the number of 0s stored in r8 so that r1 is getting rid of the leading zeros to read at bit15
        
ShiftLoop
		TEQ		R1, #0		; test R0 to see if it's 0 - set Zero flag so you can use BEQ, BNE R0 is the number of delays
        BEQ 	longDelay	;branch if the we have no more bits in the single character left
        LSLS    R1, R1, #1        ; Shift left the Morse code pattern by 1 bit and check for a condition
        BCS     LIGHT_ON             ; Branch if Carry flag is set (indicating a 'dot' in Morse code)
        BCC     LIGHT_OFF            ; Branch if Carry flag is clear (indicating a 'dash' in Morse code)
		
;done; this checks if the we are done all the pattern in one character
   ; MOV        R6, #0x8000                ;16th bit
   ; ANDS       R7, R1, R6                ;check if = 0
   ; BEQ        longDelay                ;delay between characters
  ;  B          continue                        ;if not end of char, go back check next bit in char

LIGHT_ON
        MOV     R0, #1 ;after the led is on, we need to delay it for 1 dot
        BL      LED_ON ;branch to the ledon function
        BL      DELAY ; branch and link the delay
        B      ShiftLoop

LIGHT_OFF
        MOV     R0, #1 ;you want to delay for one dot
        BL      LED_OFF
		BL      DELAY; branch and link the delay
       ; BL      done
;continue    BL      DELAY; branch and link the delay
        B       ShiftLoop

longDelay
        MOV     R0, #3
		BL		LED_OFF
        BL      DELAY
        B		NextChar

;*************************************************************************************************************************************************
;*****************  These are alternate methods to read the bits in the Morse code LUT. You can use them or not **********************************
;************************************************************************************************************************************************* 

;	This is a different way to read the bits in the Morse Code LUT than is in the lab manual.
; 	Choose whichever one you like.
; 
;	First - loop until we have a 1 bit to send  (no code provided)
;
;	This is confusing as we're shifting a 32-bit value left, but the data is ONLY in the lowest 16 bits, so test starting at bit 15 for 1 or 0
;	Then loop thru all of the data bits:
;
;		MOV		R6, #0x8000	; Init R6 with the value for the bit, 15th, which we wish to test
;		LSL		R1, R1, #1	; shift R1 left by 1, store in R1
;		ANDS		R7, R1, R6	; R7 gets R1 AND R6, Zero bit gets set telling us if the bit is 0 or 1
;		BEQ		; branch somewhere it's zero
;		BNE		; branch somewhere - it's not zero
;
;		....  lots of code
;		B 		somewhere in your code! 	; This is the end of the main program 
;
;	Alternate Method #2
; Shifting the data left - makes you walk thru it to the right.  You may find this confusing!
; Instead of shifting data - shift the masking pattern.  Consider this and you may find that
;   there is a much easier way to detect that all data has been dealt with.
;
;		LSR		R6, #1		; shift the mask 1 bit to the right
;		ANDS		R7, R1, R6	; R7 gets R1 AND R6, Zero bit gets set telling us if the bit is 0 or 1
;
;
;   Alternate Method #3
; All of the above methods do not use the shift operation properly.
; In the shift operation the bit which is being lost, or pushed off of the register,
; "falls" into the C flag - then one can BCC (Branch Carry Clear) or BCS (Branch Carry Set)
; This method works very well when coupled with an instruction which counts the number 
;  of leading zeros (CLZ) and a shift left operation to remove those leading zeros.

;*************************************************************************************************************************************************
;
;
; Subroutines
;
;			convert ASCII character to Morse pattern
;			pass ASCII character in R0, output in R1
;			index into MorseLuT must be by steps of 2 bytes
CHAR2MORSE	
        STMFD		R13!,{R14}	; push stack pointer Link Register (return address) onto the stack
		;
		;... add code here to convert the ASCII to an index (subtract 41) and lookup the Morse pattern in the Lookup Table
        ;convert from ascii to index;
        SUB R0, R0, #0x41 ; subtract r0 by 41 and put in R0 to get the ascii value into an index. what this means is that in ascii values, letter a to z have values in decimal 65 to 90, and 41 in decimal is 65, subtracting 65 gives out 0
        MOV            R9, #0x00000002
        MUL            R0, R0, R9 ;multiply the index by 2
        LDR  R6, = MorseLUT ;read the morse pattern from the Morse look up table
        LDRH R1, [R6, R0] ;LDRH R0, {MORSE_LUT_ADDR, INDEX*2} (this is in pseudo-code)
		LDMFD		R13!,{R15}	; restore LR to R15 the Program Counter to return ;popping the l register to pc so pc can return basically

; Turn the LED on, but deal with the stack in a simpler way
; NOTE: This method of returning from subroutine (BX  LR) does NOT work if subroutines are nested!!
;
LED_ON 	   	push 		{r3-r4}		; preserve R3 and R4 on the R13 stack
		;... insert your code here
        MOV     R3, #0xA0000000 ;	R3 gets assigned the value 0xA0000000
        STR     R3, [R4,#0x20]         ; write the value of R3 to the address of R4 with 0x20
		pop     {r3-r4}
		BX 		LR		; branch to the address in the Link Register.  Ie return to the caller

; Turn the LED off, but deal with the stack in the proper way
; the Link register gets pushed onto the stack so that subroutines can be nested
;
LED_OFF	   	STMFD		R13!,{R3, R14}	; push R3 and Link Register (return address) on stack
		;... insert your code here
        MOV     R3, #0xB0000000 ;exclusive or the value of R3 with the value 1 shrifted the left
        STR     R3, [R4,#0x20]         ; write the value of R3 to the address of R4 with 0x20
		LDMFD	R13!,{R3, R15}	; restore R3 and LR to R15 the Program Counter to return, i.e. pop and return to the LR
;	Delay 500ms * R0 times
;	Use the delay loop from Lab-1 but loop R0 times around
;
DELAY			STMFD		R13!,{R2, R14}

MultipleDelay
            TEQ		R0, #0		; test R0 to see if it's 0 - set Zero flag so you can use BEQ, BNE R0 is the number of delays
			;;... insert your code here
            MOV         R10, #0x2C2A         ; Initialize R0 lower word for countdown
            MOVT        R10, #0xA            ;Initializes ro upper word for count down
            ;3/4MHZ*number of loops = 0.5s
            
loop
            SUBS        R10, #1;decrement R1 by unit of 1 for a delay duration
            BNE         loop

            SUBS        R0, #1; Decrement r0 and set the Z status bits
            BNE         MultipleDelay; branch if the loop is no longer greater than or equals to 0
exitDelay	LDMFD		R13!,{R2, R15}
            BX          LR

;
; Data used in the program
; DCB is Define Constant Byte size
; DCW is Define Constant Word (16-bit) size
; EQU is EQUate or assign a value.  This takes no memory but instead of typing the same address in many places one can just use an EQU
;
		ALIGN				; make sure things fall on word addresses

; One way to provide a data to convert to Morse code is to use a string in memory.
; Simply read bytes of the string until the NULL or "0" is hit.  This makes it very easy to loop until done.
;
InputLUT	DCB		"HQTNE", 0	; strings must be stored, and read, as BYTES

		ALIGN				; make sure things fall on word addresses
MorseLUT 
		DCW 	0x17, 0x1D5, 0x75D, 0x75 	; A, B, C, D in hexadecimal
		DCW 	0x1, 0x15D, 0x1DD, 0x55 	; E, F, G, H
		DCW 	0x5, 0x1777, 0x1D7, 0x175 	; I, J, K, L
		DCW 	0x77, 0x1D, 0x777, 0x5DD 	; M, N, O, P
		DCW 	0x1DD7, 0x5D, 0x15, 0x7 	; Q, R, S, T
		DCW 	0x57, 0x157, 0x177, 0x757 	; U, V, W, X
		DCW 	0x1D77, 0x775 			; Y, Z

; One can also define an address using the EQUate directive
;
LED_PORT_ADR	EQU	0x2009c000	; Base address of the memory that controls I/O like LEDs

		END 
