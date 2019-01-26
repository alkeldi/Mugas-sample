#include <parser.h>
#include <mugas_helper.h>
#include <encoder.h>
#include <mugas.h>

//   memory32_token_t * init_memory32(){
//     memory32_token_t *mem = malloc(sizeof(memory32_token_t));
//     memset(mem, 0, sizeof(memory32_token_t));
//     return mem;
//   }

//   int verify_memory32_modrm(memory32_token_t *memory){
//     if(memory->structure == MODRM_REG){
//       /* reg can't be esp nor ebp "not 4 nor 5"*/
//       if(memory->rm.reg.reg_value == 4 || memory->rm.reg.reg_value == 5)
//         ERROR_WITH_TOKEN(&memory->rm.token, "Bad register.");
//       memory->mod = 0;
//     }
//     else if(memory->structure == MODRM_DISP){
//       /* for disp only, the rm register should be ebp , and the disp size can be 8, 16, or 32*/
//       int sz = get_number_size(memory->disp.num);
//       if(sz == 8 || sz == 16 || sz == 32){
//         memory->mod = 0;
//         memory->rm.reg.reg_value = 5;
//         int sz = get_number_size(memory->disp.num);
//       }
//       else ERROR_WITH_TOKEN(&memory->disp.token, "Bad displacement.");

//     }
//     else if(memory->structure == MODRM_REG_AND_DISP){
//       /* reg can't be esp "4" */
//       if(memory->rm.reg.reg_value == 4 ){
//         ERROR_WITH_TOKEN(&memory->rm.token, "Bad register.");
//       }
//       /* disp size can be 8, 16, or 32 */
//       int sz = get_number_size(memory->disp.num);
//       if(sz == 8)
//         memory->mod = 1;
//       else if(sz == 16 || sz == 32)
//         memory->mod = 2;
//       else ERROR_WITH_TOKEN(&memory->disp.token, "Bad displacement.");
//     }
//   }
//   int verify_memory32_sib(memory32_token_t *memory){
//     if(memory->structure == SIB_BASE){
//       /* scale must be 1, 2, 4, 8; and index can't be esp "4"; base can't be ebp "5"*/
//       if(memory->scale.num != 1 && memory->scale.num != 2 && memory->scale.num != 4 && memory->scale.num != 8)
//          ERROR_WITH_TOKEN(&memory->scale.token, "Bad memory scale.");
//       if(memory->index.reg.reg_value == 4)
//         ERROR_WITH_TOKEN(&memory->index.token, "Bad index register.");
//       if(memory->base.reg.reg_value == 5)
//         ERROR_WITH_TOKEN(&memory->base.token, "Bad base register.");
//       /* good to go */
//       memory->mod = 0;
//       memory->rm.reg.reg_value = 4;
//     }
//     else if(memory->structure == SIB_DISP){
//       /* scale must be 1, 2, 4, 8; and index can't be esp "4"; base must be ebp "5"*/
//       if(memory->scale.num != 1 && memory->scale.num != 2 && memory->scale.num != 4 && memory->scale.num != 8)
//          ERROR_WITH_TOKEN(&memory->scale.token, "Bad memory scale.");
//       if(memory->index.reg.reg_value == 4)
//         ERROR_WITH_TOKEN(&memory->index.token, "Bad index register.");
//       /* good to go */
//       memory->mod = 0;
//       memory->rm.reg.reg_value = 4;
//       memory->base.reg.reg_value = 5;
//     }
//     else if(memory->structure == SIB_BASE_AND_DISP){
//       /* scale must be 1, 2, 4, 8; and index can't be esp "4"*/
//       if(memory->scale.num != 1 && memory->scale.num != 2 && memory->scale.num != 4 && memory->scale.num != 8)
//          ERROR_WITH_TOKEN(&memory->scale.token, "Bad memory scale.");
//       if(memory->index.reg.reg_value == 4)
//         ERROR_WITH_TOKEN(&memory->index.token, "Bad index register.");
//       /* disp size can be 8, 16, or 32 */
//       int sz = get_number_size(memory->disp.num);
//       if(sz == 8)
//         memory->mod = 1;
//       else if(sz == 16 || sz == 32)
//         memory->mod = 2;
//       else ERROR_WITH_TOKEN(&memory->disp.token, "Bad displacement.");
//       /* good to go */
//       memory->rm.reg.reg_value = 4;

//     }
//   }

// instruction_t * get_instruction0(token_t *opcode){
//   formatted_instruction_t formatted;
//   memset(&formatted, 0, sizeof(formatted_instruction_t));

//   /* make key */
//   char key[MAX_READABLE_ENCODING_LEN];
//   to_upper_case(opcode->text, key);

//   if(init_formatted_instruction(&formatted, key))
//     return make_instruction(&formatted);
//   else return NULL;
// }


// void fill_formatted_mod_reg(formatted_instruction_t *formatted, operand_token_t *operand){
//   formatted->modrm.mod = 0b11;
//   formatted->modrm.rm = operand->reg.reg.reg_value;
// }
// void fill_formatted_mod_mem(formatted_instruction_t *formatted, operand_token_t *operand){
//     int mem_sz_int;
//     switch(operand->type){
//       case MEMORY32: mem_sz_int = 32; break;
//       case MEMORY8 : mem_sz_int = 8 ; break;
//       case MEMORY16: mem_sz_int = 16; break;
//     }

//     formatted->modrm.mod = operand->mem.mod;
//     formatted->modrm.rm = operand->mem.rm.reg.reg_value;
//     formatted->sib.base =  operand->mem.base.reg.reg_value;
//     formatted->sib.index =  operand->mem.index.reg.reg_value;
//     switch(operand->mem.scale.num){
//       case 1: formatted->sib.scale = 0; break;
//       case 2: formatted->sib.scale = 1; break;
//       case 4: formatted->sib.scale = 2; break;
//       case 8: formatted->sib.scale = 3; break;
//     }
//     memcpy(formatted->disp.data, &operand->mem.disp.num, 4);
//     if(operand->mem.structure == SIB_BASE)
//       formatted->sib.size = 1;
//     else if(operand->mem.structure == MODRM_DISP || operand->mem.structure == MODRM_REG_AND_DISP){
//       // if(get_number_size(operand->mem.disp.num) == 8) formatted->disp.size = 1;
//       // else formatted->disp.size = mem_sz_int/8;
//       switch(formatted->modrm.mod){
//         case 0b01: formatted->disp.size = 2; break;
//         case 0b10: formatted->disp.size = 4; break;
//       }
//     }
//     else if(operand->mem.structure == SIB_DISP || operand->mem.structure == SIB_BASE_AND_DISP){
//         formatted->sib.size = 1;
//         switch(formatted->modrm.mod){
//           case 0b01: formatted->disp.size = 2; break;
//           case 0b10: formatted->disp.size = 4; break;
//         }
//         // if(get_number_size(operand->mem.disp.num) == 8) formatted->disp.size = 1;
//         // else formatted->disp.size = mem_sz_int/8;
//     }

// }
// void fill_formatted_reg_op(formatted_instruction_t *formatted, operand_token_t *operand){
//   formatted->modrm.reg_op = operand->reg.reg.reg_value;
// }
// void fill_operand_sizes(operand_token_t *operand, char *str, int *num){
//     switch(operand->type){
//       case    MEMORY32:
//       case  REGISTER32:
//       case IMMEDIATE32:
//         strcpy(str, "32");
//         *num = 32;
//         break;
//       case    MEMORY8: 
//       case  REGISTER8: 
//       case IMMEDIATE8: 
//         strcpy(str,  "8");
//         *num = 8;
//         break;
//       case    MEMORY16:
//       case  REGISTER16:
//       case IMMEDIATE16:
//         strcpy(str, "16");
//         *num = 16;
//         break;
//     }
// }

// instruction_t * get_instruction1(token_t *opcode, operand_token_t *operand){
//   formatted_instruction_t formatted;
//   memset(&formatted, 0, sizeof(formatted_instruction_t));

//   char key[MAX_READABLE_ENCODING_LEN];
//   to_upper_case(opcode->text, key);
//   strcat(key, " ");
//   size_t last_try = strlen(key);

//   //reg
//   if(operand->type == REGISTER32 || operand->type == REGISTER8 || operand->type == REGISTER16){
//     /* size */
//     char reg_sz[4];
//     int reg_sz_int;
//     fill_operand_sizes(operand, reg_sz, &reg_sz_int);
//     /* try reg name */
//     strcat(key, operand->reg.reg.reg_name);
//     if(init_formatted_instruction(&formatted, key))
//       return make_instruction(&formatted);
//     /* try r/m */
//     key[last_try] = 0;
//     strcat(key, "r/m");
//     strcat(key, reg_sz);
//     if(init_formatted_instruction(&formatted, key)){
//       fill_formatted_mod_reg(&formatted, operand);
//       return make_instruction(&formatted);
//     }
//     /* try r */
//     key[last_try] = 0;
//     strcat(key, "r");
//     strcat(key, reg_sz);
//     if(init_formatted_instruction(&formatted, key)){
//       fill_formatted_reg_op(&formatted, operand);
//       return make_instruction(&formatted);
//     }
//     /* can't find */
//     return NULL;
//   }
//   //mem
//   else if(operand->type == MEMORY32 || operand->type == MEMORY8 || operand->type == MEMORY16){
//     /* size */
//     char mem_sz[4];
//     int mem_sz_int;
//     fill_operand_sizes(operand, mem_sz, &mem_sz_int);
    
//     /* try r/m */
//     key[last_try] = 0;
//     strcat(key, "r/m");
//     strcat(key, mem_sz);
//     if(!init_formatted_instruction(&formatted, key)){
//       /* try m */
//       key[last_try] = 0;
//       strcat(key, "m");
//       strcat(key, mem_sz);
//       if(!init_formatted_instruction(&formatted, key)){
//         /* can't find */
//         return NULL;
//       }
//     }
//     fill_formatted_mod_mem(&formatted, operand);

//     return make_instruction(&formatted);
//   }
//   //imm
//   else if(operand->type == IMMEDIATE8 || operand->type == IMMEDIATE16 || operand->type == IMMEDIATE32){
//     char imm_sz[4];
//     int imm_sz_int;
//     fill_operand_sizes(operand, imm_sz, &imm_sz_int);
    
//     /* smallest imm */
//     key[last_try] = 0;
//     strcat(key, "imm");
//     strcat(key, imm_sz);
//     if(!init_formatted_instruction(&formatted, key)){
//       if(imm_sz_int < 16){
//         key[last_try] = 0;
//         strcat(key, "imm16");
//         if(!init_formatted_instruction(&formatted, key))
//           return NULL;
//       }
//       else if(imm_sz_int < 32){
//         key[last_try] = 0;
//         strcat(key, "imm32");
//         if(!init_formatted_instruction(&formatted, key))
//           return NULL;
//       }
//       else return NULL;
//     }

//     formatted.imm.size = imm_sz_int/8;
//     memcpy(formatted.imm.data, &operand->imm.num, 4);
        
//     return make_instruction(&formatted);
//   }
//   else return NULL;
// }

// instruction_t * get_instruction2(token_t *opcode, operand_token_t *operand1, operand_token_t *operand2){
//   formatted_instruction_t formatted;
//   memset(&formatted, 0, sizeof(formatted_instruction_t));

//   char key[MAX_READABLE_ENCODING_LEN];
//   to_upper_case(opcode->text, key);
//   strcat(key, " ");
//   size_t last_try = strlen(key);
  
//   int op1_sz_int, op2_sz_int;
//   char op1_sz[4], op2_sz[4];
//   fill_operand_sizes(operand1, op1_sz, &op1_sz_int);
//   fill_operand_sizes(operand2, op2_sz, &op2_sz_int);

//   //reg, reg
//   if((operand1->type == REGISTER32 || operand1->type == REGISTER8 || operand1->type == REGISTER16)
//     &&(operand2->type == REGISTER32 || operand2->type == REGISTER8 || operand2->type == REGISTER16)){
//     /* try r, r/m */
//     key[last_try] = 0;
//     strcat(key, "r");
//     strcat(key, op1_sz);
//     strcat(key, ", ");
//     strcat(key, "r/m");
//     strcat(key, op2_sz);
//     if(init_formatted_instruction(&formatted, key)){
//       fill_formatted_reg_op(&formatted, operand1);
//       fill_formatted_mod_reg(&formatted, operand2);
//       return make_instruction(&formatted);
//     }
//     /* try r/m, r */
//     key[last_try] = 0;
//     strcat(key, "r/m");
//     strcat(key, op1_sz);
//     strcat(key, ", ");
//     strcat(key, "r");
//     strcat(key, op1_sz);
//     if(init_formatted_instruction(&formatted, key)){
//       fill_formatted_reg_op(&formatted, operand2);
//       fill_formatted_mod_reg(&formatted, operand1);
//       return make_instruction(&formatted);
//     }
//     /* not found */
//     return NULL;
//   }

//   //reg, mem
//   else if((operand1->type == REGISTER32 || operand1->type == REGISTER8 || operand1->type == REGISTER16)
//     &&(operand2->type == MEMORY32 || operand2->type == MEMORY16 || operand2->type == MEMORY8)){
//     /* try r, r/m */
//     key[last_try] = 0;
//     strcat(key, "r");
//     strcat(key, op1_sz);
//     strcat(key, ", ");
//     strcat(key, "r/m");
//     strcat(key, op2_sz);
//     if(init_formatted_instruction(&formatted, key)){
//       fill_formatted_reg_op(&formatted, operand1);
//       fill_formatted_mod_mem(&formatted, operand2);
//       return make_instruction(&formatted);
//     }
//     /* try r, m */
//     key[last_try] = 0;
//     strcat(key, "r");
//     strcat(key, op1_sz);
//     strcat(key, ", ");
//     strcat(key, "m");
//     strcat(key, op2_sz);
//     if(init_formatted_instruction(&formatted, key)){
//       fill_formatted_reg_op(&formatted, operand1);
//       fill_formatted_mod_mem(&formatted, operand2);
//       return make_instruction(&formatted);
//     }
//     /* not found */
//     return NULL;
//   }

//   //mem, reg
//   else if((operand1->type == MEMORY32 || operand1->type == MEMORY16 || operand1->type == MEMORY8)
//     &&(operand2->type == REGISTER32 || operand2->type == REGISTER8 || operand2->type == REGISTER16)){
//     /* try r/m, r */
//     key[last_try] = 0;
//     strcat(key, "r/m");
//     strcat(key, op1_sz);
//     strcat(key, ", ");
//     strcat(key, "r");
//     strcat(key, op2_sz);
//     if(init_formatted_instruction(&formatted, key)){
//       fill_formatted_reg_op(&formatted, operand2);
//       fill_formatted_mod_mem(&formatted, operand1);
//       return make_instruction(&formatted);
//     }
//     /* try m, r */
//     key[last_try] = 0;
//     strcat(key, "m");
//     strcat(key, op1_sz);
//     strcat(key, ", ");
//     strcat(key, "r");
//     strcat(key, op2_sz);
//     if(init_formatted_instruction(&formatted, key)){
//       fill_formatted_reg_op(&formatted, operand2);
//       fill_formatted_mod_mem(&formatted, operand1);
//       return make_instruction(&formatted);
//     }
//     /* not found */
//     return NULL;
//   }

//   //reg, imm
//   else if((operand1->type == REGISTER32 || operand1->type == REGISTER8 || operand1->type == REGISTER16)
//     &&(operand2->type == IMMEDIATE8 || operand2->type == IMMEDIATE16 || operand2->type == IMMEDIATE32)){
    
//     if(op2_sz_int > op1_sz_int)
//       return NULL;

//     /* try reg name */
//     key[last_try] = 0;
//     strcat(key, operand1->reg.reg.reg_name);
//     strcat(key, ", ");
//     strcat(key, "imm");
//     strcat(key, op1_sz);
//     if(init_formatted_instruction(&formatted, key)){
//       formatted.imm.size = op1_sz_int/8;;
//       memcpy(formatted.imm.data, &operand2->imm.num, 4);
//       return make_instruction(&formatted);
//     }

//     /* try r/m, imm8 */
//     if(op2_sz_int == 8){
//       key[last_try] = 0;
//       strcat(key, "r/m");
//       strcat(key, op1_sz);
//       strcat(key, ", ");
//       strcat(key, "imm8");
//       if(init_formatted_instruction(&formatted, key)){
//         fill_formatted_mod_reg(&formatted, operand1);
//         formatted.imm.size = 1;
//         memcpy(formatted.imm.data, &operand2->imm.num, 4);
//         return make_instruction(&formatted);
//       }
//     }

//     /* try r/m, imm -> imm size == reg size */
//     key[last_try] = 0;
//     strcat(key, "r/m");
//     strcat(key, op1_sz);
//     strcat(key, ", ");
//     strcat(key, "imm");
//     strcat(key, op1_sz);
//     if(init_formatted_instruction(&formatted, key)){
//       fill_formatted_mod_reg(&formatted, operand1);
//       formatted.imm.size = op1_sz_int/8;
//       memcpy(formatted.imm.data, &operand2->imm.num, 4);
//       return make_instruction(&formatted);
//     }

//     return NULL;
//   }
  
//   //mem, imm
//   else if((operand1->type == MEMORY32 || operand1->type == MEMORY16 || operand1->type == MEMORY8)
//     &&(operand2->type == IMMEDIATE8 || operand2->type == IMMEDIATE16 || operand2->type == IMMEDIATE32)){
    
//     if(op2_sz_int > op1_sz_int)
//       return NULL;

//     /* try r/m, imm*/
//     if(op2_sz_int == 8){
//       key[last_try] = 0;
//       strcat(key, "r/m");
//       strcat(key, op1_sz);
//       strcat(key, ", ");
//       strcat(key, "imm8");
//       if(!init_formatted_instruction(&formatted, key)){
//         key[last_try] = 0;
//         strcat(key, "m");
//         strcat(key, op1_sz);
//         strcat(key, ", ");
//         strcat(key, "imm8");
//         if(!init_formatted_instruction(&formatted, key))
//           return NULL;
//       }
//       fill_formatted_mod_mem(&formatted, operand1);
//       formatted.imm.size = 1;
//       memcpy(formatted.imm.data, &operand2->imm.num, 4);
//       return make_instruction(&formatted);
//     }

//     /* try r/m, imm -> imm size == reg size */
//     key[last_try] = 0;
//     strcat(key, "r/m");
//     strcat(key, op1_sz);
//     strcat(key, ", ");
//     strcat(key, "imm");
//     strcat(key, op1_sz);
//     if(!init_formatted_instruction(&formatted, key)){
//       key[last_try] = 0;
//       strcat(key, "m");
//       strcat(key, op1_sz);
//       strcat(key, ", ");
//       strcat(key, "imm");
//       strcat(key, op1_sz);
//       if(!init_formatted_instruction(&formatted, key))
//         return NULL;
//     }

//     fill_formatted_mod_mem(&formatted, operand1);
//     formatted.imm.size = op1_sz_int/8;
//     memcpy(formatted.imm.data, &operand2->imm.num, 4);
//     return make_instruction(&formatted);
//   }

//   //error
//   else return NULL;
// }