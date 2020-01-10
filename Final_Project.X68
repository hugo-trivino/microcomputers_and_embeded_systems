*-----------------------------------------------------------
* Title      :Final Project
* Written by :Hugo Trivino
* Date       :4/20/2018
* Description:This is the final project for the ECE 441 Class
*-----------------------------------------------------------
*--------------------------------------------------------------------
    ORG    $1000
READSTR     EQU     2
WRITESTRLF  EQU     13
WRITESTR    EQU     14
START:                          ; INITIALIZATION OF THE SYSTEM
    MOVEA.L #0,  A1
    MOVEA   #$3400,SP           ;THE STACK POINTER $3000+1K
    MOVE.L  #BUSERR, (8,A1)     ;INITIALIZATION OF EXCEPTION
    MOVE.L  #ADDRERR, (12,A1)   ;VECTORS
    MOVE.L  #ILLADRERR,(16,A1)
    MOVE.L  #DIV0ERR, (20,A1)
    MOVE.L  #CHKINSTERR,(24,A1)
    MOVE.L  #PRIVERR,(32,A1)
    MOVE.L  #LINEA,(40,A1)
    MOVE.L  #LINEF,(44,A1)
*--------------------------------------------------------------------

BASH:   
    CLR     D0                          
    LEA     PROMPT,A1               
    MOVE.B  #WRITESTR ,D0               
    TRAP    #15                 ;PRINTS MONITOR441>
    LEA     BUFFINPUT,A1
    MOVE.B  #READSTR,D0                 
    TRAP    #15                 ;TAKES INPUT FROM USER
    JSR     PARSER              ;SENDS INPUT TO PARSER
    BRA     BASH                ;RETURNS TO LOOP
*--------------------------------------------------------------------

;++++++++++++++++++++++++++++++++++++++++++++++
;                   PARSER
;----------------------------------------------
;INPUT  : A1 STARTING BUFFER OF USER INPUT
;         A1 ADDRESS OF FIRST STRING
;         A2 ADDRESS SECOND STRING
;OUTPUT : D0 = 0    IF EQUAL
;         D0 = 1    IF (A1)>(A2)
;         D0 = -1   IF (A1)>(A2)
;----------------------------------------------
*--------------------------------------------------------------------

PARSER:
    LEA     COMP_TABL,A2        ;ARRAY OF COMMANDS NAMES -> A2
    MOVE.L  #11,D1              ;NUMBER OF FUNCTIONS INDEX ZERO
    MOVE.L  #11,D2              
*--------------------------------------------------------------------
LOOPARSE    
    JSR     CMPSTR              ;COMPARE THE INPUT WITH FIRST 
    TST.L   D0                  ;IF IS SMALLER THEN ERROR
    BLT     PARSERERR           ;BECAUSE THEY ARE ORDERED
    BGT     NXFN                ;IF GREATER CAN STILL BE NEXT
    MOVE.L  D2,D0               ;IF EQUAL, 
    SUB     D1,D0               ;   CALCULATE OFFSET
    LEA     COMP_ADDR,A2        ;BRING ARRAY OF ADDRESSES
    LSL     #1,D0               ;(OFFSET)*2 BECAUSE WORD ADDRESSES
    ADD     D0,A2               ;ADD OFFSET
    MOVEA   (A2),A2             ;BRING ADDRESS TO A2
    JSR     (A2)                JUMP TO COMMAND
    BRA     ENDPARSER
*--------------------------------------------------------------------
NXFN:
    DBEQ    D1,LOOPARSE         ;LOOP UNTIL THERE ARE NOT MORE CMDS    
    JSR PARSERERR               ;IF PASS THE ARRAY THEN PARSE ERROR
    BRA ENDPARSER               ;RETURN TO BASH
PARSERERR:
    LEA     STRWHAT,A1          
    MOVE.B  #WRITESTR ,D0
    TRAP #15                    ;PRINT 'WHAT?'
ENDPARSER:
    RTS
*--------------------------------------------------------------------

;----------------------------------------------
;              END      PARSER
;++++++++++++++++++++++++++++++++++++++++++++++    
    

;++++++++++++++++++++++++++++++++++++++++++++++
;                   CMPSTR
;----------------------------------------------
;INPUT  : A1 ADDRESS OF FIRST STRING
;         A2 ADDRESS SECOND STRING NULL TERMINATED
;OUTPUT : D0 = 0    IF EQUAL
;         D0 = 1    IF (A1)>(A2)
;         D0 = -1   IF (A1)>(A2)
;         A2 AT END OF BUFFER + 1 
;----------------------------------------------
*--------------------------------------------------------------------

CMPSTR:     
    MOVEM   A3,-(SP)            
    MOVEA   A1, A3              ;SAVE START OF USER INPUT
CMPSTRNX:
    CMPM.B  (A2)+,(A3)+         ;CMP INPUT BUFFER WITH CMD STRING
    BLT     CMPSTRLESS          ;IF IS LESS RETURN TO PARSER D0 =-1
    BGT     CMPSTRGREATER       ;IF IS LESS RETURN TO PARSER D0 = 1
    TST.B   (A2)
    BNE     CMPSTRNX            ;ITERATE UNTIL END OF CMD STRING
    CLR.L   D0                  ;IF EQUAL TEXT RETURN WITH   D0 = 0
    BRA     ENDCMPSTR   
*--------------------------------------------------------------------    
CMPSTRLESS:
    MOVE.L  #-1,D0
    BRA     ENDCMPSTR
CMPSTRGREATER:
    MOVE.L  #$1,D0
    BRA     ENDCMPSTR
ENDCMPSTR:
    MOVEM   (SP)+,A3
NXCMPSTR:
    TST.B   (A2)+
    BNE     NXCMPSTR
    RTS
*--------------------------------------------------------------------

;----------------------------------------------
;              END      CMPSTR
;++++++++++++++++++++++++++++++++++++++++++++++ 
 
;++++++++++++++++++++++++++++++++++++++++++++++
;                  ASCI2HX
;----------------------------------------------
;INPUT  : A1 ADDRESS OF ASCII NULL OR SPACE TERMINATED
;OUTPUT : D0 = # OF CHARS CONVERTED
;             
;         D0 = -1   IF ERROR
;         D1 = ANSWER
;         A1 AT END OF BUFFER + 1 
;----------------------------------------------
ASCI2HX:     
    MOVEM.L D2-D3/A2,-(SP)
    CLR.L   D0
    CLR.L   D1
    CLR.L   D2
    MOVE.B  (A1),D2
    BEQ     ASCI2HXERR
    CMP.B   #$24,(A1)
    BNE     ASCI2HXNOTDOL
    ADD     #1,A1
ASCI2HXNOTDOL:
    MOVE.B   (A1)+,D3
    CLR     D2
    LEA     STRASCII,A2
ASCI2HXLOOP:
    CMP.B   (A2,D2),D3
    BEQ     ASCI2HXNXTST
    TST.B   (A2,D2)
    BEQ     ASCI2HXERR
    ADDQ    #1,D2
    BRA     ASCI2HXLOOP
ASCI2HXNXTST:
    ADD     D2,D1
    ADDQ    #1,D0
    CMP.B   #8,D0
    BGT     ASCI2HXERR
    TST.B   (A1)
    BEQ     ENDASCI2HXNULL
    CMP.B   #$20,(A1)
    BEQ     ENDASCI2HX
    ASL.L   #4,D1
    BRA     ASCI2HXNOTDOL
ASCI2HXERR:
    MOVE.L  #-1,D0
ENDASCI2HX:
    ADD     #1,A1
ENDASCI2HXNULL:
    MOVEM.L (SP)+,D2-D3/A2
    RTS
;----------------------------------------------
;              END      ASCII2HEX
;++++++++++++++++++++++++++++++++++++++++++++++ 



 
;++++++++++++++++++++++++++++++++++++++++++++++
;                  HX2ASCI
;----------------------------------------------
;INPUT  : A1 LOCATION IN MEMORY WHERE TO STORE ASCII
;         D0 = HEX NUMBER
;         D1 = NUMBER OF BYTES YOU WANT TO CONVERT
;OUTPUT :                  
;         D0: UNCHANGED
;         D1: UNCHANGED
;         A1 AT END OF BUFFER +SPACE + 1 
;----------------------------------------------
HX2ASCI:     
    MOVEM.L D0-D2,-(SP)
    ADD     D1,A1
    CLR.L   D2
    MOVE.B  D0,D2
    ANDI.B  #$0F,D2
    MOVE.B  #$20,(A1)
HX2ASCINX: 
    SUBI.B  #$9,D2
    BGT     HX2ASCIGT
    ADDI.B  #$39,D2
    BRA     HX2ASCINXTST
HX2ASCIGT:
    ADDI.B  #$40,D2
    BRA     HX2ASCINXTST
HX2ASCINXTST:
    MOVE.B  D2,-(A1)
    ROR.L   #$4,D0
    MOVE.B  D0,D2
    ANDI.B  #$0F,D2 
    SUBI.B  #1,D1   
    BNE     HX2ASCINX
    MOVEM.L (SP)+,D0-D2
    ADD     D1,A1
    ADD     #1,A1
    RTS
;----------------------------------------------
;              END      HX2ASCI
;++++++++++++++++++++++++++++++++++++++++++++++ 





;****************************************************************
;****************************************************************
;****************************************************************
;****************************************************************
;*                         EXCEPTIONS!
;****************************************************************
;****************************************************************
;****************************************************************
;****************************************************************
;--------------------------------------------------------------------
BUSERR:
    
    MOVEM.L D0-D1/A1,-(SP)      ;SAVE ALL REGISTERS IN THE SSP
    LEA     SSWINTSTR,A1        ;BUFFER TO SAVE THE ASCII OF THE SSW
    MOVE.W  (12,SP),D0          ;GET SSW FROM STACK FRAME
    MOVE.W  #4,D1               ;CONVERT 4 DIGITS (WORD) TO ASCII
    JSR     HX2ASCI             ;ASCII CONVERTION
    LEA     BASTR,A1            ;BUFFER TO SAVE THE ASCII OF THE BA
    MOVE.L  (14,SP),D0          ;GET BUS ADDRESS FROM STACK FRAME
    MOVE.W  #8,D1
    JSR     HX2ASCI             ;CONVERT 8 DIG (LONG) BA TO ASCII
    LEA     IRSTR,A1            ;BUFFER TO SAVE THE ASCII OF THE IR
    MOVE.L  (18,SP),D0          ;GET IR FROM STACK FRAME
    MOVE.W  #8,D1
    JSR     HX2ASCI             ;CONVERT 8 DIG (LONG) BA TO ASCII
    LEA     BUSERRSTR,A1        ;
    MOVE.B  #WRITESTR,D0
    TRAP    #15                 ;PRINT BUS ERROR STRING
    LEA     SSWSTR,A1
    MOVE.B  #WRITESTRLF,D0      ;PRINT SSW,BA,IR
    TRAP    #15 
    MOVEM.L (SP)+,D0-D1/A1
    JSR     CMDDF               ;GET DF OUTPUT
    BRA     START               ;RESTART PROGRAM

;--------------------------------------------------------------------
ADDRERR:
    MOVEM.L D0-D1/A1,-(SP)      ;SAVE ALL REGISTERS IN THE SSP
    LEA     SSWINTSTR,A1        ;BUFFER TO SAVE THE ASCII OF THE SSW
    MOVE.W  (12,SP),D0          ;GET SSW FROM STACK FRAME
    MOVE.W  #4,D1               ;CONVERT 4 DIGITS (WORD) TO ASCII
    JSR     HX2ASCI             ;ASCII CONVERTION
    LEA     BASTR,A1            ;BUFFER TO SAVE THE ASCII OF THE BA
    MOVE.L  (14,SP),D0          ;GET BUS ADDRESS FROM STACK FRAME
    MOVE.W  #8,D1
    JSR     HX2ASCI             ;CONVERT 8 DIG (LONG) BA TO ASCII
    LEA     IRSTR,A1            ;BUFFER TO SAVE THE ASCII OF THE IR
    MOVE.L  (18,SP),D0          ;GET IR FROM STACK FRAME
    MOVE.W  #8,D1
    JSR     HX2ASCI             ;CONVERT 8 DIG (LONG) BA TO ASCII
    LEA     ADDRERRSTR,A1        ;
    MOVE.B  #WRITESTR,D0
    TRAP    #15                 ;PRINT ADDRESS ERROR STRING
    LEA     SSWSTR,A1
    MOVE.B  #WRITESTRLF,D0      ;PRINT SSW,BA,IR
    TRAP    #15 
    MOVEM.L (SP)+,D0-D1/A1
    JSR     CMDDF               ;GET DF OUTPUT
    BRA     START               ;RESTART PROGRAM
;--------------------------------------------------------------------
ILLADRERR:
    MOVEM.L D0-D1/A1,-(SP)      ;SAVE ALL REGISTERS IN THE SSP
    LEA     IRSTR,A1            ;GET BUS ADDRESS FROM STACK FRAM
    MOVE.L  (14,SP),D0
    MOVE.W  #8,D1
    JSR     HX2ASCI             ;CONVERT BA TO ASCII
    LEA     ILLERRSTR ,A1       ;PRINT ILLEGAL INSTRUCTION ERROR STR 
    MOVE.B  #WRITESTR,D0
    TRAP    #15                 
    LEA     IRSTR,A1            ;PRINT PC LOCATION OF THE ERROR
    MOVE.B  #WRITESTRLF,D0
    TRAP    #15 
    MOVEM.L (SP)+,D0-D1/A1      ;RECOVER STACK
    JSR     CMDDF               ;GET DF OUTPUT
    BRA     START               ;RESTART PROGRAM

;--------------------------------------------------------------------
PRIVERR:
    MOVEM.L D0-D1/A1,-(SP)      ;SAVE ALL REGISTERS IN THE SSP
    LEA     IRSTR,A1            ;GET BUS ADDRESS FROM STACK FRAM
    MOVE.L  (14,SP),D0
    MOVE.W  #8,D1
    JSR     HX2ASCI             ;CONVERT BA TO ASCII
    LEA     PRVERRSTR ,A1       ;PRINT PRIVILEGE VIOLATION ERROR STR 
    MOVE.B  #WRITESTR,D0
    TRAP    #15                 
    LEA     IRSTR,A1            ;PRINT PC LOCATION OF THE ERROR
    MOVE.B  #WRITESTRLF,D0
    TRAP    #15 
    MOVEM.L (SP)+,D0-D1/A1      ;RECOVER STACK
    JSR     CMDDF               ;GET DF OUTPUT
    BRA     START               ;RESTART PROGRAM
;--------------------------------------------------------------------
DIV0ERR:
    MOVEM.L D0-D1/A1,-(SP)      ;SAVE ALL REGISTERS IN THE SSP
    LEA     IRSTR,A1            ;GET BUS ADDRESS FROM STACK FRAM
    MOVE.L  (14,SP),D0
    MOVE.W  #8,D1
    JSR     HX2ASCI             ;CONVERT BA TO ASCII
    LEA     DIV0ERRSTR,A1       ;PRINT DIV0  ERROR STR 
    MOVE.B  #WRITESTR,D0
    TRAP    #15                 
    LEA     IRSTR,A1            ;PRINT PC LOCATION OF THE ERROR
    MOVE.B  #WRITESTRLF,D0
    TRAP    #15 
    MOVEM.L (SP)+,D0-D1/A1      ;RECOVER STACK
    JSR     CMDDF               ;GET DF OUTPUT
    BRA     START               ;RESTART PROGRAM

;--------------------------------------------------------------------
CHKINSTERR:
    MOVEM.L D0-D1/A1,-(SP)      ;SAVE ALL REGISTERS IN THE SSP
    LEA     IRSTR,A1            ;GET BUS ADDRESS FROM STACK FRAM
    MOVE.L  (14,SP),D0
    MOVE.W  #8,D1
    JSR     HX2ASCI             ;CONVERT BA TO ASCII
    LEA     CHKERRSTR ,A1       ;PRINT CHK INSTRUCTION ERROR STR 
    MOVE.B  #WRITESTR,D0
    TRAP    #15                 
    LEA     IRSTR,A1            ;PRINT PC LOCATION OF THE ERROR
    MOVE.B  #WRITESTRLF,D0
    TRAP    #15 
    MOVEM.L (SP)+,D0-D1/A1      ;RECOVER STACK
    JSR     CMDDF               ;GET DF OUTPUT
    BRA     START               ;RESTART PROGRAM

;--------------------------------------------------------------------
LINEA:
    MOVEM.L D0-D1/A1,-(SP)      ;SAVE ALL REGISTERS IN THE SSP
    LEA     IRSTR,A1            ;GET BUS ADDRESS FROM STACK FRAM
    MOVE.L  (14,SP),D0
    MOVE.W  #8,D1
    JSR     HX2ASCI             ;CONVERT BA TO ASCII
    LEA     LINEASRT ,A1        ;PRINT LINEA EMULATION EXCEP 
    MOVE.B  #WRITESTR,D0
    TRAP    #15                 
    LEA     IRSTR,A1            ;PRINT PC LOCATION OF THE ERROR
    MOVE.B  #WRITESTRLF,D0
    TRAP    #15 
    MOVEM.L (SP)+,D0-D1/A1      ;RECOVER STACK
    JSR     CMDDF               ;GET DF OUTPUT
    BRA     START               ;RESTART PROGRAM
;--------------------------------------------------------------------
LINEF:
    MOVEM.L D0-D1/A1,-(SP)      ;SAVE ALL REGISTERS IN THE SSP
    LEA     IRSTR,A1            ;GET BUS ADDRESS FROM STACK FRAM
    MOVE.L  (14,SP),D0
    MOVE.W  #8,D1
    JSR     HX2ASCI             ;CONVERT BA TO ASCII
    LEA     LINEFSRT ,A1        ;PRINT LINEF EMULATION EXCEP 
    MOVE.B  #WRITESTR,D0
    TRAP    #15                 
    LEA     IRSTR,A1            ;PRINT PC LOCATION OF THE ERROR
    MOVE.B  #WRITESTRLF,D0
    TRAP    #15 
    MOVEM.L (SP)+,D0-D1/A1      ;RECOVER STACK
    JSR     CMDDF               ;GET DF OUTPUT
    BRA     START               ;RESTART PROGRAM
;--------------------------------------------------------------------
;****************************************************************
;****************************************************************
;****************************************************************
;****************************************************************
;*                         COMMANDS!
;****************************************************************
;****************************************************************
;****************************************************************
;****************************************************************


;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;                  CMDBF
;----------------------------------------------------------------
;INPUT  : A1 LOCATION IN MEMORY WHERE TO STORE ASCII
;         D0 = HEX NUMBER
;         D1 = NUMBER OF BYTES YOU WANT TO CONVERT
;OUTPUT :                  
;         D0: UNCHANGED
;         D1: UNCHANGED
;         A1 AT END OF BUFFER +SPACE + 1 
;----------------------------------------------------------------
CMDBF:
    ADD     #3,A1           ;GO TO THE START OF THE ADDRESSES
    CLR.L   D0              ;
    JSR     CAPTURE2ADDR    ;CAPTURE 2 EVEN ADDRESSES ->A2 & ->A3
    TST.B   D0
    BLT     SYNTAXERR       ;IF NOT TWO PROPER ADDRESSES ->ERROR
    LEA     BUFFADDR,A4     ;SAVE ADDRESSES TO PRINT THEM LATER
    MOVE.L  A2,(A4)+        ;SAVE STARTING ADDRESS
    MOVE.L  A3,(A4)+        ;SAVE END ADDRESS
    SUB     #8,A4           ;
    JSR     ASCI2HX         ;CONVERT THE WORD DATA TO HEX
    TST.B   D0              ;TEST IF IS A PROPER HEX
    BLT     SYNTAXERR       ;RETURN ERROR IF IS NOT
;--------------------------------------------------------------------    
BFLOOP
    MOVE.W  D1,(A2)+        ;FILL MEMORY WITH THE WORD DATA
    CMP     A2,A3           ;IF UPPER BOUND STILL GREATER
    BGT     BFLOOP          ;THAN LOWER BOUND, LOOP
    MOVEA   A4,A1           ;MEMORY IS FILLED, NOW PRINT ADDRESS
    MOVE    #2,D0           ;TWO ADDRESSES
    JSR     PHYSICALADDR    ;PHYSICAL ADDRESS: XXXXXXXX XXXXXXXX
    RTS

    
;----------------------------------------------------------------
;              END      CMDBF
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++   
    

;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;                  CMDBMOV
;----------------------------------------------------------------
;--------------------------------------------------------------------
CMDBMOV:
    ADD     #5,A1               ;GO TO THE START OF THE ADDRESSES
    MOVE    #1,D0               ;
    JSR     CAPTURE2ADDR        ;CAPTURE 2 ADDRESSES ->A2 & ->A3
    TST     D0
    BLT     SYNTAXERR           ;IF NOT TWO PROPER ADDRESSES ->ERROR
    JSR     ASCI2HX             ;CONVERT TO HEX THE DESTINATION ADDR
    TST     D0
    BLT     SYNTAXERR           ;IF DEST IS NOT A PROPER HEX ->ERROR
    LEA     BUFFADDR,A4         ;SAVE THE ADDRESSES TO PRINT AT END
;--------------------------------------------------------------------
    MOVE.L  A2,(A4)+            ;SAVE STARTING ADDRESS
    MOVE.L  A3,(A4)+            ;SAVE END ADDRESS
    MOVE.L  D1,(A4)+            ;SAVE DESTINATION ADDRESS
    SUB     #12,A4
    MOVEA   D1,A1               ;IN CASE DESTINATION IS IN BETWEEN    
    MOVE    A3,D0               ;THE BOUNDARIES, WE HAVE TO TRANSFER
    SUB     A2,D0               ;IN DESCENDING ORDER TO NOT LOSS DATA
    SUB     A2,D1               ;OTHERWISE IS OK TO DO A ASCENDING
    BLT     BMOVASC
    CMP     D1,D0
    BLT     BMOVASC
;--------------------------------------------------------------------    
BMOVDES:
    ADD     D0,A1               ;IF DESC, ADD OFFSET DESTINATION
BMOVDESLP:    
    MOVE.B  -(A3),-(A1)         ;START FROM THE END OF THE BLOCK
    SUBQ    #1,D0
    BNE     BMOVDESLP           ;DO IT UNTIL THERE IS NOT MORE BYTES
    BRA     ENDBMOV             ;FINISH IF DONE
BMOVASC:    
    MOVE.B  (A2)+,(A1)+         ;THIS IS ASCENDING ORDER
    SUBQ    #1,D0               ;DO IT UNTIL THERE IS NOT MORE BYTES
    BNE     BMOVASC             ;FINISH IF DONE
;--------------------------------------------------------------------
ENDBMOV:
    MOVEA    A4,A1              ;MOVE THE BEGGINING OF ADDRESSES
    MOVE    #2,D0               ;PRINT TWO BOUNDARY ADDRESSES
    JSR     PHYSICALADDR        ;PHYSICAL ADDRESS: XXXXXXXX XXXXXXXX
    MOVE    #1,D0               ;PRINT DESTINATION ADDRESS
    JSR     PHYSICALADDR        ;PHYSYCAL ADDRESS: XXXXXXXX
    RTS
;--------------------------------------------------------------------
;----------------------------------------------------------------
;              END      CMDBMOV
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 

;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;                  CMDBSCH
;----------------------------------------------------------------
;--------------------------------------------------------------------
CMDBSCH:
    MOVE    #1,D2
    ADD     #5,A1               ;GO TO THE START OF THE ADDRESSES
    MOVE    #1,D0
    JSR     CAPTURE2ADDR        ;CAPTURE 2 ADDRESSES ->A2 & ->A3
    TST     D0
    BLT     SYNTAXERR           ;IF NOT TWO PROPER ADDRESSES ->ERROR
    LEA     BUFFADDR,A4         ;SAVE ADDRESSES TO PRINT LATER
    MOVE.L  A2,(A4)+
    MOVE.L  A3,(A4)+
    MOVE.B  (A1)+,D0            ;ERROR IF NOT STRING TO SEARCH
    BEQ     SYNTAXERR           ;
    MOVE.L  #$27,D1             ;CHECK THAT STRING START WITH QUOTES
    CMP.B   D1,D0               
    BNE     SYNTAXERR           ;ERROR IF IT DOESN'T HAVE QUOTES
    MOVE.L  A1,A5               ;SAVE STARTING ADDRESS OF INPUT
    MOVE.L  A3,D0               ;SAVE ENDING ADDRESS OF SEARCH TO CMP
;--------------------------------------------------------------------
BSCHLOOP:
    TST     D2                  ;THE FIRST TIME IS NOT EQUAL TO ZERO
    BEQ     BSCHLOOP2           ;THIS IS JUST TO INITIALIZE
    SUB     #1,A2
BSCHLOOP2:
    CMPA    D0,A2               ;IS LOWER GREATER THAN UPPER BOUND?
    BGT     BSCHNOTFOUND        ;WE FINISH WITH NO SUCCESS
    CLR     D2                  ;ELSE MAKE D2=0
    MOVE.L  A2 ,(A4)            ;
    MOVEA.L A5,A1
;--------------------------------------------------------------------
BSCHLP:
    CMPM.B   (A1)+,(A2)+        ;COMP ASCI FROM INPUT TO MEMORY RANGE
    BNE     BSCHLOOP            ;IF NOT EQUAL BEGIN FROM START +1
    ADDQ    #1,D2               ;
    CMPA    D0,A2               ;IS LOWER GREATER THAN UPPER BOUND?
    BGT     BSCHNOTFOUND        ;WE FINISH WITH NO SUCCESS
    CMP.B   (A1),D1             ;IS THE NEXT CHAR IN INPUT A QUOTE?
    BEQ     BSCHFOUND           ;WE FINISH IF THIS IS THAT CASE
    TST.B   (A1)                ;IS THE NEXT CHAR IN INPUT A NULL?
    BEQ     BSCHFOUND           ;WE FINISH IF THIS IS THAT CASE
    BRA     BSCHLP              ;ELSE, REVIEW NEXT CHAR
;--------------------------------------------------------------------
BSCHNOTFOUND:    
    LEA     BUFFADDR,A1         ;IF NOT FOUND
    MOVE    #2,D0               ;JUST PRINT THE RANGE
    JSR     PHYSICALADDR        ;PHYSICAL ADDRESS: XXXXXXXX XXXXXXXX
    RTS
;--------------------------------------------------------------------
BSCHFOUND:
    LEA     BUFFADDR,A1         ;IF FOUND, PRINT RANGE AND MATCH
    MOVE.L  #2,D0
    JSR     PHYSICALADDR        ;PHYSICAL ADDRESS: XXXXXXXX XXXXXXXX
    LEA     BUFFINPUT,A1        
    MOVE.L  (A4),D0             ;THIS IS THE ADDRESS WITH A MATCH
    MOVE.L  #8,D1               
    JSR     HX2ASCI             ;CONVERT IT IN ASCII TO PRINT
    MOVE.B  #$20,(A1)+          ;PRINT A SPACE IN FRONT
    MOVE.L  A2,D1
    MOVEA.L (A4),A4             ;START OF THE MATCHING STRING
    MOVE.B  #$27,(A1)+
;--------------------------------------------------------------------
LOOPBSCH:
    MOVE.B  (A4)+,(A1)+         ;MOVE CHARS MATCHING STRING TO BUFFER
    CMPA    D1,A4               ;SEE IF THE END OF STRING
    BEQ     ENDBSCH             ;IF IT IS PRINT AND EXIT
    BRA     LOOPBSCH            ;ELSE KEEP LOOPING
    MOVE.L  (A4),D0             ;
    MOVE.L  #8,D1
    JSR     HX2ASCI             ;CONVERT THE ADDRESS TO STRING
    MOVE.B  #$20,(A1)           
;--------------------------------------------------------------------
ENDBSCH:    
    MOVE.B  #$27,(A1)+          ;ADD A QUOTE AT THE END
    MOVE.B  #$0,(A1)+
    LEA     BUFFINPUT,A1        ;PRINT IN THE FOLLOWING FORMAT
    MOVE.B  #WRITESTRLF,D0      ;XXXXXXXX 'STR'
    TRAP    #15
    RTS
;--------------------------------------------------------------------
;              END      CMDBSCH
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 

;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;                  CMDBTST
;----------------------------------------------------------------
;--------------------------------------------------------------------
CMDBTST:
    ADD     #5,A1               ;START FROM BEGGINNING OF ADDRESSES
    MOVE    #0,D0
    JSR     CAPTURE2ADDR        ;CAPTURE 2 EVEN ADDRESSES ->A2 &->A3
    TST.B   D0
    BLT     SYNTAXERR           ;ERROR IF NOT PROPER ADDRESSES
    MOVE.L  A3,D1               ;MOVE UPPER BOUND TO D1
    LEA     BUFFADDR,A4         ;SAVE THE ADDRESSES TO PRINT AT END
    MOVE.L  A2,(A4)+            ;SAVE LOWER BOUND
    MOVE.L  A3,(A4)+            ;SAVE UPPER BOUND
    SUB     #8,A4
    LEA     TESTBTST,A3         ;BRING THE ARRAY OF TEST WORDS
;--------------------------------------------------------------------
NEXTBTST:
    MOVE.W  (A3)+,D0            ;TEST WORD->D0 (E.G AAAA OR 5555)
    MOVE.W  D0,(A2)             ;TST WORD ->MEM[A2] (WRITE)
    MOVE.W  (A2),D2             ; MEM[A2] -> D2     (READ)
    CMP.W   D0,D2               ;COMPARE WRITTEN WITH READ
    BNE     BTSTERR             ;PRINT ERROR IF THEY ARE NOT SAME
    TST.W   (A2)                ;LAST WORD IS 0000, IS THIS LAST?
    BNE     NEXTBTST            ;IF NOT TEST THE OTHER WORDS
    CMP.W   A2,D1               ;IS THIS THE UPPER BOUND IN MEMORY?
    BLT     ENDBTST             ;THEN FINISH TEST
    ADD     #2,A2               ;ELSE MOVE A WORD IN MEMORY
    LEA     TESTBTST,A3         ;LOAD LIST OF WORDS IN A3
    BRA     NEXTBTST            ;TEST ALL WORDS IN NEXT LOCATION
;--------------------------------------------------------------------
BTSTERR:
    LEA     WROTEBTST,A1        ;SAVE IN ASCII WHAT WE WROTE IN ERR
    MOVE    #4,D1
    JSR     HX2ASCI
    LEA     READBTST ,A1        ;SAVE IN ASCII WHAT WE READ IN ERR
    MOVE    D2,D0
    MOVE    #4,D1
    JSR     HX2ASCI
    LEA     BTSTERRADDR ,A1     ;SAVE IN ASCII ADDRESS OF ERR
    MOVE.L  A2,D0    
    MOVE    #8,D1
    JSR     HX2ASCI
    LEA     BTSTERRSTR ,A1      ;FAILED AT XXXXXXXX
    MOVE    #WRITESTRLF,D0      ;WROTE=XXXX READ=XXXX 
    TRAP    #15                 ;(WITHOUT <CR>)
    RTS
;--------------------------------------------------------------------

ENDBTST:
    MOVEA   A4,A1               ;IF TEST IS PASSED
    MOVE    #2,D0               ;WE PRINT THE FOLLOWING
    JSR     PHYSICALADDR        ;PHYSICAL ADDRESS: XXXXXXXX XXXXXXXX
    RTS
;--------------------------------------------------------------------
;              END      CMDBTST
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 

;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;                  CMDDF
;----------------------------------------------------------------

;--------------------------------------------------------------------
CMDDF:
    MOVEM.L D0-D7/A0-A7,-(SP)   ;SAVE ALL ORIGINAL REGISTERS
    MOVE.L  A7,D5               ;SAVE THE STACK POINTER IN D5
    SUBI    #64,D5              ;SUB THE REGISTERS THAT WE STORED
    MOVE.L  USP,A1              ;MOVE THE USER STACK POINTER A1
    MOVE.L  A1,D6               ;MAKE A COPY OF THE USP ->D6
    MOVE    SR,D3               ;COPY SR IN D3
    MOVE.L  #CMDDF,D4           ;PRINT
    LEA     DFSTRING,A1         ;PRINT :' PC='
    MOVE.B  #WRITESTR ,D0
    TRAP    #15
;--------------------------------------------------------------------
    LEA     BUFFINPUT,A1        ;CONVERT HEX TO ASCII INTO BUFFER
    MOVE    #8,D1               ;LONG REGISTER PC 
    MOVE.L  D4,D0               ;CONVERTING TO ASCII
    JSR     HX2ASCI             ;
    MOVE.B  #$00,(A1)           ;PRINT PC IN NULL TERMINATED ASCII
    LEA     BUFFINPUT,A1        ;
    MOVE.B  #WRITESTR ,D0       ; BY HERE IS PC=XXXXXXXX
    TRAP    #15
;--------------------------------------------------------------------
    MOVE.L  #$2053523D,D2       ;PRINT :' SR='
    MOVE    #4,D1               ;WORD REGISTER SR
    MOVE.L  D3,D0               ;
    JSR     DFHELPER            ;CONV HX2ASCII AND ADD TO BUFFER
    MOVE.L  #$2055533D,D2       ;PRINT :' US='
    MOVE    #8,D1               ;LONG REGISTER US
    MOVE.L  D6,D0
    JSR     DFHELPER            ;CONV HX2ASCII AND ADD TO BUFFER
    MOVE.L  #$2053533D,D2       ;PRINT :' SS='
    MOVE.L  D5,D0               ;LONG REGISTER SS
    JSR     DFHELPER            ;CONV HX2ASCII AND ADD TO BUFFER
    LEA     BUFFINPUT,A1        ;
    MOVE.B  #$00,(A1)
    MOVE.B  #WRITESTRLF ,D0     ;PC=XXXXXXXXX SR=XXXX US=XXXXXX...
    TRAP    #15
;--------------------------------------------------------------------
    MOVE.L  SP,A4               ;SP ->A4
    MOVE    #4,D3               ;ITERATE FOUR TIMES
    MOVE.L  #$2044303D,D2       ;START FROM ' D0='
    BSR     DFLOOP              ;THIS PRINTS ' D0=XXXX... D3=XXXX...
    MOVE.L  #$2044343D,D2       ;START FROM ' D4='
    MOVE    #4,D3               ;ITERATE FOUR TIMES
    BSR     DFLOOP              ;THIS PRINTS ' D4=XXXX... D7=XXXX...
    MOVE.L  #$2041303D,D2
    MOVE    #4,D3               ;ITERATE FOUR TIMES
    BSR     DFLOOP              ;THIS PRINTS ' A0=XXXX... A3=XXXX...
    MOVE.L  #$2041343D,D2
    MOVE    #4,D3               ;ITERATE FOUR TIMES
    BSR     DFLOOP              ;THIS PRINTS ' A4=XXXX... A7=XXXX...
    BRA     ENDDF
;--------------------------------------------------------------------
DFLOOP:    
    LEA     BUFFINPUT,A1        
    MOVE.L  (A4)+,D0
    JSR     DFHELPER            ;WRITES IN BUFFER CONSECUTIVE REG
    ADD     #$100,D2            ;ADD 1 TO SECND CHAR (E.G 'D0'->'D1')
    SUBI    #1,D3               ;COUNT ITERATIONS
    TST     D3
    BNE     DFLOOP
    JSR     PRINTENTER          ;PRINT <CR> AT THE END OF FOUR REGS
    RTS
;--------------------------------------------------------------------
DFHELPER:
    LEA     BUFFINPUT,A1        ;START FROM BUFFER
    ROL.L   #8,D2               ;MOVES THE UPPER BYTE TO LOWEST
    MOVE.B  D2,(A1)+            ;MOVE LOWEST BYTE TO BUFFER
    ROL.L   #8,D2               ;MOVES THE UPPER BYTE TO LOWEST
    MOVE.B  D2,(A1)+            ;MOVE LOWEST BYTE TO BUFFER
    ROL.L   #8,D2               ;MOVES THE UPPER BYTE TO LOWEST
    MOVE.B  D2,(A1)+            ;MOVE LOWEST BYTE TO BUFFER
    ROL.L   #8,D2               ;MOVES THE UPPER BYTE TO LOWEST
    MOVE.B  D2,(A1)+            ;MOVE LOWEST BYTE TO BUFFER
    JSR     HX2ASCI             ;CONVERT HX2ASCI THE REGISTER 0
    MOVE.B  #$00,(A1)           ;IT ADDS IT TO BUFF AND NULL TERMS
    LEA     BUFFINPUT,A1
    MOVE.B  #WRITESTR ,D0       ;PRINT TOGETHER THE REG WITH NAME
    TRAP    #15
    RTS
;--------------------------------------------------------------------
ENDDF:
    MOVEM.L  (SP)+,D0-D7/A0-A7  ;RETURN ORIGINAL REGISTERS
    RTS
;--------------------------------------------------------------------
;              END      CMDDF
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 

;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;                  CMDEXIT
;----------------------------------------------------------------

;--------------------------------------------------------------------
CMDEXIT:
    LEA     EXITSTR,A1          ;BRINGS WORD 'EXIT'     
    MOVE.B  #WRITESTRLF ,D0
    TRAP    #15                 ;PRINTS 'EXIT'<CR> TO TERMINAL
    BRA     END                 ;BRANCH TO END OF THE PROGRAM
    RTS
;--------------------------------------------------------------------
;              END      CMDEXIT
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
    
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;                  CMDGO
;----------------------------------------------------------------
;--------------------------------------------------------------------
CMDGO:
    ADD     #3,A1               ;BRINGS STARTING ADDRESS
    JSR     ASCI2HX             ;CONVERT ADDRESS TO HEX
    TST     D0                  ;ERROR IF NOT PROPER ADDRESS
    BLT     SYNTAXERR           ;
    MOVE.L  D1,A1               ;BRING ADDRESS TO A1
    JMP     (A1)                ;JUMP TO ADDRESS
    RTS
;--------------------------------------------------------------------
;              END      CMDGO
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;                  CMDHELP
;----------------------------------------------------------------
;INPUT  : A1 LOCATION IN MEMORY WHERE TO STORE ASCII
;         D0 = HEX NUMBER
;         D1 = NUMBER OF BYTES YOU WANT TO CONVERT
;OUTPUT :                  
;         D0: UNCHANGED
;         D1: UNCHANGED
;         A1 AT END OF BUFFER +SPACE + 1 
;--------------------------------------------------------------------
CMDHELP:
    LEA HELPDISPLAY,A1          ;BRINGS THE HELP MESSAGE
    MOVE.B  #WRITESTRLF ,D0
    TRAP #15                    ;PRINTS THE HELP MESSAGE
    RTS
;--------------------------------------------------------------------
;              END      CMDHELP
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;                  CMDMDSP
;----------------------------------------------------------------
;INPUT  : A1 LOCATION IN MEMORY WHERE TO STORE ASCII
;         D0 = HEX NUMBER
;         D1 = NUMBER OF BYTES YOU WANT TO CONVERT
;OUTPUT :                  
;         D0: UNCHANGED
;         D1: UNCHANGED
;         A1 AT END OF BUFFER +SPACE + 1 
;--------------------------------------------------------------------

CMDMDSP:
    ADD     #5,A1               ;STARTING OF THE ADDRESS(ES)
    JSR     ASCI2HX             ;CONVERT FIRST ADDRESS TO HEX
    TST     D0                  
    BLT     SYNTAXERR           ;ERROR IF NOT PROPER HEX
    MOVEA   D1,A2               ;MOVE LOWER BOUND TO A2
    TST.B   (A1)                ;IS THERE ANOTHER ADDRESS?
    BEQ     MDSP1ND             ;IF THERE IS NOT, DO DEFAULT
    JSR     ASCI2HX             ;CONVERT SECOND ADDRESS TO HEX
    TST     D0
    BLT     SYNTAXERR           ;ERROR IF NOT PROPER HEX
    MOVEA   D1,A3               ;MOVE UPPER BOUND TO A2
    CMP     A3,A2           
    BGT     SYNTAXERR           ;ERROR IF LOWER>UPPER ADDRESSES
    BRA     MDSPLOOP
;--------------------------------------------------------------------
MDSP1ND
    MOVEA   A2,A3               ;DEFAULT WILL SHOW $F ADDRESSES
    ADD     #15,A3              ;MAKE UPPER BOUND A2+$F ->A3
MDSPLOOP
    LEA     BUFFINPUT ,A1       ;BUFFER TO PRINT
    MOVE    A2, D0              ;BRING ADDRESS TO D0 TO PRINT
    MOVE    #8,D1
    JSR     HX2ASCI             ;CONVERT ADDRESS TO ASCII
;--------------------------------------------------------------------
    MOVE.B  #$20,(A1)+          ;PLACE TWO SPACES BEFORE CONTENT
    MOVE.B  #$20,(A1)+
    MOVE.B  (A2)+,D0            ;BRING CONTENT TO D0
    MOVE    #2,D1
    JSR     HX2ASCI             ;CONVERT TO ASCII BYTE SIZE
    MOVE.B  #0,(A1)
    LEA     BUFFINPUT,A1
    MOVE.B  #WRITESTRLF ,D0     ;PRINT XXXXXXXXX  XX
    TRAP    #15
    CMP     A2,A3               ;LOWER <UPPER? KEEP GOING
    BGT     MDSPLOOP            ;ELSE, END
    RTS
;--------------------------------------------------------------------

;----------------------------------------------------------------
;              END      CMDMDSP
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;                  CMDMM
;----------------------------------------------------------------
;INPUT  : A1 LOCATION IN MEMORY WHERE TO STORE ASCII
;         D0 = HEX NUMBER
;         D1 = NUMBER OF BYTES YOU WANT TO CONVERT
;OUTPUT :                  
;         D0: UNCHANGED
;         D1: UNCHANGED
;         A1 AT END OF BUFFER +SPACE + 1 
;--------------------------------------------------------------------
CMDMM:
    ADD     #3,A1               ;START AT THE BEGGINING OF ADDRESS
    JSR     ASCI2HX             ;ADDRESS TO HEX
    TST     D0
    BLT     SYNTAXERR           ;ERROR IF NOT PROPER ADDRESS
    TST.B   (A1)                ;IF NOT OTHER ARG
    BEQ     MMBYTE              ;THEN MUST BE BYTE BY DEFAULT
    AND.B   #$FE,D1             ;ELSE, MAKE SURE IS AN EVEN ADDRESS
    MOVE.L  D1,A2               ;ADDRESS GIVEN ->A2
    CMP.W  #$3B57,(A1)          ;IS NEXT ARGUMENT ':W'??
    BEQ     MMWORD              ;THEN GO TO THE WORD ROUTINE
    CMP.W  #$3B4C,(A1)          ;IS NEXT ARGUMENT ':L'??
    BEQ     MMLONG              ;THEN GO TO THE LONG ROUTINE
    BRA     SYNTAXERR           ;ERROR IF NEITHER OF THOSE ARGS
;--------------------------------------------------------------------
MMBYTE:
    MOVEA   D1,A2
    MOVE    #2,D2               ;SIZE TO WORK WITH IS 2 CHARS (BYTE)
    BRA     MMLOOP              ;GO TO LOOP
MMWORD 
    MOVE    #4,D2               ;SIZE TO WORK WITH IS 4 CHARS (WORD)
    BRA     MMLOOP              ;GO TO LOOP
MMLONG:   
    MOVE    #8,D2               ;SIZE TO WORK WITH IS 8 CHARS (LONG)
;--------------------------------------------------------------------
MMLOOP:
    LEA     BUFFINPUT ,A1       ;INPUT BUFFER
    MOVE.L  A2, D0
    MOVE    #8,D1
    JSR     HX2ASCI             ;MOVE CURRENT ADDRESS IN HEX
    MOVE.B  #$20,(A1)+          ;PLUS SPACE
    CMP.B   #2,D2               ;IS THE BYTE?
    BEQ     MMBYTPR             ;   PRINT A BYTE 
    CMP.B   #4,D2               ;   IS THE WORD?
    BEQ     MMWRDPR             ;       PRINT A WORD 
    BRA     MMLNGPR             ;ELSE LONG
;--------------------------------------------------------------------
MMBYTPR:
    MOVE.B  (A2),D0             ;MOVE FOR CONVERSION SIZE DATA BYTE
    BRA     MMCONT
MMWRDPR:
    MOVE.W  (A2),D0             ;MOVE FOR CONVERSION SIZE DATA WORD
    BRA     MMCONT
MMLNGPR:
    MOVE.L  (A2),D0             ;MOVE FOR CONVERSION SIZE DATA LONG
;--------------------------------------------------------------------
MMCONT:
    MOVE.L  D2,D1               ;MOVE THE SIZE FOR HEX CONVERSION
    JSR     HX2ASCI             ;CONVERT
    SUB     #1,A1           
    MOVE.L  #$203F2000,(A1)+    ;ADD ' ? ' AT THE END OF ADDRESS
    LEA     BUFFINPUT,A1        
    MOVE.B  #WRITESTR,D0
    TRAP    #15                 ;PRINT 'XXXXXXXX ? '
    LEA     BUFFINPUT,A1
    MOVE.B  #READSTR,D0
    TRAP    #15                 ;READ ANSWER FROM USER
;--------------------------------------------------------------------
    LEA     BUFFINPUT,A1        ;
    MOVE.B  (A1),D0             ;MOVE THE FIRST BYTE OF THE ANSWER
    CMP.B   #$2E,D0             ;IF IS A DOT "." END THE COMMAND
    BEQ     ENDMM               ;   
    TST.B   D0          
    BEQ     MMPASS              ;IF EMPTY MEANS THAT PASS W/O CHANGE
    JSR     ASCI2HX             ;ELSE, CONVERT TO HEX TO SAVE CHANGES
    TST     D0
    BLT     SYNTAXERR           ;IF NOT A PROPER HEX PRINT ERR
    CMP.B   #2,D2
    BEQ     MMMVBYT             ;SAVE BYTE
    CMP.B   #4,D2
    BEQ     MMMVWRD             ;SAVE WORD
    BRA     MMMVLNG             ;SAVE LONG
;--------------------------------------------------------------------
MMMVBYT
    MOVE.B  D1,(A2)+            ;SAVE BYTE
    BRA     MMLOOP              ;KEEP GOING UNTIL A DOT "."
MMMVWRD
    MOVE.W  D1,(A2)+            ;SAVE WORD
    BRA     MMLOOP              ;KEEP GOING UNTIL A DOT "."
MMMVLNG
    MOVE.L  D1,(A2)+            ;SAVE LONG
    BRA     MMLOOP              ;KEEP GOING UNTIL A DOT "."
;--------------------------------------------------------------------
MMPASS:
    MOVE    D2,D3               ;IF PASSED, ADD TO THE ADDRESS
    ASR     #1,D3               ;A2+1 OR +2 OR +4 DEPENDING OF D2
    ADD     D3,A2
    BRA     MMLOOP              ;LOOP
ENDMM
    RTS  
;--------------------------------------------------------------------
;--------------------------------------------------------------------
;              END      CMDMM
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;                  CMDMS
;----------------------------------------------------------------
;INPUT  : A1 LOCATION IN MEMORY WHERE TO STORE ASCII
;         D0 = HEX NUMBER
;         D1 = NUMBER OF BYTES YOU WANT TO CONVERT
;OUTPUT :                  
;         D0: UNCHANGED
;         D1: UNCHANGED
;         A1 AT END OF BUFFER +SPACE + 1 
;--------------------------------------------------------------------
CMDMS:
    ADD     #3,A1               ;STARTING ADDRESS
    JSR     ASCI2HX             ;CONVERT FIRST ADDRESS TO HEX
    TST     D0          
    BLT     SYNTAXERR           ;ERROR IF NOT A PROPER ADDRESS
    SUB     #1,A1
    TST.B   (A1)+
    BEQ     SYNTAXERR           ;IF NOT INPUT HEX OR ASCI IS ERR
    MOVEA   D1, A2
    SUBI.B  #$27,(A1)+          ;IF INPUT START WITH QUOTES IS ASCII
    BEQ     MSASCII             ;BRANCH TO ASCII
    ADDI.B  #$27,-(A1)          
    CMP.B   #$24,(A1)           ;IF HEX INPUT W/O '$' TAKE INPUT 
    BNE     MSHEXNOTDOL         ;INMEDIATELY
    ADD     #1,A1               ;OTHERWISE ADD 1 BYTE AND TAKE INPUT
;--------------------------------------------------------------------
MSHEXNOTDOL:
    MOVE    A1,A3               ;
MSHEX: 
    JSR     ASCI2HX             ;CONVERT THE INPUT TO HEX
    TST.B   D0  
    BLT     SYNTAXERR           ;IF NOT A PROPER HEX PRINT ERR
    ADDQ    #1,D0               ;ADD ONE AND DIVIDE BY TWO TO GET
    LSR     #1,D0               ;ROOF OF # OF PAIR CHARACTERS
    MOVE    D0,D2               ;SINCE 2 NIBBLES PER BYTE
    SUB     #4,D2
;--------------------------------------------------------------------
MSPOSSITION:
    TST     D2                  ;ROTATE MSB TO THE LSB POSITION
    BEQ     MSLOOPHX            ;IN ORDER TO WORK BYTE PER BYTE
    ROL.L   #8,D1
    ADDQ    #1,D2
    BRA     MSPOSSITION
;--------------------------------------------------------------------
MSLOOPHX:
    ROL.L   #8,D1               ;WRITE EACH HEX BYTE INTO THE ADDR
    MOVE.B  D1,(A2)+            ;GIVEN BY A2
    SUBI.B  #1,D0               ;UNTIL THE NUMBER OF PAIRS IS ZERO
    BNE     MSLOOPHX            ;LOOP
    TST.B   -(A1)               ;END IF THERE IS A NULL TERMINATION
    BEQ     ENDMS               ;IN THE USER INPUT.
    ADD     #1,A1
    BRA     MSHEX   
;--------------------------------------------------------------------
MSASCII:
    MOVE.B  #$27,-(A1)          ;ASCII IS EASIER, IS LAST CHAR A "'"?
    ADD     #1,A1               ;
MSASCIILOOP:
    TST.B   (A1)                ;IF CHAR IS NULL, STRING TERMINATED
    BEQ     ENDMS
    MOVE.B  (A1),D0
    CMP.B   #$27, D0            ;IF CHAR IS "'", STRING TERMINATED
    BEQ     ENDMS
    MOVE.B  (A1)+,(A2)+         ;COPY FROM INPUT TO MEMORY
    BRA     MSASCIILOOP
ENDMS
    RTS
;--------------------------------------------------------------------
;              END      CMDMS
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;                  CMDSORTW
;----------------------------------------------------------------
;INPUT  : A1 LOCATION IN MEMORY WHERE TO STORE ASCII
;         D0 = HEX NUMBER
;         D1 = NUMBER OF BYTES YOU WANT TO CONVERT
;OUTPUT :                  
;         D0: UNCHANGED
;         D1: UNCHANGED
;         A1 AT END OF BUFFER +SPACE + 1 
;--------------------------------------------------------------------
CMDSORTW:
    ADD     #6,A1               ;BEGGINING OF ADDRESSES
    MOVE    #0,D0
    JSR     CAPTURE2ADDR        ;GET TWO EVEN ADDRESSES A2 & A3
    TST     D0
    BLT     SYNTAXERR           ;ERROR IF NOT PROPER ADDRESS
    MOVE.L  #-1,D1              ;IS DESCENDENT D1=-1
    CMP.B   #$44,(A1)           ;IF ARGUMENT IS 'D' DESCENDENT
    BNE     SORTWDESC
    CLR.L   D1                  ;IS ASCENDENT D1=0
;--------------------------------------------------------------------
SORTWDESC:                      ;THIS IS PRETTY MUCH BUBBLE SORT
    MOVE.L  A2,A0
    MOVE.L  A0,A2               ; A2 IS THE STARTING ADDRESS
SORTBGNN:
    MOVE.L  A2,A0               ; START FROM BEGGINING AGAIN
SORTCMP:
    CMP.W   (A0)+,(A0)+         ; IF (ARRAY[i] < ARRAY[i+1])
    BHI.S   SWAPSORT            ; THEN SWAP THE VALUES
    SUBQ.L  #2,A0               ; ELSE: GO TO THE NEXT ELEMENT
    CMP.L   A0,A3               ; IF CURRENT ELEMENT == LAST?
    BNE     SORTCMP             ; IF NOT, GO TO THE NEXT ELEMENT  
    TST     D1                  ; IF THEY ARE EQUAL, YOU HAVE 
    BEQ     ENDSORT             ; ALL SORTED IN DESCENDING 
    ADD     #2,A3               ; IF WANT ASCENDING SWAP WHOLE ARRAY
;--------------------------------------------------------------------
SORTASC:
    MOVE.W  (A2),D1             ;COPY FIRST VALUE IN D1
    MOVE.W  -(A3),(A2)+         ;COPY LAST VALUE IN FIRST POSITION
    MOVE.W  D1,(A3)             ;COPY FIRST VALUE IN LAST POSITION
    CMP     A2,A3               ;DO IT UNTIL LOWER>UPPER BOUND
    BGT     SORTASC
    BRA     ENDSORT             ;WHEN THIS IS DONE YOU FINISH!
;--------------------------------------------------------------------
SWAPSORT:
    MOVE.L  -(A0),D0            ; PUT 2 WORDS IN D0
    SWAP.W  D0                  ; SWAP WORDS D0
    MOVE.L  D0,(A0)             ; BRING IT BACK TO MEMORY
    BRA     SORTBGNN            ; START FROM BEGGINING COMPARISON
ENDSORT
  
    RTS
;----------------------------------------------------------------
;              END      CMDSORTW
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;                  CMDEXTRA1
;----------------------------------------------------------------
;INPUT  : A1 LOCATION IN MEMORY WHERE TO STORE ASCII
;         D0 = HEX NUMBER
;         D1 = NUMBER OF BYTES YOU WANT TO CONVERT
;OUTPUT :                  
;         D0: UNCHANGED
;         D1: UNCHANGED
;         A1 AT END OF BUFFER +SPACE + 1 
;----------------------------------------------------------------
CMDEXTRA1:
    LEA COMP_TABL,A1
    MOVE.B  #WRITESTRLF ,D0
    TRAP #15
    RTS
;----------------------------------------------------------------
;              END      CMDEXTRA1
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;                  CMDEXTRA2
;----------------------------------------------------------------
;INPUT  : A1 LOCATION IN MEMORY WHERE TO STORE ASCII
;         D0 = HEX NUMBER
;         D1 = NUMBER OF BYTES YOU WANT TO CONVERT
;OUTPUT :                  
;         D0: UNCHANGED
;         D1: UNCHANGED
;         A1 AT END OF BUFFER +SPACE + 1 
;----------------------------------------------------------------
CMDEXTRA2:
    LEA COMP_TABL,A1
    MOVE.B  #WRITESTRLF ,D0
    TRAP #15
    RTS
;----------------------------------------------------------------
;              END      CMDEXTRA2
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++



;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;                  CAPTURE2ADDR
;----------------------------------------------------------------
;INPUT  : A1 LOCATION IN MEMORY WHERE TO STORE ASCII ADDRESSES
;            SEPARATED BY A SPACE
;         D0 = 0 IF EVEN OR 1 IF NOT
;         D1 = NUMBER OF BYTES YOU WANT TO CONVERT
;OUTPUT :                  
;         A2: FIRST ADDRESS
;         A3: SECOND ADDRESS
;         A1 AT END OF BUFFER +SPACE + 1 
;----------------------------------------------------------------

CAPTURE2ADDR:
    MOVEM.L D1-D2,-(SP)
    MOVE    D0,D2
    JSR     ASCI2HX
    TST     D0
    BLT     CAPTURE2ADDRERR
    TST     D2
    BNE     ADDRNTEVEN1
    ANDI.B  #$FE,D1 ;MAKING SURE THAT ADDRESS ARE EVEN
ADDRNTEVEN1:
    MOVEA.L   D1,A2
    JSR     ASCI2HX
    TST     D0
    BLT     CAPTURE2ADDRERR
    TST     D2
    BNE     ADDRNTEVEN2
    ANDI.B  #$FE,D1 ;MAKING SURE THAT ADDRESS ARE EVEN
ADDRNTEVEN2:
    MOVEA.L   D1,A3
    CMP     A3,A2
    BGT     CAPTURE2ADDRERR ;ERROR IF THE SECOND ADDRESS IS SMALLER THAN THE FIRST ONE   
    MOVEM.L (SP)+,D1-D2
    RTS
CAPTURE2ADDRERR:
    MOVE    #-1,D0
    MOVEM.L (SP)+,D1-D2
    RTS
;----------------------------------------------------------------
;              END      CAPTURE2ADDR
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;                  PHYSICALADDR
;----------------------------------------------------------------
;INPUT  : A1 LOCATION IN MEMORY WHERE TO STORE HEX ADDRESSES
;         D0 = NUMBER OF ADDRESSES
;OUTPUT :                  
;         A2: FIRST ADDRESS
;         A3: SECOND ADDRESS
;         A1 AT END OF BUFFER +SPACE + 1 
;----------------------------------------------------------------

PHYSICALADDR:
    MOVEM.L A2/D2,-(SP)
    MOVEA   A1,A2
    MOVE    D0,D2
    LEA     PHYSICALSTR,A1
    MOVE.B  #WRITESTR,D0
    TRAP    #15
PHYSICALADDRLOOP:
    LEA     BUFFINPUT ,A1
    MOVE.L  (A2)+, D0
    MOVE    #8,D1
    JSR     HX2ASCI
    MOVE.B  #$20,(A1)+   
    MOVE.B  #$00,(A1)
    LEA     BUFFINPUT,A1
    MOVE.B  #WRITESTR,D0
    TRAP    #15
    SUBI    #1,D2
    BEQ     ENDPHYSICALADDR
    BRA     PHYSICALADDRLOOP
ENDPHYSICALADDR:
    LEA     BUFFINPUT ,A1
    MOVE.B  #$20,(A1)+
    MOVE.B  #0,(A1)   
    LEA     BUFFINPUT,A1
    MOVE.B  #WRITESTRLF,D0
    TRAP    #15
    MOVE    A2,A1
    MOVEM.L (SP)+,A2/D2
    RTS

;----------------------------------------------------------------
;              END      PHYSICALADDR
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

PRINTENTER:
    LEA     BUFFINPUT,A1
    MOVE.B  #$20,(A1)+
    MOVE.B  #$00,(A1)+
    LEA     BUFFINPUT,A1

    MOVE.B  #WRITESTRLF ,D0
    TRAP    #15    
    RTS
SYNTAXERR:
    LEA     SYNTAXSTR,A1
    MOVE.B  #WRITESTRLF  ,D0
    TRAP #15
    RTS



    SIMHALT             ; halt simulator
PROMPT      DC.B    'MONITOR441> '
            DC.W    0
BUFFINPUT   DS.B    40
            DC.B    0         
BUFFADDR    DS.L    4
            DC.B    0      
COMP_TABL:
BFSTR       DC.B    'BF '
            DC.B    0
BMOVSTR     DC.B    'BMOV '
            DC.B    0
BSCHSTR     DC.B    'BSCH '
            DC.B    0
BTSTSTR     DC.B    'BTST '
            DC.B    0
DFSTR       DC.B    'DF'
            DC.B    0
EXITSTR     DC.B    'EXIT'
            DC.B    0
GOSTR       DC.B    'GO '
            DC.B    0
HELPSTR     DC.B    'HELP' 
            DC.B    0
MDSPSTR     DC.B    'MDSP '
            DC.B    0
MMSTR       DC.B    'MM '
            DC.B    0
MSSTR       DC.B    'MS '
            DC.B    0
SORTWSTR    DC.B    'SORTW '
            DC.B    0
SYNTAXSTR   DC.B    'SYNTAX ERROR, TYPE "HELP" FOR ASSISTANCE'
            DC.B    0
COMP_ADDR   DC.W    CMDBF
            DC.W    CMDBMOV
            DC.W    CMDBSCH
            DC.W    CMDBTST 
            DC.W    CMDDF 
            DC.W    CMDEXIT 
            DC.W    CMDGO 
            DC.W    CMDHELP  
            DC.W    CMDMDSP 
            DC.W    CMDMM 
            DC.W    CMDMS 
            DC.W    CMDSORTW
PHYSICALSTR DC.W    'PHYSICAL ADDRESS='
            DC.B    0
TESTBTST    DC.W    $AAAA,$5555,$5500,$0055,$AA00,$00AA,$0000
            DC.B    0
BTSTERRSTR  DC.B    'FAILED AT '
BTSTERRADDR DS.B    8
            DC.B    ' WROTE='
WROTEBTST   DS.B    4
            DC.B    ' READ='
READBTST    DS.B    4
            DC.B    0
DFSTRING    DC.W    ' PC='
            DC.B    0        
STRWHAT     DC.B    'WHAT?'
            DC.B    $0A
            DC.B    $0D
            DC.B    0
STRASCII    DC.B    '0123456789ABCDEF'
            DC.B    0            
HELPDISPLAY DC.B    'HELP: Display this msg',$D,$A
            DC.B    'BF: Fill memory range with word data',$D,$A
            DC.B    'BF <Addr1> <Addr2> <W> e.g BF 800 900 4848<CR>',$D,$A
            DC.B    'BMOV: Move range of memory to location',$A,$D
            DC.B    'BMOV <Addr1> <Addr2> <Dest> e.g BMOV 700 800 850<CR>',$D,$A
            DC.B    'BSCH: Return first match for string in memory range',$A,$D
            DC.B    'BSCH <Addr1> <addr2> <Str> e.g BSCH 800 900 ',$27,'hi',$27,'<CR>',$D,$A
            DC.B    'BTST: Destructive R/W test in memory range',$A,$D
            DC.B    'BTST <Addr1> <Addr2> e.g BTST 800 950<CR>',$D,$A
            DC.B    'DF: Display values in reg: PC,SR,US,SP,D,A',$D,$A
            DC.B    'GO: Start Execution at given address',$A,$D
            DC.B    'GO <target addr> e.g GO 900<CR>',$D,$A
            DC.B    'MDSP: Output Address and Memory Contents',$A,$D
            DC.B    'MDSP <Addr1> <Addr2> e.g MDSP 900 9D2<CR>',$D,$A        
            DC.B    'MM: Modify memory manually ,default size byte',$A,$D
            DC.B    'MM <addr>;<sz> e.g MM 700<CR> OR MM 700;W<CR>',$D,$A
            DC.B    'MS: Write bytes in memory in Hex or ASCII',$A,$D
            DC.B    'MS <addr> <data> e.g MS 600 ',$27,'hi',$27,'<CR> OR MS 600 35C<CR>',$D,$A
            DC.B    'SORTW: Sort words in asc or desc order (A or D) in mem range',$A,$D
            DC.B    'SORTW <addr1> <addr2> <ord> e.g SORTW 600 600 D<CR>',$D,$A
            DC.B    'EXIT: Terminates Monitor Program',$A,$D          
            DC.W    0        
BUSERRSTR   DC.B    'BUS ERROR !',$A,$D   
            DC.B    0
ADDRERRSTR  DC.B    'ADDR ERROR !',$A,$D   
            DC.B    0
SSWSTR      DC.B    'SSW='
SSWINTSTR   DS.B    4
            DC.B    ' BA='
BASTR       DS.B    8
            DC.B    ' IR='
IRSTR       DS.B    8
            DC.B    0 
            DC.B    0
DIV0ERRSTR  DC.B    'DIV/0 ERROR AT LOCATION : '
            DC.B    0
ILLERRSTR   DC.B    'ILLEGAL INST ERROR AT LOCATION : '
            DC.B    0
PRVERRSTR   DC.B    'PRIVILEGE VIOLATION ERROR AT LOCATION : '
            DC.B    0
CHKERRSTR   DC.B    'CHECK ERROR AT LOCATION : '
            DC.B    0
LINEASRT    DC.B    'LINEA ERROR AT LOCATION : '
            DC.B    0  
LINEFSRT    DC.B    'LINEF ERROR AT LOCATION : '
            DC.B    0
            DC.W    0

    ORG $5000
EREDIV0:
    CLR     D0
    DIVU    D1,D0
    DIVU    D0,D1
    
    ORG $5100
ERRADDR:
    MOVE.W  #$3001,A1 ;ODD ADDRESS
    MOVE.L  #$2222,(A1)+
    
    ORG $5200
ERRBUS:
    MOVE.B  $03000000,D0
    BRA     $1000


    ORG $5300

ERRILL:
    DC.W    $4AFA
    
    ORG $5400
ERRPRIV:
    ANDI.W  #$0700,SR
    BRA     $1000
    
    ORG $5500
ERRCHK:

    MOVE.W  #$40,D7
    MOVE.W  #$30,D6
    CHK.W   D6,D7
    BRA     $1000

    ORG $5600
ERRLINEA:
    DC.W    $A000
    BRA     $1000
    ORG $5700
ERRLINEF:
    DC.W    $F000
    BRA     $1000
END:
    END    START                        ; last line of source
    
                                    








*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
