SRC := src
OBJ := obj
CC = gcc

SOURCES := $(wildcard $(SRC)/*.c)
OBJECTS := $(patsubst $(SRC)/%.c, $(OBJ)/%.o, $(SOURCES))
HEADERS := $(wildcard $(SRC)/*.h)

mpeg_tb: $(OBJECTS)
	$(CC) $^ -o $@

$(OBJ)/%.o: $(SRC)/%.c $(HEADERS)
	$(CC) -c $< -o $@ -I$(SRC) 

clean:
	-rm -f $(OBJECTS)
