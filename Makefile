TARGET = ABCDM

build_and_clean: all clean

all:
	bison -d $(TARGET).y
	lex $(TARGET).l
	g++ IDList.cpp lex.yy.c  $(TARGET).tab.c -std=c++11 -o $(TARGET)
	
clean:
	rm -f lex.yy.c $(TARGET).tab.h $(TARGET).tab.c