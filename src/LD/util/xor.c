static void _xor(char *p){
	int i;
	for(i = 0; i < strlen(p); i++)
		if(p[i] ^ XKEY)
			p[i] ^= XKEY;
}

static void clean(void *var){
	memset(var, 0x00, strlen((char *)var));
	free(var);
}

#define xor(new_name, target) char *new_name = strdup(target); _xor(new_name);
