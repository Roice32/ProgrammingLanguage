TARGET = ABCDM

buildAndClean: all clean

all:
	bison -d $(TARGET).y
	lex $(TARGET).l
	g++ Code.cpp lex.yy.c  $(TARGET).tab.c -std=c++11 -o $(TARGET)
	
clean:
	rm -f lex.yy.c $(TARGET).tab.h $(TARGET).tab.c