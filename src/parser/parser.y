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
%}


%union {
  struct integer_token_t *integer;
  struct register_token_t *reg;
  struct memory32_token_t *mem32;
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
%type <integer> expresion;
%type <mem32> memory memory_32 modrm //sib no_base no_disp disp_base scaled_index


%start all

%%

all: lines;

lines: line | line lines;

line: 
  memory NEWLINE {
    printf("memory\n");
  };

memory: 
  OPEN_BRACKET memory_32 CLOSE_BRACKET {
    $$ = $2;
    printf("reg: %d    mod: %d   disp: %lld\n", $$->rm_reg.reg_value, $$->mod, $$->disp);
  };
memory_32: modrm | sib ;
modrm: 
  REG {
    $$ = make_memory32(&$1->token);
    $$->mod = 0;
    $$->rm_reg = $1->reg;
  }|
  expresion {
    $$ = make_memory32(&$1->token);
    $$->mod = 0;
    $$->rm_reg.reg_value = 5;
  }|
  REG PLUS expresion {
    $$ = make_memory32(&$1->token);
    $$->rm_reg = $1->reg;
    $$->disp = $3->num;
  }| 
  REG MINUS expresion {
    $$ = make_memory32(&$1->token);
    $$->rm_reg = $1->reg;
    $$->disp = -1 * $3->num;
  }| 
  expresion PLUS REG {
    $$ = make_memory32(&$1->token);
    $$->rm_reg = $3->reg;
    $$->disp = $1->num;
  };

sib: no_disp | no_base | disp_base;
no_base: scaled_index PLUS expresion | scaled_index MINUS expresion | expresion PLUS scaled_index;
no_disp: REG PLUS scaled_index | scaled_index PLUS REG;
disp_base: REG PLUS no_base | no_base PLUS REG | no_disp PLUS expresion | no_disp MINUS expresion| expresion PLUS no_disp;
scaled_index: REG | expresion MULTIPLY REG | REG MULTIPLY expresion ;


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
  }|
  MINUS expresion %prec NEGATIVE {
    $$ = $2;
    $$->num = -1 * $$->num;
  }|
  PLUS expresion %prec POSITIVE {
    $$ = $2;
  };

%%

void yyerror (char const *s) {
   fprintf (stderr, "[%s]\n", s);
}