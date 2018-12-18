%{
  #include <stdio.h>
%}


%%

\"(\\.|[^"])*\"                     return STRING;
"global"|"extern"                   return MODIFIER;
"section"                           return SECTION_WORD;
[.][_a-zA-Z0-9]+                    return SECTION_NAME;
"db"|"dw"|"dd"|"dq"|"dt"            return DATA_TYPE;
"mov"|"add"|"sub"|"push"            return OPCODE;
"pop"|"call"|"int"|"ret"            return OPCODE;
"eax"|"ebx"|"ecx"|"edx"             return REGISTER;
[0-9]+|(0[xX][0-9a-fA-F]+)          return NUMBER;
\[[_a-zA-Z]+[_a-zA-Z0-9]*\]         return MEMORY_CONTENT;
[_a-zA-Z]+[_a-zA-Z0-9]*             return LEGAL_NAME;
:                                   return COLON;
,                                   return COMMA;
\n                                  return NEWLINE;
[ \t]+                              ;
;[.]*                               printf("parser error: unexpected\n");

%%