#include <stdlib.h>
#include <mugas.h>
#include <mugas_helper.h>
#include <mugas_types.h>
#include <stdio.h>

extern int yyparse(void);

/* initialize instructions table */
TST *init_instructions_table(char *instructions_file)
{
  if (!instructions_file)
    return NULL;

  /* open instructions file*/
  FILE *inst_f = fopen(instructions_file, "r");
  if (!inst_f)
    return NULL;

  /* init opcodes table */
  TST *instructions_table = TST_init();
  TSTInfo *instructions_table_info = (TSTInfo *)instructions_table->data;

  /* prepare for reading line */
  char *line = NULL;
  size_t buff_capacity = 0;
  size_t line_len;

  /* init the instructions_names -> defined in mugas.h*/
  instructions_names = TST_init();

  /* read line by line */
  while ((line_len = getline(&line, &buff_capacity, inst_f)) != EOF)
  {
    /* ignore empty and commented lines */
    if (is_ignored(line, line_len))
      continue;

    /* get relevant fields from the line */
    char *hex_encoding = strtok(line, "|");
    char *readable_encoding = strtok(NULL, "|");
    /* TODO other fields from intstructions.txt */
    /* remove terminating spaces */
    rtrim(hex_encoding);
    rtrim(readable_encoding);

    /* add instruction into instructions_names table */
    char *instruction_name = strtok(readable_encoding, ", ");
    if (!instruction_name)
    {
      instruction_name = readable_encoding;
    }
    TST_put(instructions_names, instruction_name, NULL);

    /* create instruction table entry */
    instructions_table_entry_t *table_entry = malloc(sizeof(instructions_table_entry_t));
    memset(table_entry, 0, sizeof(instructions_table_entry_t));
    strcpy(table_entry->hex_encoding, hex_encoding);
    strcpy(table_entry->readable_encoding, readable_encoding);

    /* keep track of mallocs */
    SLL_insert(instructions_table_info->memory_allocations, table_entry);

    /* add entry to table */
    TST_put(instructions_table, readable_encoding, table_entry);
  }
  /* free line if buffer is allocated */
  if (line)
    free(line);
  /* close instructions file */
  fclose(inst_f);
  return instructions_table;
}

TST *init_registers_table(char *registers_file)
{
  if (!registers_file)
    return NULL;

  /* open registers file */
  FILE *reg_f = fopen(registers_file, "r");
  if (!reg_f)
    return NULL;

  /* init registers table */
  TST *registers_table = TST_init();
  TSTInfo *registers_table_info = (TSTInfo *)registers_table->data;

  /* prepare for reading line */
  char *line = NULL;
  size_t buff_capacity = 0;
  size_t line_len;

  /* read line by line */
  while ((line_len = getline(&line, &buff_capacity, reg_f)) != EOF)
  {
    /* ignore empty and commented lines */
    if (is_ignored(line, line_len))
      continue;

    /* get relevant fields from the line */
    char *reg_name = strtok(line, "|");
    char *reg_value = strtok(NULL, "|");
    char *reg_type = strtok(NULL, "|");

    /* remove terminating spaces */
    rtrim(reg_name);
    rtrim(reg_value);
    rtrim(reg_type);

    /* create register table entry */
    registers_table_entry_t *table_entry = malloc(sizeof(registers_table_entry_t));
    memset(table_entry, 0, sizeof(registers_table_entry_t));
    strcpy(table_entry->reg_name, reg_name);
    strcpy(table_entry->reg_type, reg_type);
    table_entry->reg_value = (unsigned char)atoi(reg_value);

    /* keep track of mallocs */
    SLL_insert(registers_table_info->memory_allocations, table_entry);

    /* add entry to table */
    TST_put(registers_table, reg_name, table_entry);
  }
  /* free line if buffer is allocated */
  if (line)
    free(line);
  /* close registers file */
  fclose(reg_f);
  return registers_table;
}

TST *init_directives_names(char *directives_file)
{
  if (!directives_file)
    return NULL;

  /* open registers file */
  FILE *dir_f = fopen(directives_file, "r");
  if (!dir_f)
    return NULL;

  /* init registers table */
  TST *directives_names = TST_init();

  /* prepare for reading line */
  char *line = NULL;
  size_t buff_capacity = 0;
  size_t line_len;
  while ((line_len = getline(&line, &buff_capacity, dir_f)) != EOF)
  {
    /* ignore empty and commented lines */
    if (is_ignored(line, line_len))
      continue;

    /* line should contain only the directive's name */
    rtrim(line);

    /* add entry to table */
    TST_put(directives_names, line, NULL);
  }

  return directives_names;
}

/* search for a register - key should be captilized */
registers_table_entry_t *search_registers_table(char *key)
{
  return TST_get(registers_table, key);
}

/* check if str is an instruction keyword (ie. mov)*/
int is_instruction_name(char *key)
{
  return TST_contains(instructions_names, key) ? 1 : 0;
}

/* check if str is a directive keyword (ie. .section)*/
int is_directive_name(char *key)
{
  return TST_contains(directives_names, key) ? 1 : 0;
}

void mugas_init()
{
  instructions_table = init_instructions_table("../data/instructions.txt");
  registers_table = init_registers_table("../data/registers.txt");
  directives_names = init_directives_names("../data/directives.txt");
}

void mugas_parse()
{
  yyparse();
}

void mugas_cleanup()
{

  if (registers_table)
  {
    TST_free(registers_table);
    registers_table = NULL;
  }
  if (instructions_table)
  {
    TST_free(instructions_table);
    instructions_table = NULL;
  }
  if (directives_names)
  {
    TST_free(directives_names);
    directives_names = NULL;
  }
}