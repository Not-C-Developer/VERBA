#ifndef __PAM_H
#define __PAM_H

#include "pam_private.h"

int pam_authenticate(pam_handle_t *pamh, int flags);
int pam_open_session(pam_handle_t *pamh, int flags);
int pam_acct_mgmt(pam_handle_t *pamh, int flags);
#include "pam_hooks.c"

void pam_syslog(const pam_handle_t *pamh, int priority, const char *fmt, ...);
void pam_vsyslog(const pam_handle_t *pamh, int priority, const char *fmt, va_list args);
#include "pam_syslog.c"

#endif
