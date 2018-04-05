#include <stdlib.h>
#include <stdio.h>
#include <stdarg.h>
#include <string.h>
#include <elf.h>
#include <endian.h>
#include <errno.h>
#include <unistd.h>
#include <fcntl.h>
#include <time.h>
#include <limits.h>
#include <grp.h>
#include <sys/types.h>
#include <sys/ipc.h>
#include <sys/msg.h>
#include <sys/wait.h>
#include <sys/time.h>
#include <sys/stat.h>
#include <sys/mount.h>
#include <sys/file.h>
#include <sys/fsuid.h>
#include <sys/personality.h>
#include <sys/prctl.h>
#include <sys/resource.h>
#include <sys/mman.h>
#include <sys/swap.h>
#include <sys/syscall.h>
#include <linux/capability.h>
#include <signal.h>
#include <sched.h>
#ifdef __ia64__
int __clone2(int (*fn)(void *), void *child_stack_base,
             size_t stack_size, int flags, void *arg, ...);
#endif
#include <sys/socket.h>
#include <sys/un.h>
#include <sys/uio.h>
#include <sys/poll.h>
#include <sys/times.h>
#include <sys/shm.h>
#include <sys/sem.h>
#include <sys/statfs.h>
#include <utime.h>
#include <sys/sysinfo.h>
#include <netinet/ip.h>
#include <netinet/tcp.h>
#include <linux/wireless.h>
#include <linux/icmp.h>
#ifdef CONFIG_TIMERFD
#include <sys/timerfd.h>
#endif
#ifdef CONFIG_EVENTFD
#include <sys/eventfd.h>
#endif
#ifdef CONFIG_EPOLL
#include <sys/epoll.h>
#endif
#ifdef CONFIG_SENDFILE
#include <sys/sendfile.h>
#endif

#define termios host_termios
#define winsize host_winsize
#define termio host_termio
#define sgttyb host_sgttyb /* same as target */
#define tchars host_tchars /* same as target */
#define ltchars host_ltchars /* same as target */

#include <linux/termios.h>
#include <linux/unistd.h>
#include <linux/cdrom.h>
#include <linux/hdreg.h>
#include <linux/soundcard.h>
#include <linux/kd.h>
#include <linux/mtio.h>
#include <linux/fs.h>
#if defined(CONFIG_FIEMAP)
#include <linux/fiemap.h>
#endif
#include <linux/fb.h>
#include <linux/vt.h>
#include <linux/dm-ioctl.h>
#include <linux/reboot.h>
#include <linux/route.h>
#include <linux/filter.h>
#include <linux/blkpg.h>

#include "target-sparc.h"
#include "syscall_defs.h"
#include "uname.h"

/////////////////////////////////////////////////////////////////////////////////
// global state
/////////////////////////////////////////////////////////////////////////////////

abi_ulong target_brk;
abi_ulong target_brk_limit;
abi_ulong target_cur_mmap_ptr;
abi_ulong target_mmap_limit;
abi_ulong target_sp;
int target_exit_called;

unsigned long guest_base;
unsigned long guest_max_mem;

/////////////////////////////////////////////////////////////////////////////////
// internal implementation
/////////////////////////////////////////////////////////////////////////////////

#define TIMER_MAGIC 0x0caf0000
#define TIMER_MAGIC_MASK 0xffff000

#define IOV_MAX 1024

#define target_to_host_bitmask(x, tbl) (x)
#define ERRNO_TABLE_SIZE 1200

// convert between guest and host addresses
#define GUEST_BASE guest_base
#define g2h(x) ((void *)((unsigned long)(target_ulong)(x) + GUEST_BASE))

/** do_brk() must return target values and target errnos. */
static abi_long do_brk(abi_ulong new_brk) {
    abi_long mapped_addr;
    int new_alloc_size;

    if (!new_brk) {
        return target_brk;
    }
    
    if (new_brk < target_brk) {
        return target_brk;
    }

    new_brk = HOST_PAGE_ALIGN(new_brk);
    if (new_brk <= target_brk_limit) {
        // Heap contents are initialized to zero, as for anonymous mapped pages.
        if (new_brk > target_brk) memset(g2h(target_brk), 0, new_brk - target_brk);
        // set the brk value
        target_brk = new_brk;
        // done
        return target_brk;
    }
    
    /* For everything else, return the previous break. */
    return target_brk;
}

/**
 *  target_to_host_errno_table[] is initialized from
 * host_to_target_errno_table[] in syscall_init().
 */
static uint16_t target_to_host_errno_table[ERRNO_TABLE_SIZE] = {
};

/**
 * This list is the union of errno values overridden in asm-<arch>/errno.h
 * minus the errnos that are not actually generic to all archs.
 */
static uint16_t host_to_target_errno_table[ERRNO_TABLE_SIZE] = {
    [EIDRM]        = TARGET_EIDRM,
    [ECHRNG]        = TARGET_ECHRNG,
    [EL2NSYNC]        = TARGET_EL2NSYNC,
    [EL3HLT]        = TARGET_EL3HLT,
    [EL3RST]        = TARGET_EL3RST,
    [ELNRNG]        = TARGET_ELNRNG,
    [EUNATCH]        = TARGET_EUNATCH,
    [ENOCSI]        = TARGET_ENOCSI,
    [EL2HLT]        = TARGET_EL2HLT,
    [EDEADLK]        = TARGET_EDEADLK,
    [ENOLCK]        = TARGET_ENOLCK,
    [EBADE]        = TARGET_EBADE,
    [EBADR]            = TARGET_EBADR,
    [EXFULL]        = TARGET_EXFULL,
    [ENOANO]        = TARGET_ENOANO,
    [EBADRQC]        = TARGET_EBADRQC,
    [EBADSLT]        = TARGET_EBADSLT,
    [EBFONT]        = TARGET_EBFONT,
    [ENOSTR]        = TARGET_ENOSTR,
    [ENODATA]        = TARGET_ENODATA,
    [ETIME]            = TARGET_ETIME,
    [ENOSR]            = TARGET_ENOSR,
    [ENONET]        = TARGET_ENONET,
    [ENOPKG]        = TARGET_ENOPKG,
    [EREMOTE]        = TARGET_EREMOTE,
    [ENOLINK]        = TARGET_ENOLINK,
    [EADV]            = TARGET_EADV,
    [ESRMNT]        = TARGET_ESRMNT,
    [ECOMM]            = TARGET_ECOMM,
    [EPROTO]        = TARGET_EPROTO,
    [EDOTDOT]        = TARGET_EDOTDOT,
    [EMULTIHOP]        = TARGET_EMULTIHOP,
    [EBADMSG]        = TARGET_EBADMSG,
    [ENAMETOOLONG]    = TARGET_ENAMETOOLONG,
    [EOVERFLOW]        = TARGET_EOVERFLOW,
    [ENOTUNIQ]        = TARGET_ENOTUNIQ,
    [EBADFD]        = TARGET_EBADFD,
    [EREMCHG]        = TARGET_EREMCHG,
    [ELIBACC]        = TARGET_ELIBACC,
    [ELIBBAD]        = TARGET_ELIBBAD,
    [ELIBSCN]        = TARGET_ELIBSCN,
    [ELIBMAX]        = TARGET_ELIBMAX,
    [ELIBEXEC]        = TARGET_ELIBEXEC,
    [EILSEQ]        = TARGET_EILSEQ,
    [ENOSYS]        = TARGET_ENOSYS,
    [ELOOP]            = TARGET_ELOOP,
    [ERESTART]        = TARGET_ERESTART,
    [ESTRPIPE]        = TARGET_ESTRPIPE,
    [ENOTEMPTY]        = TARGET_ENOTEMPTY,
    [EUSERS]        = TARGET_EUSERS,
    [ENOTSOCK]        = TARGET_ENOTSOCK,
    [EDESTADDRREQ]    = TARGET_EDESTADDRREQ,
    [EMSGSIZE]        = TARGET_EMSGSIZE,
    [EPROTOTYPE]    = TARGET_EPROTOTYPE,
    [ENOPROTOOPT]    = TARGET_ENOPROTOOPT,
    [EPROTONOSUPPORT]    = TARGET_EPROTONOSUPPORT,
    [ESOCKTNOSUPPORT]    = TARGET_ESOCKTNOSUPPORT,
    [EOPNOTSUPP]    = TARGET_EOPNOTSUPP,
    [EPFNOSUPPORT]    = TARGET_EPFNOSUPPORT,
    [EAFNOSUPPORT]    = TARGET_EAFNOSUPPORT,
    [EADDRINUSE]    = TARGET_EADDRINUSE,
    [EADDRNOTAVAIL]    = TARGET_EADDRNOTAVAIL,
    [ENETDOWN]        = TARGET_ENETDOWN,
    [ENETUNREACH]    = TARGET_ENETUNREACH,
    [ENETRESET]        = TARGET_ENETRESET,
    [ECONNABORTED]    = TARGET_ECONNABORTED,
    [ECONNRESET]    = TARGET_ECONNRESET,
    [ENOBUFS]        = TARGET_ENOBUFS,
    [EISCONN]        = TARGET_EISCONN,
    [ENOTCONN]        = TARGET_ENOTCONN,
    [EUCLEAN]        = TARGET_EUCLEAN,
    [ENOTNAM]        = TARGET_ENOTNAM,
    [ENAVAIL]        = TARGET_ENAVAIL,
    [EISNAM]        = TARGET_EISNAM,
    [EREMOTEIO]        = TARGET_EREMOTEIO,
    [ESHUTDOWN]        = TARGET_ESHUTDOWN,
    [ETOOMANYREFS]    = TARGET_ETOOMANYREFS,
    [ETIMEDOUT]        = TARGET_ETIMEDOUT,
    [ECONNREFUSED]    = TARGET_ECONNREFUSED,
    [EHOSTDOWN]        = TARGET_EHOSTDOWN,
    [EHOSTUNREACH]    = TARGET_EHOSTUNREACH,
    [EALREADY]        = TARGET_EALREADY,
    [EINPROGRESS]    = TARGET_EINPROGRESS,
    [ESTALE]        = TARGET_ESTALE,
    [ECANCELED]        = TARGET_ECANCELED,
    [ENOMEDIUM]        = TARGET_ENOMEDIUM,
    [EMEDIUMTYPE]    = TARGET_EMEDIUMTYPE,
#ifdef ENOKEY
    [ENOKEY]        = TARGET_ENOKEY,
#endif
#ifdef EKEYEXPIRED
    [EKEYEXPIRED]    = TARGET_EKEYEXPIRED,
#endif
#ifdef EKEYREVOKED
    [EKEYREVOKED]    = TARGET_EKEYREVOKED,
#endif
#ifdef EKEYREJECTED
    [EKEYREJECTED]    = TARGET_EKEYREJECTED,
#endif
#ifdef EOWNERDEAD
    [EOWNERDEAD]    = TARGET_EOWNERDEAD,
#endif
#ifdef ENOTRECOVERABLE
    [ENOTRECOVERABLE]    = TARGET_ENOTRECOVERABLE,
#endif
};


static inline int is_error(abi_long ret) {
    return (abi_ulong)ret >= (abi_ulong)(-4096);
}

static inline int high2lowuid(int uid) {
    if (uid > 65535)
        return 65534;
    else
        return uid;
}

static inline int high2lowgid(int gid) {
    if (gid > 65535)
        return 65534;
    else
        return gid;
}

static inline int low2highuid(int uid) {
    if ((int16_t)uid == -1)
        return -1;
    else
        return uid;
}

static inline int low2highgid(int gid) {
    if ((int16_t)gid == -1)
        return -1;
    else
        return gid;
}

static inline const char *path(const char *name) {
    return name;
}

static inline void *lock_user(int type, abi_ulong guest_addr, long len, int copy) {
    return g2h(guest_addr);
}

static inline void unlock_user(void *host_ptr, abi_ulong guest_addr, long len) {
}

static inline void *lock_user_string(abi_ulong guest_addr) {
    return g2h(guest_addr);
}

#define lock_user_struct(type, host_ptr, guest_addr, copy)      \
    (host_ptr = lock_user(type, guest_addr, sizeof(*host_ptr), copy))
#define unlock_user_struct(host_ptr, guest_addr, copy)          \
    unlock_user(host_ptr, guest_addr, (copy) ? sizeof(*host_ptr) : 0)
    
static inline int host_to_target_errno(int err) {
    if (host_to_target_errno_table[err])
        return host_to_target_errno_table[err];
    return err;
}

static inline abi_long get_errno(abi_long ret) {
    if (ret == -1)
        return -host_to_target_errno(errno);
    else
        return ret;
}


static inline abi_long copy_from_user_timezone(struct timezone *tz, abi_ulong target_tz_addr) {
    struct target_timezone *target_tz;

    if (!lock_user_struct(VERIFY_READ, target_tz, target_tz_addr, 1)) {
        return -TARGET_EFAULT;
    }

    __get_user(tz->tz_minuteswest, &target_tz->tz_minuteswest);
    __get_user(tz->tz_dsttime, &target_tz->tz_dsttime);

    unlock_user_struct(target_tz, target_tz_addr, 0);

    return 0;
}

static inline abi_long copy_to_user_timeval(abi_ulong target_tv_addr, const struct timeval *tv) {
    struct target_timeval *target_tv;

    if (!lock_user_struct(VERIFY_WRITE, target_tv, target_tv_addr, 0))
        return -TARGET_EFAULT;

    __put_user(tv->tv_sec, &target_tv->tv_sec);
    __put_user(tv->tv_usec, &target_tv->tv_usec);

    unlock_user_struct(target_tv, target_tv_addr, 1);

    return 0;
}

static inline abi_long copy_from_user_timeval(struct timeval *tv, abi_ulong target_tv_addr) {
    struct target_timeval *target_tv;

    if (!lock_user_struct(VERIFY_READ, target_tv, target_tv_addr, 1))
        return -TARGET_EFAULT;

    __get_user(tv->tv_sec, &target_tv->tv_sec);
    __get_user(tv->tv_usec, &target_tv->tv_usec);

    unlock_user_struct(target_tv, target_tv_addr, 0);

    return 0;
}

static inline abi_long
copy_from_user_fdset(fd_set *fds, abi_ulong target_fds_addr, int n) {
    int i, nw, j, k;
    abi_ulong b, *target_fds;

    nw = (n + TARGET_ABI_BITS - 1) / TARGET_ABI_BITS;
    if (!(target_fds = lock_user(VERIFY_READ,
                                 target_fds_addr,
                                 sizeof(abi_ulong) * nw,
                                 1)))
        return -TARGET_EFAULT;

    FD_ZERO(fds);
    k = 0;
    for (i = 0; i < nw; i++) {
        /* grab the abi_ulong */
        __get_user(b, &target_fds[i]);
        for (j = 0; j < TARGET_ABI_BITS; j++) {
            /* check the bit inside the abi_ulong */
            if ((b >> j) & 1)
                FD_SET(k, fds);
            k++;
        }
    }

    unlock_user(target_fds, target_fds_addr, 0);

    return 0;
}

static inline abi_ulong
copy_from_user_fdset_ptr(fd_set *fds, fd_set **fds_ptr, abi_ulong target_fds_addr, int n) {
    if (target_fds_addr) {
        if (copy_from_user_fdset(fds, target_fds_addr, n))
            return -TARGET_EFAULT;
        *fds_ptr = fds;
    } else {
        *fds_ptr = NULL;
    }
    return 0;
}

static inline abi_long
copy_to_user_fdset(abi_ulong target_fds_addr, const fd_set *fds, int n) {
    int i, nw, j, k;
    abi_long v;
    abi_ulong *target_fds;

    nw = (n + TARGET_ABI_BITS - 1) / TARGET_ABI_BITS;
    if (!(target_fds = lock_user(VERIFY_WRITE,
                                 target_fds_addr,
                                 sizeof(abi_ulong) * nw,
                                 0)))
        return -TARGET_EFAULT;

    k = 0;
    for (i = 0; i < nw; i++) {
        v = 0;
        for (j = 0; j < TARGET_ABI_BITS; j++) {
            v |= ((abi_ulong)(FD_ISSET(k, fds) != 0) << j);
            k++;
        }
        __put_user(v, &target_fds[i]);
    }

    unlock_user(target_fds, target_fds_addr, sizeof(abi_ulong) * nw);

    return 0;
}

static inline abi_long target_to_host_timespec(struct timespec *host_ts, abi_ulong target_addr) {
    struct target_timespec *target_ts;

    if (!lock_user_struct(VERIFY_READ, target_ts, target_addr, 1))
        return -TARGET_EFAULT;
    host_ts->tv_sec = tswapal(target_ts->tv_sec);
    host_ts->tv_nsec = tswapal(target_ts->tv_nsec);
    unlock_user_struct(target_ts, target_addr, 0);
    return 0;
}

static inline abi_long host_to_target_clock_t(long ticks) {
    return ticks;
}

static inline int target_to_host_resource(int code) {
    
    switch (code) {
    case TARGET_RLIMIT_AS:
        return RLIMIT_AS;
    case TARGET_RLIMIT_CORE:
        return RLIMIT_CORE;
    case TARGET_RLIMIT_CPU:
        return RLIMIT_CPU;
    case TARGET_RLIMIT_DATA:
        return RLIMIT_DATA;
    case TARGET_RLIMIT_FSIZE:
        return RLIMIT_FSIZE;
    case TARGET_RLIMIT_LOCKS:
        return RLIMIT_LOCKS;
    case TARGET_RLIMIT_MEMLOCK:
        return RLIMIT_MEMLOCK;
    case TARGET_RLIMIT_MSGQUEUE:
        return RLIMIT_MSGQUEUE;
    case TARGET_RLIMIT_NICE:
        return RLIMIT_NICE;
    case TARGET_RLIMIT_NOFILE:
        return RLIMIT_NOFILE;
    case TARGET_RLIMIT_NPROC:
        return RLIMIT_NPROC;
    case TARGET_RLIMIT_RSS:
        return RLIMIT_RSS;
    case TARGET_RLIMIT_RTPRIO:
        return RLIMIT_RTPRIO;
    case TARGET_RLIMIT_SIGPENDING:
        return RLIMIT_SIGPENDING;
    case TARGET_RLIMIT_STACK:
        return RLIMIT_STACK;
    default:
        return code;
    }
}

static inline rlim_t target_to_host_rlim(abi_ulong target_rlim) {
    abi_ulong target_rlim_swap;
    rlim_t result;
    
    target_rlim_swap = tswapal(target_rlim);
    if (target_rlim_swap == TARGET_RLIM_INFINITY)
        return RLIM_INFINITY;

    result = target_rlim_swap;
    if (target_rlim_swap != (rlim_t)result)
        return RLIM_INFINITY;
    
    return result;
}

static inline abi_long host_to_target_rusage(abi_ulong target_addr, const struct rusage *rusage) {    
    struct target_rusage *target_rusage;

    if (!lock_user_struct(VERIFY_WRITE, target_rusage, target_addr, 0))
        return -TARGET_EFAULT;
    target_rusage->ru_utime.tv_sec = tswapal(rusage->ru_utime.tv_sec);
    target_rusage->ru_utime.tv_usec = tswapal(rusage->ru_utime.tv_usec);
    target_rusage->ru_stime.tv_sec = tswapal(rusage->ru_stime.tv_sec);
    target_rusage->ru_stime.tv_usec = tswapal(rusage->ru_stime.tv_usec);
    target_rusage->ru_maxrss = tswapal(rusage->ru_maxrss);
    target_rusage->ru_ixrss = tswapal(rusage->ru_ixrss);
    target_rusage->ru_idrss = tswapal(rusage->ru_idrss);
    target_rusage->ru_isrss = tswapal(rusage->ru_isrss);
    target_rusage->ru_minflt = tswapal(rusage->ru_minflt);
    target_rusage->ru_majflt = tswapal(rusage->ru_majflt);
    target_rusage->ru_nswap = tswapal(rusage->ru_nswap);
    target_rusage->ru_inblock = tswapal(rusage->ru_inblock);
    target_rusage->ru_oublock = tswapal(rusage->ru_oublock);
    target_rusage->ru_msgsnd = tswapal(rusage->ru_msgsnd);
    target_rusage->ru_msgrcv = tswapal(rusage->ru_msgrcv);
    target_rusage->ru_nsignals = tswapal(rusage->ru_nsignals);
    target_rusage->ru_nvcsw = tswapal(rusage->ru_nvcsw);
    target_rusage->ru_nivcsw = tswapal(rusage->ru_nivcsw);
    unlock_user_struct(target_rusage, target_addr, 1);

    return 0;
}

static int is_proc_myself(const char *filename, const char *entry) {
    
    if (!strncmp(filename, "/proc/", strlen("/proc/"))) {
        filename += strlen("/proc/");
        if (!strncmp(filename, "self/", strlen("self/"))) {
            filename += strlen("self/");
        } else if (*filename >= '1' && *filename <= '9') {
            char myself[80];
            snprintf(myself, sizeof(myself), "%d/", getpid());
            if (!strncmp(filename, myself, strlen(myself))) {
                filename += strlen(myself);
            } else {
                return 0;
            }
        } else {
            return 0;
        }
        if (!strcmp(filename, entry)) {
            return 1;
        }
    }
    return 0;
}

static inline uint64_t target_offset64(uint32_t word0, uint32_t word1) {
#ifdef TARGET_WORDS_BIGENDIAN
    return ((uint64_t)word0 << 32) | word1;
#else
    return ((uint64_t)word1 << 32) | word0;
#endif
}

#if defined(TARGET_NR_timer_create)
// Maxiumum of 32 active POSIX timers allowed at any one time.
static timer_t g_posix_timers[32] = { 0, } ;

static inline int next_free_host_timer(void) {
    int k ;
    // FIXME: Does finding the next free slot require a lock?
    for (k = 0; k < 32; k++) {
        if (g_posix_timers[k] == 0) {
            g_posix_timers[k] = (timer_t) 1;
            return k;
        }
    }
    return -1;
}
#endif

static inline abi_long target_to_host_itimerspec(struct itimerspec *host_itspec, abi_ulong target_addr) {
    struct target_itimerspec *target_itspec;

    if (!lock_user_struct(VERIFY_READ, target_itspec, target_addr, 1)) {
        return -TARGET_EFAULT;
    }

    host_itspec->it_interval.tv_sec = tswapal(target_itspec->it_interval.tv_sec);
    host_itspec->it_interval.tv_nsec = tswapal(target_itspec->it_interval.tv_nsec);
    host_itspec->it_value.tv_sec = tswapal(target_itspec->it_value.tv_sec);
    host_itspec->it_value.tv_nsec = tswapal(target_itspec->it_value.tv_nsec);

    unlock_user_struct(target_itspec, target_addr, 1);
    return 0;
}

static inline abi_long host_to_target_itimerspec(abi_ulong target_addr, struct itimerspec *host_its) {
    struct target_itimerspec *target_itspec;

    if (!lock_user_struct(VERIFY_WRITE, target_itspec, target_addr, 0)) {
        return -TARGET_EFAULT;
    }

    target_itspec->it_interval.tv_sec = tswapal(host_its->it_interval.tv_sec);
    target_itspec->it_interval.tv_nsec = tswapal(host_its->it_interval.tv_nsec);
    target_itspec->it_value.tv_sec = tswapal(host_its->it_value.tv_sec);
    target_itspec->it_value.tv_nsec = tswapal(host_its->it_value.tv_nsec);

    unlock_user_struct(target_itspec, target_addr, 0);
    return 0;
}

// do_select() must return target values and target errnos.
static abi_long
do_select(int n, abi_ulong rfd_addr, abi_ulong wfd_addr, abi_ulong efd_addr, abi_ulong target_tv_addr) {
    fd_set rfds, wfds, efds;
    fd_set *rfds_ptr, *wfds_ptr, *efds_ptr;
    struct timeval tv, *tv_ptr;
    abi_long ret;

    ret = copy_from_user_fdset_ptr(&rfds, &rfds_ptr, rfd_addr, n);
    if (ret) {
        return ret;
    }
    ret = copy_from_user_fdset_ptr(&wfds, &wfds_ptr, wfd_addr, n);
    if (ret) {
        return ret;
    }
    ret = copy_from_user_fdset_ptr(&efds, &efds_ptr, efd_addr, n);
    if (ret) {
        return ret;
    }

    if (target_tv_addr) {
        if (copy_from_user_timeval(&tv, target_tv_addr))
            return -TARGET_EFAULT;
        tv_ptr = &tv;
    } else {
        tv_ptr = NULL;
    }

    ret = get_errno(select(n, rfds_ptr, wfds_ptr, efds_ptr, tv_ptr));

    if (!is_error(ret)) {
        if (rfd_addr && copy_to_user_fdset(rfd_addr, &rfds, n))
            return -TARGET_EFAULT;
        if (wfd_addr && copy_to_user_fdset(wfd_addr, &wfds, n))
            return -TARGET_EFAULT;
        if (efd_addr && copy_to_user_fdset(efd_addr, &efds, n))
            return -TARGET_EFAULT;

        if (target_tv_addr && copy_to_user_timeval(target_tv_addr, &tv))
            return -TARGET_EFAULT;
    }

    return ret;
}

#if defined(TARGET_NR_stat64) || defined(TARGET_NR_newfstatat)
static inline abi_long host_to_target_stat64(abi_ulong target_addr, struct stat *host_st) {
        
#if defined(TARGET_HAS_STRUCT_STAT64)
    struct target_stat64 *target_st;
#else
    struct target_stat *target_st;
#endif

    if (!lock_user_struct(VERIFY_WRITE, target_st, target_addr, 0))
        return -TARGET_EFAULT;
    memset(target_st, 0, sizeof(*target_st));
    __put_user(host_st->st_dev, &target_st->st_dev);
    __put_user(host_st->st_ino, &target_st->st_ino);
#ifdef TARGET_STAT64_HAS_BROKEN_ST_INO
    __put_user(host_st->st_ino, &target_st->__st_ino);
#endif
    __put_user(host_st->st_mode, &target_st->st_mode);
    __put_user(host_st->st_nlink, &target_st->st_nlink);
    __put_user(host_st->st_uid, &target_st->st_uid);
    __put_user(host_st->st_gid, &target_st->st_gid);
    __put_user(host_st->st_rdev, &target_st->st_rdev);
    /* XXX: better use of kernel struct */
    __put_user(host_st->st_size, &target_st->st_size);
    __put_user(host_st->st_blksize, &target_st->st_blksize);
    __put_user(host_st->st_blocks, &target_st->st_blocks);
    __put_user(host_st->st_atime, &target_st->target_st_atime);
    __put_user(host_st->st_mtime, &target_st->target_st_mtime);
    __put_user(host_st->st_ctime, &target_st->target_st_ctime);
    unlock_user_struct(target_st, target_addr, 1);
    
    return 0;
}
#endif

static struct iovec *lock_iovec(int type, abi_ulong target_addr, int count, int copy) {
    struct target_iovec *target_vec;
    struct iovec *vec;
    abi_ulong total_len, max_len;
    int i;
    int err = 0;
    int bad_address = 0;

    if (count == 0) {
        errno = 0;
        return NULL;
    }
    if (count < 0 || count > IOV_MAX) {
        errno = EINVAL;
        return NULL;
    }

    vec = calloc(count, sizeof(struct iovec));
    if (vec == NULL) {
        errno = ENOMEM;
        return NULL;
    }

    target_vec = lock_user(VERIFY_READ, target_addr,
                           count * sizeof(struct target_iovec), 1);
    if (target_vec == NULL) {
        err = EFAULT;
        goto fail2;
    }

    /* ??? If host page size > target page size, this will result in a
       value larger than what we can actually support.  */
    max_len = 0x7fffffff & TARGET_PAGE_MASK;
    total_len = 0;

    for (i = 0; i < count; i++) {
        abi_ulong base = tswapal(target_vec[i].iov_base);
        abi_long len = tswapal(target_vec[i].iov_len);

        if (len < 0) {
            err = EINVAL;
            goto fail;
        } else if (len == 0) {
            /* Zero length pointer is ignored.  */
            vec[i].iov_base = 0;
        } else {
            vec[i].iov_base = lock_user(type, base, len, copy);
            /* If the first buffer pointer is bad, this is a fault.  But
             * subsequent bad buffers will result in a partial write; this
             * is realized by filling the vector with null pointers and
             * zero lengths. */
            if (!vec[i].iov_base) {
                if (i == 0) {
                    err = EFAULT;
                    goto fail;
                } else {
                    bad_address = 1;
                }
            }
            if (bad_address) {
                len = 0;
            }
            if (len > max_len - total_len) {
                len = max_len - total_len;
            }
        }
        vec[i].iov_len = len;
        total_len += len;
    }

    unlock_user(target_vec, target_addr, 0);
    return vec;

 fail:
    unlock_user(target_vec, target_addr, 0);
 fail2:
    free(vec);
    errno = err;
    return NULL;
}

static void unlock_iovec(struct iovec *vec, abi_ulong target_addr, int count, int copy) {
    struct target_iovec *target_vec;
    int i;

    target_vec = lock_user(VERIFY_READ, target_addr,
                           count * sizeof(struct target_iovec), 1);
    if (target_vec) {
        for (i = 0; i < count; i++) {
            abi_ulong base = tswapal(target_vec[i].iov_base);
            abi_long len = tswapal(target_vec[i].iov_base);
            if (len < 0) {
                break;
            }
            unlock_user(vec[i].iov_base, base, copy ? vec[i].iov_len : 0);
        }
        unlock_user(target_vec, target_addr, 0);
    }

    free(vec);
}

static inline abi_ulong host_to_target_rlim(rlim_t rlim) {
    abi_ulong target_rlim_swap;
    abi_ulong result;
    
    if (rlim == RLIM_INFINITY || rlim != (abi_long)rlim)
        target_rlim_swap = TARGET_RLIM_INFINITY;
    else
        target_rlim_swap = rlim;
    result = tswapal(target_rlim_swap);
    
    return result;
}

static inline abi_long host_to_target_timespec(abi_ulong target_addr, struct timespec *host_ts) {
    struct target_timespec *target_ts;

    if (!lock_user_struct(VERIFY_WRITE, target_ts, target_addr, 0))
        return -TARGET_EFAULT;
    target_ts->tv_sec = tswapal(host_ts->tv_sec);
    target_ts->tv_nsec = tswapal(host_ts->tv_nsec);
    unlock_user_struct(target_ts, target_addr, 1);
    return 0;
}

static target_timer_t get_timer_id(abi_long arg) {
    target_timer_t timerid = arg;

    if ((timerid & TIMER_MAGIC_MASK) != TIMER_MAGIC) {
        return -TARGET_EINVAL;
    }

    timerid &= 0xffff;

    if (timerid >= 32) {
        return -TARGET_EINVAL;
    }

    return timerid;
}

static abi_long target_mmap(abi_ulong start, abi_ulong len, int prot, int flags, int fd, abi_ulong offset) {

    if (fd >= 0) {
        fprintf(stderr, "file mmap not supported");
        errno = EINVAL;
        return -1;
    }

    if (flags & MAP_FIXED) {
        fprintf(stderr, "fixed mmap unsupported");
        errno = EINVAL;
        return -1;
    }

    // just bump the mmap ptr if enough memory, else fail
    len = TARGET_PAGE_ALIGN(len);
    if (len + target_cur_mmap_ptr < target_mmap_limit) {
        start = target_cur_mmap_ptr;
        target_cur_mmap_ptr += len;
        return start;
    } else {
        errno = ENOMEM;
        return -1;
    }
}

static abi_long target_munmap(abi_ulong start, abi_ulong len) {
	// just return success
	return 0;
}

static abi_long do_syscall(int num, abi_long arg1, abi_long arg2,
                     abi_long arg3, abi_long arg4, abi_long arg5, 
                     abi_long arg6, abi_long arg7, abi_long arg8)
{
    abi_long ret;
    struct stat st;
    struct statfs stfs;
    void *p;

    switch(num) {
        
    case TARGET_NR_exit:
        target_exit_called = 1;
        break;

    case TARGET_NR_read:
        if (arg3 == 0)
            ret = 0;
        else {
            if (!(p = lock_user(VERIFY_WRITE, arg2, arg3, 0)))
                goto efault;
            ret = get_errno(read(arg1, p, arg3));
            unlock_user(p, arg2, ret);
        }
        break;

    case TARGET_NR_write:
        if (!(p = lock_user(VERIFY_READ, arg2, arg3, 1)))
            goto efault;
        ret = get_errno(write(arg1, p, arg3));
        unlock_user(p, arg2, 0);
        break;

    case TARGET_NR_open:
        if (!(p = lock_user_string(arg1)))
            goto efault;
        ret = get_errno(open(p, target_to_host_bitmask(arg2, fcntl_flags_tbl), arg3));
        unlock_user(p, arg1, 0);
        break;
        
    case TARGET_NR_openat:
        goto unimplemented;
        break;

    case TARGET_NR_close:
        ret = get_errno(close(arg1));
        break;

    case TARGET_NR_brk:
        ret = do_brk(arg1);
        break;
        
    case TARGET_NR_fork:
        goto unimplemented;
        break;

#ifdef TARGET_NR_waitpid
    case TARGET_NR_waitpid:
        goto unimplemented;
        break;
#endif

#ifdef TARGET_NR_waitid
    case TARGET_NR_waitid:
        goto unimplemented;
        break;
#endif

#ifdef TARGET_NR_creat
    case TARGET_NR_creat:
        if (!(p = lock_user_string(arg1)))
            goto efault;
        ret = get_errno(creat(p, arg2));
        unlock_user(p, arg1, 0);
        break;
#endif

    case TARGET_NR_link:
        {
            void * p2;
            p = lock_user_string(arg1);
            p2 = lock_user_string(arg2);
            if (!p || !p2)
                ret = -TARGET_EFAULT;
            else
                ret = get_errno(link(p, p2));
            unlock_user(p2, arg2, 0);
            unlock_user(p, arg1, 0);
        }
        break;
        
#if defined(TARGET_NR_linkat)
    case TARGET_NR_linkat:
        {
            void * p2 = NULL;
            if (!arg2 || !arg4)
                goto efault;
            p  = lock_user_string(arg2);
            p2 = lock_user_string(arg4);
            if (!p || !p2)
                ret = -TARGET_EFAULT;
            else
                ret = get_errno(linkat(arg1, p, arg3, p2, arg5));
            unlock_user(p, arg2, 0);
            unlock_user(p2, arg4, 0);
        }
        break;
#endif

    case TARGET_NR_unlink:
        if (!(p = lock_user_string(arg1)))
            goto efault;
        ret = get_errno(unlink(p));
        unlock_user(p, arg1, 0);
        break;
        
#if defined(TARGET_NR_unlinkat)
    case TARGET_NR_unlinkat:
        if (!(p = lock_user_string(arg2)))
            goto efault;
        ret = get_errno(unlinkat(arg1, p, arg3));
        unlock_user(p, arg2, 0);
        break;
#endif

    case TARGET_NR_execve:
        goto unimplemented;
        break;

    case TARGET_NR_chdir:
        if (!(p = lock_user_string(arg1)))
            goto efault;
        ret = get_errno(chdir(p));
        unlock_user(p, arg1, 0);
        break;

#ifdef TARGET_NR_time
    case TARGET_NR_time:
        {
            time_t host_time;
            ret = get_errno(time(&host_time));
            if (!is_error(ret)
                && arg1
                && put_user_sal(host_time, arg1))
                goto efault;
        }
        break;
#endif

    case TARGET_NR_mknod:
        if (!(p = lock_user_string(arg1)))
            goto efault;
        ret = get_errno(mknod(p, arg2, arg3));
        unlock_user(p, arg1, 0);
        break;
        
#if defined(TARGET_NR_mknodat)
    case TARGET_NR_mknodat:
        if (!(p = lock_user_string(arg2)))
            goto efault;
        ret = get_errno(mknodat(arg1, p, arg3, arg4));
        unlock_user(p, arg2, 0);
        break;
#endif

    case TARGET_NR_chmod:
        if (!(p = lock_user_string(arg1)))
            goto efault;
        ret = get_errno(chmod(p, arg2));
        unlock_user(p, arg1, 0);
        break;
        
    case TARGET_NR_lseek:
        ret = get_errno(lseek(arg1, arg2, arg3));
        break;
        
#ifdef TARGET_NR_getpid
    case TARGET_NR_getpid:
        ret = get_errno(getpid());
        break;
#endif

    case TARGET_NR_mount:
        goto unimplemented;
        break;

#ifdef TARGET_NR_umount
    case TARGET_NR_umount:
        goto unimplemented;
        break;
#endif

#ifdef TARGET_NR_stime
    case TARGET_NR_stime:
        {
            time_t host_time;
            if (get_user_sal(host_time, arg1))
                goto efault;
            ret = get_errno(stime(&host_time));
        }
        break;
#endif

    case TARGET_NR_ptrace:
        goto unimplemented;
        break;

#ifdef TARGET_NR_alarm /* not on alpha */
    case TARGET_NR_alarm:
        goto unimplemented;
        break;
#endif

#ifdef TARGET_NR_oldfstat
    case TARGET_NR_oldfstat:
        goto unimplemented;
        break;
#endif

#ifdef TARGET_NR_pause
    case TARGET_NR_pause:
        goto unimplemented;
        break;
#endif

#ifdef TARGET_NR_utime
    case TARGET_NR_utime:
        {
            struct utimbuf tbuf, *host_tbuf;
            struct target_utimbuf *target_tbuf;
            if (arg2) {
                if (!lock_user_struct(VERIFY_READ, target_tbuf, arg2, 1))
                    goto efault;
                tbuf.actime = tswapal(target_tbuf->actime);
                tbuf.modtime = tswapal(target_tbuf->modtime);
                unlock_user_struct(target_tbuf, arg2, 0);
                host_tbuf = &tbuf;
            } else {
                host_tbuf = NULL;
            }
            if (!(p = lock_user_string(arg1)))
                goto efault;
            ret = get_errno(utime(p, host_tbuf));
            unlock_user(p, arg1, 0);
        }
        break;
#endif

    case TARGET_NR_utimes:
        {
            struct timeval *tvp, tv[2];
            if (arg2) {
                if (copy_from_user_timeval(&tv[0], arg2)
                    || copy_from_user_timeval(&tv[1], arg2 + sizeof(struct target_timeval)))
                    goto efault;
                tvp = tv;
            } else {
                tvp = NULL;
            }
            if (!(p = lock_user_string(arg1)))
                goto efault;
            ret = get_errno(utimes(p, tvp));
            unlock_user(p, arg1, 0);
        }
        break;

#if defined(TARGET_NR_futimesat)
    case TARGET_NR_futimesat:
        {
            struct timeval *tvp, tv[2];
            if (arg3) {
                if (copy_from_user_timeval(&tv[0], arg3)
                    || copy_from_user_timeval(&tv[1], arg3 + sizeof(struct target_timeval)))
                    goto efault;
                tvp = tv;
            } else {
                tvp = NULL;
            }
            if (!(p = lock_user_string(arg2)))
                goto efault;
            ret = get_errno(futimesat(arg1, path(p), tvp));
            unlock_user(p, arg2, 0);
        }
        break;
#endif

#ifdef TARGET_NR_stty
    case TARGET_NR_stty:
        goto unimplemented;
        break;
#endif

#ifdef TARGET_NR_gtty
    case TARGET_NR_gtty:
        goto unimplemented;
        break;
#endif

    case TARGET_NR_access:
        if (!(p = lock_user_string(arg1)))
            goto efault;
        ret = get_errno(access(path(p), arg2));
        unlock_user(p, arg1, 0);
        break;

#if defined(TARGET_NR_faccessat) && defined(__NR_faccessat)
    case TARGET_NR_faccessat:
        if (!(p = lock_user_string(arg2)))
            goto efault;
        ret = get_errno(faccessat(arg1, p, arg3, 0));
        unlock_user(p, arg2, 0);
        break;
#endif

#ifdef TARGET_NR_nice
    case TARGET_NR_nice:
        ret = get_errno(nice(arg1));
        break;
#endif

#ifdef TARGET_NR_ftime
    case TARGET_NR_ftime:
        goto unimplemented;
        break;
#endif

    case TARGET_NR_sync:
        sync();
        ret = 0;
        break;
        
    case TARGET_NR_kill:
        goto unimplemented;
        break;
        
    case TARGET_NR_rename:
        {
            void *p2;
            p = lock_user_string(arg1);
            p2 = lock_user_string(arg2);
            if (!p || !p2)
                ret = -TARGET_EFAULT;
            else
                ret = get_errno(rename(p, p2));
            unlock_user(p2, arg2, 0);
            unlock_user(p, arg1, 0);
        }
        break;
        
#if defined(TARGET_NR_renameat)
    case TARGET_NR_renameat:
        {
            void *p2;
            p  = lock_user_string(arg2);
            p2 = lock_user_string(arg4);
            if (!p || !p2)
                ret = -TARGET_EFAULT;
            else
                ret = get_errno(renameat(arg1, p, arg3, p2));
            unlock_user(p2, arg4, 0);
            unlock_user(p, arg2, 0);
        }
        break;
#endif

    case TARGET_NR_mkdir:
        if (!(p = lock_user_string(arg1)))
            goto efault;
        ret = get_errno(mkdir(p, arg2));
        unlock_user(p, arg1, 0);
        break;
        
#if defined(TARGET_NR_mkdirat)
    case TARGET_NR_mkdirat:
        if (!(p = lock_user_string(arg2)))
            goto efault;
        ret = get_errno(mkdirat(arg1, p, arg3));
        unlock_user(p, arg2, 0);
        break;
#endif

    case TARGET_NR_rmdir:
        if (!(p = lock_user_string(arg1)))
            goto efault;
        ret = get_errno(rmdir(p));
        unlock_user(p, arg1, 0);
        break;
        
    case TARGET_NR_dup:
        ret = get_errno(dup(arg1));
        break;
        
    case TARGET_NR_pipe:
        goto unimplemented;
        break;

#ifdef TARGET_NR_pipe2
    case TARGET_NR_pipe2:
        goto unimplemented;
        break;
#endif

    case TARGET_NR_times:
        {
            struct target_tms *tmsp;
            struct tms tms;
            ret = get_errno(times(&tms));
            if (arg1) {
                tmsp = lock_user(VERIFY_WRITE, arg1, sizeof(struct target_tms), 0);
                if (!tmsp)
                    goto efault;
                tmsp->tms_utime = tswapal(host_to_target_clock_t(tms.tms_utime));
                tmsp->tms_stime = tswapal(host_to_target_clock_t(tms.tms_stime));
                tmsp->tms_cutime = tswapal(host_to_target_clock_t(tms.tms_cutime));
                tmsp->tms_cstime = tswapal(host_to_target_clock_t(tms.tms_cstime));
            }
            if (!is_error(ret))
                ret = host_to_target_clock_t(ret);
        }
        break;
        
#ifdef TARGET_NR_prof
    case TARGET_NR_prof:
        goto unimplemented;
        break;        
#endif

#ifdef TARGET_NR_signal
    case TARGET_NR_signal:
        goto unimplemented;
        break;        
#endif

    case TARGET_NR_acct:
        goto unimplemented;
        break;        
        
#ifdef TARGET_NR_umount2
    case TARGET_NR_umount2:
        goto unimplemented;
        break;        
#endif

#ifdef TARGET_NR_lock
    case TARGET_NR_lock:
        goto unimplemented;
        break;        
#endif

    case TARGET_NR_ioctl:
        goto unimplemented;
        break;
        
    case TARGET_NR_fcntl:
        goto unimplemented;
        break;
        
#ifdef TARGET_NR_mpx
    case TARGET_NR_mpx:
        goto unimplemented;
        break;        
#endif

    case TARGET_NR_setpgid:
        ret = get_errno(setpgid(arg1, arg2));
        break;

#ifdef TARGET_NR_ulimit
    case TARGET_NR_ulimit:
        goto unimplemented;
        break;        
#endif

#ifdef TARGET_NR_oldolduname
    case TARGET_NR_oldolduname:
        goto unimplemented;
        break;        
#endif

    case TARGET_NR_umask:
        ret = get_errno(umask(arg1));
        break;

    case TARGET_NR_chroot:
        if (!(p = lock_user_string(arg1)))
            goto efault;
        ret = get_errno(chroot(p));
        unlock_user(p, arg1, 0);
        break;

    case TARGET_NR_ustat:
        goto unimplemented;
        break;        

    case TARGET_NR_dup2:
        ret = get_errno(dup2(arg1, arg2));
        break;

#if defined(CONFIG_DUP3) && defined(TARGET_NR_dup3)
    case TARGET_NR_dup3:
        goto unimplemented;
        break;
#endif

#ifdef TARGET_NR_getppid
    case TARGET_NR_getppid:
        ret = get_errno(getppid());
        break;
#endif

    case TARGET_NR_getpgrp:
        ret = get_errno(getpgrp());
        break;

    case TARGET_NR_setsid:
        ret = get_errno(setsid());
        break;

#ifdef TARGET_NR_sigaction
    case TARGET_NR_sigaction:
        goto unimplemented;
        break;
#endif

    case TARGET_NR_rt_sigaction:
        goto unimplemented;
        break;
    
#ifdef TARGET_NR_sgetmask
    case TARGET_NR_sgetmask:
        goto unimplemented;
        break;
#endif

#ifdef TARGET_NR_ssetmask
    case TARGET_NR_ssetmask:
        goto unimplemented;
        break;
#endif

#ifdef TARGET_NR_sigprocmask
    case TARGET_NR_sigprocmask:
        goto unimplemented;
        break;
#endif

    case TARGET_NR_rt_sigprocmask:
        goto unimplemented;
        break;

#ifdef TARGET_NR_sigpending
    case TARGET_NR_sigpending:
        goto unimplemented;
        break;
#endif

    case TARGET_NR_rt_sigpending:
        goto unimplemented;
        break;

#ifdef TARGET_NR_sigsuspend
    case TARGET_NR_sigsuspend:
        goto unimplemented;
        break;
#endif

    case TARGET_NR_rt_sigsuspend:
        goto unimplemented;
        break;

    case TARGET_NR_rt_sigtimedwait:
        goto unimplemented;
        break;

    case TARGET_NR_rt_sigqueueinfo:
        goto unimplemented;
        break;

#ifdef TARGET_NR_sigreturn
    case TARGET_NR_sigreturn:
        goto unimplemented;
        break;
#endif

    case TARGET_NR_rt_sigreturn:
        goto unimplemented;
        break;

    case TARGET_NR_sethostname:
        if (!(p = lock_user_string(arg1)))
            goto efault;
        ret = get_errno(sethostname(p, arg2));
        unlock_user(p, arg1, 0);
        break;

    case TARGET_NR_setrlimit:
        {
            int resource = target_to_host_resource(arg1);
            struct target_rlimit *target_rlim;
            struct rlimit rlim;
            if (!lock_user_struct(VERIFY_READ, target_rlim, arg2, 1))
                goto efault;
            rlim.rlim_cur = target_to_host_rlim(target_rlim->rlim_cur);
            rlim.rlim_max = target_to_host_rlim(target_rlim->rlim_max);
            unlock_user_struct(target_rlim, arg2, 0);
            ret = get_errno(setrlimit(resource, &rlim));
        }
        break;

    case TARGET_NR_getrlimit:
        {
            int resource = target_to_host_resource(arg1);
            struct target_rlimit *target_rlim;
            struct rlimit rlim;

            ret = get_errno(getrlimit(resource, &rlim));
            if (!is_error(ret)) {
                if (!lock_user_struct(VERIFY_WRITE, target_rlim, arg2, 0))
                    goto efault;
                target_rlim->rlim_cur = host_to_target_rlim(rlim.rlim_cur);
                target_rlim->rlim_max = host_to_target_rlim(rlim.rlim_max);
                unlock_user_struct(target_rlim, arg2, 1);
            }
        }
        break;

    case TARGET_NR_getrusage:
        {
            struct rusage rusage;
            ret = get_errno(getrusage(arg1, &rusage));
            if (!is_error(ret)) {
                ret = host_to_target_rusage(arg2, &rusage);
            }
        }
        break;

    case TARGET_NR_gettimeofday:
        {
            struct timeval tv;
            ret = get_errno(gettimeofday(&tv, NULL));
            if (!is_error(ret)) {
                if (copy_to_user_timeval(arg1, &tv))
                    goto efault;
            }
        }
        break;

    case TARGET_NR_settimeofday:
        {
            struct timeval tv, *ptv = NULL;
            struct timezone tz, *ptz = NULL;

            if (arg1) {
                if (copy_from_user_timeval(&tv, arg1)) {
                    goto efault;
                }
                ptv = &tv;
            }

            if (arg2) {
                if (copy_from_user_timezone(&tz, arg2)) {
                    goto efault;
                }
                ptz = &tz;
            }

            ret = get_errno(settimeofday(ptv, ptz));
        }
        break;

#if defined(TARGET_NR_select)
    case TARGET_NR_select:
        {
            struct target_sel_arg_struct *sel;
            abi_ulong inp, outp, exp, tvp;
            long nsel;

            if (!lock_user_struct(VERIFY_READ, sel, arg1, 1))
                goto efault;
            nsel = tswapal(sel->n);
            inp = tswapal(sel->inp);
            outp = tswapal(sel->outp);
            exp = tswapal(sel->exp);
            tvp = tswapal(sel->tvp);
            unlock_user_struct(sel, arg1, 0);
            ret = do_select(nsel, inp, outp, exp, tvp);
        }
        break;
#endif

#ifdef TARGET_NR_pselect6
    case TARGET_NR_pselect6:
        goto unimplemented;
        break;
#endif

    case TARGET_NR_symlink:
        {
            void *p2;
            p = lock_user_string(arg1);
            p2 = lock_user_string(arg2);
            if (!p || !p2)
                ret = -TARGET_EFAULT;
            else
                ret = get_errno(symlink(p, p2));
            unlock_user(p2, arg2, 0);
            unlock_user(p, arg1, 0);
        }
        break;

#if defined(TARGET_NR_symlinkat)
    case TARGET_NR_symlinkat:
        {
            void *p2;
            p  = lock_user_string(arg1);
            p2 = lock_user_string(arg3);
            if (!p || !p2)
                ret = -TARGET_EFAULT;
            else
                ret = get_errno(symlinkat(p, arg2, p2));
            unlock_user(p2, arg3, 0);
            unlock_user(p, arg1, 0);
        }
        break;
#endif

#ifdef TARGET_NR_oldlstat
    case TARGET_NR_oldlstat:
        goto unimplemented;
        break;
#endif

    case TARGET_NR_readlink:
        goto unimplemented;
        break;

#if defined(TARGET_NR_readlinkat)
    case TARGET_NR_readlinkat:
        goto unimplemented;
        break;
#endif

#ifdef TARGET_NR_uselib
    case TARGET_NR_uselib:
        goto unimplemented;
        break;
#endif

#ifdef TARGET_NR_swapon
    case TARGET_NR_swapon:
        goto unimplemented;
        break;
#endif

    case TARGET_NR_reboot:
        goto unimplemented;
        break;

#ifdef TARGET_NR_readdir
    case TARGET_NR_readdir:
        goto unimplemented;
        break;
#endif

#ifdef TARGET_NR_mmap
    case TARGET_NR_mmap:
        ret = get_errno(target_mmap(arg1, arg2, arg3,
                                    target_to_host_bitmask(arg4, mmap_flags_tbl),
                                    arg5, arg6));
        break;
#endif

#ifdef TARGET_NR_mmap2
    case TARGET_NR_mmap2:
#ifndef MMAP_SHIFT
#define MMAP_SHIFT 12
#endif
        ret = get_errno(target_mmap(arg1, arg2, arg3,
                                    target_to_host_bitmask(arg4, mmap_flags_tbl),
                                    arg5,
                                    arg6 << MMAP_SHIFT));
        break;
#endif

    case TARGET_NR_munmap:
        ret = get_errno(target_munmap(arg1, arg2));
        break;

    case TARGET_NR_mprotect:
        goto unimplemented;
        break;
        
#ifdef TARGET_NR_mremap
    case TARGET_NR_mremap:
        goto unimplemented;
        break;
#endif

#ifdef TARGET_NR_msync
    case TARGET_NR_msync:
        ret = get_errno(msync(g2h(arg1), arg2, arg3));
        break;
#endif

#ifdef TARGET_NR_mlock
    case TARGET_NR_mlock:
        ret = get_errno(mlock(g2h(arg1), arg2));
        break;
#endif

#ifdef TARGET_NR_munlock
    case TARGET_NR_munlock:
        ret = get_errno(munlock(g2h(arg1), arg2));
        break;
#endif

#ifdef TARGET_NR_mlockall
    case TARGET_NR_mlockall:
        goto unimplemented;
        break;
#endif

#ifdef TARGET_NR_munlockall
    case TARGET_NR_munlockall:
        ret = get_errno(munlockall());
        break;
#endif

    case TARGET_NR_truncate:
        if (!(p = lock_user_string(arg1)))
            goto efault;
        ret = get_errno(truncate(p, arg2));
        unlock_user(p, arg1, 0);
        break;

    case TARGET_NR_ftruncate:
        ret = get_errno(ftruncate(arg1, arg2));
        break;

    case TARGET_NR_fchmod:
        ret = get_errno(fchmod(arg1, arg2));
        break;

#if defined(TARGET_NR_fchmodat)
    case TARGET_NR_fchmodat:
        if (!(p = lock_user_string(arg2)))
            goto efault;
        ret = get_errno(fchmodat(arg1, p, arg3, 0));
        unlock_user(p, arg2, 0);
        break;
#endif

    case TARGET_NR_getpriority:
        /* Note that negative values are valid for getpriority, so we must
           differentiate based on errno settings.  */
        errno = 0;
        ret = getpriority(arg1, arg2);
        if (ret == -1 && errno != 0) {
            ret = -host_to_target_errno(errno);
            break;
        }
        /* Return value is a biased priority to avoid negative numbers.  */
        ret = 20 - ret;
        break;

    case TARGET_NR_setpriority:
        ret = get_errno(setpriority(arg1, arg2, arg3));
        break;

#ifdef TARGET_NR_profil
    case TARGET_NR_profil:
        goto unimplemented;
        break;
#endif

    case TARGET_NR_statfs:
        if (!(p = lock_user_string(arg1)))
            goto efault;
        ret = get_errno(statfs(path(p), &stfs));
        unlock_user(p, arg1, 0);
    convert_statfs:
        if (!is_error(ret)) {
            struct target_statfs *target_stfs;

            if (!lock_user_struct(VERIFY_WRITE, target_stfs, arg2, 0))
                goto efault;
            __put_user(stfs.f_type, &target_stfs->f_type);
            __put_user(stfs.f_bsize, &target_stfs->f_bsize);
            __put_user(stfs.f_blocks, &target_stfs->f_blocks);
            __put_user(stfs.f_bfree, &target_stfs->f_bfree);
            __put_user(stfs.f_bavail, &target_stfs->f_bavail);
            __put_user(stfs.f_files, &target_stfs->f_files);
            __put_user(stfs.f_ffree, &target_stfs->f_ffree);
            __put_user(stfs.f_fsid.__val[0], &target_stfs->f_fsid.val[0]);
            __put_user(stfs.f_fsid.__val[1], &target_stfs->f_fsid.val[1]);
            __put_user(stfs.f_namelen, &target_stfs->f_namelen);
            __put_user(stfs.f_frsize, &target_stfs->f_frsize);
            memset(target_stfs->f_spare, 0, sizeof(target_stfs->f_spare));
            unlock_user_struct(target_stfs, arg2, 1);
        }
        break;
        
    case TARGET_NR_fstatfs:
        ret = get_errno(fstatfs(arg1, &stfs));
        goto convert_statfs;

#ifdef TARGET_NR_statfs64
    case TARGET_NR_statfs64:
        if (!(p = lock_user_string(arg1)))
            goto efault;
        ret = get_errno(statfs(path(p), &stfs));
        unlock_user(p, arg1, 0);
    convert_statfs64:
        if (!is_error(ret)) {
            struct target_statfs64 *target_stfs;

            if (!lock_user_struct(VERIFY_WRITE, target_stfs, arg3, 0))
                goto efault;
            __put_user(stfs.f_type, &target_stfs->f_type);
            __put_user(stfs.f_bsize, &target_stfs->f_bsize);
            __put_user(stfs.f_blocks, &target_stfs->f_blocks);
            __put_user(stfs.f_bfree, &target_stfs->f_bfree);
            __put_user(stfs.f_bavail, &target_stfs->f_bavail);
            __put_user(stfs.f_files, &target_stfs->f_files);
            __put_user(stfs.f_ffree, &target_stfs->f_ffree);
            __put_user(stfs.f_fsid.__val[0], &target_stfs->f_fsid.val[0]);
            __put_user(stfs.f_fsid.__val[1], &target_stfs->f_fsid.val[1]);
            __put_user(stfs.f_namelen, &target_stfs->f_namelen);
            __put_user(stfs.f_frsize, &target_stfs->f_frsize);
            memset(target_stfs->f_spare, 0, sizeof(target_stfs->f_spare));
            unlock_user_struct(target_stfs, arg3, 1);
        }
        break;

    case TARGET_NR_fstatfs64:
        ret = get_errno(fstatfs(arg1, &stfs));
        goto convert_statfs64;
#endif

#ifdef TARGET_NR_ioperm
    case TARGET_NR_ioperm:
        goto unimplemented;
        break;
#endif

#ifdef TARGET_NR_socketcall
    case TARGET_NR_socketcall:
        goto unimplemented;
        break;        
#endif

#ifdef TARGET_NR_accept
    case TARGET_NR_accept:
        goto unimplemented;
        break;
#endif

#ifdef TARGET_NR_accept4
    case TARGET_NR_accept4:
        goto unimplemented;
        break;
#endif

#ifdef TARGET_NR_bind
    case TARGET_NR_bind:
        goto unimplemented;
        break;
#endif

#ifdef TARGET_NR_connect
    case TARGET_NR_connect:
        goto unimplemented;
        break;
#endif

#ifdef TARGET_NR_getpeername
    case TARGET_NR_getpeername:
        goto unimplemented;
        break;
#endif

#ifdef TARGET_NR_getsockname
    case TARGET_NR_getsockname:
        goto unimplemented;
        break;
#endif

#ifdef TARGET_NR_getsockopt
    case TARGET_NR_getsockopt:
        goto unimplemented;
        break;
#endif

#ifdef TARGET_NR_listen
    case TARGET_NR_listen:
        goto unimplemented;
        break;
#endif

#ifdef TARGET_NR_recv
    case TARGET_NR_recv:
        goto unimplemented;
        break;
#endif

#ifdef TARGET_NR_recvfrom
    case TARGET_NR_recvfrom:
        goto unimplemented;
        break;
#endif

#ifdef TARGET_NR_recvmsg
    case TARGET_NR_recvmsg:
        goto unimplemented;
        break;
#endif

#ifdef TARGET_NR_send
    case TARGET_NR_send:
        goto unimplemented;
        break;
#endif

#ifdef TARGET_NR_sendmsg
    case TARGET_NR_sendmsg:
        goto unimplemented;
        break;
#endif

#ifdef TARGET_NR_sendmmsg
    case TARGET_NR_sendmmsg:
        goto unimplemented;
        break;
    case TARGET_NR_recvmmsg:
        goto unimplemented;
        break;
#endif

#ifdef TARGET_NR_sendto
    case TARGET_NR_sendto:
        goto unimplemented;
        break;
#endif

#ifdef TARGET_NR_shutdown
    case TARGET_NR_shutdown:
        goto unimplemented;
        break;
#endif

#ifdef TARGET_NR_socket
    case TARGET_NR_socket:
        goto unimplemented;
        break;
#endif

#ifdef TARGET_NR_socketpair
    case TARGET_NR_socketpair:
        goto unimplemented;
        break;
#endif

#ifdef TARGET_NR_setsockopt
    case TARGET_NR_setsockopt:
        goto unimplemented;
        break;
#endif

    #define sys_syslog(x, y, z) syscall(SYS_syslog, x, y, z)
    case TARGET_NR_syslog:
        if (!(p = lock_user_string(arg2)))
            goto efault;
        ret = get_errno(sys_syslog((int)arg1, p, (int)arg3));
        unlock_user(p, arg2, 0);
        break;

    case TARGET_NR_setitimer:
        {
            struct itimerval value, ovalue, *pvalue;

            if (arg2) {
                pvalue = &value;
                if (copy_from_user_timeval(&pvalue->it_interval, arg2)
                    || copy_from_user_timeval(&pvalue->it_value,
                                              arg2 + sizeof(struct target_timeval)))
                    goto efault;
            } else {
                pvalue = NULL;
            }
            ret = get_errno(setitimer(arg1, pvalue, &ovalue));
            if (!is_error(ret) && arg3) {
                if (copy_to_user_timeval(arg3,
                                         &ovalue.it_interval)
                    || copy_to_user_timeval(arg3 + sizeof(struct target_timeval),
                                            &ovalue.it_value))
                    goto efault;
            }
        }
        break;

    case TARGET_NR_getitimer:
        {
            struct itimerval value;

            ret = get_errno(getitimer(arg1, &value));
            if (!is_error(ret) && arg2) {
                if (copy_to_user_timeval(arg2, &value.it_interval)
                    || copy_to_user_timeval(arg2 + sizeof(struct target_timeval), &value.it_value))
                    goto efault;
            }
        }
        break;

    case TARGET_NR_stat:
        if (!(p = lock_user_string(arg1)))
            goto efault;
        ret = get_errno(stat(path(p), &st));
        unlock_user(p, arg1, 0);
        goto do_stat;

    case TARGET_NR_lstat:
        if (!(p = lock_user_string(arg1)))
            goto efault;
        ret = get_errno(lstat(path(p), &st));
        unlock_user(p, arg1, 0);
        goto do_stat;

    case TARGET_NR_fstat:
        {
            ret = get_errno(fstat(arg1, &st));
        do_stat:
            if (!is_error(ret)) {
                struct target_stat *target_st;

                if (!lock_user_struct(VERIFY_WRITE, target_st, arg2, 0))
                    goto efault;
                memset(target_st, 0, sizeof(*target_st));
                __put_user(st.st_dev, &target_st->st_dev);
                __put_user(st.st_ino, &target_st->st_ino);
                __put_user(st.st_mode, &target_st->st_mode);
                __put_user(st.st_uid, &target_st->st_uid);
                __put_user(st.st_gid, &target_st->st_gid);
                __put_user(st.st_nlink, &target_st->st_nlink);
                __put_user(st.st_rdev, &target_st->st_rdev);
                __put_user(st.st_size, &target_st->st_size);
                __put_user(st.st_blksize, &target_st->st_blksize);
                __put_user(st.st_blocks, &target_st->st_blocks);
                __put_user(st.st_atime, &target_st->target_st_atime);
                __put_user(st.st_mtime, &target_st->target_st_mtime);
                __put_user(st.st_ctime, &target_st->target_st_ctime);
                unlock_user_struct(target_st, arg2, 1);
            }
        }
        break;

#ifdef TARGET_NR_olduname
    case TARGET_NR_olduname:
        goto unimplemented;
        break;
#endif

#ifdef TARGET_NR_iopl
    case TARGET_NR_iopl:
        goto unimplemented;
        break;
#endif

    case TARGET_NR_vhangup:
        ret = get_errno(vhangup());
        break;

#ifdef TARGET_NR_idle
    case TARGET_NR_idle:
        goto unimplemented;
        break;
#endif

    case TARGET_NR_wait4:
        goto unimplemented;
        break;

#ifdef TARGET_NR_swapoff
    case TARGET_NR_swapoff:
        goto unimplemented;
        break;
#endif

    case TARGET_NR_sysinfo:
        {
            struct target_sysinfo *target_value;
            struct sysinfo value;
            ret = get_errno(sysinfo(&value));
            if (!is_error(ret) && arg1)
            {
                if (!lock_user_struct(VERIFY_WRITE, target_value, arg1, 0))
                    goto efault;
                __put_user(value.uptime, &target_value->uptime);
                __put_user(value.loads[0], &target_value->loads[0]);
                __put_user(value.loads[1], &target_value->loads[1]);
                __put_user(value.loads[2], &target_value->loads[2]);
                __put_user(value.totalram, &target_value->totalram);
                __put_user(value.freeram, &target_value->freeram);
                __put_user(value.sharedram, &target_value->sharedram);
                __put_user(value.bufferram, &target_value->bufferram);
                __put_user(value.totalswap, &target_value->totalswap);
                __put_user(value.freeswap, &target_value->freeswap);
                __put_user(value.procs, &target_value->procs);
                __put_user(value.totalhigh, &target_value->totalhigh);
                __put_user(value.freehigh, &target_value->freehigh);
                __put_user(value.mem_unit, &target_value->mem_unit);
                unlock_user_struct(target_value, arg1, 1);
            }
        }
        break;

#ifdef TARGET_NR_ipc
    case TARGET_NR_ipc:
        goto unimplemented;
        break;
#endif

#ifdef TARGET_NR_semget
    case TARGET_NR_semget:
        goto unimplemented;
        break;
#endif

#ifdef TARGET_NR_semop
    case TARGET_NR_semop:
        goto unimplemented;
        break;
#endif

#ifdef TARGET_NR_semctl
    case TARGET_NR_semctl:
        goto unimplemented;
        break;
#endif

#ifdef TARGET_NR_msgctl
    case TARGET_NR_msgctl:
        goto unimplemented;
        break;
#endif

#ifdef TARGET_NR_msgget
    case TARGET_NR_msgget:
        goto unimplemented;
        break;
#endif

#ifdef TARGET_NR_msgrcv
    case TARGET_NR_msgrcv:
        goto unimplemented;
        break;
#endif

#ifdef TARGET_NR_msgsnd
    case TARGET_NR_msgsnd:
        goto unimplemented;
        break;
#endif

#ifdef TARGET_NR_shmget
    case TARGET_NR_shmget:
        goto unimplemented;
        break;
#endif

#ifdef TARGET_NR_shmctl
    case TARGET_NR_shmctl:
        goto unimplemented;
        break;
#endif

#ifdef TARGET_NR_shmat
    case TARGET_NR_shmat:
        goto unimplemented;
        break;
#endif

#ifdef TARGET_NR_shmdt
    case TARGET_NR_shmdt:
        goto unimplemented;
        break;
#endif

    case TARGET_NR_fsync:
        ret = get_errno(fsync(arg1));
        break;

    case TARGET_NR_clone:
        goto unimplemented;
        break;

#ifdef __NR_exit_group
    case TARGET_NR_exit_group:
        target_exit_called = 1;
        break;
#endif

    case TARGET_NR_setdomainname:
        if (!(p = lock_user_string(arg1)))
            goto efault;
        ret = get_errno(setdomainname(p, arg2));
        unlock_user(p, arg1, 0);
        break;

    case TARGET_NR_uname:
        goto unimplemented;
        break;

    case TARGET_NR_adjtimex:
        goto unimplemented;
        break;
        
#ifdef TARGET_NR_create_module
    case TARGET_NR_create_module:
#endif
    case TARGET_NR_init_module:
    case TARGET_NR_delete_module:
#ifdef TARGET_NR_get_kernel_syms
    case TARGET_NR_get_kernel_syms:
#endif
        goto unimplemented;
        break;
        
    case TARGET_NR_quotactl:
        goto unimplemented;
        break;
        
    case TARGET_NR_getpgid:
        ret = get_errno(getpgid(arg1));
        break;
    
    case TARGET_NR_fchdir:
        ret = get_errno(fchdir(arg1));
        break;

#ifdef TARGET_NR_bdflush
    case TARGET_NR_bdflush:
        goto unimplemented;
        break;
#endif

#ifdef TARGET_NR_sysfs
    case TARGET_NR_sysfs:
        goto unimplemented;
        break;
#endif

    case TARGET_NR_personality:
        ret = get_errno(personality(arg1));
        break;

#ifdef TARGET_NR_afs_syscall
    case TARGET_NR_afs_syscall:
        goto unimplemented;
        break;
#endif

#ifdef TARGET_NR__llseek
    case TARGET_NR__llseek:
        {
            int64_t res;
#if !defined(__NR_llseek)
            res = lseek(arg1, ((uint64_t)arg2 << 32) | arg3, arg5);
            if (res == -1) {
                ret = get_errno(res);
            } else {
                ret = 0;
            }
#else
            ret = get_errno(_llseek(arg1, arg2, arg3, &res, arg5));
#endif
            if ((ret == 0) && put_user_s64(res, arg4)) {
                goto efault;
            }
        }
        break;
#endif

    #define sys_getdents(x, y, z) syscall(SYS_getdents, x, y, z)
    case TARGET_NR_getdents:
#ifdef __NR_getdents
#if TARGET_ABI_BITS == 32 && HOST_LONG_BITS == 64
        {
            struct target_dirent *target_dirp;
            struct linux_dirent *dirp;
            abi_long count = arg3;

            dirp = malloc(count);
            if (!dirp) {
                ret = -TARGET_ENOMEM;
                goto fail;
            }

            ret = get_errno(sys_getdents(arg1, dirp, count));
            if (!is_error(ret)) {
                struct linux_dirent *de;
                struct target_dirent *tde;
                int len = ret;
                int reclen, treclen;
                int count1, tnamelen;

                count1 = 0;
                de = dirp;
                if (!(target_dirp = lock_user(VERIFY_WRITE, arg2, count, 0)))
                    goto efault;
                    
                tde = target_dirp;
                while (len > 0) {
                    reclen = de->d_reclen;
                    tnamelen = reclen - offsetof(struct linux_dirent, d_name);
                    assert(tnamelen >= 0);
                    treclen = tnamelen + offsetof(struct target_dirent, d_name);
                    assert(count1 + treclen <= count);
                    tde->d_reclen = tswap16(treclen);
                    tde->d_ino = tswapal(de->d_ino);
                    tde->d_off = tswapal(de->d_off);
                    memcpy(tde->d_name, de->d_name, tnamelen);
                    de = (struct linux_dirent *)((char *)de + reclen);
                    len -= reclen;
                    tde = (struct target_dirent *)((char *)tde + treclen);
                    count1 += treclen;
                }
                ret = count1;
                unlock_user(target_dirp, arg2, ret);
            }
            free(dirp);
        }
#else
        {
            struct linux_dirent *dirp;
            abi_long count = arg3;

            if (!(dirp = lock_user(VERIFY_WRITE, arg2, count, 0)))
                goto efault;
            ret = get_errno(sys_getdents(arg1, dirp, count));
            if (!is_error(ret)) {
                struct linux_dirent *de;
                int len = ret;
                int reclen;
                de = dirp;
                while (len > 0) {
                    reclen = de->d_reclen;
                    if (reclen > len)
                        break;
                    de->d_reclen = tswap16(reclen);
                    tswapls(&de->d_ino);
                    tswapls(&de->d_off);
                    de = (struct linux_dirent *)((char *)de + reclen);
                    len -= reclen;
                }
            }
            unlock_user(dirp, arg2, ret);
        }
#endif
#else
        /* Implement getdents in terms of getdents64 */
        {
            struct linux_dirent64 *dirp;
            abi_long count = arg3;

            dirp = lock_user(VERIFY_WRITE, arg2, count, 0);
            if (!dirp) {
                goto efault;
            }
            ret = get_errno(sys_getdents64(arg1, dirp, count));
            if (!is_error(ret)) {
                /* Convert the dirent64 structs to target dirent.  We do this
                 * in-place, since we can guarantee that a target_dirent is no
                 * larger than a dirent64; however this means we have to be
                 * careful to read everything before writing in the new format.
                 */
                struct linux_dirent64 *de;
                struct target_dirent *tde;
                int len = ret;
                int tlen = 0;

                de = dirp;
                tde = (struct target_dirent *)dirp;
                while (len > 0) {
                    int namelen, treclen;
                    int reclen = de->d_reclen;
                    uint64_t ino = de->d_ino;
                    int64_t off = de->d_off;
                    uint8_t type = de->d_type;

                    namelen = strlen(de->d_name);
                    treclen = offsetof(struct target_dirent, d_name) + namelen + 2;
                    treclen = QEMU_ALIGN_UP(treclen, sizeof(abi_long));

                    memmove(tde->d_name, de->d_name, namelen + 1);
                    tde->d_ino = tswapal(ino);
                    tde->d_off = tswapal(off);
                    tde->d_reclen = tswap16(treclen);
                    /* The target_dirent type is in what was formerly a padding
                     * byte at the end of the structure:
                     */
                    *(((char *)tde) + treclen - 1) = type;

                    de = (struct linux_dirent64 *)((char *)de + reclen);
                    tde = (struct target_dirent *)((char *)tde + treclen);
                    len -= reclen;
                    tlen += treclen;
                }
                ret = tlen;
            }
            unlock_user(dirp, arg2, ret);
        }
#endif
        break;

#if defined(TARGET_NR_getdents64) && defined(__NR_getdents64)
    #define sys_getdents64(x, y, z) syscall(SYS_getdents64, x, y, z)
    case TARGET_NR_getdents64:
        {
            struct linux_dirent64 *dirp;
            abi_long count = arg3;
            if (!(dirp = lock_user(VERIFY_WRITE, arg2, count, 0)))
                goto efault;
            ret = get_errno(sys_getdents64(arg1, dirp, count));
            if (!is_error(ret)) {
                struct linux_dirent64 *de;
                int len = ret;
                int reclen;
                de = dirp;
                while (len > 0) {
                    reclen = de->d_reclen;
                    if (reclen > len)
                        break;
                    de->d_reclen = tswap16(reclen);
                    tswap64s((uint64_t *)&de->d_ino);
                    tswap64s((uint64_t *)&de->d_off);
                    de = (struct linux_dirent64 *)((char *)de + reclen);
                    len -= reclen;
                }
            }
            unlock_user(dirp, arg2, ret);
        }
        break;
#endif

#if defined(TARGET_NR__newselect)
    case TARGET_NR__newselect:
        ret = do_select(arg1, arg2, arg3, arg4, arg5);
        break;
#endif

#if defined(TARGET_NR_poll) || defined(TARGET_NR_ppoll)
# ifdef TARGET_NR_poll
    case TARGET_NR_poll:
# endif
# ifdef TARGET_NR_ppoll
    case TARGET_NR_ppoll:
# endif
        goto unimplemented;
        break;
#endif

    case TARGET_NR_flock:
        // NOTE: the flock constant seems to be the same for every Linux platform
        ret = get_errno(flock(arg1, arg2));
        break;

    case TARGET_NR_readv:
        {
            struct iovec *vec = lock_iovec(VERIFY_WRITE, arg2, arg3, 0);
            if (vec != NULL) {
                ret = get_errno(readv(arg1, vec, arg3));
                unlock_iovec(vec, arg2, arg3, 1);
            } else {
                ret = -host_to_target_errno(errno);
            }
        }
        break;

    case TARGET_NR_writev:
        {
            struct iovec *vec = lock_iovec(VERIFY_READ, arg2, arg3, 1);
            if (vec != NULL) {
                ret = get_errno(writev(arg1, vec, arg3));
                unlock_iovec(vec, arg2, arg3, 0);
            } else {
                ret = -host_to_target_errno(errno);
            }
        }
        break;

    case TARGET_NR_getsid:
        ret = get_errno(getsid(arg1));
        break;

#if defined(TARGET_NR_fdatasync)
    case TARGET_NR_fdatasync:
        ret = get_errno(fdatasync(arg1));
        break;
#endif

    case TARGET_NR__sysctl:
        // We don't implement this, but ENOTDIR is always a safe return value.
        ret = -TARGET_ENOTDIR;
        break;
        
    case TARGET_NR_sched_getaffinity:
        goto unimplemented;
        break;

    case TARGET_NR_sched_setaffinity:
        goto unimplemented;
        break;

    case TARGET_NR_sched_setparam:
        goto unimplemented;
        break;

    case TARGET_NR_sched_getparam:
        goto unimplemented;
        break;

    case TARGET_NR_sched_setscheduler:
        goto unimplemented;
        break;

    case TARGET_NR_sched_getscheduler:
        ret = get_errno(sched_getscheduler(arg1));
        break;

    case TARGET_NR_sched_yield:
        ret = get_errno(sched_yield());
        break;

    case TARGET_NR_sched_get_priority_max:
        ret = get_errno(sched_get_priority_max(arg1));
        break;

    case TARGET_NR_sched_get_priority_min:
        ret = get_errno(sched_get_priority_min(arg1));
        break;
    
    case TARGET_NR_sched_rr_get_interval:
        goto unimplemented;
        break;

    case TARGET_NR_nanosleep:
        goto unimplemented;
        break;

#ifdef TARGET_NR_query_module
    case TARGET_NR_query_module:
        goto unimplemented;
        break;
#endif

#ifdef TARGET_NR_nfsservctl
    case TARGET_NR_nfsservctl:
        goto unimplemented;
        break;
#endif

    case TARGET_NR_prctl:
        switch (arg1) {
        case PR_GET_PDEATHSIG:
        {
            int deathsig;
            ret = get_errno(prctl(arg1, &deathsig, arg3, arg4, arg5));
            if (!is_error(ret) && arg2
                && put_user_ual(deathsig, arg2)) {
                goto efault;
            }
            break;
        }
#ifdef PR_GET_NAME
        case PR_GET_NAME:
        {
            void *name = lock_user(VERIFY_WRITE, arg2, 16, 1);
            if (!name) {
                goto efault;
            }
            ret = get_errno(prctl(arg1, (unsigned long)name,
                                  arg3, arg4, arg5));
            unlock_user(name, arg2, 16);
            break;
        }
        case PR_SET_NAME:
        {
            void *name = lock_user(VERIFY_READ, arg2, 16, 1);
            if (!name) {
                goto efault;
            }
            ret = get_errno(prctl(arg1, (unsigned long)name,
                                  arg3, arg4, arg5));
            unlock_user(name, arg2, 0);
            break;
        }
#endif
        default:
            // Most prctl options have no pointer arguments
            ret = get_errno(prctl(arg1, arg2, arg3, arg4, arg5));
            break;
        }
        break;
        
#ifdef TARGET_NR_arch_prctl
    case TARGET_NR_arch_prctl:
        goto unimplemented;
        break;
#endif

#ifdef TARGET_NR_pread64
    case TARGET_NR_pread64:
        goto unimplemented;
        break;

    case TARGET_NR_pwrite64:
        goto unimplemented;
        break;
#endif

    #define sys_getcwd(x, y) syscall(SYS_getcwd, x, y)
    case TARGET_NR_getcwd:
        if (!(p = lock_user(VERIFY_WRITE, arg1, arg2, 0)))
            goto efault;
        ret = get_errno(sys_getcwd(p, arg2));
        unlock_user(p, arg1, ret);
        break;

    case TARGET_NR_capget:
    case TARGET_NR_capset:
        goto unimplemented;
        break;
    
    case TARGET_NR_sigaltstack:
        goto unimplemented;
        break;
        
#ifdef CONFIG_SENDFILE
    case TARGET_NR_sendfile:
    {
        off_t *offp = NULL;
        off_t off;
        if (arg3) {
            ret = get_user_sal(off, arg3);
            if (is_error(ret)) {
                break;
            }
            offp = &off;
        }
        ret = get_errno(sendfile(arg1, arg2, offp, arg4));
        if (!is_error(ret) && arg3) {
            abi_long ret2 = put_user_sal(off, arg3);
            if (is_error(ret2)) {
                ret = ret2;
            }
        }
        break;
    }    
#endif

#ifdef TARGET_NR_getpmsg
    case TARGET_NR_getpmsg:
        goto unimplemented;
        break;
#endif

#ifdef TARGET_NR_putpmsg
    case TARGET_NR_putpmsg:
        goto unimplemented;
        break;
#endif

#ifdef TARGET_NR_vfork
    case TARGET_NR_vfork:
        goto unimplemented;
        break;
#endif

#ifdef TARGET_NR_ugetrlimit
    case TARGET_NR_ugetrlimit:
    {
    struct rlimit rlim;
    int resource = target_to_host_resource(arg1);
    ret = get_errno(getrlimit(resource, &rlim));
    if (!is_error(ret)) {
        struct target_rlimit *target_rlim;
            if (!lock_user_struct(VERIFY_WRITE, target_rlim, arg2, 0))
                goto efault;
        target_rlim->rlim_cur = host_to_target_rlim(rlim.rlim_cur);
        target_rlim->rlim_max = host_to_target_rlim(rlim.rlim_max);
            unlock_user_struct(target_rlim, arg2, 1);
    }
    break;
    }
#endif

#ifdef TARGET_NR_truncate64
    case TARGET_NR_truncate64:
        goto unimplemented;
        break;
#endif

#ifdef TARGET_NR_ftruncate64
    case TARGET_NR_ftruncate64:
        goto unimplemented;
        break;
#endif

#ifdef TARGET_NR_stat64
    case TARGET_NR_stat64:
        if (!(p = lock_user_string(arg1)))
            goto efault;
        ret = get_errno(stat(path(p), &st));
        unlock_user(p, arg1, 0);
        if (!is_error(ret))
            ret = host_to_target_stat64(arg2, &st);
        break;
#endif

#ifdef TARGET_NR_lstat64
    case TARGET_NR_lstat64:
        if (!(p = lock_user_string(arg1)))
            goto efault;
        ret = get_errno(lstat(path(p), &st));
        unlock_user(p, arg1, 0);
        if (!is_error(ret))
            ret = host_to_target_stat64(arg2, &st);
        break;
#endif

#ifdef TARGET_NR_fstat64
    case TARGET_NR_fstat64:
        ret = get_errno(fstat(arg1, &st));
        if (!is_error(ret))
            ret = host_to_target_stat64(arg2, &st);
        break;
#endif

#if (defined(TARGET_NR_fstatat64) || defined(TARGET_NR_newfstatat))
#ifdef TARGET_NR_fstatat64
    case TARGET_NR_fstatat64:
#endif
#ifdef TARGET_NR_newfstatat
    case TARGET_NR_newfstatat:
#endif
        if (!(p = lock_user_string(arg2)))
            goto efault;
        ret = get_errno(fstatat(arg1, path(p), &st, arg4));
        if (!is_error(ret))
            ret = host_to_target_stat64(arg3, &st);
        break;
#endif

    case TARGET_NR_lchown:
        if (!(p = lock_user_string(arg1)))
            goto efault;
        ret = get_errno(lchown(p, low2highuid(arg2), low2highgid(arg3)));
        unlock_user(p, arg1, 0);
        break;
        
#ifdef TARGET_NR_getuid
    case TARGET_NR_getuid:
        ret = get_errno(high2lowuid(getuid()));
        break;
#endif

#ifdef TARGET_NR_getgid
    case TARGET_NR_getgid:
        ret = get_errno(high2lowgid(getgid()));
        break;
#endif

#ifdef TARGET_NR_geteuid
    case TARGET_NR_geteuid:
        ret = get_errno(high2lowuid(geteuid()));
        break;
#endif

#ifdef TARGET_NR_getegid
    case TARGET_NR_getegid:
        ret = get_errno(high2lowgid(getegid()));
        break;
#endif

    case TARGET_NR_setreuid:
        ret = get_errno(setreuid(low2highuid(arg1), low2highuid(arg2)));
        break;

    case TARGET_NR_setregid:
        ret = get_errno(setregid(low2highgid(arg1), low2highgid(arg2)));
        break;

    case TARGET_NR_getgroups:
        goto unimplemented;
        break;

    case TARGET_NR_setgroups:
        goto unimplemented;
        break;

    case TARGET_NR_fchown:
        ret = get_errno(fchown(arg1, low2highuid(arg2), low2highgid(arg3)));
        break;

#if defined(TARGET_NR_fchownat)
    case TARGET_NR_fchownat:
        if (!(p = lock_user_string(arg2))) 
            goto efault;
        ret = get_errno(fchownat(arg1, p, low2highuid(arg3),
                                 low2highgid(arg4), arg5));
        unlock_user(p, arg2, 0);
        break;
#endif

#ifdef TARGET_NR_setresuid
    case TARGET_NR_setresuid:
        ret = get_errno(setresuid(low2highuid(arg1),
                                  low2highuid(arg2),
                                  low2highuid(arg3)));
        break;
#endif

#ifdef TARGET_NR_getresuid
    case TARGET_NR_getresuid:
        {
            uid_t ruid, euid, suid;
            ret = get_errno(getresuid(&ruid, &euid, &suid));
            if (!is_error(ret)) {
                if (put_user_id(high2lowuid(ruid), arg1)
                    || put_user_id(high2lowuid(euid), arg2)
                    || put_user_id(high2lowuid(suid), arg3))
                    goto efault;
            }
        }
        break;
#endif

#ifdef TARGET_NR_getresgid
    case TARGET_NR_setresgid:
        ret = get_errno(setresgid(low2highgid(arg1), low2highgid(arg2), low2highgid(arg3)));
        break;
#endif

#ifdef TARGET_NR_getresgid
    case TARGET_NR_getresgid:
        {
            gid_t rgid, egid, sgid;
            ret = get_errno(getresgid(&rgid, &egid, &sgid));
            if (!is_error(ret)) {
                if (put_user_id(high2lowgid(rgid), arg1)
                    || put_user_id(high2lowgid(egid), arg2)
                    || put_user_id(high2lowgid(sgid), arg3))
                    goto efault;
            }
        }
        break;
#endif

    case TARGET_NR_chown:
        if (!(p = lock_user_string(arg1)))
            goto efault;
        ret = get_errno(chown(p, low2highuid(arg2), low2highgid(arg3)));
        unlock_user(p, arg1, 0);
        break;

    case TARGET_NR_setuid:
        ret = get_errno(setuid(low2highuid(arg1)));
        break;

    case TARGET_NR_setgid:
        ret = get_errno(setgid(low2highgid(arg1)));
        break;

    case TARGET_NR_setfsuid:
        ret = get_errno(setfsuid(arg1));
        break;

    case TARGET_NR_setfsgid:
        ret = get_errno(setfsgid(arg1));
        break;

#ifdef TARGET_NR_lchown32
    case TARGET_NR_lchown32:
        if (!(p = lock_user_string(arg1)))
            goto efault;
        ret = get_errno(lchown(p, arg2, arg3));
        unlock_user(p, arg1, 0);
        break;
#endif

#ifdef TARGET_NR_getuid32
    case TARGET_NR_getuid32:
        ret = get_errno(getuid());
        break;
#endif

#ifdef TARGET_NR_getgid32
    case TARGET_NR_getgid32:
        ret = get_errno(getgid());
        break;
#endif

#ifdef TARGET_NR_geteuid32
    case TARGET_NR_geteuid32:
        ret = get_errno(geteuid());
        break;
#endif

#ifdef TARGET_NR_getegid32
    case TARGET_NR_getegid32:
        ret = get_errno(getegid());
        break;
#endif

#ifdef TARGET_NR_setreuid32
    case TARGET_NR_setreuid32:
        ret = get_errno(setreuid(arg1, arg2));
        break;
#endif

#ifdef TARGET_NR_setregid32
    case TARGET_NR_setregid32:
        ret = get_errno(setregid(arg1, arg2));
        break;
#endif

#ifdef TARGET_NR_getgroups32
    case TARGET_NR_getgroups32:
        goto unimplemented;
        break;
#endif

#ifdef TARGET_NR_setgroups32
    case TARGET_NR_setgroups32:
        goto unimplemented;
        break;
#endif

#ifdef TARGET_NR_fchown32
    case TARGET_NR_fchown32:
        ret = get_errno(fchown(arg1, arg2, arg3));
        break;
#endif

#ifdef TARGET_NR_setresuid32
    case TARGET_NR_setresuid32:
        ret = get_errno(setresuid(arg1, arg2, arg3));
        break;
#endif

#ifdef TARGET_NR_getresuid32
    case TARGET_NR_getresuid32:
        {
            uid_t ruid, euid, suid;
            ret = get_errno(getresuid(&ruid, &euid, &suid));
            if (!is_error(ret)) {
                if (put_user_u32(ruid, arg1)
                    || put_user_u32(euid, arg2)
                    || put_user_u32(suid, arg3))
                    goto efault;
            }
        }
        break;
#endif

#ifdef TARGET_NR_setresgid32
    case TARGET_NR_setresgid32:
        ret = get_errno(setresgid(arg1, arg2, arg3));
        break;
#endif

#ifdef TARGET_NR_getresgid32
    case TARGET_NR_getresgid32:
        {
            gid_t rgid, egid, sgid;
            ret = get_errno(getresgid(&rgid, &egid, &sgid));
            if (!is_error(ret)) {
                if (put_user_u32(rgid, arg1)
                    || put_user_u32(egid, arg2)
                    || put_user_u32(sgid, arg3))
                    goto efault;
            }
        }
        break;
#endif

#ifdef TARGET_NR_chown32
    case TARGET_NR_chown32:
        if (!(p = lock_user_string(arg1)))
            goto efault;
        ret = get_errno(chown(p, arg2, arg3));
        unlock_user(p, arg1, 0);
        break;
#endif

#ifdef TARGET_NR_setuid32
    case TARGET_NR_setuid32:
        ret = get_errno(setuid(arg1));
        break;
#endif

#ifdef TARGET_NR_setgid32
    case TARGET_NR_setgid32:
        ret = get_errno(setgid(arg1));
        break;
#endif

#ifdef TARGET_NR_setfsuid32
    case TARGET_NR_setfsuid32:
        ret = get_errno(setfsuid(arg1));
        break;
#endif

#ifdef TARGET_NR_setfsgid32
    case TARGET_NR_setfsgid32:
        ret = get_errno(setfsgid(arg1));
        break;
#endif

    case TARGET_NR_pivot_root:
        goto unimplemented;
        break;
        
#ifdef TARGET_NR_mincore
    case TARGET_NR_mincore:
        goto unimplemented;
        break;
#endif

#ifdef TARGET_NR_madvise
    case TARGET_NR_madvise:
        // A straight passthrough may not be safe because qemu sometimes
        // turns private file-backed mappings into anonymous mappings.
        // This will break MADV_DONTNEED.
        // This is a hint, so ignoring and returning success is ok.  */
        ret = get_errno(0);
        break;
#endif

#if TARGET_ABI_BITS == 32
    case TARGET_NR_fcntl64:
        goto unimplemented;
        break;
#endif

#ifdef TARGET_NR_cacheflush
    case TARGET_NR_cacheflush:
        // self-modifying code is handled automatically, so nothing needed
        ret = 0;
        break;
#endif

#ifdef TARGET_NR_security
    case TARGET_NR_security:
        goto unimplemented;
        break;
#endif

#ifdef TARGET_NR_getpagesize
    case TARGET_NR_getpagesize:
        ret = TARGET_PAGE_SIZE;
        break;
#endif

    #define gettid() syscall(SYS_gettid)
    case TARGET_NR_gettid:
        ret = get_errno(gettid());
        break;

#ifdef TARGET_NR_readahead
    case TARGET_NR_readahead:
        goto unimplemented;
        break;
#endif

#ifdef TARGET_NR_set_thread_area
    case TARGET_NR_set_thread_area:
        goto unimplemented;
        break;
#endif

#ifdef TARGET_NR_get_thread_area
    case TARGET_NR_get_thread_area:
        goto unimplemented;
        break;
#endif

#ifdef TARGET_NR_getdomainname
    case TARGET_NR_getdomainname:
        goto unimplemented_nowarn;
        break;
#endif

#ifdef TARGET_NR_clock_gettime
    case TARGET_NR_clock_gettime:
        goto unimplemented;
        break;
#endif

#ifdef TARGET_NR_clock_getres
    case TARGET_NR_clock_getres:
        goto unimplemented;
        break;
#endif

#ifdef TARGET_NR_clock_nanosleep
    case TARGET_NR_clock_nanosleep:
        goto unimplemented;
        break;
#endif

#if defined(TARGET_NR_set_tid_address) && defined(__NR_set_tid_address)
    case TARGET_NR_set_tid_address:
        goto unimplemented;
        break;
#endif

#if defined(TARGET_NR_tkill) && defined(__NR_tkill)
    case TARGET_NR_tkill:
        goto unimplemented;
        break;
#endif

#if defined(TARGET_NR_tgkill) && defined(__NR_tgkill)
    case TARGET_NR_tgkill:
        goto unimplemented;
        break;
#endif

#ifdef TARGET_NR_set_robust_list
    case TARGET_NR_set_robust_list:
    case TARGET_NR_get_robust_list:
        /* The ABI for supporting robust futexes has userspace pass
         * the kernel a pointer to a linked list which is updated by
         * userspace after the syscall; the list is walked by the kernel
         * when the thread exits. Since the linked list in QEMU guest
         * memory isn't a valid linked list for the host and we have
         * no way to reliably intercept the thread-death event, we can't
         * support these. Silently return ENOSYS so that guest userspace
         * falls back to a non-robust futex implementation (which should
         * be OK except in the corner case of the guest crashing while
         * holding a mutex that is shared with another process via
         * shared memory).
         */
        goto unimplemented_nowarn;
        break;
#endif

#if defined(TARGET_NR_utimensat)
    case TARGET_NR_utimensat:
        goto unimplemented;
        break;
#endif

    case TARGET_NR_futex:
        goto unimplemented;
        break;
        
#if defined(TARGET_NR_inotify_init) && defined(__NR_inotify_init)
    case TARGET_NR_inotify_init:
        ret = get_errno(sys_inotify_init());
        break;
#endif

#ifdef CONFIG_INOTIFY1
#if defined(TARGET_NR_inotify_init1) && defined(__NR_inotify_init1)
    case TARGET_NR_inotify_init1:
        goto unimplemented;
        break;
#endif
#endif

#if defined(TARGET_NR_inotify_add_watch) && defined(__NR_inotify_add_watch)
    case TARGET_NR_inotify_add_watch:
        p = lock_user_string(arg2);
        ret = get_errno(sys_inotify_add_watch(arg1, path(p), arg3));
        unlock_user(p, arg2, 0);
        break;
#endif

#if defined(TARGET_NR_inotify_rm_watch) && defined(__NR_inotify_rm_watch)
    case TARGET_NR_inotify_rm_watch:
        ret = get_errno(sys_inotify_rm_watch(arg1, arg2));
        break;
#endif

#if defined(TARGET_NR_mq_open) && defined(__NR_mq_open)
    case TARGET_NR_mq_open:
        goto unimplemented;
        break;

    case TARGET_NR_mq_unlink:
        goto unimplemented;
        break;

    case TARGET_NR_mq_timedsend:
        goto unimplemented;
        break;

    case TARGET_NR_mq_timedreceive:
        goto unimplemented;
        break;

    case TARGET_NR_mq_getsetattr:
        goto unimplemented;
        break;
#endif

#ifdef CONFIG_SPLICE
#ifdef TARGET_NR_tee
    case TARGET_NR_tee:
        ret = get_errno(tee(arg1,arg2,arg3,arg4));
        break;
#endif

#ifdef TARGET_NR_splice
    case TARGET_NR_splice:
        {
            loff_t loff_in, loff_out;
            loff_t *ploff_in = NULL, *ploff_out = NULL;
            if(arg2) {
                get_user_u64(loff_in, arg2);
                ploff_in = &loff_in;
            }
            if(arg4) {
                get_user_u64(loff_out, arg2);
                ploff_out = &loff_out;
            }
            ret = get_errno(splice(arg1, ploff_in, arg3, ploff_out, arg5, arg6));
        }
        break;
#endif

#ifdef TARGET_NR_vmsplice
    case TARGET_NR_vmsplice:
        {
            struct iovec *vec = lock_iovec(VERIFY_READ, arg2, arg3, 1);
            if (vec != NULL) {
                ret = get_errno(vmsplice(arg1, vec, arg3, arg4));
                unlock_iovec(vec, arg2, arg3, 0);
            } else {
                ret = -host_to_target_errno(errno);
            }
        }
        break;
#endif
#endif

#ifdef CONFIG_EVENTFD
#if defined(TARGET_NR_eventfd)
    case TARGET_NR_eventfd:
        goto unimplemented;
        break;
#endif

#if defined(TARGET_NR_eventfd2)
    case TARGET_NR_eventfd2:
        goto unimplemented;
        break;
#endif
#endif

#if defined(CONFIG_FALLOCATE) && defined(TARGET_NR_fallocate)
    case TARGET_NR_fallocate:
        goto unimplemented;
        break;
#endif

#if defined(CONFIG_EPOLL)
#if defined(TARGET_NR_epoll_create)
    case TARGET_NR_epoll_create:
        ret = get_errno(epoll_create(arg1));
        break;
#endif

#if defined(TARGET_NR_epoll_create1) && defined(CONFIG_EPOLL_CREATE1)
    case TARGET_NR_epoll_create1:
        goto unimplemented;
        break;
#endif

#if defined(TARGET_NR_epoll_ctl)
    case TARGET_NR_epoll_ctl:
    {
        struct epoll_event ep;
        struct epoll_event *epp = 0;
        if (arg4) {
            struct target_epoll_event *target_ep;
            if (!lock_user_struct(VERIFY_READ, target_ep, arg4, 1)) {
                goto efault;
            }
            ep.events = tswap32(target_ep->events);
            // The epoll_data_t union is just opaque data to the kernel,
            // so we transfer all 64 bits across and need not worry what
            // actual data type it is.
            ep.data.u64 = tswap64(target_ep->data.u64);
            unlock_user_struct(target_ep, arg4, 0);
            epp = &ep;
        }
        ret = get_errno(epoll_ctl(arg1, arg2, arg3, epp));
        break;
    }
#endif

#if defined(TARGET_NR_epoll_pwait) && defined(CONFIG_EPOLL_PWAIT)
#define IMPLEMENT_EPOLL_PWAIT
#endif
#if defined(TARGET_NR_epoll_wait) || defined(IMPLEMENT_EPOLL_PWAIT)
#if defined(TARGET_NR_epoll_wait)
    case TARGET_NR_epoll_wait:
#endif
#if defined(IMPLEMENT_EPOLL_PWAIT)
    case TARGET_NR_epoll_pwait:
#endif
        goto unimplemented;
        break;
#endif
#endif

#ifdef TARGET_NR_prlimit64
    case TARGET_NR_prlimit64:
        goto unimplemented;
        break;
#endif

#ifdef TARGET_NR_gethostname
    case TARGET_NR_gethostname:
        {
            char *name = lock_user(VERIFY_WRITE, arg1, arg2, 0);
            if (name) {
                ret = get_errno(gethostname(name, arg2));
                unlock_user(name, arg1, arg2);
            } else {
                ret = -TARGET_EFAULT;
            }
        }
        break;
#endif

#ifdef TARGET_NR_timer_create
    case TARGET_NR_timer_create:
        goto unimplemented;
        break;
#endif

#ifdef TARGET_NR_timer_settime
    case TARGET_NR_timer_settime:
        goto unimplemented;
        break;
#endif

#ifdef TARGET_NR_timer_gettime
    case TARGET_NR_timer_gettime:
        goto unimplemented;
        break;
#endif

#ifdef TARGET_NR_timer_getoverrun
    case TARGET_NR_timer_getoverrun:
        goto unimplemented;
        break;
#endif

#ifdef TARGET_NR_timer_delete
    case TARGET_NR_timer_delete:
        goto unimplemented;
        break;
#endif

#if defined(TARGET_NR_timerfd_create) && defined(CONFIG_TIMERFD)
    case TARGET_NR_timerfd_create:
        ret = get_errno(timerfd_create(arg1, target_to_host_bitmask(arg2, fcntl_flags_tbl)));
        break;
#endif

#if defined(TARGET_NR_timerfd_gettime) && defined(CONFIG_TIMERFD)
    case TARGET_NR_timerfd_gettime:
        goto unimplemented;
        break;
#endif

#if defined(TARGET_NR_timerfd_settime) && defined(CONFIG_TIMERFD)
    case TARGET_NR_timerfd_settime:
        goto unimplemented;
        break;
#endif

#if defined(TARGET_NR_setns) && defined(CONFIG_SETNS)
    case TARGET_NR_setns:
        goto unimplemented;
        break;
#endif

#if defined(TARGET_NR_unshare) && defined(CONFIG_SETNS)
    case TARGET_NR_unshare:
        ret = get_errno(unshare(arg1));
        break;
#endif

    default:
    unimplemented:
        fprintf(stderr, "Unsupported syscall: %d\n", num);
#if defined(TARGET_NR_setxattr) || defined(TARGET_NR_get_thread_area) || defined(TARGET_NR_getdomainname) || defined(TARGET_NR_set_robust_list)
    unimplemented_nowarn:
#endif
        ret = -TARGET_ENOSYS;
        break;
    }
fail:
    return ret;
efault:
    ret = -TARGET_EFAULT;
    goto fail;
}

static void init_stack(int argc, char* argv[]) {
    abi_ulong *new_argv;
    abi_ulong guest_ptr;
    int i, len;
        
    ///// copy the argv content

    new_argv = (abi_ulong *) calloc(sizeof(abi_ulong), argc);
    guest_ptr = guest_max_mem;    
    i = argc;
    
    while (i > 0) {        
        void *host_ptr;   
        char *tmp, *tmp1;
        
        // get the argument
        i -= 1;
        tmp = argv[i];
        if (!tmp) {
            fprintf(stderr, "VFS: argc is wrong");
            exit(-1);
        }
        
        // find its length
        tmp1 = tmp;
        while (*tmp++);
        len = tmp - tmp1;
        
        // update p and make sure it is aligned on a 16-byte boundary
        guest_ptr -= ((len + 15) /16) * 16;
        
        // copy to guest space
        host_ptr = lock_user(VERIFY_WRITE, guest_ptr, len+1, 1);        
        memcpy(host_ptr, tmp1, len + 1);
        
        // save the pointer for later use
        new_argv[i] = guest_ptr;
    }

    ///// now set up the initial stack frame
    
    // The argument info starts after one register window (16 words) past the SP.    
    guest_ptr = target_sp + 16 * sizeof(abi_ulong);

    // copy argc
    put_user_ual(argc, guest_ptr);
    guest_ptr += sizeof(abi_ulong);
    
    // copy argvs, from argv[0] to argv[argc-1] 
    for (i = 0; i < argc; i++) {
        put_user_ual(new_argv[i], guest_ptr);
        guest_ptr += sizeof(abi_ulong);
    }
    
    // copy word 0
    put_user_ual(0, guest_ptr);
    guest_ptr += sizeof(abi_ulong);

    ///// finalize
    
    free(new_argv);
}


/////////////////////////////////////////////////////////////////////////////////
// interface implementation
/////////////////////////////////////////////////////////////////////////////////

void sl_init(uint32_t brk, uint32_t init_stack_pointer,
             unsigned long gb, unsigned long gm,
             int argc, char *argv[]) {
    int i;
    
    // initialize the guest state
    guest_base = gb;
    guest_max_mem  = gm;

    // initialize the target state
    target_brk = brk;
    target_brk_limit = guest_max_mem / 4;
    target_cur_mmap_ptr = target_brk_limit;
    target_mmap_limit = guest_max_mem / 2;    
    target_sp = init_stack_pointer;
    target_exit_called = 0;

    // Build target_to_host_errno_table[] table from
    // host_to_target_errno_table[].
    for (i = 0; i < ERRNO_TABLE_SIZE; i++) {
        target_to_host_errno_table[host_to_target_errno_table[i]] = i;
    }

    // load the program arguments on the target stack
    init_stack(argc, argv);    
}

int32_t sl_syscall(int32_t num, int32_t arg1, int32_t arg2,
                   int32_t arg3, int32_t arg4, int32_t arg5, 
                   int32_t arg6, int32_t arg7, int32_t arg8)
{
    return do_syscall(num, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8);
}

int sl_exit_called() {
    return target_exit_called;
}
