

#define NESRAMBASE   0x0000
#define NESRAMBASEM1 0x0800
#define NESRAMBASEM2 0x1000
#define NESRAMBASEM3 0x1800
#define NESRAMSIZE   0X0800

#define NESPPUBASE   0x2000
#define NESPPUSIZE   0x1FFF

#define NESAPUBASE   0x4000
#define NESAPUSIZE   0x401F

#define PRGRAMBASE   0x6000
#define PRGRAMBSZ    0x1FFF

#define JOYSTICK1               0X4016
#define JOYSTICK2_SNDSEQUENCER  0X4017

#define NBIOPORTS  (0x08 + 0x18)

#define IS_PORT(a) (((a >= 0x2000 && a < 0x2008) || \
		     (a >= 0x4000 && a < 0x4018)) && \
		    a != 0x4009 && a != 0x400D)

#define IS_PORT_RANGE(a) (a >= 0x2000 && a < 0x5000)

// Converts an IO port address into an index between 0 and 31
#define PORT2INDEX(a) ((a & 0x4000) == 0x4000? 8 + (a & 0x1F) : (a & 0x07))

#define IS_BACKUP_RAM_RANGE(a) ((a >= 0x6000) && (a < 0x8000))

#define IS_STACK_RANGE(a) ((a >= 0x0100) && (a < 0x0200))

typedef struct
{
  int  addr;
  char name[64];
}      t_nesioport;

class CnesIO
{
public:
  static bool isio(int addr);
  static const char *getioname(int addr);
public:
  static t_nesioport m_nesios[];
};
