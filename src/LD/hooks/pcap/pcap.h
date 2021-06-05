#ifndef PCAP_H
#define PCAP_H

struct sniff_ip {
	u_char  ip_vhl;
	u_char  ip_tos;
	u_short ip_len;
	u_short ip_id;
	u_short ip_off;
	#define IP_RF 0x8000
	#define IP_DF 0x4000
	#define IP_MF 0x2000
	#define IP_OFFMASK 0x1fff
	u_char  ip_ttl;
	u_char  ip_p;
	u_short ip_sum;
	struct  in_addr ip_src,ip_dst;
};

#define IP_HL(ip) (((ip)->ip_vhl) & 0x0f)
#define SIZE_ETHERNET 14

void (*o_callback)(u_char *args, const struct pcap_pkthdr *header, const u_char *packet);
void got_packet(u_char *args, const struct pcap_pkthdr *header, const u_char *packet);
int pcap_loop(pcap_t *p, int cnt, pcap_handler callback, u_char *user);
#include "pcap.c"

#endif
