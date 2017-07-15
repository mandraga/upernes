
%{
#include <stdio.h>
#include "parse_codes.h"
#if 0
#define DEBUG_FLEX(m) printf(m)
#else
#define DEBUG_FLEX(m)
#endif
int           zznum_line;
%}

%%
[\n]                     DEBUG_FLEX("EOL\n"); zznum_line++; return (EOL);
[ ]
#.*                      DEBUG_FLEX("COMMENT\n"); return (COMMENT);
crc32:                   DEBUG_FLEX("CRC "); return (CRC);
IndirectJump:            DEBUG_FLEX("JUMP "); return (JUMP);
DisableIndJumpPatching   DEBUG_FLEX("DISJUMP\n"); return (DISJUMP);
SoundEmuLine:            DEBUG_FLEX("SOUNDLINE\n"); return (SOUNDLINE);
addr                     DEBUG_FLEX("ADDR "); return (ADDR);
$[0-9A-Fa-f]{2}          DEBUG_FLEX(" BYTE\n"); return (BYTE);
$[0-9A-Fa-f]{4}          DEBUG_FLEX(" WORD\n"); return (WORD);
$[0-9A-Fa-f]{8}          DEBUG_FLEX(" LONG\n"); return (DWORD);
%%
