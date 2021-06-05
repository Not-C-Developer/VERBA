#include <stdlib.h>
#include <stdio.h>
#include <elf.h>
#include <string.h>
#include <getopt.h>

#undef ELF_ST_BIND
#undef ELF_ST_INFO
#if defined(__i386__) || defined(i386) || defined(_M_IX86)
	typedef Elf32_Ehdr T_ehdr;
	typedef Elf32_Shdr T_shdr;
	typedef Elf32_Sym T_sym;
	typedef Elf32_Off T_off;
	typedef Elf32_Addr T_addr;
	typedef Elf32_Word T_word;
	typedef Elf32_Half T_half;
	#define ELF_ST_BIND	ELF32_ST_BIND
	#define ELF_ST_INFO	ELF32_ST_INFO
#elif defined(__x86_64__) || defined(__amd64__) || defined(__x86_64) || defined(_M_AMD64)
	typedef Elf64_Ehdr T_ehdr;
	typedef Elf64_Shdr T_shdr;
	typedef Elf64_Sym T_sym;
        typedef Elf64_Off T_off;
        typedef Elf64_Addr T_addr;
	typedef Elf64_Word T_word;
	typedef Elf64_Half T_half;
	#define ELF_ST_BIND	ELF64_ST_BIND
	#define ELF_ST_INFO	ELF64_ST_INFO
#else
        #error Unknown CPU, please report this to numpy maintainers with information about your platform (OS, CPU and compiler)
#endif

int ElfGetSectionByName(FILE *fd, T_ehdr *ehdr, char *section, T_shdr *shdr);
int ElfGetSectionName(FILE *fd, T_word sh_name, T_shdr *shstrtable, char *res, size_t len);
T_off ElfGetSymbolByName(FILE *fd, T_shdr *symtab, T_shdr *strtab, char *name, T_sym *sym);
void ElfGetSymbolName(FILE *fd, T_word sym_name, T_shdr *strtable, char *res, size_t len);
unsigned long ReorderSymbols(FILE *fd, T_shdr *symtab, T_shdr *strtab, char *name);
int ReoderRelocation(FILE *fd, T_shdr *symtab, T_shdr *strtab, char *name, T_sym *sym);
int ElfGetSectionByIndex(FILE *fd, T_ehdr *ehdr, T_half index, T_shdr *shdr);

int main(int argc, char **argv){
	FILE *fd;
	T_ehdr hdr;
	T_shdr symtab, strtab;
	T_sym sym;
	T_off symoffset;
	T_addr value;
	unsigned long new_index = 0;
	int gflag = 0, vflag = 0, fflag = 0, sym_value = 0, opt;
	char *sym_name;
	long sym_off, str_off;
	if(argc != 4 && argc != 6)
		exit(-1);
	while((opt = getopt(argc, argv, "vsg")) != -1){
		switch(opt){
			case 'g':
				if(argc-1 < optind)
					exit(-2);
				gflag = 1;
				sym_name = argv[optind];
				break;
			case 's':
				if(argc-1 < optind)
					exit(-3);
				fflag = 1;
				sym_name = argv[optind];
				break;
			case 'v':
				if(argc-1 < optind)
					exit(-4);
				vflag = 1;
				sym_value = strtol(argv[optind], (char **)NULL, 16);
				break;
			default:
				exit(-5);
		}
	}
	fd = fopen(argv[argc-1], "r+");
	if(fd == NULL)
		exit(-6);
	if(fread(&hdr, sizeof(T_ehdr), 1, fd) < 1)
		exit(-7);
	sym_off = ElfGetSectionByName(fd, &hdr, ".symtab", &symtab);
	if(sym_off == -1)
		exit(-8);
	str_off = ElfGetSectionByName(fd, &hdr, ".strtab", &strtab);
	if(str_off  == -1)
		exit(-9);
	symoffset = ElfGetSymbolByName(fd, &symtab, &strtab, sym_name, &sym);
	if((int)symoffset == -1)
		exit(-10);
	if(gflag == 1)
		if(ELF_ST_BIND(sym.st_info) == STB_LOCAL){
			unsigned char global;
			unsigned long offset = 0;
			new_index = ReorderSymbols(fd, &symtab, &strtab, sym_name);
			symoffset = ElfGetSymbolByName(fd, &symtab, &strtab, sym_name, &sym);
			if((int)symoffset == -1)
				exit(-11);
			offset = symoffset + 1 + sizeof(T_addr) + 1 + sizeof(T_word)+2;
			if(fseek(fd, offset, SEEK_SET) == -1)
				exit(-12);
			global = ELF_ST_INFO(STB_GLOBAL, STT_FUNC);
			if(fwrite(&global, sizeof(unsigned char), 1, fd) < 1)
				exit(-13);
			if(fseek(fd, sym_off, SEEK_SET) == -1)
				exit(-14);
			symtab.sh_info = new_index;
			if(fwrite(&symtab, sizeof(T_shdr), 1, fd) < 1)
				exit(-15);
		}else{}
	else if(fflag == 1 && vflag == 1){
		memset(&value, 0, sizeof(T_addr));
		memcpy(&value, &sym_value, sizeof(T_addr));
#if defined(__i386__) || defined(i386) || defined(_M_IX86)
		if(fseek(fd, symoffset + sizeof(T_word), SEEK_SET) == -1)
#elif defined(__x86_64__) || defined(__amd64__) || defined(__x86_64) || defined(_M_AMD64)
		if(fseek(fd, symoffset + sizeof(T_word) + 2 * sizeof(unsigned char) + sizeof(T_half), SEEK_SET) == -1)
#endif
			exit(-16);
		if(fwrite(&value, sizeof(T_addr), 1, fd) < 1)
			exit(-17);
		fclose(fd);
	}
	return 0;
}

T_off ElfGetSymbolByName(FILE *fd, T_shdr *symtab, T_shdr *strtab, char *name, T_sym *sym){
	unsigned int i;
	char symname[255];
	for(i=0;i<(symtab->sh_size/symtab->sh_entsize);i++){
		if(fseek(fd, symtab->sh_offset + (i * symtab->sh_entsize), SEEK_SET) == -1)
			exit(-18);
		if(fread(sym, sizeof(T_sym), 1, fd) < 1)
			exit(-19);
		memset(symname, 0, sizeof(symname));
		ElfGetSymbolName(fd, sym->st_name, strtab, symname, sizeof(symname));
		if(!strcmp(symname, name))
			return symtab->sh_offset + (i * symtab->sh_entsize);
	}
	return -1;
}

unsigned long ReorderSymbols(FILE *fd, T_shdr *symtab, T_shdr *strtab, char *name){
	unsigned int i = 0, j = 0;
	char symname[255];
	T_sym *all, temp;
	unsigned long new_index = 0, my_off = 0;
	all = (T_sym *)malloc(sizeof(T_sym) * (symtab->sh_size/symtab->sh_entsize));
	if(all == NULL)
		return -1;
	memset(all, 0, symtab->sh_size/symtab->sh_entsize);
	my_off = symtab->sh_offset;
	for(i = 0; i < (symtab->sh_size/symtab->sh_entsize); i++){
		if(fseek(fd, symtab->sh_offset + (i * symtab->sh_entsize), SEEK_SET) == -1)
			exit(-20);
		if(fread(&all[i], sizeof(T_sym), 1, fd) < 1)
			exit(-21);
		memset(symname, 0, sizeof(symname));
		ElfGetSymbolName(fd, all[i].st_name, strtab, symname, sizeof(symname));
		if(!strcmp(symname, name)){
			j = i;
			continue;
		}
	}
	temp = all[j];
	for(i = j; i < (symtab->sh_size/symtab->sh_entsize); i++){
		if(i+1 >= symtab->sh_size/symtab->sh_entsize)
			break;
		if(ELF_ST_BIND(all[i+1].st_info) == STB_LOCAL)
			all[i] = all[i+1];
		else {
			new_index = i;
			all[i] = temp;
			break;
		}
	}
	if(fseek(fd, my_off, SEEK_SET) == -1)
		exit(-22);
	if(fwrite(all, sizeof(T_sym), symtab->sh_size/symtab->sh_entsize, fd) < (symtab->sh_size/symtab->sh_entsize))
		exit(-23);
	free(all);
	return new_index;
}

int ElfGetSectionByIndex(FILE *fd, T_ehdr *ehdr, T_half index, T_shdr *shdr){
	if(fseek(fd, ehdr->e_shoff + (index * ehdr->e_shentsize), SEEK_SET) == -1)
		exit(-24);
	if(fread(shdr, sizeof(T_shdr), 1, fd) < 1)
		exit(-25);
	return 0;
}

int ElfGetSectionByName(FILE *fd, T_ehdr *ehdr, char *section, T_shdr *shdr){
	int i;
	char name[255];
	T_shdr shstrtable;
	ElfGetSectionByIndex(fd, ehdr, ehdr->e_shstrndx, &shstrtable);
	memset(name, 0, sizeof(name));
	for(i = 0; i < ehdr->e_shnum; i++){
		if(fseek(fd, ehdr->e_shoff + (i * ehdr->e_shentsize), SEEK_SET) == -1)
			exit(-26);
		if(fread(shdr, sizeof(T_shdr), 1, fd) < 1)
			exit(-27);
		ElfGetSectionName(fd, shdr->sh_name, &shstrtable, name, sizeof(name));
		if(!strcmp(name, section))
			return ehdr->e_shoff + (i * ehdr->e_shentsize);
	}
	return -1;
}

int ElfGetSectionName(FILE *fd, T_word sh_name, T_shdr *shstrtable, char *res, size_t len){
	size_t i = 0;
	if(fseek(fd, shstrtable->sh_offset + sh_name, SEEK_SET) == -1)
		exit(-28);
	while((i < len-1) || *res != '\0'){
		*res = fgetc(fd);
		i++;
		res++;
	}
	return 0;
}

void ElfGetSymbolName(FILE *fd, T_word sym_name, T_shdr *strtable, char *res, size_t len){
	size_t i = 0;
	if(fseek(fd, strtable->sh_offset + sym_name, SEEK_SET) == -1)
		exit(-29);
	while((i < len-1) || *res != '\0'){
		*res = fgetc (fd);
		i++;
		res++;
	}
	return;
}
