#ifndef encoder_h
#define encoder_h
/* TODO, use these value everywhere in encoder.c */
#define MAX_PREFIX_SIZE 4
#define MAX_OPCODE_SIZE 3
#define MAX_DISP_SIZE 4
#define MAX_IMM_SIZE 4
#define MAX_REG_NAME_LEN 7
#define MAX_REG_TYPE_LEN 7
#define MAX_HEX_ENCODING_LEN 63
#define MAX_READABLE_ENCODING_LEN 63
typedef long long int integer;

typedef struct reg_t
{
  unsigned char reg_value;
  char reg_name[MAX_REG_NAME_LEN + 1];
  char reg_type[MAX_REG_TYPE_LEN + 1];
} reg_t;


typedef struct inst_info_t
{
  char hex_encoding[MAX_HEX_ENCODING_LEN + 1];
  char readable_encoding[MAX_READABLE_ENCODING_LEN + 1];
} inst_info_t;

typedef struct instruction_prefix_t
{
  unsigned char size;
  unsigned char data[MAX_PREFIX_SIZE];
} instruction_prefix_t;
typedef struct instruction_opcode_t
{
  unsigned char size;
  unsigned char data[MAX_OPCODE_SIZE];
} instruction_opcode_t;
typedef struct instruction_modrm_t
{
  unsigned char size;
  unsigned char mod;
  unsigned char reg_op;
  unsigned char rm;
} instruction_modrm_t;
typedef struct instruction_sib_t
{
  unsigned char size;
  unsigned char scale;
  unsigned char index;
  unsigned char base;
} instruction_sib_t;
typedef struct instruction_disp_t
{
  unsigned char size;
  unsigned char data[MAX_DISP_SIZE];
} instruction_disp_t;

typedef struct instruction_imm_t
{
  unsigned char size;
  unsigned char data[MAX_IMM_SIZE];
} instruction_imm_t;
typedef struct formatted_instruction_t
{
  instruction_prefix_t prefix;
  instruction_opcode_t opcode;
  instruction_modrm_t modrm;
  instruction_sib_t sib;
  instruction_disp_t disp;
  instruction_imm_t imm;
} formatted_instruction_t;

typedef struct instruction_t {
  unsigned char size;
  unsigned char *data;
} instruction_t;

extern void print_instruction(instruction_t *instruction);
extern instruction_t *make_instruction(formatted_instruction_t *formatted);
extern int fill_formatted_instruction_with_defaults(formatted_instruction_t *formatted, char *_default_encoding);
extern int init_formatted_instruction(formatted_instruction_t *formatted, char *key);
#endif