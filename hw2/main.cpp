#include <iostream>
#include <string.h>
#include "Vtop.h"
#include "verilated.h"
#include "system.h"
#if VM_TRACE
# include <verilated_vcd_c.h>	// Trace file format header
#endif

#define RAM_SIZE  (1*MEGA)

int main(int argc, char* argv[]) {

	// initialize
	Verilated::commandArgs(argc, argv);
	Vtop top;
	System sys(&top, RAM_SIZE, ps_per_clock);
	
	// to ensure the repeatability of the generated random numbers
	srand(0);
	
	VerilatedVcdC* tfp = NULL;
#if VM_TRACE
	// If verilator was invoked with --trace
	Verilated::traceEverOn(true);
	VL_PRINTF("Enabling waves...\n");
	tfp = new VerilatedVcdC;
	assert(tfp);
	// Trace 99 levels of hierarchy
	top.trace (tfp, 99);
	tfp->spTrace()->set_time_resolution("1 ps");
	// Open the dump file
	tfp->open ("../trace.vcd");
#endif

#define TICK() do {                        \
		top.clk = !top.clk;                \
		top.eval();                        \
		if (tfp) tfp->dump(main_time);     \
		sys.tick(top.clk);                 \
		main_time += ps_per_clock/4;       \
		top.eval();                        \
		if (tfp) tfp->dump(main_time);     \
		main_time += ps_per_clock/4;       \
	} while(0)

	top.reset = 1;
	top.clk = 0;
	TICK(); // 1
	TICK(); // 0
	top.reset = 0;
	TICK(); // 1
	TICK(); // 0
	while (main_time/ps_per_clock < 200*KILO && !Verilated::gotFinish()) {
		TICK();
	}

	top.final();

#if VM_TRACE
	if (tfp) tfp->close();
	delete tfp;
#endif

	return 0;
}
