#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <mugas_helper.h>
#include <encoder.h>
#define get_modrm_data(modrm) ((modrm->mod) << 6) | ((modrm->reg_op) << 3) | (modrm->rm)
#define get_sib_data(sib) ((sib->scale) << 6) | ((sib->index) << 3) | (sib->base)

void print_instruction(instruction_t *instruction)
{
  if (!instruction || instruction->size == 0 || instruction->data == NULL)
  {
    printf("(empty)\n");
    return;
  }
  printf("0x");
  for (int i = 0; i < instruction->size; i++)
  {
    unsigned char byte = instruction->data[i];
    printf("%02x", byte);
  }
  printf("\n");
}

instruction_t *_make_instruction(
    instruction_prefix_t *prefix,
    instruction_opcode_t *opcode,
    instruction_modrm_t *modrm,
    instruction_sib_t *sib,
    instruction_disp_t *disp,
    instruction_imm_t *imm)
{
  /* check for errors in input */
  int error = 0;
  if (!prefix || prefix->size > 4)
    error = 1;
  else if (!opcode || opcode->size > 3)
    error = 2;
  else if (!modrm || modrm->size > 1)
    error = 3;
  else if (!sib || sib->size > 1)
    error = 4;
  else if (!disp || (disp->size != 0 && disp->size != 1 && disp->size != 2 && disp->size != 4))
    error = 5;
  else if (!imm || (imm->size != 0 && imm->size != 1 && imm->size != 2 && imm->size != 4))
    error = 6;
  
  /* action when error */
  if (error)
  {
    return NULL;
  }

  /* create instruction */
  instruction_t *instruction = malloc(sizeof(instruction_t));
  instruction->size = prefix->size + opcode->size + modrm->size + sib->size + disp->size + imm->size;
  instruction->data = malloc(instruction->size);

  /* fill instruction with prefix */
  size_t current_size = 0;
  memcpy(instruction->data + current_size, prefix->data, prefix->size);
  current_size += prefix->size;
  /* fill instruction with opcode */
  memcpy(instruction->data + current_size, opcode->data, opcode->size);
  current_size += opcode->size;
  /* fill instruction with modrm */
  unsigned char modrm_data = get_modrm_data(modrm);
  memcpy(instruction->data + current_size, &modrm_data, modrm->size);
  current_size += modrm->size;
  /* fill instruction with sib */
  unsigned char sib_data = get_sib_data(sib);
  memcpy(instruction->data + current_size, &sib_data, sib->size);
  current_size += sib->size;
  /* fill instruction with displacement */
  memcpy(instruction->data + current_size, disp->data, disp->size);
  current_size += disp->size;
  /* fill instruction with immediate value */
  memcpy(instruction->data + current_size, imm->data, imm->size);
  current_size += imm->size;

  /*verify the instruction size */
  if (current_size != instruction->size)
  {
    return NULL;
  }

  /* return the instruction pointer */
  return instruction;
}

instruction_t *make_instruction(formatted_instruction_t *formatted)
{
  if (!formatted)
    return NULL;
  return _make_instruction(&formatted->prefix, &formatted->opcode, &formatted->modrm,
                           &formatted->sib, &formatted->disp, &formatted->imm);
}

int fill_formatted_instruction_with_defaults(formatted_instruction_t *formatted, char *_default_encoding)
{
  if (!formatted || !_default_encoding)
    return 0;

  /* copy string to heap */
  size_t default_encoding_len = strlen(_default_encoding);
  char *default_encoding = malloc(default_encoding_len + 1);
  strcpy(default_encoding, _default_encoding);

  /* read information */
  int look_for_prefix = 1;
  int look_for_opcode = 1;
  int look_for_modrm = 1;
  int look_for_imm = 1;

  char *token = strtok(default_encoding, " ");
  do
  {
    
    if (!token)
      break;

    /* check errors */
    if (strlen(token) != 2)
      return 0;

    /* if a hex value */
    if (is_hex_n(token, 2))
    {
      /* check prefixes */
      if (
          (look_for_prefix) && (formatted->prefix.size < 4) &&
          (!strcmp(token, "F0") || !strcmp(token, "F2") ||
           !strcmp(token, "F3") || !strcmp(token, "2E") ||
           !strcmp(token, "36") || !strcmp(token, "3E") ||
           !strcmp(token, "26") || !strcmp(token, "64") ||
           !strcmp(token, "65") || !strcmp(token, "66") ||
           !strcmp(token, "67")))
      {
        formatted->prefix.data[formatted->prefix.size++] = hex_to_byte(token);
        continue;
      }

      /* stop looking for prefixes */
      look_for_prefix = 0;

      /* look for opcode */
      if (look_for_opcode)
      {
        formatted->opcode.data[formatted->opcode.size++] = hex_to_byte(token);
        if (!strcmp(token, "0F") || formatted->opcode.size < 3)
        {
          continue;
        }
        /* stop looking for opcode bytes */
        look_for_opcode = 0;
      }
    }
    /* if not a hex value */
    else
    {
      if (token[0] == '/' && look_for_modrm)
      {
        if (token[1] == 'r')
        {
          // formatted->modrm.reg_op = 0;
          formatted->modrm.size = 1;
          look_for_modrm = 0;
          continue;
        }
        else if (token[1] >= 48 && token[1] <= 55)
        {
          formatted->modrm.reg_op = token[1] - 48;
          formatted->modrm.size = 1;
          look_for_modrm = 0;
          continue;
        }
        else return 0;
      }
      else if (token[0] == 'i' && look_for_imm)
      {
        switch (token[1])
        {
        case 'b':
          formatted->imm.size = 1;
          look_for_modrm = 0;
          continue;
        case 'w':
          formatted->imm.size = 2;
          look_for_modrm = 0;
          continue;
        case 'd':
          formatted->imm.size = 4;
          look_for_modrm = 0;
          continue;
        default:
          return 0;
        }
      }
      else return 0;
    }
  } while ((token = strtok(NULL, " ")));

  /* cleanup */
  free(default_encoding);
  default_encoding = NULL;
  return 1;
}

int init_formatted_instruction(formatted_instruction_t *formatted, char *key){
  if(!formatted || !key)
    return 0;
  inst_info_t *info = search_instructions_table(key);

  if(!info)
    return 0;

  if(!fill_formatted_instruction_with_defaults(formatted, info->hex_encoding))
    return 0;
  return 1;
}