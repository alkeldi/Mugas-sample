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
  struct datum_s {
    int type;
    char *strval;
  };
  
  struct instruction_s {
    char *opcode;
    struct DLLNode *operands_list;
  };
  struct data_block_s {
    char *data_type;
    struct DLLNode *data_list;
  };

  void print_instruction(struct instruction_s *instruction){
    printf("instruction:{\n");
    printf("\topcode: %s,\n", instruction->opcode);
    DLLNode * iter = instruction->operands_list->next;
    int i = 1;
    while(iter !=  instruction->operands_list){
      struct operand_s *operand = (struct operand_s*)iter->data;
      printf("\toperand%d: %s",i++, operand->strval);
      if(iter->next != instruction->operands_list)
        printf(",\n");
      else printf("\n");
      iter = iter->next;
    }
    printf("}\n");
  }
  void print_data_block(struct data_block_s *data_block){
    printf("data_block:{\n");
    printf("\tdata_type: %s,\n", data_block->data_type);
    DLLNode * iter = data_block->data_list->next;
    int i = 1;
    while(iter !=  data_block->data_list){
      struct datum_s *datum = (struct datum_s*)iter->data;
      printf("\tdatum%d: %s",i++, datum->strval);
      if(iter->next != data_block->data_list)
        printf(",\n");
      else printf("\n");
      iter = iter->next;
    }
    printf("}\n");
  }


%}

%union {
  int intval;
  char *strval;
  struct operand_s *operand_t;
  struct datum_s *datum_t;
  struct instruction_s *instruction_t;
  struct data_block_s *data_block_t;
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
%type <datum_t> datum;
%type <instruction_t> instruction;
%type <data_block_t> data_block;
%type <list_t> operands_list data_list;

%start all

%%

instruction: 
  OPCODE operands_list NEWLINE {
    $$ = (struct instruction_s*)malloc(sizeof(struct instruction_s));
    $$->opcode = $1;
    $$->operands_list = $2;
    print_instruction($$);
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
  DATA_TYPE data_list NEWLINE{
  $$ = (struct data_block_s*)malloc(sizeof(struct data_block_s));
  $$->data_type = $1;
  $$->data_list = $2;
  print_data_block($$);
  };
data_list: 
  datum {
    $$ = DLList_init(NULL);
    DLList_addEnd($$, $1);
  }|
  data_list COMMA datum{
    DLList_addEnd($1, $3);
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

label_line: label NEWLINE | label instruction | label data_block;
label: LEGAL_NAME COLON {
  
};

section_switch: SECTION_WORD SECTION_NAME NEWLINE;

variable_declaration: MODIFIER variables_list NEWLINE;
variables_list: LEGAL_NAME | variables_list COMMA LEGAL_NAME;

line: label_line | instruction | data_block | section_switch | variable_declaration;
lines: line | lines line;
all: lines;

%%

void yyerror (char const *s) {
  //  fprintf (stderr, "[%s]\n", s);
}
