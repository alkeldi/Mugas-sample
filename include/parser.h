#ifndef parser_h
#define parser_h
#include <mugas.h>
#include <encoder.h>

typedef struct token_t {
  char * text;
  size_t len;
  size_t line;
  size_t column;
} token_t;

typedef struct instruction_imm_t_t {
  instruction_imm_t imm;
  token_t token;
}instruction_imm_t_t;

typedef struct instruction_reg_t_t
{
  reg_t reg;
  token_t token;
} instruction_reg_t_t;

typedef struct instruction_mem_t_t
{
  instruction_modrm_t modrm;
  instruction_sib_t sib;
  instruction_disp_t disp;
  token_t token;
} instruction_mem_t_t;

enum operand_type {
  REG_OP, MEM_OP, IMM_OP
};

typedef struct instruction_operand_t_t {
  enum operand_type type;
  union{
    instruction_reg_t_t *reg;
    instruction_mem_t_t *mem;
    instruction_imm_t_t *imm;
  };
}instruction_operand_t_t;

/******** functions ********/
instruction_imm_t_t * reduce_math_expression(instruction_imm_t_t *imm1, instruction_imm_t_t *imm2, char operation);
#endif