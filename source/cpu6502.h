
#define UNKNOWN (-1)
#define MAX_INSTR_SIZE 3
#define STACK_START 0x100
#define STACK_STOP  0x1FF

#define VECTOR_ADDR_NMI      0xFFFA
#define VECTOR_ADDR_RESET    0xFFFC
#define VECTOR_ADDR_IRQ_BRK  0xFFFE

class Ccpu6502
{
  //public:
  //  Ccpu6502();
  //~Ccpu6502();
public:
  int Acc;
  int X;
  int Y;
  int status;
  int SP;
  int PC; 
};

