#ifndef mugas_types_h
#define mugas_types_h

/****************************************************** Operand *****************************************************/
#define MAX_OPERAND_TYPE_LEN 7

/************************************************ instructions table ************************************************/
#define MAX_HEX_ENCODING_LEN 63
#define MAX_READABLE_ENCODING_LEN 63
typedef struct instructions_table_entry_t
{
  char hex_encoding[MAX_HEX_ENCODING_LEN + 1];
  char readable_encoding[MAX_READABLE_ENCODING_LEN + 1];
  /* TODO other fields from intstructions.txt */
} instructions_table_entry_t;

/************************************************** registers table *************************************************/
#define MAX_REG_NAME_LEN 7
#define MAX_REG_TYPE_LEN 7
typedef struct registers_table_entry_t
{
  unsigned char reg_value;
  char reg_name[MAX_REG_NAME_LEN + 1];
  char reg_type[MAX_REG_TYPE_LEN + 1];
} registers_table_entry_t;

#endif