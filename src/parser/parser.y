%{
  #include <stdio.h>
  #include <stdlib.h>
  #include <mugas_types.h>
  #include <mugas_helper.h>
  extern int yylex (void);
  extern size_t line;
  extern size_t column;
  void yyerror(char const *);
  memory32_token_t * make_memory32(token_t * token){
    memory32_token_t *mem = malloc(sizeof(memory32_token_t));
    memset(mem, 0, sizeof(memory32_token_t));
    mem->token.line = token->line;
    mem->token.column = token->column;
    return mem;
  }
  int verify_memory32_modrm(memory32_token_t *memory){
    if(memory->type == MODRM_REG){
      /* reg can't be esp nor ebp "not 4 nor 5"*/
      if(memory->rm.reg.reg_value == 4 || memory->rm.reg.reg_value == 5)
        ERROR_WITH_TOKEN(&memory->rm.token, "Bad register.");
      memory->mod = 0;
    }
    else if(memory->type == MODRM_DISP){
      /* for disp only, the rm register should be ebp , and the disp size can be 8, 16, or 32*/
      int sz = get_number_size(memory->disp.num);
      if(sz == 8 || sz == 16 || sz == 32){
        memory->mod = 0;
        memory->rm.reg.reg_value = 5;
        int sz = get_number_size(memory->disp.num);
      }
      else ERROR_WITH_TOKEN(&memory->disp.token, "Bad displacement.");

    }
    else if(memory->type == MODRM_REG_AND_DISP){
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
    if(memory->type == SIB_BASE){
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
    else if(memory->type == SIB_DISP){
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
    else if(memory->type == SIB_BASE_AND_DISP){
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
%}


%union {
  struct integer_token_t *integer;
  struct register_token_t *reg;
  struct memory32_token_t *mem32;
  struct operand_token_t *operand;
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
%token <integer> INTEGER
%nonassoc NEGATIVE POSITIVE

/* nonterminals */
%type <integer> expresion
%type <mem32> memory memory_32 modrm scaled_index disp base disp_and_base sib    
%type <operand> operand

%start all

%%

all: lines;

lines: line | line lines;

line: 
  memory NEWLINE {
    printf("instruction\n");
  };

instuction: 
  OPCODE {
    
  }|
  OPCODE operand{

  }|
  OPCODE operand COMMA operand{
    
  }
;

operand:
  REG {
    $$ = malloc(sizeof(operand_token_t));
    $$->reg = *$1;
    $$->type = REGISTER;
  }|
  memory {
    $$ = malloc(sizeof(memory32_token_t));
    $$->memory = *$1;
    $$->type = MEMORY;
  }
;

memory: 
   memory_32 {
    $$ = $1;
    printf("modrm -> mod : %d,    rm: %d,  disp: %lld\n", $$->mod, $$->rm.reg.reg_value, $$->disp.num);
    printf("sib   -> base: %d, scale: %lld, index: %d\n", $$->base.reg.reg_value, $$->scale.num, $$->index.reg.reg_value);
  }
;
memory_32: 
  OPEN_BRACKET modrm CLOSE_BRACKET{
    $$ = $2;
    verify_memory32_modrm($$);
  }| 
  OPEN_BRACKET sib CLOSE_BRACKET{
    $$ = $2;
    verify_memory32_sib($$);
  } 
;
modrm: 
  REG {
    $$ = make_memory32(&$1->token);
    $$->rm = *$1;
    $$->type = MODRM_REG;
  }|
  expresion {
    $$ = make_memory32(&$1->token);
    $$->rm.reg.reg_value = 5;
    $$->type = MODRM_DISP;
  }|
  REG PLUS expresion {
    $$ = make_memory32(&$1->token);
    $$->rm = *$1;
    $$->disp = *$3;
    $$->type = MODRM_REG_AND_DISP;
  }| 
  REG MINUS expresion {
    $$ = make_memory32(&$1->token);
    $$->rm = *$1;
    $$->disp = *$3;
    $$->disp.num *= -1;
    $$->type = MODRM_REG_AND_DISP;
  }| 
  expresion PLUS REG {
    $$ = make_memory32(&$1->token);
    $$->rm = *$3;
    $$->disp = *$1;
    $$->type = MODRM_REG_AND_DISP;
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
    $$ = $1;
    $$->disp.num = 0;
    $$->type = SIB_DISP;
  }|
  scaled_index PLUS expresion {
    $$ = $1;
    $$->disp = *$3;
    $$->type = SIB_DISP;
  }|
  scaled_index MINUS expresion {
    $$ = $1;
    $$->disp = *$3;
    $$->disp.num *= -1;
    $$->type = SIB_DISP;
  }|
  expresion PLUS scaled_index {
    $$ = $3;
    $$->disp = *$1;
    $$->type = SIB_DISP;
  }
;
base: 
  REG PLUS scaled_index {
    $$ = $3;
    $$->base = *$1;
    $$->type = SIB_BASE;
  }|
  scaled_index PLUS REG{
    $$ = $1;
    $$->base = *$3;
    $$->type = SIB_BASE;
  }
;
disp_and_base: 
  REG PLUS disp {
    $$ = $3;
    $$->base = *$1;
    $$->type = SIB_BASE_AND_DISP;
  }|
  disp PLUS REG {
    $$ = $1;
    $$->base = *$3;
    $$->type = SIB_BASE_AND_DISP;
  }|
  base PLUS expresion {
    $$ = $1;
    $$->disp = *$3;
    $$->type = SIB_BASE_AND_DISP;
  }|
  base MINUS expresion{
    $$ = $1;
    $$->disp = *$3;
    $$->disp.num *= -1;
    $$->type = SIB_BASE_AND_DISP;
  }|
  expresion PLUS base{
    $$ = $3;
    $$->disp = *$1;
    $$->type = SIB_BASE_AND_DISP;
  }
;
scaled_index: 
  REG {
    /* reg * 1 */
    $$ = make_memory32(&$1->token);
    $$->scale.num = 1;
    $$->index = *$1;
  }|
  expresion MULTIPLY REG {
    /* n*reg */
    $$ = make_memory32(&$1->token);
    $$->scale = *$1;
    $$->index = *$3;
  }|
  REG MULTIPLY expresion{
    /* reg*n */
    $$ = make_memory32(&$1->token);
    $$->scale = *$3;
    $$->index = *$1;
  }
;

expresion:
  INTEGER{
    $$ = malloc(sizeof(integer_token_t)); /* TODO free */
    memset($$, 0, sizeof(integer_token_t));
    $$->num = $1->num;
    $$->token.line = $1->token.line;
    $$->token.column = $1->token.column;
  }|
  expresion PLUS expresion {
    $$ = $1;
    $$->num = $1->num + $3->num; 
    free($3);
  }|
  expresion MINUS expresion {
    $$ = $1;
    $$->num = $1->num - $3->num; 
    free($3);
  }|
  expresion MULTIPLY expresion {
    $$ = $1;
    $$->num = $1->num * $3->num; 
    free($3);
  }|
  expresion DIVIDE expresion { 
    $$ = $1;
    $$->num = $1->num / $3->num; 
    free($3);
  }|
  expresion REMINDER expresion {
    $$ = $1;
    $$->num = $1->num % $3->num; 
    free($3);
  }|
  OPEN_PARENTHESES expresion CLOSE_PARENTHESES{
    $$ = $2;
    $$->token.line = $1->line;
    $$->token.column = $1->column;
  }|
  MINUS expresion %prec NEGATIVE {
    $$ = $2;
    $$->num = -1 * $$->num;
    $$->token.line = $1->line;
    $$->token.column = $1->column;
  }|
  PLUS expresion %prec POSITIVE {
    $$ = $2;
    $$->token.line = $1->line;
    $$->token.column = $1->column;
  }
;

%%

void yyerror (char const *s) {
   fprintf (stderr, "[%s]\n", s);
}