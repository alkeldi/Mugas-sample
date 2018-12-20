#include <stdio.h>
#include <stdlib.h>
#include <DLList.h>
#include <mugas.h>

struct DLLNode *mugas_list;
extern int yyparse(void);
void mugas_parse()
{
  yyparse();
}

void cleanup_instruction(struct instruction_s *instruction)
{
  free(instruction->opcode);
  instruction->opcode = NULL;
  DLList_free(instruction->operands_list);
  instruction->operands_list = NULL;
  free(instruction);
  instruction = NULL;
}
void cleanup_data_block(struct data_block_s *data_block)
{
  free(data_block->data_type);
  data_block->data_type = NULL;
  DLList_free(data_block->data_list);
  data_block->data_list = NULL;
  free(data_block);
  data_block = NULL;
}
void cleanup_label(struct label_s *label)
{
  free(label->name);
  label->name = NULL;
  free(label);
  label = NULL;
}
void cleanup_section_switch(struct section_switch_s *section_switch)
{
  free(section_switch->section);
  section_switch->section = NULL;
  free(section_switch);
  section_switch = NULL;
}
void cleanup_variable_declaration(struct variable_declaration_s *variable_declaration)
{
  free(variable_declaration->modifier);
  variable_declaration->modifier = NULL;
  DLList_free(variable_declaration->variables_list);
  variable_declaration->variables_list = NULL;
  free(variable_declaration);
  variable_declaration = NULL;
}
void cleanup_all_lines(DLLNode *lines_list)
{
  DLLNode *iter = lines_list->next;
  while (iter != lines_list)
  {
    struct line_s *line = (struct line_s *)iter->data;
    switch (line->type)
    {
    case LINE_TYPE_LABEL:
      cleanup_label(line->label);
      break;
    case LINE_TYPE_INSTRUCTION:
      cleanup_instruction(line->instruction);
      break;
    case LINE_TYPE_DATA_BLOCK:
      cleanup_data_block(line->data_block);
      break;
    case LINE_TYPE_SECTION_SWITCH:
      cleanup_section_switch(line->section_switch);
      break;
    case LINE_TYPE_VARIABLE_DECLARATION:
      cleanup_variable_declaration(line->variable_declaration);
      break;
    default:
      fprintf(stderr, "error: lines list contains an invalid entry\n");
      exit(1);
    }
    iter = iter->next;
  }
  DLList_free(lines_list);
}
void mugas_cleanup()
{
  cleanup_all_lines(mugas_list);
}