#include <parser.h>
#include <mugas_helper.h>
#include <encoder.h>
#include <mugas.h>

  memory32_token_t * init_memory32(){
    memory32_token_t *mem = malloc(sizeof(memory32_token_t));
    memset(mem, 0, sizeof(memory32_token_t));
    return mem;
  }

  int verify_memory32_modrm(memory32_token_t *memory){
    if(memory->structure == MODRM_REG){
      /* reg can't be esp nor ebp "not 4 nor 5"*/
      if(memory->rm.reg.reg_value == 4 || memory->rm.reg.reg_value == 5)
        ERROR_WITH_TOKEN(&memory->rm.token, "Bad register.");
      memory->mod = 0;
    }
    else if(memory->structure == MODRM_DISP){
      /* for disp only, the rm register should be ebp , and the disp size can be 8, 16, or 32*/
      int sz = get_number_size(memory->disp.num);
      if(sz == 8 || sz == 16 || sz == 32){
        memory->mod = 0;
        memory->rm.reg.reg_value = 5;
        int sz = get_number_size(memory->disp.num);
      }
      else ERROR_WITH_TOKEN(&memory->disp.token, "Bad displacement.");

    }
    else if(memory->structure == MODRM_REG_AND_DISP){
      /* reg can't be esp "4" */
      if(memory->rm.reg.reg_value == 4 ){
        ERROR_WITH_TOKEN(&memory->rm.token, "Bad register.");
      }
      /* disp size can be 8, 16, or 32 */
      int sz = get_number_size(memory->disp.num);
      if(sz == 8)
        memory->mod = 1;
      else if(sz == 16 || sz == 32)
        memory->mod = 2;
      else ERROR_WITH_TOKEN(&memory->disp.token, "Bad displacement.");
    }
  }
  int verify_memory32_sib(memory32_token_t *memory){
    if(memory->structure == SIB_BASE){
      /* scale must be 1, 2, 4, 8; and index can't be esp "4"; base can't be ebp "5"*/
      if(memory->scale.num != 1 && memory->scale.num != 2 && memory->scale.num != 4 && memory->scale.num != 8)
         ERROR_WITH_TOKEN(&memory->scale.token, "Bad memory scale.");
      if(memory->index.reg.reg_value == 4)
        ERROR_WITH_TOKEN(&memory->index.token, "Bad index register.");
      if(memory->base.reg.reg_value == 5)
        ERROR_WITH_TOKEN(&memory->base.token, "Bad base register.");
      /* good to go */
      memory->mod = 0;
      memory->rm.reg.reg_value = 4;
    }
    else if(memory->structure == SIB_DISP){
      /* scale must be 1, 2, 4, 8; and index can't be esp "4"; base must be ebp "5"*/
      if(memory->scale.num != 1 && memory->scale.num != 2 && memory->scale.num != 4 && memory->scale.num != 8)
         ERROR_WITH_TOKEN(&memory->scale.token, "Bad memory scale.");
      if(memory->index.reg.reg_value == 4)
        ERROR_WITH_TOKEN(&memory->index.token, "Bad index register.");
      /* good to go */
      memory->mod = 0;
      memory->rm.reg.reg_value = 4;
      memory->base.reg.reg_value = 5;
    }
    else if(memory->structure == SIB_BASE_AND_DISP){
      /* scale must be 1, 2, 4, 8; and index can't be esp "4"*/
      if(memory->scale.num != 1 && memory->scale.num != 2 && memory->scale.num != 4 && memory->scale.num != 8)
         ERROR_WITH_TOKEN(&memory->scale.token, "Bad memory scale.");
      if(memory->index.reg.reg_value == 4)
        ERROR_WITH_TOKEN(&memory->index.token, "Bad index register.");
      /* disp size can be 8, 16, or 32 */
      int sz = get_number_size(memory->disp.num);
      if(sz == 8)
        memory->mod = 1;
      else if(sz == 16 || sz == 32)
        memory->mod = 2;
      else ERROR_WITH_TOKEN(&memory->disp.token, "Bad displacement.");
      /* good to go */
      memory->rm.reg.reg_value = 4;

    }
  }


instruction_t * get_instruction0(token_t *opcode){
  formatted_instruction_t formatted;
  memset(&formatted, 0, sizeof(formatted_instruction_t));

  /* make key */
  char key[opcode->len+1];
  to_upper_case(opcode->text, key);

  inst_info_t *info = search_instructions_table(key);
  if(!fill_formatted_instruction_with_defaults(&formatted, info->hex_encoding))
    return NULL;

  return make_instruction(&formatted);
}