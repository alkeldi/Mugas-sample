#ifndef mugas_log_h
#define mugas_log_h
#include <mugas.h>
void print_instruction(struct instruction_s *instruction);
void print_data_block(struct data_block_s *data_block);
void print_label(struct label_s *label);
void print_section_switch(struct section_switch_s *section_switch);
void print_variable_declaration(struct variable_declaration_s *variable_declaration);
void print_all_lines(DLLNode *lines_list);
#endif