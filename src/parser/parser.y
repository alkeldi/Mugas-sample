%{
  #include <stdio.h>
  #include <stdlib.h>
  #include <parser.h>
  #include <mugas_helper.h>
  #include <mugas.h>
  #include <encoder.h>
  #include <elf_maker.h>
  #include <elf_maker_special_sections.h>
  extern int yylex (void);
  extern size_t line;
  extern size_t column;
  extern elf_section_t *text_section;
  void yyerror(char const *);
  typedef struct scaled_reg_t {
    instruction_reg_t_t * index;
    instruction_imm_t_t * ss;
  }scaled_reg_t;

  //TODO: better tokens handling
  //TODO: make numbers signed
  //TODO: esp can be addressed somehow
  integer get_imm_value(instruction_imm_t_t *imm){
    integer val;
    memcpy(&val, imm->imm.data, imm->imm.size);
    return val;
  }
  void set_imm_value(instruction_imm_t_t *imm, int32_t val){
    memcpy(imm->imm.data, &val, MAX_IMM_SIZE);
    imm->imm.size = get_number_size(val); //should always be a good size because val is of type int32_t
  }

  instruction_imm_t_t * create_imm(int32_t i){
    instruction_imm_t_t *imm = malloc(sizeof(instruction_imm_t_t));
    memset(imm, 0, sizeof(instruction_imm_t_t));
    set_imm_value(imm, i);
    return imm;
  }
  scaled_reg_t * create_scaled_reg(instruction_reg_t_t *index, instruction_imm_t_t *ss){
    scaled_reg_t *scaled = malloc(sizeof(scaled_reg_t));
    memset(scaled, 0, sizeof(scaled_reg_t));
    scaled->index = index;
    scaled->ss = ss;
  }
  instruction_imm_t_t * negate_expression(instruction_imm_t_t *exp){
    //create another temp expression with value zero
    instruction_imm_t_t *temp = malloc(sizeof(instruction_imm_t_t));
    memset(temp, 0, sizeof(instruction_imm_t_t));
    temp->imm.size = 1;

    //exp = 0 - exp
    reduce_math_expression(temp, exp, '-');

    return temp;
  }
 

  instruction_imm_t_t * reduce_math_expression(instruction_imm_t_t *imm1, instruction_imm_t_t *imm2, char operation){
    integer i1, i2, result;
    i1 = get_imm_value(imm1);
    i2 = get_imm_value(imm2);

    switch(operation){
      case '+': result = i1 + i2; break;
      case '-': result = i1 - i2; break;
      case '*': result = i1 * i2; break;
      case '/': result = i1 / i2; break;
      case '%': result = i1 / i2; break;
      default: ERROR_WITH_TOKEN(&imm1->token, "unknown math operation.\n");
    };

    int sz = get_number_size(result);
    if(sz < 1 || sz > MAX_IMM_SIZE){
      ERROR_WITH_TOKEN(&imm1->token, "reduce_math_expression: integer overflow/underflow.");
    }

    set_imm_value(imm1, result);
    if(imm2->token.text){
      free(imm2->token.text);
      imm2->token.text = NULL;
    }
    free(imm2);
    imm2 = NULL;

    return imm1;
  }

  //TODO: carefully review
  instruction_mem_t_t * handle_reg_addressing(instruction_reg_t_t *reg, instruction_imm_t_t * disp){       
    if(!reg && !disp){
      ERROR_WITH_TOKEN(NULL, "handle_reg_addressing -> both reg and disp are null.");
    }
    
    //prepare
    instruction_mem_t_t *mem = malloc(sizeof(instruction_mem_t_t));
    memset(mem, 0, sizeof(instruction_mem_t_t));

    //reg
    if(reg){
      mem->modrm.size = 1;
      mem->modrm.rm = reg->reg.reg_value;
    }

    //disp
    integer dispval = 0;
    if(disp) {
      mem->modrm.size = 1;
      dispval = get_imm_value(disp);
      memcpy(mem->disp.data, disp->imm.data, MAX_IMM_SIZE);
      int sz = get_number_size(dispval);
      switch(sz){
        case 1: mem->disp.size = 1; mem->modrm.mod = 0b01; break;
        case 2: mem->disp.size = 4; mem->modrm.mod = 0b10; break;
        case 4: mem->disp.size = 4; mem->modrm.mod = 0b10; break;
        default: ERROR_WITH_TOKEN(&disp->token, "handle_reg_addressing:integer overflow/underflow.");
      }
    }

    //special cases
    if(mem->modrm.rm == 0b100) //esp can't be addressed
      ERROR_WITH_TOKEN(&reg->token, "Bad register.");
    if(mem->modrm.rm == 0b101 && mem->disp.size == 0){ //ebp can be addressed only with a displacement
      mem->disp.size = 1;
      mem->modrm.mod = 0b01;
    }
    if(disp && dispval == 0 && reg->reg.reg_value != 0b101) //if displacement is zero, then ignore it except for ebp
      mem->disp.size = 0;


    return mem;
  }

  //TODO: carefully review
  instruction_mem_t_t * handle_base_index_addressing(instruction_reg_t_t *base, scaled_reg_t *scaled_reg, instruction_imm_t_t *disp){
    if(!base && !scaled_reg && !disp){
      ERROR_WITH_TOKEN(NULL, "handle_base_index_addressing -> base, scaled_reg, and disp are all null.");
    }

    //prepare
    instruction_mem_t_t *mem = malloc(sizeof(instruction_mem_t_t));
    memset(mem, 0, sizeof(instruction_mem_t_t));
    mem->modrm.rm = 0b100;

    //scaled reg
    unsigned scale = 0;
    if(scaled_reg){
      scale = (unsigned)get_imm_value(scaled_reg->ss); //careful
      if(scale == 0) return handle_reg_addressing(base, disp);
      else if(scale == 1) mem->sib.scale = 0b00;
      else if(scale == 2) mem->sib.scale = 0b01;
      else if(scale == 4) mem->sib.scale = 0b10;
      else if(scale == 8) mem->sib.scale = 0b11;
      else ERROR_WITH_TOKEN(NULL, "handle_base_index_addressing -> bad scale.");
      mem->sib.size = 1;
      mem->modrm.size = 1;
      mem->sib.index = scaled_reg->index->reg.reg_value;

    }
    else return handle_reg_addressing(base, disp);

    //base
    if(base){
      mem->modrm.size = 1;
      mem->sib.size = 1;
      mem->sib.base = base->reg.reg_value;
    }

    //disp
    integer dispval = 0;
    if(disp) {
      mem->modrm.size = 1;
      mem->sib.size = 1;
      dispval = get_imm_value(disp);
      memcpy(mem->disp.data, disp->imm.data, MAX_IMM_SIZE);
      int sz = get_number_size(dispval);
      switch(sz){
        case 1: mem->disp.size = 1; mem->modrm.mod = 0b01; break;
        case 2: mem->disp.size = 4; mem->modrm.mod = 0b10; break;
        case 4: mem->disp.size = 4; mem->modrm.mod = 0b10; break;
        default: ERROR_WITH_TOKEN(&disp->token, "handle_base_index_addressing: integer overflow/underflow.");
      }
    }

    //special cases
    if(scaled_reg && scale == 1){
      mem->sib.scale = 0b00;
      if(base){
        instruction_reg_t_t reg1 = *base;
        instruction_reg_t_t reg2 = *scaled_reg->index;
        if(reg1.reg.reg_value == reg2.reg.reg_value){
          if(reg1.reg.reg_value == 0b100) //esp can't be addressed as index
            ERROR_WITH_TOKEN(NULL, "Bad register.");
          else if(reg1.reg.reg_value == 0b101){
            mem->sib.base = reg1.reg.reg_value;
            mem->sib.index = reg2.reg.reg_value;
            if(mem->disp.size == 0){ //ebp can be a base only with a displacement
              mem->disp.size = 1;
              mem->modrm.mod = 0b01;
            }
          }
        }
        else{
          if(reg1.reg.reg_value == 0b100){
            mem->sib.base = reg1.reg.reg_value;
            mem->sib.index = reg2.reg.reg_value;            
          }
          else if(reg2.reg.reg_value == 0b100){
            mem->sib.base = reg2.reg.reg_value;
            mem->sib.index = reg1.reg.reg_value;   
          }
          else if(reg1.reg.reg_value == 0b101){
            mem->sib.index = reg1.reg.reg_value;   
            mem->sib.base = reg2.reg.reg_value;
          }
          else if(reg2.reg.reg_value == 0b101){
            mem->sib.index = reg2.reg.reg_value;   
            mem->sib.base = reg1.reg.reg_value;
          }
        }

      }
      else return handle_reg_addressing(scaled_reg->index, disp);
    }
    else if(scaled_reg){
      if(!base){
        mem->modrm.mod = 0b00;
        mem->sib.base = 0b101;
        mem->disp.size = 4;
      }
      
    }

    if(mem->sib.index == 0b100) //esp can't be addressed
      ERROR_WITH_TOKEN(NULL, "Bad register.");
    if(mem->sib.base == 0b101 && mem->disp.size == 0){ //ebp can be addressed only with a displacement
      mem->disp.size = 1;
      mem->modrm.mod = 0b01;
    }
    if(disp && dispval == 0 && mem->sib.base != 0b101) //if displacement is zero, then ignore it except for ebp as a base
      mem->disp.size = 0;


    return mem;
  }


%}


%union {
  struct instruction_imm_t_t *imm;
  struct instruction_reg_t_t *reg;
  struct instruction_mem_t_t *mem;
  struct scaled_reg_t *scaled_reg;
  struct instruction_operand_t_t *operand;
  struct instruction_t *instruction;
  struct token_t *token;
}

/* content */
%token STRING
%token <reg> REG;
%token <token> OPCODE DIRECTIVE LABEL

/* punctuation */
%token NEWLINE COLON COMMA 

/* calculator */
%left <token> PLUS MINUS
%left <token> DIVIDE MULTIPLY REMINDER
%token <token> OPEN_PARENTHESES CLOSE_PARENTHESES OPEN_BRACKET CLOSE_BRACKET
%token <imm> INTEGER
%nonassoc NEGATIVE POSITIVE

/* nonterminals */
%type <imm> expresion
%type <mem> memory reg_addressing  base_index_addressing
%type <scaled_reg> scaled_reg;
%type <operand> operand
%type <instruction> instruction
%start all

%%

all: lines;

lines: line | line lines;

line: instruction {
  //TODO add all mallocs into a list, then free them when error or a line is processed
  elf_maker_add_section_entry(text_section, $1->data, $1->size);
};

instruction: 
  OPCODE NEWLINE {
    $$ = get_instruction0($1);
    if($$){
      print_instruction($$);
    }
    else ERROR_WITH_TOKEN($1, "Either an error, or the instruction is not supported yest\n");
    
  }|
  OPCODE operand NEWLINE{
    $$ = get_instruction1($1, $2);
    if($$){
      print_instruction($$);
    }
    else ERROR_WITH_TOKEN($1, "Either an error, or the instruction is not supported yest\n");
  }|
  OPCODE operand COMMA operand NEWLINE{
    $$ = get_instruction2($1, $2, $4);
    if($$){
      print_instruction($$);
    }
    else ERROR_WITH_TOKEN($1, "Either an error, or the instruction is not supported yest\n");
  }
;
operand:
  REG {
    $$ = malloc(sizeof(instruction_operand_t_t));
    $$->reg = $1;
    $$->type = REG_OP;
  }|
  memory {
    $$ = malloc(sizeof(instruction_operand_t_t));
    $$->mem = $1;
    $$->type = MEM_OP;
  }|
  expresion {
    $$ = malloc(sizeof(instruction_operand_t_t));
    $$->imm = $1;
    $$->type = IMM_OP;
  }
;
memory: 
//TODO handle sizes
  OPEN_BRACKET reg_addressing CLOSE_BRACKET{
    $$ = $2;
  }| 
  OPEN_BRACKET base_index_addressing CLOSE_BRACKET{
    $$ = $2;
  } 
;

scaled_reg: 
  expresion MULTIPLY REG {
    $$ = create_scaled_reg($3, $1);
  }
  |REG MULTIPLY expresion {
    $$ = create_scaled_reg($1, $3);
  }
;

reg_addressing: 
   REG {
    $$ = handle_reg_addressing($1, NULL);
  }
  |expresion{
    $$ = handle_reg_addressing(NULL, $1);
  }
  |REG PLUS expresion {
    $$ = handle_reg_addressing($1, $3);
  }
  |REG MINUS expresion {
    negate_expression($3);
    $$ = handle_reg_addressing($1, $3);
  }
  |expresion PLUS REG {
    $$ = handle_reg_addressing($3, $1);
  }
;

base_index_addressing: 
   scaled_reg {
     $$ = handle_base_index_addressing(NULL, $1, NULL);
  }
  |REG PLUS REG {
    instruction_imm_t_t *imm = create_imm(1);
    scaled_reg_t *scaled = create_scaled_reg($3, imm);
    $$ = handle_base_index_addressing($1, scaled, NULL);
  }
  |REG PLUS scaled_reg {
    $$ = handle_base_index_addressing($1, $3, NULL);
  }
  |scaled_reg PLUS REG {
    $$ = handle_base_index_addressing($3, $1, NULL);
  }
  |REG PLUS scaled_reg PLUS expresion {
    $$ = handle_base_index_addressing($1, $3, $5);
  }
  |REG PLUS scaled_reg MINUS expresion {
    negate_expression($5);
    $$ = handle_base_index_addressing($1, $3, $5);
  }
  |REG PLUS expresion PLUS scaled_reg {
    $$ = handle_base_index_addressing($1, $5, $3);
  }
  |REG MINUS expresion PLUS scaled_reg {
    negate_expression($3);
    $$ = handle_base_index_addressing($1, $5, $3);
  }
  |scaled_reg PLUS REG PLUS expresion {
    $$ = handle_base_index_addressing($3, $1, $5);
  }
  |scaled_reg PLUS REG MINUS expresion {
    negate_expression($5);
    $$ = handle_base_index_addressing($3, $1, $5);
  }
  |scaled_reg PLUS expresion PLUS REG {
    $$ = handle_base_index_addressing($5, $1, $3);
  }
  |scaled_reg MINUS expresion PLUS REG {
    negate_expression($3);
    $$ = handle_base_index_addressing($5, $1, $3);
  }
  |expresion PLUS REG PLUS scaled_reg {
    $$ = handle_base_index_addressing($3, $5, $1);
  }
  |expresion PLUS scaled_reg PLUS REG {
    $$ = handle_base_index_addressing($5, $3, $1);
  }
  |REG PLUS REG PLUS expresion {
    instruction_imm_t_t *imm = create_imm(1);
    scaled_reg_t *scaled = create_scaled_reg($3, imm);
    $$ = handle_base_index_addressing($1, scaled, $5);
  }
  |REG PLUS expresion PLUS REG {
    instruction_imm_t_t *imm = create_imm(1);
    scaled_reg_t *scaled = create_scaled_reg($5, imm);
    $$ = handle_base_index_addressing($1, scaled, $3);
  }
  |REG MINUS expresion PLUS REG {
    instruction_imm_t_t *imm = create_imm(1);
    scaled_reg_t *scaled = create_scaled_reg($5, imm);
    negate_expression($3);
    $$ = handle_base_index_addressing($1, scaled, $3);
  }
  |expresion PLUS REG PLUS REG {
    instruction_imm_t_t *imm = create_imm(1);
    scaled_reg_t *scaled = create_scaled_reg($5, imm);
    $$ = handle_base_index_addressing($3, scaled, $1);
  }
;

expresion:
  INTEGER {
    $$ = $1;
  }|
  expresion PLUS expresion {
    $$ = reduce_math_expression($1, $3, '+');
  }|
  expresion MINUS expresion {
    $$ = reduce_math_expression($1, $3, '-');
  }|
  expresion MULTIPLY expresion {
    $$ = reduce_math_expression($1, $3, '*');
  }|
  expresion DIVIDE expresion { 
    $$ = reduce_math_expression($1, $3, '/');
  }|
  expresion REMINDER expresion {
    $$ = reduce_math_expression($1, $3, '%');
  }|
  OPEN_PARENTHESES expresion CLOSE_PARENTHESES{
    $$ = $2;
    $$->token = *$1;
  }|
  MINUS expresion %prec NEGATIVE {
    $$ = negate_expression($2);
    $$->token = *$1;
  }|
  PLUS expresion %prec POSITIVE {
    $$ = $2;
    $$->token = *$1;
  }
;

%%

void yyerror (char const *s) {
   fprintf (stderr, "[%s]\n", s);
}