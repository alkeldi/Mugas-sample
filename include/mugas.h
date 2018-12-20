#ifndef mugas_h
#define mugas_h
#include <DLList.h>
extern struct DLLNode *mugas_list;
struct operand_s
{
  int type;
  char *strval;
};
struct datum_s
{
  int type;
  char *strval;
};

struct instruction_s
{
  char *opcode;
  struct DLLNode *operands_list;
};

struct data_block_s
{
  char *data_type;
  struct DLLNode *data_list;
};

struct label_s
{
  char *name;
};

struct variable_declaration_s
{
  char *modifier;
  struct DLLNode *variables_list;
};

struct section_switch_s
{
  char *section;
};

enum line_type
{
  LINE_TYPE_LABEL,
  LINE_TYPE_DATA_BLOCK,
  LINE_TYPE_INSTRUCTION,
  LINE_TYPE_VARIABLE_DECLARATION,
  LINE_TYPE_SECTION_SWITCH
};

struct line_s
{
  enum line_type type;
  union {
    struct label_s *label;
    struct data_block_s *data_block;
    struct instruction_s *instruction;
    struct variable_declaration_s *variable_declaration;
    struct section_switch_s *section_switch;
  };
};

void mugas_parse();
void cleanup_instruction(struct instruction_s *instruction);
void cleanup_data_block(struct data_block_s *data_block);
void cleanup_label(struct label_s *label);
void cleanup_section_switch(struct section_switch_s *section_switch);
void cleanup_variable_declaration(struct variable_declaration_s *variable_declaration);
void cleanup_all_lines(DLLNode *lines_list);
void mugas_cleanup();
#endif