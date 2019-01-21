#ifndef mugas_h
#define mugas_h
#include <DLList.h>
#include <TST.h>

#define MAX_REG_NAME_LEN 7
#define MAX_REG_TYPE_LEN 7
#define MAX_HEX_ENCODING_LEN 63
#define MAX_READABLE_ENCODING_LEN 63

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