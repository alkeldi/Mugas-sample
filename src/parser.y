%{

%}

%token STRING;
%token MODIFIER;
%token SECTION_WORD;
%token SECTION_NAME;
%token DATA_TYPE;
%token OPCODE;
%token REGISTER;
%token NUMBER;
%token MEMORY_CONTENT;
%token LEGAL_NAME;
%token COLON;
%token COMMA;
%token NEWLINE;

%start all

%%

instruction: OPCODE operands_list NEWLINE;
operands_list: operand | operands_list COMMA operand;
operand: REGISTER | NUMBER | MEMORY_CONTENT | LEGAL_NAME;

data: DATA_TYPE data_list NEWLINE;
data_list: datum | data_list COMMA datum;
datum: NUMBER | STRING | LEGAL_NAME;

label_line: label NEWLINE | label instruction | label data;
label: LEGAL_NAME COLON;

section_switch: SECTION_WORD SECTION_NAME NEWLINE;

variable_declaration: MODIFIER variables_list NEWLINE;
variables_list: LEGAL_NAME | variables_list COMMA LEGAL_NAME;

line: label_line | instruction | data | section_switch | variable_declaration;
lines: line | lines line;
all: lines;

%%
 
