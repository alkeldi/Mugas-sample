#Project Structure
PROJECT_ROOT =	..

SRC_DIR = $(PROJECT_ROOT)/src
INCLUDE_DIR = $(PROJECT_ROOT)/include
OBJ_DIR = $(PROJECT_ROOT)/obj

HEADER_FILES = $(wildcard $(INCLUDE_DIR)/*.h)
SRC_FILES = $(wildcard $(SRC_DIR)/*.c)
OBJ_FILES = $(patsubst $(SRC_DIR)/%.c, $(OBJ_DIR)/%.o, $(SRC_FILES))

#Compiler
CC = gcc
CFLAGS = -I$(INCLUDE_DIR)

#parser
LEX = flex
LEX_IN_FILE = $(SRC_DIR)/parser/parser.l
LEX_OUT_FILE = $(SRC_DIR)/parser/lex.yy.c
LEX_EXECUTABLE = parser

#main target
asm: $(OBJ_FILES) PARSER
	$(CC) -o $@ $< $(CFLAGS)
	$(CC) -o $(LEX_EXECUTABLE) $(LEX_OUT_FILE) -lfl

#create object files
$(OBJ_FILES): $(SRC_FILES) $(HEADER_FILES) CREATE_MISSING_DIRS
	$(CC) -c -o $@ $< $(CFLAGS)
	

PARSER: $(LEX_IN_FILE)
	$(LEX) -o $(LEX_OUT_FILE) $(LEX_IN_FILE)

#create directories if needed
CREATE_MISSING_DIRS:
	mkdir -p $(OBJ_DIR) $(SRC_DIR) $(INCLUDE_DIR)

#phony functions
.PHONY: clean

#clean up
clean:
	rm -rf $(OBJ_FILES)
	rm -rf asm
	rm -rf $(LEX_OUT_FILE) $(LEX_EXECUTABLE)