#include <mugas.h>
#include <stdio.h>
#include <DLList.h>

void print_instruction(struct instruction_s *instruction)
{
  printf("instruction:{\n");
  printf("\topcode: %s,\n", instruction->opcode);
  DLLNode *iter = instruction->operands_list->next;
  int i = 1;
  while (iter != instruction->operands_list)
  {
    struct operand_s *operand = (struct operand_s *)iter->data;
    printf("\toperand%d: %s", i++, operand->strval);
    if (iter->next != instruction->operands_list)
      printf(",\n");
    else
      printf("\n");
    iter = iter->next;
  }
  printf("}\n");
}
void print_data_block(struct data_block_s *data_block)
{
  printf("data_block:{\n");
  printf("\tdata_type: %s,\n", data_block->data_type);
  DLLNode *iter = data_block->data_list->next;
  int i = 1;
  while (iter != data_block->data_list)
  {
    struct datum_s *datum = (struct datum_s *)iter->data;
    printf("\tdatum%d: %s", i++, datum->strval);
    if (iter->next != data_block->data_list)
      printf(",\n");
    else
      printf("\n");
    iter = iter->next;
  }
  printf("}\n");
}
void print_label(struct label_s *label)
{
  printf("label:{\n");
  printf("\tname: %s\n", label->name);
  printf("}\n");
}
void print_section_switch(struct section_switch_s *section_switch)
{
  printf("section_switch:{\n");
  printf("\tsection: %s\n", section_switch->section);
  printf("}\n");
}
void print_variable_declaration(struct variable_declaration_s *variable_declaration)
{
  printf("variable_declaration:{\n");
  printf("\tmodifier: %s,\n", variable_declaration->modifier);
  DLLNode *iter = variable_declaration->variables_list->next;
  int i = 1;
  while (iter != variable_declaration->variables_list)
  {
    printf("\tvariable%d: %s", i++, (char *)iter->data);
    if (iter->next != variable_declaration->variables_list)
      printf(",\n");
    else
      printf("\n");
    iter = iter->next;
  }
  printf("}\n");
}
void print_all_lines(DLLNode *lines_list)
{
  DLLNode *iter = lines_list->next;
  while (iter != lines_list)
  {
    struct line_s *line = (struct line_s *)iter->data;
    switch (line->type)
    {
    case LINE_TYPE_LABEL:
      print_label(line->label);
      break;
    case LINE_TYPE_INSTRUCTION:
      print_instruction(line->instruction);
      break;
    case LINE_TYPE_DATA_BLOCK:
      print_data_block(line->data_block);
      break;
    case LINE_TYPE_SECTION_SWITCH:
      print_section_switch(line->section_switch);
      break;
    case LINE_TYPE_VARIABLE_DECLARATION:
      print_variable_declaration(line->variable_declaration);
      break;
    default:
      fprintf(stderr, "error: lines list contains an invalid entry\n");
      exit(1);
    }
    iter = iter->next;
  }
}

void mugas_log(){
  print_all_lines(mugas_list);
}