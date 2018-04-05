#ifndef CSE502_SYSCALL_H_
#define CSE502_SYSCALL_H_

#ifdef __cplusplus
extern "C" {
#endif

/** Initialize the system-call subsystem. */
void sl_init(uint32_t guest_brk, uint32_t init_stack_pointer,
			 unsigned long guest_base, unsigned long guest_max_mem,
			 int argc, char *argv[]);

/**
 * Do system call.
 * This function expects its arguments in little-endian (host machine) format.
 */
int32_t sl_syscall(int32_t num, int32_t arg1, int32_t arg2,
                   int32_t arg3, int32_t arg4, int32_t arg5, 
                   int32_t arg6, int32_t arg7, int32_t arg8);

int sl_exit_called();

#ifdef __cplusplus
}
#endif
                   
#endif // #ifndef CSE502_SYSCALL_H_
