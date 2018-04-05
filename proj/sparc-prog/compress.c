// compress.c - Demonstrates miniz.c's compress() function
#include "prints.c"
#include "miniz.c"

typedef unsigned char uint8;
typedef unsigned short uint16;
typedef unsigned int uint;

// The string to compress.
static const char *s_pStr = "Good morning Dr. Chandra. This is Hal. I am ready for my first lesson." \
  "Good morning Dr. Chandra. This is Hal. I am ready for my first lesson." \
  "Good morning Dr. Chandra. This is Hal. I am ready for my first lesson." \
  "Good morning Dr. Chandra. This is Hal. I am ready for my first lesson." \
  "Good morning Dr. Chandra. This is Hal. I am ready for my first lesson." \
  "Good morning Dr. Chandra. This is Hal. I am ready for my first lesson." \
  "Good morning Dr. Chandra. This is Hal. I am ready for my first lesson.";

int main() {
  int cmp_status;
  uLong src_len = (uLong)strlen(s_pStr);
  uLong cmp_len = compressBound(src_len);
  uint8 *pCmp, *pUncomp;

  print_("miniz.c version: ");
  print_(MZ_VERSION);
  print_("\n");

  // Allocate buffers to hold compressed and uncompressed data.
  pCmp = (mz_uint8 *)malloc((size_t)cmp_len);
  pUncomp = (mz_uint8 *)malloc((size_t)src_len);
  if ((!pCmp) || (!pUncomp)) {
    print_("Out of memory!\n");
    return EXIT_FAILURE;
  }

  // Compress the string.
  cmp_status = compress(pCmp, &cmp_len, (const unsigned char *)s_pStr, src_len);
  if (cmp_status != Z_OK) {
    print_("compress() failed!\n");
    free(pCmp);
    free(pUncomp);
    return EXIT_FAILURE;
  }

  print_("Compressed from ");
  print_udecimal((mz_uint32)src_len);
  print_(" to ");
  print_udecimal((mz_uint32)cmp_len);
  print_(" bytes\n");

  free(pCmp);
  free(pUncomp);

  print_("Success.\n");
  return EXIT_SUCCESS;
}
