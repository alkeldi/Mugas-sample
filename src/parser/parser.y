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
%}


%union {
  struct integer_token_t *integer;
  struct reg_token_t *reg;
  struct memory32_token_t *mem32;
  struct operand_token_t *operand;
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
%token <integer> INTEGER
%nonassoc NEGATIVE POSITIVE

/* nonterminals */
%type <integer> expresion
%type <mem32> memory_32 modrm scaled_index disp base disp_and_base sib    
%type <operand> operand
%type <instruction> instruction
%start all

%%

all: lines;

lines: line | line lines;

line: 
  instruction{
    printf("->instruction\n");
  };

instruction: 
  OPCODE NEWLINE{
    $$ = get_instruction0($1);
    if($$){
      print_instruction($$);
    }
  }|
  OPCODE operand NEWLINE{
    $$ = get_instruction1($1, $2);
    if($$){
      print_instruction($$);
    }
  }|
  OPCODE operand COMMA operand NEWLINE{
    $$ = get_instruction2($1, $2, $4);
    if($$){
      print_instruction($$);
    }
  }
;

operand:
  REG {
    $$ = malloc(sizeof(operand_token_t));
    $$->reg = *$1;
    $$->type = REGISTER32;
    if(!strcmp($1->reg.reg_type, "r8"))       $$->type = REGISTER8;
    else if(!strcmp($1->reg.reg_type, "r32")) $$->type = REGISTER32;
    else if(!strcmp($1->reg.reg_type, "r16")) $$->type = REGISTER16;
    else ERROR_WITH_TOKEN(&$1->token, "bad register type.");

  }|
  memory_32 {
    $$ = malloc(sizeof(operand_token_t));
    $$->mem = *$1;
    $$->type = MEMORY32;
  }|
  expresion {
    $$ = malloc(sizeof(operand_token_t));
    $$->imm = *$1;
    /* set operand type */
    int sz = get_number_size($1->num);
    if     (sz == 8 ) $$->type = IMMEDIATE8;
    else if(sz == 32) $$->type = IMMEDIATE32;
    else if(sz == 16) $$->type = IMMEDIATE16;
    else ERROR_WITH_TOKEN(&$1->token, "bad constant size.");
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
    $$ = init_memory32();
    $$->rm = *$1;
    $$->structure = MODRM_REG;
  }|
  expresion {
    $$ = init_memory32();
    $$->disp = *$1;
    $$->rm.reg.reg_value = 5;
    $$->structure = MODRM_DISP;
  }|
  REG PLUS expresion {
    $$ = init_memory32();
    $$->rm = *$1;
    $$->disp = *$3;
    $$->structure = MODRM_REG_AND_DISP;
  }| 
  REG MINUS expresion {
    $$ = init_memory32();
    $$->rm = *$1;
    $$->disp = *$3;
    $$->disp.num *= -1;
    $$->structure = MODRM_REG_AND_DISP;
  }| 
  expresion PLUS REG {
    $$ = init_memory32();
    $$->rm = *$3;
    $$->disp = *$1;
    $$->structure = MODRM_REG_AND_DISP;
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
    $$->structure = SIB_DISP;
  }|
  scaled_index PLUS expresion {
    $$ = $1;
    $$->disp = *$3;
    $$->structure = SIB_DISP;
  }|
  scaled_index MINUS expresion {
    $$ = $1;
    $$->disp = *$3;
    $$->disp.num *= -1;
    $$->structure = SIB_DISP;
  }|
  expresion PLUS scaled_index {
    $$ = $3;
    $$->disp = *$1;
    $$->structure = SIB_DISP;
  }
;
base: 
  REG PLUS scaled_index {
    $$ = $3;
    $$->base = *$1;
    $$->structure = SIB_BASE;
  }|
  scaled_index PLUS REG{
    $$ = $1;
    $$->base = *$3;
    $$->structure = SIB_BASE;
  }
;
disp_and_base: 
  REG PLUS disp {
    $$ = $3;
    $$->base = *$1;
    $$->structure = SIB_BASE_AND_DISP;
  }|
  disp PLUS REG {
    $$ = $1;
    $$->base = *$3;
    $$->structure = SIB_BASE_AND_DISP;
  }|
  base PLUS expresion {
    $$ = $1;
    $$->disp = *$3;
    $$->structure = SIB_BASE_AND_DISP;
  }|
  base MINUS expresion{
    $$ = $1;
    $$->disp = *$3;
    $$->disp.num *= -1;
    $$->structure = SIB_BASE_AND_DISP;
  }|
  expresion PLUS base{
    $$ = $3;
    $$->disp = *$1;
    $$->structure = SIB_BASE_AND_DISP;
  }
;
scaled_index: 
  REG {
    /* reg * 1 */
    $$ = init_memory32();
    $$->scale.num = 1;
    $$->index = *$1;
  }|
  expresion MULTIPLY REG {
    /* n*reg */
    $$ = init_memory32();
    $$->scale = *$1;
    $$->index = *$3;
  }|
  REG MULTIPLY expresion{
    /* reg*n */
    $$ = init_memory32();
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