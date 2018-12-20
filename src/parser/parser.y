%{
  #include <stdio.h>
  #include <stdlib.h>
  #include <DLList.h>
  #include <mugas.h>
  extern int yylex (void);
  void yyerror(char const *);
  
%}

%union {
  int intval;
  char *strval;
  struct operand_s *operand_t;
  struct datum_s *datum_t;
  struct label_s *label_t;
  struct instruction_s *instruction_t;
  struct data_block_s *data_block_t;
  struct variable_declaration_s *variable_declaration_t;
  struct section_switch_s *section_switch_t;
  struct line_s *line_t;
  struct DLLNode *list_t;
}

%token <strval> STRING;
%token <strval> MODIFIER;
%token <strval> SECTION_WORD;
%token <strval> SECTION_NAME;
%token <strval> DATA_TYPE;
%token <strval> OPCODE;
%token <strval> REGISTER;
%token <strval> NUMBER;
%token <strval> MEMORY_CONTENT;
%token <strval> LEGAL_NAME;
%token <strval> COLON;
%token <strval> COMMA;
%token <strval> NEWLINE;

%type <label_t> label;
%type <section_switch_t> section_switch;
%type <operand_t> operand;
%type <datum_t> datum;
%type <instruction_t> instruction;
%type <data_block_t> data_block;
%type <variable_declaration_t> variable_declaration;
%type <line_t> line;
%type <list_t> operands_list data_list variables_list lines_list;

%start all

%%


instruction: 
  OPCODE operands_list NEWLINE {
    $$ = (struct instruction_s*)malloc(sizeof(struct instruction_s));
    $$->opcode = $1;
    $$->operands_list = $2;
  };
operands_list: 
  operand {
    $$ = DLList_init(NULL);
    DLList_addEnd($$, $1);
  }| 
  operands_list COMMA operand {
    DLList_addEnd($1, $3);
    $$ = $1;
  };

operand: 
  REGISTER {
    $$ = (struct operand_s*)malloc(sizeof(struct operand_s));
    $$->type = REGISTER;
    $$->strval = $1;

  }| 
  NUMBER {
    $$ = (struct operand_s*)malloc(sizeof(struct operand_s));
    $$->type = NUMBER;
    $$->strval = $1;
  }| 
  MEMORY_CONTENT {
    $$ = (struct operand_s*)malloc(sizeof(struct operand_s));
    $$->type = MEMORY_CONTENT;
    $$->strval = $1;
  }| 
  LEGAL_NAME {
    $$ = (struct operand_s*)malloc(sizeof(struct operand_s));
    $$->type = LEGAL_NAME;
    $$->strval = $1;
  };

data_block: 
  DATA_TYPE data_list NEWLINE {
    $$ = (struct data_block_s*)malloc(sizeof(struct data_block_s));
    $$->data_type = $1;
    $$->data_list = $2;
  };
data_list: 
  datum {
    $$ = DLList_init(NULL);
    DLList_addEnd($$, $1);
  }|
  data_list COMMA datum{
    DLList_addEnd($1, $3);
    $$ = $1;
  };
datum:
  NUMBER {
    $$ = (struct datum_s*)malloc(sizeof(struct datum_s));
    $$->type = NUMBER;
    $$->strval = $1;
  }|
  STRING {
    $$ = (struct datum_s*)malloc(sizeof(struct datum_s));
    $$->type = STRING;
    $$->strval = $1;
  }| 
  LEGAL_NAME{
    $$ = (struct datum_s*)malloc(sizeof(struct datum_s));
    $$->type = LEGAL_NAME;
    $$->strval = $1;
  };

label: 
  LEGAL_NAME COLON NEWLINE{
    $$ = (struct label_s*)malloc(sizeof(struct label_s));
    $$->name = $1;
    $$->address = NULL;
  };

section_switch:
  SECTION_WORD SECTION_NAME NEWLINE {
    $$ = (struct section_switch_s *)malloc(sizeof(struct section_switch_s));
    $$->section = $2;
  };

variable_declaration:
  MODIFIER variables_list NEWLINE {
    $$ = (struct variable_declaration_s*)malloc(sizeof(struct variable_declaration_s));
    $$->modifier = $1;
    $$->variables_list = $2;
  };
variables_list:
  LEGAL_NAME {
    $$ = DLList_init(NULL);
    DLList_addEnd($$, $1);
  }|
  variables_list COMMA LEGAL_NAME {
    DLList_addEnd($1, $3);
    $$ = $1;
  };

line:
  label {
    $$ = (struct line_s*)malloc(sizeof(struct line_s));
    $$->type = LINE_TYPE_LABEL;
    $$->label = $1;
  }|
  instruction {
    $$ = (struct line_s*)malloc(sizeof(struct line_s));
    $$->type = LINE_TYPE_INSTRUCTION;
    $$->instruction = $1;
  }| 
  data_block {
    $$ = (struct line_s*)malloc(sizeof(struct line_s));
    $$->type = LINE_TYPE_DATA_BLOCK;
    $$->data_block = $1;
  }| 
  section_switch {
    $$ = (struct line_s*)malloc(sizeof(struct line_s));
    $$->type = LINE_TYPE_SECTION_SWITCH;
    $$->section_switch = $1;
  }| 
  variable_declaration {
    $$ = (struct line_s*)malloc(sizeof(struct line_s));
    $$->type = LINE_TYPE_VARIABLE_DECLARATION;
    $$->variable_declaration = $1;
  }|
  line NEWLINE {
    $$ = $1;
  }
  
lines_list: 
  line {
    $$ = DLList_init(NULL);
    DLList_addEnd($$, $1);
  }|
  lines_list line {
    DLList_addEnd($1, $2);
    $$ = $1;
  };

all: 
  lines_list {
    mugas_list = $1;
  }
  
%%

void yyerror (char const *s) {
  //TODO add all malloced pointers into a list for cleanup
   fprintf (stderr, "[%s]\n", s);
}
