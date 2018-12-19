%{
  #include <stdio.h>
  #include <stdlib.h>
  #include <DLList.h>
  extern int yylex (void);
  void yyerror(char const *);

  struct operand_s {
    int type;
    char *strval;
  };
  
  struct instruction_s {
    char *opcode;
    struct DLLNode *operands_list;
  };


%}

%union {
  int intval;
  char* strval;
  struct operand_s *operand_t;
  struct instruction_s *instruction_t;
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

%type <operand_t> operand;
%type <instruction_t> instruction;
%type <list_t> operands_list;

%start all

%%

instruction: 
  OPCODE operands_list NEWLINE {
    $$->opcode = $1;
    $$->operands_list = $2;
    printf("instruction\n");
  };
operands_list: 
  operand {
    $$ = DLList_init(NULL);
    DLList_addEnd($$, $1);
  }| 
  operands_list COMMA operand {
    DLList_addEnd($1, $3);
  };
operand: 
  REGISTER {
    $$->type = REGISTER;
    $$->strval = $1;
  }| 
  NUMBER{
    $$->type = NUMBER;
    $$->strval = $1;
  }| 
  MEMORY_CONTENT {
    $$->type = MEMORY_CONTENT;
    $$->strval = $1;
  }| 
  LEGAL_NAME {
    $$->type = LEGAL_NAME;
    $$->strval = $1;
  };

data: DATA_TYPE data_list NEWLINE;
data_list: datum | data_list COMMA datum;
datum: NUMBER | STRING | LEGAL_NAME;

label_line: label NEWLINE | label instruction | label data;
label: LEGAL_NAME COLON {
  
};

section_switch: SECTION_WORD SECTION_NAME NEWLINE;

variable_declaration: MODIFIER variables_list NEWLINE;
variables_list: LEGAL_NAME | variables_list COMMA LEGAL_NAME;

line: label_line | instruction | data | section_switch | variable_declaration;
lines: line | lines line;
all: lines;

%%

void yyerror (char const *s) {
  //  fprintf (stderr, "[%s]\n", s);
}
