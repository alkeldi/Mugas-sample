%{
  #include <stdio.h>
  #include <stdlib.h>
  #include <parser.h>
  #include <mugas_helper.h>
  #include <mugas.h>
  #include <encoder.h>
  extern int yylex (void);
  extern size_t line;
  extern size_t column;
  void yyerror(char const *);

  instruction_imm_t_t * reduce_math_expression(instruction_imm_t_t *imm1, instruction_imm_t_t *imm2, char operation){
    integer i1, i2, result;
    memcpy(&i1, imm1->imm.data, MAX_IMM_SIZE);
    memcpy(&i2, imm2->imm.data, MAX_IMM_SIZE);

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
      ERROR_WITH_TOKEN(&imm1->token, "integer overflow/underflow.");
    }

    imm1->imm.size = sz;
    memcpy(imm1->imm.data, &result, MAX_IMM_SIZE);

    if(imm2->token.text){
      free(imm2->token.text);
      imm2->token.text = NULL;
    }
    free(imm2);
    imm2 = NULL;

    return imm1;
  }
  instruction_mem_t_t * reduce_modrm_expression(instruction_reg_t_t *reg, instruction_imm_t_t *disp){
    instruction_mem_t_t *result = malloc(sizeof(instruction_reg_t_t));
    memset(result, 0, sizeof(instruction_reg_t_t));

    /* reg can't be esp "not 4"*/
    if(reg->reg.reg_value  == 0b100)
      ERROR_WITH_TOKEN(&reg->token, "Bad register.");
    
    integer i;
    memcpy(&i, disp->imm.data, MAX_IMM_SIZE);
    int num_sz = get_number_size(i);
    if(num_sz < 1 || num_sz > 4)
      ERROR_WITH_TOKEN(&disp->token, "integer overflow/underflow.");

    result->modrm.size = 1;
    result->modrm.mod = (num_sz == 1) ? 0b01 : 0b10;
    result->modrm.rm = reg->reg.reg_value;
    result->disp.size = num_sz; 
    memcpy(result->disp.data, disp->imm.data, MAX_DISP_SIZE);

    /* if not ebp and the integer is zero, then drop the integer*/
    if(i == 0 && reg->reg.reg_value  != 0b101)
      result->disp.size = 0;

    return result;
  }
  instruction_mem_t_t * reduce_scaled_index_expression(instruction_reg_t_t *index, instruction_imm_t_t *scale){
    //[n*reg] -> special if n = 0, 1
    integer i;
    memcpy(&i, scale->imm.data, MAX_IMM_SIZE);
    if(i != 1 && i != 2 && i != 4 && i != 8)
      ERROR_WITH_TOKEN(&index->token, "Bad address scale.");
    instruction_mem_t_t *result = malloc(sizeof(instruction_reg_t_t));
    memset(result, 0, sizeof(instruction_reg_t_t));

  }
%}


%union {
  struct instruction_imm_t_t *imm;
  struct instruction_reg_t_t *reg;
  struct instruction_mem_t_t *mem;
  struct instruction_operand_t_t *operand;
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
%type <mem> memory modrm scaled_index disp base disp_and_base sib    
%type <operand> operand
%type <instruction> instruction
%start all

%%

all: lines;

lines: line | line lines;

line: 
  instruction{
  };

instruction: 
  OPCODE NEWLINE{
    // $$ = get_instruction0($1);
    // if($$){
    //   print_instruction($$);
    // }
  }|
  OPCODE operand NEWLINE{
    // $$ = get_instruction1($1, $2);
    // if($$){
    //   print_instruction($$);
    // }
  }|
  OPCODE operand COMMA operand NEWLINE{
    // $$ = get_instruction2($1, $2, $4);
    // if($$){
    //   print_instruction($$);
    // }
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
  OPEN_BRACKET modrm CLOSE_BRACKET{
    $$ = $2;
  }| 
  OPEN_BRACKET sib CLOSE_BRACKET{
    $$ = $2;
  } 
;
//[reg], [disp], [reg + disp]
modrm: 
  REG {
    $$ = malloc(sizeof(instruction_reg_t_t));
    memset($$, 0, sizeof(instruction_reg_t_t));

    /* reg can't be esp */
    if($1->reg.reg_value  == 0b100)
      ERROR_WITH_TOKEN(&$1->token, "Bad register.");
    
    $$->modrm.size = 1;
    $$->modrm.mod = 0b00;
    $$->modrm.rm = $1->reg.reg_value;

    /* reg can be ebp only with displacement  -> so we add the displacement but keep its value zero*/
    if($1->reg.reg_value  == 0b101)
      $$->disp.size = 1;
    
  }|
  expresion {
    $$ = malloc(sizeof(instruction_reg_t_t));
    memset($$, 0, sizeof(instruction_reg_t_t));

    $$->modrm.size = 1;
    $$->modrm.mod = 0b00;
    $$->modrm.rm = 0b101; /* must be 5 for only displacement*/
    $$->disp.size = 4; /* must be 4, this disp can only be 4 bytes */
    memcpy($$->disp.data, $1->imm.data, MAX_DISP_SIZE);
  }|
  REG PLUS expresion {
    $$ = reduce_modrm_expression($1, $3);
  }| 
  REG MINUS expresion {
    instruction_imm_t_t *imm1 = malloc(sizeof(instruction_imm_t_t));
    memset(&imm1, 0, sizeof(instruction_imm_t_t));
    imm1->imm.size = 1;

    instruction_imm_t_t *imm2 = malloc(sizeof(instruction_imm_t_t)); /* freed by reduce_math_expression*/
    *imm2 = *$3;

    reduce_math_expression(imm1, imm2, '-');

    $$ = reduce_modrm_expression($1, imm1);

    free(imm1);

  }| 
  expresion PLUS REG {
    $$ = reduce_modrm_expression($3, $1);
  }
;
sib: 
  base {
    $$ = $1;
  }|
  disp {
    $$ = $1;
  }| 
  disp_and_base {
    $$ = $1;
  }
;
disp: 
  scaled_index {
    // $$ = $1;
    // $$->disp.num = 0;
    // $$->structure = SIB_DISP;
  }|
  scaled_index PLUS expresion {
    // $$ = $1;
    // $$->disp = *$3;
    // $$->structure = SIB_DISP;
  }|
  scaled_index MINUS expresion {
    // $$ = $1;
    // $$->disp = *$3;
    // $$->disp.num *= -1;
    // $$->structure = SIB_DISP;
  }|
  expresion PLUS scaled_index {
    // $$ = $3;
    // $$->disp = *$1;
    // $$->structure = SIB_DISP;
  }
;
base: 
  REG PLUS scaled_index {
    // $$ = $3;
    // $$->base = *$1;
    // $$->structure = SIB_BASE;
  }|
  scaled_index PLUS REG{
    // $$ = $1;
    // $$->base = *$3;
    // $$->structure = SIB_BASE;
  }
;
disp_and_base: 
  // REG PLUS disp {
  //   // $$ = $3;
  //   // $$->base = *$1;
  //   // $$->structure = SIB_BASE_AND_DISP;
  // }|
  // disp PLUS REG {
  //   // $$ = $1;
  //   // $$->base = *$3;
  //   // $$->structure = SIB_BASE_AND_DISP;
  // }|
  base PLUS expresion {
    // $$ = $1;
    // $$->disp = *$3;
    // $$->structure = SIB_BASE_AND_DISP;
  }|
  base MINUS expresion{
    // $$ = $1;
    // $$->disp = *$3;
    // $$->disp.num *= -1;
    // $$->structure = SIB_BASE_AND_DISP;
  }|
  expresion PLUS base{
    // $$ = $3;
    // $$->disp = *$1;
    // $$->structure = SIB_BASE_AND_DISP;
  }
;

//[n*reg] -> special if n = 0, 1
scaled_index: 
  // REG {
    /* reg * 1 */
    // $$ = init_memory32();
    // $$->scale.num = 1;
    // $$->index = *$1;
  // }|
  expresion MULTIPLY REG {
    reduce_scaled_index_expression($3, $1);
  }|
  REG MULTIPLY expresion{
    reduce_scaled_index_expression($1, $3);
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
    instruction_imm_t_t *imm = malloc(sizeof(instruction_imm_t_t));
    memset(&imm, 0, sizeof(instruction_imm_t_t));
    imm->imm.size = 1;
    $$ = reduce_math_expression($2, imm, '-');
    $$->token = *$1;
    free(imm)
;  }|
  PLUS expresion %prec POSITIVE {
    $$ = $2;
    $$->token = *$1;
  }
;

%%

void yyerror (char const *s) {
   fprintf (stderr, "[%s]\n", s);
}