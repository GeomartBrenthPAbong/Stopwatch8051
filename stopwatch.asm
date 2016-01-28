; Geomart Brenth Abong
; Clock Frequency: 11.0592 Mhz
; Interrupts are edge triggered
; Timer 0 is used and is in 16-bit mode
; TIMER FORMAT: M1 M2 S1 S2
; Some useful info:
;	IE0 -- used for starting or stopping the timer
;	IE1 -- used for resetting the stopwatch
;	P1  -- used for selecting the seven-segment display to be used
;	P2  -- used to display the number
;	P3  -- pins 2 and 3 are used for ie0 and ie1
;	32H -- used to store the high byte of the DISPLAY_TIME procedure
;	33H -- used to store the low byte of the DISPLAY_TIME procedure
;	R0  -- used as a counter for the timer so that the timer will continually run 
;	    -- from 4BFD - FFFF 20 times which is approximately 1s
;	R1  -- used as a holder for the value of P1
;	R3  -- used as a holder for the value of P2
;	R4  -- used as a holder for the value of S2
;	R5  -- used as a holder for the value of S1
;	R6  -- used as a holder for the value of M2
;	R7  -- used as a holder for the value of M1
;	00H -- indicator if the state of the timer has been stopped/started
;	01H -- indicator that the timer has been stopped

ORG 0000H
LJMP INIT

ORG 0003H 
SJMP START_STOP_TIMER

ORG 000BH
SJMP UPDATE_TIME

ORG 0013H
ACALL RESET
SJMP PUSH_MAIN_ADDRESS

; Updates the time
UPDATE_TIME: MOV TH0,#4BH
	     MOV TL0,#0FDH
	     MOV A,R0
	     ADD A,#01H
	     MOV R0,A
	     CJNE R0,#14H,PUSH_MAIN_ADDRESS
	     ACALL ADD_ONE_SEC
	     MOV R0,#00H
	     SJMP PUSH_MAIN_ADDRESS

; Used to start or stop the timer
START_STOP_TIMER: CPL 00H
		  JB 00H, START_TIMER
		  CLR TR0
		  SETB 01H
		  SJMP PUSH_MAIN_ADDRESS
START_TIMER:      JB 01H,STATUS_UPDATED
		  MOV TH0,#4BH
		  MOV TL0,#0FDH
STATUS_UPDATED:   CLR 01H
		  SETB TR0
		  SJMP PUSH_MAIN_ADDRESS

; Adds one to the timer
ADD_ONE_SEC: MOV A,R4
	     ADD A,#01H
	     MOV R4,A
	     CJNE A,#0AH,UPDATE_FINISHED
	     MOV R4,#00H
	     MOV A,R5
	     ADD A,#01H
	     MOV R5,A
	     CJNE A,#06H,UPDATE_FINISHED
	     MOV R5,#00H
	     MOV A,R6
	     ADD A,#01H
	     MOV R6,A
	     CJNE A,#0AH,UPDATE_FINISHED
	     MOV R6,#00H
	     MOV A,R7
	     ADD A,#01H
	     MOV R7,A
	     CJNE A,#06H,UPDATE_FINISHED
	     MOV R7,#00H
UPDATE_FINISHED: RET

; Cleans the stack and pushes the address of the DISPLAY_TIME procedure
PUSH_MAIN_ADDRESS: MOV A,SP
		   CJNE A,#07H,POP_ADDRESSES
		   PUSH 32H
		   PUSH 33H
		   RETI
POP_ADDRESSES:	   POP 34H
		   POP 34H
		   SJMP PUSH_MAIN_ADDRESS

; Initializes everything
INIT: MOV P2,#00H
      MOV P2,#00H
      MOV P1,#00H
      MOV P3,#0CH
      MOV 32H,#00H
      MOV 33H,#01H
      MOV TMOD,#01H
      SETB IT0
      SETB IT1
      SETB EX0
      SETB EX1
      SETB ET0
      SETB EA
      ACALL RESET
      SJMP DISPLAY_TIME

; Resets appropriate memory
RESET: CLR TR0
       CLR 00H
       CLR 01H
       MOV 35H,#00H
       MOV 36H,#00H
       MOV R0,#00H
       MOV R1,#0FEH
       MOV R4,#00H
       MOV R5,#00H
       MOV R6,#00H
       MOV R7,#00H
       RET  

; Displays the time
ORG 0100H
DISPLAY_TIME: 	  CJNE R1,#0FEH,TRY_TWO
		  MOV A,R4
		  MOV R3,A
		  SJMP DISPLAY
TRY_TWO:	  CJNE R1,#0FDH,TRY_FOUR
		  MOV A,R5
		  MOV R3,A
		  SJMP DISPLAY
TRY_FOUR:	  CJNE R1,#0FBH,TRY_EIGHT
		  MOV A,R6
		  MOV R3,A
		  SJMP DISPLAY
TRY_EIGHT:	  MOV A,R7
		  MOV R3,A
DISPLAY: 	  ACALL NUM_TO_SSD	
		  MOV P1,R1		; Select seven segment display to display the number in R3 
	      	  MOV P2,R3		; Display the number
	      	  ACALL DELAY
	      	  MOV A,R1
	      	  RL A
	      	  MOV R1,A
	          CJNE A,#0EFH,DISPLAY_TIME
	          MOV R1,#0FEH
	          SJMP DISPLAY_TIME

; Converts the value stored in R3 to corresponding seven segment signal for that number
; and then store the result to R3
NUM_TO_SSD: CJNE R3,#00H,NOT_ZERO
	    MOV R3,#03H
	    RET
NOT_ZERO:   CJNE R3,#01H,NOT_ONE
	    MOV R3,#9FH
	    RET
NOT_ONE:    CJNE R3,#02H,NOT_TWO
	    MOV R3,#25H
	    RET
NOT_TWO:    CJNE R3,#03H,NOT_THREE
	    MOV R3,#0DH
	    RET
NOT_THREE:  CJNE R3,#04H,NOT_FOUR
	    MOV R3,#99H
	    RET
NOT_FOUR:   CJNE R3,#05H,NOT_FIVE
	    MOV R3,#49H
	    RET
NOT_FIVE:   CJNE R3,#06H,NOT_SIX
	    MOV R3,#41H
	    RET
NOT_SIX:    CJNE R3,#07H,NOT_SEVEN
	    MOV R3,#1FH
	    RET
NOT_SEVEN:  CJNE R3,#08H,NOT_EIGHT
	    MOV R3,#01H
	    RET
NOT_EIGHT:  MOV R3,#09H
	    RET

; Delays for approximately 2.78ms
; ((((255*2)+1)*5)+(5*2)+2+1)*1.085us ~= 2.78ms
DELAY: MOV 30H,#05H		; 1C
DELAY_UPDATE: MOV 31H,#0FFH	; 1C
       DJNZ 31H,$		; 2C
       DJNZ 30H,DELAY_UPDATE	; 2C
       RET			; 2C

END