#include <stdint.h>
#include <stdio.h>

#define N		2

static uint16_t m[1024 * N];

int main(int argc, char *argv[]) {
	if (argc != 2) {
		fprintf(stderr, "Usage: cnv <bin>\n");
		return 1;
	}
	FILE *fi = fopen(argv[1], "rb");
	if (!fi) {
		fprintf(stderr, "cannot open\n");
		return 1;
	}
	int ofs = 0, c0, c1;
	fseek(fi, 239, SEEK_SET);
	while ((c0 = getc(fi)) != EOF && (c1 = getc(fi)) != EOF) {
		if (c0 & 0200) break;
		if (c0 & 0100) ofs = (c0 << 6 | c1) & 0xfff;
		else if (ofs < 1024 * N) m[ofs++] = c0 << 6 | c1;
	}
	fclose(fi);
#if N == 1
	fi = fopen("ram.mem", "wb");
	if (!fi) {
		fprintf(stderr, "cannot write\n");
		return 2;
	}
	for (int j = 0; j < 4096; j++)
		fprintf(fi, "%03x\n", m[j] & 07777);
	fclose(fi);
#else
	for (int i = 0; i < N; i++) {
		char s[16];
		sprintf(s, "ram%d.mem", i);
		fi = fopen(s, "wb");
		if (!fi) {
			fprintf(stderr, "cannot write\n");
			return 2;
		}
		for (int j = 0; j < 1024; j++)
			fprintf(fi, "%03x\n", m[1024 * i + j] & 07777);
		fclose(fi);
	}
#endif
	return 0;
}
