#Project Structure
PROJECT_ROOT =	..
SRC_DIR = $(PROJECT_ROOT)/src
INCLUDE_DIR = $(PROJECT_ROOT)/include
OBJ_DIR = $(PROJECT_ROOT)/obj

#Compiler
CC = gcc
CFLAGS = -I$(INCLUDE_DIR) -lfl

#parser
LEX = flex
LEX_IN = $(SRC_DIR)/parser.l
LEX_OUT = $(SRC_DIR)/parser.c

#Files Lists
HEADER_FILES = $(wildcard $(INCLUDE_DIR)/*.h)
SRC_FILES = $(wildcard $(SRC_DIR)/*.c)
OBJ_FILES = $(patsubst $(SRC_DIR)/%.c, $(OBJ_DIR)/%.o, $(SRC_FILES))

#main target
asm: $(OBJ_FILES)
	$(CC) -o $@ $^ $(CFLAGS)

#Create object files
$(OBJ_FILES): $(SRC_FILES) CREATE_MISSING_DIRS
	$(CC) -c -o $@ $(patsubst $(OBJ_DIR)/%.o, $(SRC_DIR)/%.c, $@) $(CFLAGS)	

#generate required source files
$(SRC_FILES): $(LEX_IN)
	$(LEX) -o $(LEX_OUT) $(LEX_IN)

CREATE_MISSING_DIRS:
	mkdir -p $(OBJ_DIR) $(SRC_DIR) $(INCLUDE_DIR)

#phony functions
.PHONY: clean

#clean up
clean:
	rm -rf $(OBJ_FILES) asm