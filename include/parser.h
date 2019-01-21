#ifndef parser_h
#define parser_h
#include <mugas.h>
#include <encoder.h>

enum memory32_structure{
  SIB_BASE, SIB_DISP, SIB_BASE_AND_DISP,
  MODRM_REG, MODRM_DISP, MODRM_REG_AND_DISP
};

enum operand_type {
  MEMORY, REGISTER, IMMEDIATE
};

typedef struct token_t {
  char * text;
  size_t len;
  size_t line;
  size_t column;
} token_t;

typedef struct integer_token_t {
  long long int  num;
  token_t token;
}integer_token_t;

typedef struct reg_token_t {
  reg_t  reg;
  token_t token;
}reg_token_t;


typedef struct memory32_token_t {
  enum memory32_structure structure; 
  unsigned char mod; 
  reg_token_t rm;
  integer_token_t scale;
  reg_token_t index;
  reg_token_t base;
  integer_token_t  disp;
} memory32_token_t;

typedef struct operand_token_t {
  enum operand_type type;
  union {
    memory32_token_t mem;
    reg_token_t reg;
    integer_token_t imm;
  };
}operand_token_t;


 memory32_token_t * init_memory32();
extern int verify_memory32_modrm(memory32_token_t *memory);
extern int verify_memory32_sib(memory32_token_t *memory);
extern instruction_t * get_instruction0(token_t *opcode);
#endif