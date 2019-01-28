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
    return NULL;
  }
  else if(operand1->type == IMM_OP){
    formatted.imm = operand1->imm->imm;
    if(formatted.imm.size == 2) formatted.imm.size = 4; //no 16bits
    
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
    return NULL;
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
    return NULL;
  }


}

instruction_t * get_instruction2(token_t *opcode, instruction_operand_t_t *operand1, instruction_operand_t_t *operand2){
  formatted_instruction_t formatted;
  memset(&formatted, 0, sizeof(formatted_instruction_t));
  char key[MAX_READABLE_ENCODING_LEN];
  if(operand1->type == REG_OP){
    if(operand2->type == REG_OP){
      //try r/m32, r32
      formatted.modrm.mod = 0b11;
      formatted.modrm.reg_op = operand2->reg->reg.reg_value;
      formatted.modrm.rm = operand1->reg->reg.reg_value;
      to_upper_case(opcode->text, key);
      strcat(key, " r/m32, r32");
      if(init_formatted_instruction(&formatted, key)){
        //no formatting needed when reg name matched
        return make_instruction(&formatted);
      }

      //try r32, r/m32
      formatted.modrm.mod = 0b11;
      formatted.modrm.reg_op = operand1->reg->reg.reg_value;
      formatted.modrm.rm = operand2->reg->reg.reg_value;
      to_upper_case(opcode->text, key);
      strcat(key, " r32, r/m32");
      if(init_formatted_instruction(&formatted, key)){
        return make_instruction(&formatted);
      }

      return NULL;
      //TODO try other  memories 
    }
    else if(operand2->type == IMM_OP){
      //try name, imm
      formatted.modrm.mod = 0b11;
      formatted.modrm.rm = operand1->reg->reg.reg_value;
      formatted.imm = operand2->imm->imm;
      if(formatted.imm.size == 2) formatted.imm.size = 4; //no 16bits

      to_upper_case(opcode->text, key);
      strcat(key, " ");
      strcat(key, operand1->reg->reg.reg_name);
      if(formatted.imm.size == 1)
        strcat(key, ", imm8");
      else if(formatted.imm.size == 4)
        strcat(key, ", imm32");
      else ERROR_WITH_TOKEN(NULL, "get_instruction2: bad imm size.2");
      if(init_formatted_instruction(&formatted, key)){
        return make_instruction(&formatted);
      }

      //try r/m32, imm
      formatted.modrm.mod = 0b11;
      formatted.modrm.rm = operand1->reg->reg.reg_value;
      to_upper_case(opcode->text, key);
      if(formatted.imm.size == 1)
        strcat(key, " r/m32, imm8");
      else if(formatted.imm.size == 4)
        strcat(key, " r/m32, imm32");
      else ERROR_WITH_TOKEN(NULL, "get_instruction2: bad imm size.3");
      if(init_formatted_instruction(&formatted, key)){
        return make_instruction(&formatted);
      }

      //try r32, imm
      formatted.modrm.mod = 0b11;
      formatted.modrm.reg_op = operand1->reg->reg.reg_value;
      to_upper_case(opcode->text, key);
      if(formatted.imm.size == 1)
        strcat(key, " r32, imm8");
      else if(formatted.imm.size == 4)
        strcat(key, " r32, imm32");
      else ERROR_WITH_TOKEN(NULL, "get_instruction2: bad imm size.4");
      if(init_formatted_instruction(&formatted, key)){
        return make_instruction(&formatted);
      }

      // try to override size to 4 for r/m32
      formatted.modrm.mod = 0b11;
      formatted.modrm.rm = operand1->reg->reg.reg_value;
      formatted.imm.size = 4;
      to_upper_case(opcode->text, key);
      strcat(key, " r/m32, imm32");
      if(init_formatted_instruction(&formatted, key)){
        return make_instruction(&formatted);
      }


      //try to override size to 4 for r32
      formatted.modrm.mod = 0b11;
      formatted.modrm.reg_op = operand1->reg->reg.reg_value;
      formatted.imm.size = 4;
      to_upper_case(opcode->text, key);
      strcat(key, " r32, imm32");
      if(init_formatted_instruction(&formatted, key)){
        formatted.imm.size = 4;
        return make_instruction(&formatted);
      }

      return NULL;
    }
    else if(operand2->type == MEM_OP){
      //try r32, r/m32
      formatted.modrm = operand2->mem->modrm;
      formatted.sib = operand2->mem->sib;
      formatted.disp = operand2->mem->disp;
      formatted.modrm.reg_op = operand1->reg->reg.reg_value;
      to_upper_case(opcode->text, key);
      strcat(key, " r32, r/m32");
      if(init_formatted_instruction(&formatted, key)){
        return make_instruction(&formatted);
      }
      else ERROR_WITH_TOKEN(NULL, "get_instruction2: bad operand.");
      //TODO other memories
    }
    else ERROR_WITH_TOKEN(NULL, "get_instruction2: bad operand");
  }
  else if(operand1->type == IMM_OP){
    ERROR_WITH_TOKEN(NULL, "get_instruction2: bad operand.");
  }
  else if(operand1->type == MEM_OP){
    if(operand2->type == REG_OP){
      //try r/m32, r32
      formatted.modrm = operand1->mem->modrm;
      formatted.sib = operand1->mem->sib;
      formatted.disp = operand1->mem->disp;
      formatted.modrm.reg_op = operand2->reg->reg.reg_value;
      to_upper_case(opcode->text, key);
      strcat(key, " r/m32, r32");
      if(init_formatted_instruction(&formatted, key)){
        return make_instruction(&formatted);
      }
      return NULL;
      //TODO other memories
    }
    else if(operand2->type == IMM_OP){
      //try r/m32, imm
      formatted.modrm = operand1->mem->modrm;
      formatted.sib = operand1->mem->sib;
      formatted.disp = operand1->mem->disp;
      formatted.imm = operand2->imm->imm;
      if(formatted.imm.size == 2) formatted.imm.size = 4; //no 16bits
      
      to_upper_case(opcode->text, key);
      if(formatted.imm.size == 1)
        strcat(key, " r/m32, imm8");
      else if(formatted.imm.size == 4)
        strcat(key, " r/m32, imm32");
      else ERROR_WITH_TOKEN(NULL, "get_instruction2: bad imm size.1");
      if(init_formatted_instruction(&formatted, key)){
        return make_instruction(&formatted);
      }

      //try to override size to 4
      to_upper_case(opcode->text, key);
      strcat(key, " r/m32, imm32");
      if(init_formatted_instruction(&formatted, key)){
        formatted.imm.size = 4;
        return make_instruction(&formatted);
      }
      
      return NULL;
      //TODO other memories
    }
    else ERROR_WITH_TOKEN(NULL, "get_instruction2: bad operand.");
  }

}
