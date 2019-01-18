#ifndef mugas_h
#define mugas_h
#include <DLList.h>
#include <TST.h>
#include <mugas_types.h>

TST *instructions_names; /* table to have instructions names only (ie. mov)*/
TST *directives_names;   /* table to have directive names */
TST *instructions_table; /* table to have instructions_table_entry_t struct  */
TST *registers_table;    /* table to have registers_table_entry_t struct*/
void mugas_init();
void mugas_parse();
void mugas_cleanup();
int is_instruction_name(char *key);
int is_directive_name(char *key);
registers_table_entry_t *search_registers_table(char *key);
#endif