.SUFFIXES: .b .bin

all: ram.mem
	iverilog f6100.v mem.v test.v && ./a.out | less

ram.mem: queen.bin cnv
	./cnv $<

.b.bin:
	8bc -k $<

clean:
	rm -f a.out cnv ram* *.{bin,lst,pal}
