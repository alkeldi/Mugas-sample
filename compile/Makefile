#Project Structure
PROJECT_ROOT =	..
SRC_DIR = $(PROJECT_ROOT)/src
INCLUDE_DIR = $(PROJECT_ROOT)/include
OBJ_DIR = $(PROJECT_ROOT)/obj
PARSER_DIR = $(SRC_DIR)/parser

#Compiler
CC = gcc
CFLAGS = -I$(INCLUDE_DIR) -lfl -g

#parser
LEX = flex
LEX_IN = $(PARSER_DIR)/parser.l
LEX_OUT = $(PARSER_DIR)/parser.l.c

YACC = bison
YACC_IN = $(PARSER_DIR)/parser.y
YACC_OUT = $(PARSER_DIR)/parser.y.c

#Files Lists
HEADER_FILES = $(wildcard $(INCLUDE_DIR)/*.h)
SRC_FILES = $(wildcard $(SRC_DIR)/*.c) $(LEX_OUT) $(YACC_OUT)
OBJ_FILES = $(patsubst $(SRC_DIR)/%.c, $(OBJ_DIR)/%.o, $(SRC_FILES))

#main target
asm: $(OBJ_FILES)
	$(CC) -o $@ $^ $(CFLAGS)

#Create object files
$(OBJ_FILES): CREATE_MISSING_DIRS PARSER
	$(CC) -c -o $@ $(patsubst $(OBJ_DIR)/%.o, $(SRC_DIR)/%.c, $@) $(CFLAGS)	

#generate required source files
PARSER: $(LEX_IN) $(YACC_IN)
	$(YACC) $(YACC_IN) -d -o $(YACC_OUT)
	$(LEX) -o $(LEX_OUT) $(LEX_IN) 

#Fake rule for generating missing directories when needed
CREATE_MISSING_DIRS:
	mkdir -p $(OBJ_DIR)
	mkdir -p $(OBJ_DIR)/$(notdir $(PARSER_DIR))

#phony functions
.PHONY: clean

#clean up
clean:
	rm -rf asm
	rm -rf $(OBJ_FILES) 
	rm -rf $(LEX_OUT) $(YACC_OUT) $(patsubst %.c, %.h, $(YACC_OUT))