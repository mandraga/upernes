
#define LABELSZ 128

typedef struct
{
  int  addr;
  bool is_indirectjmp;
  bool is_staticjmp;
  bool is_jsr;
  int  countijmp;
  int  countjmp;
  int  countjsr;
} t_label;

typedef std::list<t_label> t_label_list;
