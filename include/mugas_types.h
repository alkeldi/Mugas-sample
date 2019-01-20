#ifndef mugas_types_h
#define mugas_types_h

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
/****************************************************** TOKEN ******************************************************/
typedef struct token_t {
  char * text;
  size_t len;
  size_t line;
  size_t column;
} token_t;
/*************************************************** INTEGER TOKEN *************************************************/
typedef struct integer_token_t {
  long long int  num;
  token_t token;
}integer_token_t;
/************************************************** REGISTER TOKEN *************************************************/
typedef struct register_token_t {
  registers_table_entry_t  reg;
  token_t token;
}register_token_t;
/************************************************** MEMORY TOKEN *************************************************/
enum memory32_types{
  SIB_BASE, SIB_DISP, SIB_BASE_AND_DISP,
  MODRM_REG, MODRM_DISP, MODRM_REG_AND_DISP
};
typedef struct memory32_token_t {
  /* type */
  enum memory32_types type;

  /* mod_rm */
  unsigned char mod;
  registers_table_entry_t rm_reg;

  /* sib */
  long long int scale;
  registers_table_entry_t index;
  registers_table_entry_t base;

  /* disp*/
  long long int  disp;

  /* info */
  token_t token;
} memory32_token_t;
#endif