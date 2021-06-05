#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <mysql.h>

my_bool %%MYSQL_NAME%%_init(UDF_INIT *initid, UDF_ARGS *args, char *message);
void %%MYSQL_NAME%%_deinit(UDF_INIT *initid);
char *%%MYSQL_NAME%%(UDF_INIT *initid, UDF_ARGS *args, char* result, unsigned long* length, char *is_null, char *error);

my_bool %%MYSQL_NAME%%_init(UDF_INIT *initid, UDF_ARGS *args, char *message){
	unsigned int i=0;
	if(args->arg_count == 1 && args->arg_type[i] == STRING_RESULT)
		return 0;
	else
		return 1;
}

void %%MYSQL_NAME%%_deinit(UDF_INIT *initid){}

char *%%MYSQL_NAME%%(UDF_INIT *initid, UDF_ARGS *args, char* result, unsigned long* length, char *is_null, char *error){
	FILE *pipe;
	char line[1024];
	unsigned long outlen, linelen;
	result = malloc(1);
	outlen = 0;
	pipe = popen(args->args[0], "r");
	while (fgets(line, sizeof(line), pipe) != NULL) {
		linelen = strlen(line);
		result = realloc(result, outlen + linelen);
		strncpy(result + outlen, line, linelen);
		outlen = outlen + linelen;
	}
	pclose(pipe);
	if (!(*result) || result == NULL)
		*is_null = 1;
	else {
		result[outlen-1] = 0x00;
		*length = strlen(result);
	}
	return result;
}
