#ifndef __SYSTEM_H
#define __SYSTEM_H

#include <map>
#include <list>
#include <queue>
#include <stdint.h>
#include "Vtop.h"
#include "dramsim2/DRAMSim.h"

#define KILO (1024UL)
#define MEGA (1024UL*1024)
#define GIGA (1024UL*1024*1024)

extern uint64_t main_time;
extern const int ps_per_clock;
double sc_time_stamp();

class System {
    Vtop* top;

    char* ram;
    unsigned int ramsize;

    int cmd, rx_count;
    uint64_t xfer_addr;
    std::map<uint64_t, int> addr_to_tag;
    std::list<std::pair<uint64_t, int> > tx_queue;

    void dram_read_complete(unsigned id, uint64_t address, uint64_t clock_cycle);
    void dram_write_complete(unsigned id, uint64_t address, uint64_t clock_cycle);
    DRAMSim::MultiChannelMemorySystem* dramsim;

    void procTick(int clk);
    void ramTick(int clk);
    
public:
    System(Vtop* top, unsigned ramsize, int ps_per_clock);
    ~System();

    void tick(int clk);

    uint64_t get_ram_address()  { return (uint64_t)ram; }    
};

#endif
