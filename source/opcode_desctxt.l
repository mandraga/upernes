
%{
#include <stdio.h>
#include "parse_codes.h"
#if 0
#define DEBUG_FLEX(m) printf(m)
#else
#define DEBUG_FLEX(m)
#endif
int           num_line;
unsigned char Bflags;
%}

%x sopcode
%x sdescription
%x smemuse
%x smemc
%x sopstr
%x sflags
%%
[\n]                     DEBUG_FLEX("EOL\n"); num_line++; return (EOL);
[;]                      DEBUG_FLEX("SEMCOL "); return (SEMCOL);
[ ]
#.*                      DEBUG_FLEX("COMMENT "); return (COMMENT);
Arithmetic:              DEBUG_FLEX("TYPE_ARITHMETIC "); return (ARITHMETIC);
Logic:                   DEBUG_FLEX("TYPE_LOGIC "); return (LOGIC);
Move:                    DEBUG_FLEX("TYPE_MOVE "); return (MOVE);
Stack:                   DEBUG_FLEX("TYPE_STACK "); return (STACK);
Flags:                   {
                           DEBUG_FLEX("TYPE_FLAGS ");
                           BEGIN(sflags);
                           Bflags = 0;
                           return (FLAGS);
}
Jump:                    DEBUG_FLEX("TYPE_JUMP "); return (JUMP);
Interrupt:               DEBUG_FLEX("TYPE_INTERRUPT "); return (INTERRUPT);
<INITIAL,sflags>Opcode:  DEBUG_FLEX("OPCODEDEF "); BEGIN(sopcode); return (OPCODEDEF);
Description:             DEBUG_FLEX("DESCRIPTION "); BEGIN(sdescription); return (DESCRIPTION);
Implied|Imm|Acc|PCR|zp|zpX|zpY|Abs|AbsX|AbsY|Ind|IndX|IndY DEBUG_FLEX("MEM_USAGE "); BEGIN(smemc); return (MEMUSE);
<smemc>[;]               BEGIN(sopstr);
<sdescription>.*\n       DEBUG_FLEX(" DESCRIPTION_TXT\n");  num_line++; BEGIN(INITIAL); return (DESCRIPTION_TXT);
<sopcode>{
[a-zA-Z]{3}[ \t]*[\n]    DEBUG_FLEX(" OPCODESTR\n"); num_line++; BEGIN(INITIAL); return (OPCODESTR);
[ ]
}
<sopstr>{
[^;]*                    DEBUG_FLEX(" opstr "); return (OPSTR);
[;]                      DEBUG_FLEX("SEMCOL "); BEGIN(smemuse);
}
<smemuse>{
$[0-9A-Fa-f]{2}          DEBUG_FLEX(" Byte "); return (BYTE);
[1-9][+]*                DEBUG_FLEX(" Number "); return (NUMBER);
[;]                      DEBUG_FLEX("SEMCOL ");
[\n]                     DEBUG_FLEX(" EOL\n");  num_line++; BEGIN(INITIAL); return (EOL);
[ ]|[\t]
}
<sflags>{
all                      DEBUG_FLEX(" All flags "); Bflags = 0xFF;
C                        Bflags |= 0x01;
Z                        Bflags |= 0x02;
I                        Bflags |= 0x04;
D                        Bflags |= 0x08;
B                        Bflags |= 0x10;
S                        Bflags |= 0x20;
V                        Bflags |= 0x40;
N                        Bflags |= 0x80;
[ ]
[\n]                     {
                           DEBUG_FLEX(" EOL\n");
                           num_line++;
                           BEGIN(INITIAL);
                           return(EOL);
                         }
}

%%
