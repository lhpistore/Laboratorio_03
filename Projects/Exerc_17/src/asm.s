        PUBLIC  __iar_program_start
        PUBLIC  __vector_table

        SECTION .text:CODE:REORDER(2)
        
        ;; Keep vector table even if it's not referenced
        REQUIRE __vector_table
        
        THUMB

SYSCTL_RCGCGPIO_R       EQU     0x400FE608
SYSCTL_PRGPIO_R		EQU     0x400FEA08
PORTN_BIT               EQU     1000000000000b ; bit 12 = Port N
PORTF_BIT               EQU     0000000100000b ; bit 5 = Port F

GPIO_PORTN_DATA_R    	EQU     0x40064000
GPIO_PORTN_DIR_R     	EQU     0x40064400
GPIO_PORTN_DEN_R     	EQU     0x4006451C

GPIO_PORTF_DATA_R    	EQU     0x4005D000
GPIO_PORTF_DIR_R     	EQU     0x4005D400
GPIO_PORTF_DEN_R     	EQU     0x4005D51C


__iar_program_start
        
main    
        BL init
	
        MOV R2, #00000011b ; máscara PORTN bit 0 e 1
        MOV R4, #00010001b ; máscara PORTF bit 0 e 4
        MOV R1, #00000000b ; estado PORTN
        MOV R5, #00000000b ; estado PORTF 
 	LDR R0, = GPIO_PORTN_DATA_R ; endereço PORTN
        LDR R6, = GPIO_PORTF_DATA_R ; endereço PORTF
        
        MOV R7, #0000 ; estado inicial contador
        

loop	
        AND R9, R7,#0001b
        MOV R1, R9, LSL #1 ;LED D1
        AND R9, R7, #0010b 
        ADD R1, R9, LSR #1 ;LED D2
        STR R1, [R0, R2, LSL #2] ; aciona LED N com estado atual
        
        AND R9, R7,#0100b
        MOV R5, R9, LSL #2 ;LED D3
        AND R9, R7,#1000b
        ADD R5, R5, R9, LSR #3 ;LED D4
        STR R5, [R6, R4, LSL #2] ; aciona LED F com estado atual

        MOVT R3, #0x0050 ; constante de atraso 
delay   CBZ R3, theend ; 1 clock
        SUB R3, R3, #1 ; 1 clock
        B delay ; 3 clocks

theend  ADD R7, #1
        AND R7, R7, #0001111b ; troca o estado F
        B loop


init    ;inicializações 
        PUSH {LR}
        MOV R0, #PORTN_BIT  
	BL Hab_Port ;habilita portN

        MOV R0, #PORTF_BIT  
	BL Hab_Port ;habilita portF
        
        
        LDR R0, =GPIO_PORTN_DIR_R
        LDR R1, =GPIO_PORTN_DEN_R
        MOV R2, #00000011b ; bit 0 e 1
        BL Digital_P   ;configura saídas digitais PORTN
        
        LDR R0, =GPIO_PORTF_DIR_R
        LDR R1, =GPIO_PORTF_DEN_R
        MOV R2, #00010001b ; bit 0 e 4
        BL Digital_P ;configura saídas digitais PORTF
        
        POP {PC}

Hab_Port  ; Habilita clock para porta. 
          ; Entrada: R0 - bit de endereço da porta (R0 destruído)
          PUSH {R1,LR} ; salva R1 e LR
          LDR LR, =SYSCTL_RCGCGPIO_R ; busca do endereço RCGCGPIO para LR
          LDR R1, [LR] ; leitura do estado anterior
          ORR R1, R0 ; habilita o port de R0
          STR R1, [LR] ; escrita do novo estado

          LDR LR, =SYSCTL_PRGPIO_R ; busca do endereço RCGCGPIO para LR
wait	  LDR R0, [LR] ; leitura do estado atual
          TEQ R1, R0 ; clock do port N habilitado?
          BNE wait ; caso negativo, aguarda
          POP {R1,PC}  ;fim
          
Digital_P ; Programa terminais como entrada ou saída 
          ; Entradas: R0, R1 e R2 - sendo R0 endereço GPIODIR, R1 endereço GPIOEN, R2 bits de entrada ou saída
          PUSH {LR}
          LDR LR, [R0] ; leitura do estado anterior
          ORR LR, R2 ; bit de saída
          STR LR, [R0] ; escrita do novo estado
          LDR LR, [R1] ; leitura do estado anterior
          ORR LR, R2 ; habilita função digital
          STR LR, [R1] ; escrita do novo estado
          POP {PC}  ;fim

        ;; Forward declaration of sections.
        SECTION CSTACK:DATA:NOROOT(3)
        SECTION .intvec:CODE:NOROOT(2)
        
        DATA

__vector_table
        DCD     sfe(CSTACK)
        DCD     __iar_program_start

        DCD     NMI_Handler
        DCD     HardFault_Handler
        DCD     MemManage_Handler
        DCD     BusFault_Handler
        DCD     UsageFault_Handler
        DCD     0
        DCD     0
        DCD     0
        DCD     0
        DCD     SVC_Handler
        DCD     DebugMon_Handler
        DCD     0
        DCD     PendSV_Handler
        DCD     SysTick_Handler

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Default interrupt handlers.
;;

        PUBWEAK NMI_Handler
        PUBWEAK HardFault_Handler
        PUBWEAK MemManage_Handler
        PUBWEAK BusFault_Handler
        PUBWEAK UsageFault_Handler
        PUBWEAK SVC_Handler
        PUBWEAK DebugMon_Handler
        PUBWEAK PendSV_Handler
        PUBWEAK SysTick_Handler

        SECTION .text:CODE:REORDER:NOROOT(1)
        THUMB

NMI_Handler
HardFault_Handler
MemManage_Handler
BusFault_Handler
UsageFault_Handler
SVC_Handler
DebugMon_Handler
PendSV_Handler
SysTick_Handler
Default_Handler
__default_handler
        CALL_GRAPH_ROOT __default_handler, "interrupt"
        NOCALL __default_handler
        B __default_handler

        END
