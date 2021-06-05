#define PROGRAM_VERSION_STRING "1"
#define _GNU_SOURCE
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>

#define CPIO_END "TRAILER!!!"
#define CPIO_ENDLEN (sizeof(CPIO_END)-1)

static char buf[CPIO_ENDLEN * 2 + 1];

int main(int argc, char **argv){
	FILE *f;
	size_t s;
	if(argc != 2){
		fprintf(stderr, "Usage: %s <file>\n", argv[0]);
		exit(1);
	}
	f = fopen(argv[1], "r");
	if(f == NULL){
		fprintf(stderr, "Cannot open file '%s'\n", argv[1]);
		exit(1);
	}
	s = fread(buf, 6, 1, f);
	if(s <= 0){
		fprintf(stderr, "Read error from file '%s'\n", argv[1]);
		fclose(f);
		exit(1);
	}
	fseek(f, 0, SEEK_SET);
	if(buf[0] == '0' && buf[1] == '7' && buf[2] == '0' && buf[3] == '7' && buf[4] == '0' && buf[5] == '1'){
		long pos = 0;
		do{
			char *h;
			fseek(f, pos, SEEK_SET);
			buf[sizeof(buf) - 1] = 0;
			s = fread(buf, CPIO_ENDLEN, 2, f);
			if(s <= 0)
				break;
			h = strstr(buf, CPIO_END);
			if(h){
				pos = (h - buf) + pos + CPIO_ENDLEN;
				fseek(f, pos, SEEK_SET);
				break;
			}
			pos += CPIO_ENDLEN;
		} while(!feof(f));
		if(feof(f))
                        fseek(f, 0, SEEK_SET);
                else{
			while(!feof(f)){
				size_t i;
				buf[sizeof(buf) - 1] = 0;
				s = fread(buf, 1, sizeof(buf) - 1, f);
				if(s <= 0)
					break;
				for(i = 0; (i < s) && (buf[i] == 0); i++);
					if (buf[i] != 0){
						pos += i;
						fseek(f, pos, SEEK_SET);
						break;
					}
				pos += s;
			}
		}
	}
	while (!feof(f)){
		s = fread(buf, 1, sizeof(buf), f);
		if (s <= 0)
			break;
		s = fwrite(buf, 1, s, stdout);
		if (s <= 0)
			break;
	}
	fclose(f);
	return EXIT_SUCCESS;
}
