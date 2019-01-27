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
  typedef struct scaled_reg_t {
    instruction_reg_t_t * index;
    instruction_imm_t_t * ss;
  }scaled_reg_t;

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

  instruction_mem_t_t * handle_reg_addressing(instruction_reg_t_t *reg, instruction_imm_t_t * disp){

  }

  instruction_mem_t_t * handle_base_index_addressing(
    instruction_reg_t_t *base,
    scaled_reg_t *scaled_reg,
    instruction_imm_t_t *disp
  ){

  }

  instruction_imm_t_t * negate_expression(instruction_imm_t_t *exp){
    //create another temp expression with value zero
    instruction_imm_t_t *temp = malloc(sizeof(instruction_imm_t_t));
    memset(&temp, 0, sizeof(instruction_imm_t_t));
    temp->imm.size = 1;

    //exp = 0 - exp
    reduce_math_expression(temp, exp, '-');

    return temp;
  }
%}


%union {
  struct instruction_imm_t_t *imm;
  struct instruction_reg_t_t *reg;
  struct instruction_mem_t_t *mem;
  struct scaled_reg_t *scaled_reg;
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
%type <mem> memory reg_addressing  base_index_addressing
%type <scaled_reg> scaled_reg;
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
  OPEN_BRACKET reg_addressing CLOSE_BRACKET{
    $$ = $2;
  }| 
  OPEN_BRACKET base_index_addressing CLOSE_BRACKET{
    $$ = $2;
  } 
;

scaled_reg: 
  expresion MULTIPLY REG {
    $$ = malloc(sizeof(scaled_reg_t));
    $$->ss = $1;
    $$->index = $3;
  }
  |REG MULTIPLY expresion {
    $$ = malloc(sizeof(scaled_reg_t));
    $$->ss = $3;
    $$->index = $1;
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

//TODO reg+reg+disp variations
base_index_addressing: 
   scaled_reg {
     $$ = handle_base_index_addressing(NULL, $1, NULL);
  }
  |REG PLUS REG {
    //base + index*1
    //create an immediate of value 1
    instruction_imm_t_t *imm = malloc(sizeof(instruction_imm_t_t));
    int num = 1;
    memcpy(imm->imm.data, &num, MAX_IMM_SIZE);

    //create a scaled index with ss of 1 and index $3
    scaled_reg_t *scaled = malloc(sizeof(scaled_reg_t));
    scaled->index = $3;
    scaled->ss = imm;

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