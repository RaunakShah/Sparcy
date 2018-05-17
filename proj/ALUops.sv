`ifndef __alu__ops
`define __alu__ops

// macro definitions for op3
//define for CALL before using

`define AND 6'b000001 // need to change this one too
`define ANDcc 6'b010001
`define ANDN 6'b000101
`define ANDNcc 6'b010101
`define OR 6'b000010
`define ORcc 6'b010010
`define ORN 6'b000110
`define ORNcc 6'b010110
`define XOR 6'b000011
`define XORcc 6'b010011
`define XNOR 6'b000111
`define XNORcc 6'b010111
`define SLL 6'b100101
`define SRL 6'b100110
`define SRA 6'b100111
`define ADD 6'b000000
`define ADDcc 6'b010000
`define ADDX 6'b001000
`define ADDXcc 6'b011000
`define TADDcc 6'b100000
`define TADDccTV 6'b100010
`define SUB 6'b000100
`define SUBcc 6'b010100
`define SUBX 6'b001100
`define SUBXcc 6'b011100
`define TSUBcc 6'b100001
`define TSUBccTV 6'b100011
`define MULScc 6'b100100
`define UMUL 6'b001010
`define SMUL 6'b001011
`define UMULcc 6'b011010
`define SMULcc 6'b011011
`define UDIV 6'b001110
`define SDIV 6'b001111
`define UDIVcc 6'b011110
`define SDIVcc 6'b011111
`define SAVE 6'b111100
`define RESTORE 6'b111101
`define JMPL 6'b111000
`define SETHI 3'b100
`define RETT 6'b111001
`define LDSB 6'b001001
`define LDSH 6'b001010
`define LDUB 6'b000001
`define LDUH 6'b000010
`define LD 6'b000000
`define LDD 6'b000011
`define STB 6'b000101
`define STH 6'b000110
`define ST 6'b000100
`define STD 6'b000111
`define LDSTUB 6'b001101
`define SWAP 6'b001111
`define BA 4'b1000
`define BN 4'b0000
`define BNE 4'b1001
`define BE 4'b0001
`define BG 4'b1010
`define BLE 4'b0010
`define BGE 4'b1011
`define BL 4'b0011
`define BGU 4'b1100
`define BLEU 4'b0100
`define BCC 4'b1101
`define BCS 4'b0101
`define BPOS 4'b1110
`define BNEG 4'b0110
`define BVC 4'b1111
`define BVS 4'b0111
`define TA 4'b1000
`define TN 4'b0000
`define TNE 4'b1001
`define TE 4'b0001
`define TG 4'b1010
`define TLE 4'b0010
`define TGE 4'b1011
`define TL 4'b0011
`define TGU 4'b1100
`define TLEU 4'b0100
`define TCC 4'b1101
`define TCS 4'b0101
`define TPOS 4'b1110
`define TNEG 4'b0100
`define TVC 4'b1111
`define TVS 4'b0111
`define RDY 6'b101000
`define WRY 6'b110000
`define FLUSH 6'b111011


`endif
