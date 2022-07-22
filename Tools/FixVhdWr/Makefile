TARGET = FixVhdWr

all:	${TARGET}
${TARGET} : ${TARGET}.c  ${TARGET}.h
	gcc -o ${TARGET} $< -m32

clean:
	rm -f *.o ${TARGET}