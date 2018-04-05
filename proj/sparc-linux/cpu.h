#ifndef CPU_SPARC_H
#define CPU_SPARC_H

#define ALIGNED_ONLY

#if !defined(TARGET_SPARC64)
#define TARGET_LONG_BITS 32
#define TARGET_DPREGS 16
#define TARGET_PAGE_BITS 12 /* 4k */
#define TARGET_PHYS_ADDR_SPACE_BITS 36
#define TARGET_VIRT_ADDR_SPACE_BITS 32
#else
#define TARGET_LONG_BITS 64
#define TARGET_DPREGS 32
#define TARGET_PAGE_BITS 13 /* 8k */
#define TARGET_PHYS_ADDR_SPACE_BITS 41
# ifdef TARGET_ABI32
#  define TARGET_VIRT_ADDR_SPACE_BITS 32
# else
#  define TARGET_VIRT_ADDR_SPACE_BITS 44
# endif
#endif

#include "cpu-defs.h"

#define TARGET_HAS_ICE 1

#if !defined(TARGET_SPARC64)
#define ELF_MACHINE     EM_SPARC
#else
#define ELF_MACHINE     EM_SPARCV9
#endif

/* trap definitions */
#ifndef TARGET_SPARC64
#define TT_TFAULT   0x01
#define TT_ILL_INSN 0x02
#define TT_PRIV_INSN 0x03
#define TT_NFPU_INSN 0x04
#define TT_WIN_OVF  0x05
#define TT_WIN_UNF  0x06
#define TT_UNALIGNED 0x07
#define TT_FP_EXCP  0x08
#define TT_DFAULT   0x09
#define TT_TOVF     0x0a
#define TT_EXTINT   0x10
#define TT_CODE_ACCESS 0x21
#define TT_UNIMP_FLUSH 0x25
#define TT_DATA_ACCESS 0x29
#define TT_DIV_ZERO 0x2a
#define TT_NCP_INSN 0x24
#define TT_TRAP     0x80
#else
#define TT_POWER_ON_RESET 0x01
#define TT_TFAULT   0x08
#define TT_CODE_ACCESS 0x0a
#define TT_ILL_INSN 0x10
#define TT_UNIMP_FLUSH TT_ILL_INSN
#define TT_PRIV_INSN 0x11
#define TT_NFPU_INSN 0x20
#define TT_FP_EXCP  0x21
#define TT_TOVF     0x23
#define TT_CLRWIN   0x24
#define TT_DIV_ZERO 0x28
#define TT_DFAULT   0x30
#define TT_DATA_ACCESS 0x32
#define TT_UNALIGNED 0x34
#define TT_PRIV_ACT 0x37
#define TT_EXTINT   0x40
#define TT_IVEC     0x60
#define TT_TMISS    0x64
#define TT_DMISS    0x68
#define TT_DPROT    0x6c
#define TT_SPILL    0x80
#define TT_FILL     0xc0
#define TT_WOTHER   (1 << 5)
#define TT_TRAP     0x100
#endif

#define PSR_NEG_SHIFT 23
#define PSR_NEG   (1 << PSR_NEG_SHIFT)
#define PSR_ZERO_SHIFT 22
#define PSR_ZERO  (1 << PSR_ZERO_SHIFT)
#define PSR_OVF_SHIFT 21
#define PSR_OVF   (1 << PSR_OVF_SHIFT)
#define PSR_CARRY_SHIFT 20
#define PSR_CARRY (1 << PSR_CARRY_SHIFT)
#define PSR_ICC   (PSR_NEG|PSR_ZERO|PSR_OVF|PSR_CARRY)
#if !defined(TARGET_SPARC64)
#define PSR_EF    (1<<12)
#define PSR_PIL   0xf00
#define PSR_S     (1<<7)
#define PSR_PS    (1<<6)
#define PSR_ET    (1<<5)
#define PSR_CWP   0x1f
#endif

#define CC_SRC (env->cc_src)
#define CC_SRC2 (env->cc_src2)
#define CC_DST (env->cc_dst)
#define CC_OP  (env->cc_op)

enum {
    CC_OP_DYNAMIC, /* must use dynamic code to get cc_op */
    CC_OP_FLAGS,   /* all cc are back in status register */
    CC_OP_DIV,     /* modify N, Z and V, C = 0*/
    CC_OP_ADD,     /* modify all flags, CC_DST = res, CC_SRC = src1 */
    CC_OP_ADDX,    /* modify all flags, CC_DST = res, CC_SRC = src1 */
    CC_OP_TADD,    /* modify all flags, CC_DST = res, CC_SRC = src1 */
    CC_OP_TADDTV,  /* modify all flags except V, CC_DST = res, CC_SRC = src1 */
    CC_OP_SUB,     /* modify all flags, CC_DST = res, CC_SRC = src1 */
    CC_OP_SUBX,    /* modify all flags, CC_DST = res, CC_SRC = src1 */
    CC_OP_TSUB,    /* modify all flags, CC_DST = res, CC_SRC = src1 */
    CC_OP_TSUBTV,  /* modify all flags except V, CC_DST = res, CC_SRC = src1 */
    CC_OP_LOGIC,   /* modify N and Z, C = V = 0, CC_DST = res */
    CC_OP_NB,
};

/* Trap base register */
#define TBR_BASE_MASK 0xfffff000

#if defined(TARGET_SPARC64)
#define PS_TCT   (1<<12) /* UA2007, impl.dep. trap on control transfer */
#define PS_IG    (1<<11) /* v9, zero on UA2007 */
#define PS_MG    (1<<10) /* v9, zero on UA2007 */
#define PS_CLE   (1<<9) /* UA2007 */
#define PS_TLE   (1<<8) /* UA2007 */
#define PS_RMO   (1<<7)
#define PS_RED   (1<<5) /* v9, zero on UA2007 */
#define PS_PEF   (1<<4) /* enable fpu */
#define PS_AM    (1<<3) /* address mask */
#define PS_PRIV  (1<<2)
#define PS_IE    (1<<1)
#define PS_AG    (1<<0) /* v9, zero on UA2007 */

#define FPRS_FEF (1<<2)

#define HS_PRIV  (1<<2)
#endif

/* Fcc */
#define FSR_RD1        (1ULL << 31)
#define FSR_RD0        (1ULL << 30)
#define FSR_RD_MASK    (FSR_RD1 | FSR_RD0)
#define FSR_RD_NEAREST 0
#define FSR_RD_ZERO    FSR_RD0
#define FSR_RD_POS     FSR_RD1
#define FSR_RD_NEG     (FSR_RD1 | FSR_RD0)

#define FSR_NVM   (1ULL << 27)
#define FSR_OFM   (1ULL << 26)
#define FSR_UFM   (1ULL << 25)
#define FSR_DZM   (1ULL << 24)
#define FSR_NXM   (1ULL << 23)
#define FSR_TEM_MASK (FSR_NVM | FSR_OFM | FSR_UFM | FSR_DZM | FSR_NXM)

#define FSR_NVA   (1ULL << 9)
#define FSR_OFA   (1ULL << 8)
#define FSR_UFA   (1ULL << 7)
#define FSR_DZA   (1ULL << 6)
#define FSR_NXA   (1ULL << 5)
#define FSR_AEXC_MASK (FSR_NVA | FSR_OFA | FSR_UFA | FSR_DZA | FSR_NXA)

#define FSR_NVC   (1ULL << 4)
#define FSR_OFC   (1ULL << 3)
#define FSR_UFC   (1ULL << 2)
#define FSR_DZC   (1ULL << 1)
#define FSR_NXC   (1ULL << 0)
#define FSR_CEXC_MASK (FSR_NVC | FSR_OFC | FSR_UFC | FSR_DZC | FSR_NXC)

#define FSR_FTT2   (1ULL << 16)
#define FSR_FTT1   (1ULL << 15)
#define FSR_FTT0   (1ULL << 14)
//gcc warns about constant overflow for ~FSR_FTT_MASK
//#define FSR_FTT_MASK (FSR_FTT2 | FSR_FTT1 | FSR_FTT0)
#ifdef TARGET_SPARC64
#define FSR_FTT_NMASK      0xfffffffffffe3fffULL
#define FSR_FTT_CEXC_NMASK 0xfffffffffffe3fe0ULL
#define FSR_LDFSR_OLDMASK  0x0000003f000fc000ULL
#define FSR_LDXFSR_MASK    0x0000003fcfc00fffULL
#define FSR_LDXFSR_OLDMASK 0x00000000000fc000ULL
#else
#define FSR_FTT_NMASK      0xfffe3fffULL
#define FSR_FTT_CEXC_NMASK 0xfffe3fe0ULL
#define FSR_LDFSR_OLDMASK  0x000fc000ULL
#endif
#define FSR_LDFSR_MASK     0xcfc00fffULL
#define FSR_FTT_IEEE_EXCP (1ULL << 14)
#define FSR_FTT_UNIMPFPOP (3ULL << 14)
#define FSR_FTT_SEQ_ERROR (4ULL << 14)
#define FSR_FTT_INVAL_FPR (6ULL << 14)

#define FSR_FCC1_SHIFT 11
#define FSR_FCC1  (1ULL << FSR_FCC1_SHIFT)
#define FSR_FCC0_SHIFT 10
#define FSR_FCC0  (1ULL << FSR_FCC0_SHIFT)

/* MMU */
#define MMU_E     (1<<0)
#define MMU_NF    (1<<1)

#define PTE_ENTRYTYPE_MASK 3
#define PTE_ACCESS_MASK    0x1c
#define PTE_ACCESS_SHIFT   2
#define PTE_PPN_SHIFT      7
#define PTE_ADDR_MASK      0xffffff00

#define PG_ACCESSED_BIT 5
#define PG_MODIFIED_BIT 6
#define PG_CACHE_BIT    7

#define PG_ACCESSED_MASK (1 << PG_ACCESSED_BIT)
#define PG_MODIFIED_MASK (1 << PG_MODIFIED_BIT)
#define PG_CACHE_MASK    (1 << PG_CACHE_BIT)

/* 3 <= NWINDOWS <= 32. */
#define MIN_NWINDOWS 3
#define MAX_NWINDOWS 32

#if !defined(TARGET_SPARC64)
#define NB_MMU_MODES 2
#else
#define NB_MMU_MODES 6
typedef struct trap_state {
    uint64_t tpc;
    uint64_t tnpc;
    uint64_t tstate;
    uint32_t tt;
} trap_state;
#endif

typedef struct sparc_def_t {
    const char *name;
    target_ulong iu_version;
    uint32_t fpu_version;
    uint32_t mmu_version;
    uint32_t mmu_bm;
    uint32_t mmu_ctpr_mask;
    uint32_t mmu_cxr_mask;
    uint32_t mmu_sfsr_mask;
    uint32_t mmu_trcr_mask;
    uint32_t mxcc_version;
    uint32_t features;
    uint32_t nwindows;
    uint32_t maxtl;
} sparc_def_t;

#define CPU_FEATURE_FLOAT        (1 << 0)
#define CPU_FEATURE_FLOAT128     (1 << 1)
#define CPU_FEATURE_SWAP         (1 << 2)
#define CPU_FEATURE_MUL          (1 << 3)
#define CPU_FEATURE_DIV          (1 << 4)
#define CPU_FEATURE_FLUSH        (1 << 5)
#define CPU_FEATURE_FSQRT        (1 << 6)
#define CPU_FEATURE_FMUL         (1 << 7)
#define CPU_FEATURE_VIS1         (1 << 8)
#define CPU_FEATURE_VIS2         (1 << 9)
#define CPU_FEATURE_FSMULD       (1 << 10)
#define CPU_FEATURE_HYPV         (1 << 11)
#define CPU_FEATURE_CMT          (1 << 12)
#define CPU_FEATURE_GL           (1 << 13)
#define CPU_FEATURE_TA0_SHUTDOWN (1 << 14) /* Shutdown on "ta 0x0" */
#define CPU_FEATURE_ASR17        (1 << 15)
#define CPU_FEATURE_CACHE_CTRL   (1 << 16)
#define CPU_FEATURE_POWERDOWN    (1 << 17)
#define CPU_FEATURE_CASA         (1 << 18)

#ifndef TARGET_SPARC64
#define CPU_DEFAULT_FEATURES (CPU_FEATURE_FLOAT | CPU_FEATURE_SWAP |  \
                              CPU_FEATURE_MUL | CPU_FEATURE_DIV |     \
                              CPU_FEATURE_FLUSH | CPU_FEATURE_FSQRT | \
                              CPU_FEATURE_FMUL | CPU_FEATURE_FSMULD)
#else
#define CPU_DEFAULT_FEATURES (CPU_FEATURE_FLOAT | CPU_FEATURE_SWAP |  \
                              CPU_FEATURE_MUL | CPU_FEATURE_DIV |     \
                              CPU_FEATURE_FLUSH | CPU_FEATURE_FSQRT | \
                              CPU_FEATURE_FMUL | CPU_FEATURE_VIS1 |   \
                              CPU_FEATURE_VIS2 | CPU_FEATURE_FSMULD | \
                              CPU_FEATURE_CASA)
enum {
    mmu_us_12, // Ultrasparc < III (64 entry TLB)
    mmu_us_3,  // Ultrasparc III (512 entry TLB)
    mmu_us_4,  // Ultrasparc IV (several TLBs, 32 and 256MB pages)
    mmu_sun4v, // T1, T2
};
#endif

#define TTE_VALID_BIT       (1ULL << 63)
#define TTE_NFO_BIT         (1ULL << 60)
#define TTE_USED_BIT        (1ULL << 41)
#define TTE_LOCKED_BIT      (1ULL <<  6)
#define TTE_SIDEEFFECT_BIT  (1ULL <<  3)
#define TTE_PRIV_BIT        (1ULL <<  2)
#define TTE_W_OK_BIT        (1ULL <<  1)
#define TTE_GLOBAL_BIT      (1ULL <<  0)

#define TTE_IS_VALID(tte)   ((tte) & TTE_VALID_BIT)
#define TTE_IS_NFO(tte)     ((tte) & TTE_NFO_BIT)
#define TTE_IS_USED(tte)    ((tte) & TTE_USED_BIT)
#define TTE_IS_LOCKED(tte)  ((tte) & TTE_LOCKED_BIT)
#define TTE_IS_SIDEEFFECT(tte) ((tte) & TTE_SIDEEFFECT_BIT)
#define TTE_IS_PRIV(tte)    ((tte) & TTE_PRIV_BIT)
#define TTE_IS_W_OK(tte)    ((tte) & TTE_W_OK_BIT)
#define TTE_IS_GLOBAL(tte)  ((tte) & TTE_GLOBAL_BIT)

#define TTE_SET_USED(tte)   ((tte) |= TTE_USED_BIT)
#define TTE_SET_UNUSED(tte) ((tte) &= ~TTE_USED_BIT)

#define TTE_PGSIZE(tte)     (((tte) >> 61) & 3ULL)
#define TTE_PA(tte)         ((tte) & 0x1ffffffe000ULL)

#define SFSR_NF_BIT         (1ULL << 24)   /* JPS1 NoFault */
#define SFSR_TM_BIT         (1ULL << 15)   /* JPS1 TLB Miss */
#define SFSR_FT_VA_IMMU_BIT (1ULL << 13)   /* USIIi VA out of range (IMMU) */
#define SFSR_FT_VA_DMMU_BIT (1ULL << 12)   /* USIIi VA out of range (DMMU) */
#define SFSR_FT_NFO_BIT     (1ULL << 11)   /* NFO page access */
#define SFSR_FT_ILL_BIT     (1ULL << 10)   /* illegal LDA/STA ASI */
#define SFSR_FT_ATOMIC_BIT  (1ULL <<  9)   /* atomic op on noncacheable area */
#define SFSR_FT_NF_E_BIT    (1ULL <<  8)   /* NF access on side effect area */
#define SFSR_FT_PRIV_BIT    (1ULL <<  7)   /* privilege violation */
#define SFSR_PR_BIT         (1ULL <<  3)   /* privilege mode */
#define SFSR_WRITE_BIT      (1ULL <<  2)   /* write access mode */
#define SFSR_OW_BIT         (1ULL <<  1)   /* status overwritten */
#define SFSR_VALID_BIT      (1ULL <<  0)   /* status valid */

#define SFSR_ASI_SHIFT      16             /* 23:16 ASI value */
#define SFSR_ASI_MASK       (0xffULL << SFSR_ASI_SHIFT)
#define SFSR_CT_PRIMARY     (0ULL <<  4)   /* 5:4 context type */
#define SFSR_CT_SECONDARY   (1ULL <<  4)
#define SFSR_CT_NUCLEUS     (2ULL <<  4)
#define SFSR_CT_NOTRANS     (3ULL <<  4)
#define SFSR_CT_MASK        (3ULL <<  4)

/* Leon3 cache control */

/* Cache control: emulate the behavior of cache control registers but without
   any effect on the emulated */

#define CACHE_STATE_MASK 0x3
#define CACHE_DISABLED   0x0
#define CACHE_FROZEN     0x1
#define CACHE_ENABLED    0x3

/* Cache Control register fields */

#define CACHE_CTRL_IF (1 <<  4)  /* Instruction Cache Freeze on Interrupt */
#define CACHE_CTRL_DF (1 <<  5)  /* Data Cache Freeze on Interrupt */
#define CACHE_CTRL_DP (1 << 14)  /* Data cache flush pending */
#define CACHE_CTRL_IP (1 << 15)  /* Instruction cache flush pending */
#define CACHE_CTRL_IB (1 << 16)  /* Instruction burst fetch */
#define CACHE_CTRL_FI (1 << 21)  /* Flush Instruction cache (Write only) */
#define CACHE_CTRL_FD (1 << 22)  /* Flush Data cache (Write only) */
#define CACHE_CTRL_DS (1 << 23)  /* Data cache snoop enable */

#endif // #ifndef CPU_SPARC_H
