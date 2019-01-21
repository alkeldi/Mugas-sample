#ifndef encoder_h
#define encoder_h
typedef struct instruction_prefix_t
{
  unsigned char size;
  unsigned char data[4];
} instruction_prefix_t;
typedef struct instruction_opcode_t
{
  unsigned char size;
  unsigned char data[3];
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
  unsigned char data[4];
} instruction_disp_t;

typedef struct instruction_imm_t
{
  unsigned char size;
  unsigned char data[4];
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
#endif