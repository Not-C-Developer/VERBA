#include <pg_config.h>
#include <postgres.h>
#include <fmgr.h>

#ifdef PG_MODULE_MAGIC
PG_MODULE_MAGIC;
#endif

PG_FUNCTION_INFO_V1(%%POSTGRES_NAME%%);
#if PG_VERSION_NUM < 80300
extern DLLIMPORT Datum %%POSTGRES_NAME%%(PG_FUNCTION_ARGS){
#elif PG_VERSION_NUM >= 80300
extern PGDLLIMPORT Datum %%POSTGRES_NAME%%(PG_FUNCTION_ARGS){
#endif
	text *argv0 = PG_GETARG_TEXT_P(0), *result_text;
	int32 argv0_size = VARSIZE(argv0) - VARHDRSZ, outlen = 0, linelen;
	char *command = (char *)malloc(argv0_size + 1), *result, line[1024];
	FILE *pipe;

	memcpy(command, VARDATA(argv0), argv0_size);
	command[argv0_size] = '\0';
	result = (char *)malloc(1);
	pipe = popen(command, "r");
	while (fgets(line, sizeof(line), pipe) != NULL) {
		linelen = strlen(line);
		result = (char *)realloc(result, outlen + linelen);
		strncpy(result + outlen, line, linelen);
		outlen = outlen + linelen;
	}
	pclose(pipe);
	if (*result)
		result[outlen-1] = 0x00;
	result_text = (text *)malloc(VARHDRSZ + strlen(result));
#if PG_VERSION_NUM < 80300
	VARATT_SIZEP(result_text) = strlen(result) + VARHDRSZ;
#elif PG_VERSION_NUM >= 80300
	SET_VARSIZE(result_text, VARHDRSZ + strlen(result));
#endif
	memcpy(VARDATA(result_text), result, strlen(result));
	PG_RETURN_POINTER(result_text);
}
