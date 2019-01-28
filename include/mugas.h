#ifndef mugas_h
#define mugas_h
#include <DLList.h>
#include <TST.h>
#include <encoder.h>


TST *instructions_names; /* table to have instructions names only (ie. mov)*/
TST *directives_names;   /* table to have directive names */
TST *instructions_table; /* table to have instructions_table_entry_t struct  */
TST *registers_table;    /* table to have reg_t struct*/
extern void mugas_init();
extern void mugas_parse();
extern void mugas_cleanup();
extern int is_instruction_name(char *key);
extern int is_directive_name(char *key);
extern reg_t *search_registers_table(char *key);
extern inst_info_t * search_instructions_table(char *key);
#endif