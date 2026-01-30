/* "initdata" and "font" are
	converted from https://github.com/tinusaur/ssd1306xled */

initdata[32]
	0256, 0325, 0360, 0250, 0077, 0323, 0000, 0100,
	0215, 0024, 0040, 0000, 0241, 0310, 0332, 0022,
	0201, 0077, 0331, 0042, 0333, 0040, 0244, 0246,
	0056, 0257, 0042, 0000, 0077, 0041, 0000, 0177;

font[60]
	0000, 0076, 0121, 0111, 0105, 0076,
	0000, 0000, 0102, 0177, 0100, 0000,
	0000, 0102, 0141, 0121, 0111, 0106,
	0000, 0041, 0101, 0105, 0113, 0061,
	0000, 0030, 0024, 0022, 0177, 0020,
	0000, 0047, 0105, 0105, 0105, 0071,
	0000, 0074, 0112, 0111, 0111, 0060,
	0000, 0001, 0161, 0011, 0005, 0003,
	0000, 0066, 0111, 0111, 0111, 0066,
	0000, 0006, 0111, 0111, 0051, 0036;

command() {
	extrn putchar;
	putchar(0170); putchar(0);
}

data() {
	extrn putchar;
	putchar(0170); putchar(0100);
}

stop() {
	extrn putchar;
	putchar(0777);
}

setpos(x, y) {
	extrn putchar, command, stop;
	command();
	putchar(0260 | y & 7);
	putchar(x & 017);
	putchar(020 | x >> 4);
	stop();
}

cls() {
	extrn putchar, data, stop;
	auto i 0;
	data();
	while (i++ < 1024)
		putchar(0);
	stop();
}

init() {
	extrn initdata, putchar, command, stop, cls;
	auto i 0;
	command();
	while (i < 32)
		putchar(initdata[i++]);
	stop();
	cls();
}

/* 0:t 1:l 2:c 3:r 4:m */

depth 12;	/* max. 12 */
d[96];		/* 12*8 */
n[5];		/* max. 5digits */
one 1;		/* avoid compiler bug */
t0[12];
t1[12];

output() {
	extrn putchar, data, stop, setpos;
	extrn n, depth, d, font, t0, t1;
	auto i 0, j, p, c, m;
	while (++n[i] > 9)
		n[i++] = 0;
	setpos(64, 0);
	data();
	i = 5;
	while (i) {
		p = &font[6 * n[--i]];
		j = 6;
		while (j--)
			putchar(*p++);
	}
	stop();
	i = 0;
	while (i < depth) {
		setpos(0, i >> 1);
		/* i is even */
		c = d[(i << 3) + 4];
		m = 1;
		j = 0;
		while (j < depth) {
			if (c & m) {
				t0[j] = 017;
				t1[j] = 017;
			}
			else {
				t0[j] = 0;
				t1[j] = 6;
			}
			m =<< 1;
			j++;
		}
		i++;
		/* i is odd */
		c = d[(i << 3) + 4];
		m = 1;
		j = 0;
		data();
		while (j < depth) {
			if (i < depth)
				if (c & m) {
					t0[j] = t0[j] | 0360;
					t1[j] = t1[j] | 0360;
				}
				else t1[j] = t1[j] | 0140;
			putchar(t0[j]);
			putchar(t1[j]);
			putchar(t1[j]);
			putchar(t0[j]);
			m =<< 1;
			j++;
		}
		stop();
		i++;
	}
}

main() {
	extrn init, output;
	extrn d, depth, one;
	auto m, p, p0, mask;
	init();
	mask = (one << depth) - 1;
	p = d;
	*p = mask;
	*(p + 1) = *(p + 2) = *(p + 3) = *(p + 4) = 0;
	while (1) {
		if (*p) {
			*p =& ~(*(p + 4) = m = *p & -*p);
			if (p - d < depth - 1 << 3) {
				p0 = p;
				p =+ 8;
				*(p + 1) = (*(p0 + 1) | m) << 1;
				*(p + 2) =  *(p0 + 2) | m;
				*(p + 3) = (*(p0 + 3) | m) >> 1;
				*p = ~(*(p + 1) | *(p + 2) | *(p + 3)) & mask;
			}
			else output();
		}
		else if ((p =- 8) < d) break;
	}
}
