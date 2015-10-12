
#define CYCLE_STR_SZ 4
#define MNEMONIC_STR_SZ 4

typedef struct	s_ops
{
  int           memaccess;
  char		pstr_call[32];
  unsigned char opcode;
  int           size_B;
  char          cycles[3];
}		t_ops;

class Cmnemonic_6502
{
public:
  Cmnemonic_6502();
  ~Cmnemonic_6502();

public:
  char          mnemonic[MNEMONIC_STR_SZ];
  unsigned char Flags;
  t_ops         ops[13];
  int           nb_ops;
  int           category;
  char          pstr_description[512];
};

