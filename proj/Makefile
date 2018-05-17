include conf/lab.mk
include conf/user.mk

.PHONY: all progs run clean submit

RUNELF=$(PWD)/sparc-prog/branches.exe
TRACE=--trace
VFILES=$(wildcard *.sv)
CFILES=$(wildcard *.cpp)

all: obj_dir/Vtop progs

progs:
	$(MAKE) -C $(PWD)/sparc-prog

obj_dir/Vtop: obj_dir/Vtop.mk
	$(MAKE) -C $(PWD)/sparc-linux
	$(MAKE) -j2 -C obj_dir/ -f Vtop.mk CXX="g++"

obj_dir/Vtop.mk: $(VFILES) $(CFILES) 
	verilator -Wall -Wno-LITENDIAN -Wno-lint -O3 $(TRACE) --no-skip-identical --cc top.sv --exe $(CFILES) \
	../dramsim2/libdramsim.so $(PWD)/sparc-linux/syscall.o \
	-CFLAGS -I$(PWD)/sparc-linux \
	-LDFLAGS -Wl,-rpath=../dramsim2/ -LDFLAGS -lncurses -LDFLAGS -lelf

run: obj_dir/Vtop
	cd obj_dir/ && ./Vtop $(RUNELF)

clean:
	$(MAKE) -C $(PWD)/sparc-linux clean
	$(MAKE) -C $(PWD)/sparc-prog clean
	rm -rf obj_dir/ dramsim2/results trace.vcd core 

HANDIN_FILE=/tmp/$(NETID)-lab$(LAB).tar.gz

submit-check:
	@if [ `git status --porcelain | wc -l` != 0 ] ; then \
		echo "!!! You have uncomitted changes.  Please commit them before submitting."; \
		false; \
	fi
	@if test -n "`git ls-files -o --exclude-standard`"; then \
		git status; \
		read -p "!!! Untracked files will not be handed in.  Continue? [y/N] " r; \
		test "$$r" = y; \
	fi

submit: submit-check clean
	@echo Packing the code...
	@for s in $(SUB_PROJECTS) ; do make -C $$s clean ; done
	@git tag -f -a lab$(LAB)-handin -m "Lab$(LAB) Handin"
	@rm -rf $(HANDIN_FILE)
	@git archive --format=tar HEAD | gzip > $(HANDIN_FILE)
	@chmod o+r $(HANDIN_FILE)
	@./handin.sh $(HANDIN_FILE)
