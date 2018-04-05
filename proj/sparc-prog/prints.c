#include <string.h>
#include <unistd.h>

#define print_(str) write(1, (str), strlen(str))

inline void print_udecimal(unsigned long num) {	
	static const char *DEC_DIGITS[] = {"0", "1", "2", "3", "4", "5", "6", "7", "8", "9"};
	char digits[100];
	int num_digits = -1;
	
	while (num >= 0) {
		digits[++num_digits] = num % 10;
		num = num / 10;
		if (0 == num) break;
	}

	for (; num_digits >= 0; num_digits--)
		write(1, DEC_DIGITS[digits[num_digits]], 1);
}

inline void print_decimal(long num) {
	if (num < 0)
		print_udecimal(-num);
	else
		print_udecimal(num);
}

inline void print_hex(unsigned long num) {
	static const char *HEX_DIGITS[] = {"0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"};
	char digits[100];
	int num_digits = -1;
	
	while (num >= 0) {
		digits[++num_digits] = num % 16;
		num = num / 16;
		if (0 == num) break;
	}

	for (; num_digits >= 0; num_digits--)
		write(1, HEX_DIGITS[digits[num_digits]], 1);
}
