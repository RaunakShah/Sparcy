`ifndef __alu__ops
`define __alu__ops

// macro definitions for op3

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


`endif
