#include <parser.h>
#include <mugas_helper.h>
#include <encoder.h>
#include <mugas.h>
#include <string.h>

instruction_t * get_instruction0(token_t *opcode){
  formatted_instruction_t formatted;
  memset(&formatted, 0, sizeof(formatted_instruction_t));

  /* make key */
  char key[MAX_READABLE_ENCODING_LEN];
  to_upper_case(opcode->text, key);

  if(init_formatted_instruction(&formatted, key))
    return make_instruction(&formatted);
  else return NULL;
}

instruction_t * get_instruction1(token_t *opcode, instruction_operand_t_t *operand1){
  formatted_instruction_t formatted;
  memset(&formatted, 0, sizeof(formatted_instruction_t));
  char key[MAX_READABLE_ENCODING_LEN];

  if(operand1->type == REG_OP){
    //init_formatted_instruction would overwrite one of them or both if needed
    formatted.modrm.rm = operand1->reg->reg.reg_value;
    formatted.modrm.reg_op = operand1->reg->reg.reg_value;

    //try reg name
    to_upper_case(opcode->text, key);
    strcat(key, " ");
    strcat(key, operand1->reg->reg.reg_name);
    if(init_formatted_instruction(&formatted, key)){
      //no formatting needed when reg name matched
      return make_instruction(&formatted);
    }

    //try r/m32
    to_upper_case(opcode->text, key);
    strcat(key, " r/m32");
    if(init_formatted_instruction(&formatted, key)){
      return make_instruction(&formatted);
    }

    //try r32
    to_upper_case(opcode->text, key);
    strcat(key, " r32");
    if(init_formatted_instruction(&formatted, key)){
      return make_instruction(&formatted);
    }

    //error
    ERROR_WITH_TOKEN(NULL, "bad operand.");
  }
  else if(operand1->type == IMM_OP){
    formatted.imm = operand1->imm->imm;
    //try imm8
    if(operand1->imm->imm.size == 1){
      to_upper_case(opcode->text, key);
      strcat(key, " imm8");
      if(init_formatted_instruction(&formatted, key)){
        return make_instruction(&formatted);
      }
    }

    //try imm32
    if(operand1->imm->imm.size == 1){
      to_upper_case(opcode->text, key);
      strcat(key, " imm32");
      if(init_formatted_instruction(&formatted, key)){
        return make_instruction(&formatted);
      }
    }

    //error
    ERROR_WITH_TOKEN(NULL, "bad operand.");
  }
  else if(operand1->type == MEM_OP){
    formatted.modrm = operand1->mem->modrm;
    formatted.sib = operand1->mem->sib;
    formatted.disp = operand1->mem->disp;
    //try r/m32
    to_upper_case(opcode->text, key);
    strcat(key, " ");
    strcat(key, "r/m32");
    if(init_formatted_instruction(&formatted, key)){
      return make_instruction(&formatted);
    }
    //TODO try m32 and others
    ERROR_WITH_TOKEN(NULL, "bad operand.");
  }


}
