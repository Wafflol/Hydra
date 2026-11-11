VERILATOR = verilator

# Packages must be compiled before the modules that import them
PKGS = rtl/cpu_types.sv
RTL  = $(PKGS) $(filter-out $(PKGS),$(wildcard rtl/*.sv))

# Pick a testbench with: make TOP=tb_alu
TOP ?= tb_reg_file
TB   = tb/$(TOP).sv
OBJ  = obj_dir/$(TOP)

# All testbenches, for `make test`
TOPS = $(basename $(notdir $(wildcard tb/tb_*.sv)))

# Test programs: make prog PROG=basic builds sw/basic.S into
# build/basic.hex (plus a disassembly in build/basic.dis) and copies it
# to prog.hex, which instr_mem loads by default.
PROG  ?= basic
SW    = sw
BUILD = build
RV_CC = clang --target=riscv32 -march=rv32i -mabi=ilp32 -nostdlib
RV_LD = ld.lld -Ttext=0 --image-base=0

# Colors
RESET  = \033[0m
BOLD   = \033[1m
GREEN  = \033[32m
CYAN   = \033[36m
YELLOW = \033[33m
RED    = \033[31m

.PHONY: all build run wave lint test prog clean

all: run

build:
	@printf "$(CYAN)$(BOLD)==> Building $(TOP)...$(RESET)\n"
	@mkdir -p $(OBJ)
	$(VERILATOR) --binary --timing --trace-vcd \
		--Mdir $(OBJ) --top-module $(TOP) \
		$(RTL) $(TB)
	@printf "$(GREEN)$(BOLD)==> Build complete.$(RESET)\n"

run: build
	@printf "$(CYAN)$(BOLD)==> Running $(TOP)...$(RESET)\n"
	./$(OBJ)/V$(TOP)

wave: run
	@printf "$(CYAN)$(BOLD)==> Opening GTKWave...$(RESET)\n"
	gtkwave dump.vcd

lint:
	@printf "$(CYAN)$(BOLD)==> Linting RTL...$(RESET)\n"
	$(VERILATOR) --lint-only -Wall -Wno-MULTITOP $(RTL)
	@printf "$(GREEN)$(BOLD)==> Lint clean.$(RESET)\n"

# Quiet: one line per testbench. Logs are kept in obj_dir/<tb>/ and
# printed only when that testbench fails to build or run.
prog: $(BUILD)/$(PROG).hex
	@cp $< prog.hex
	@printf "$(GREEN)$(BOLD)==> Built $(SW)/$(PROG).S -> prog.hex$(RESET)\n"

# Assemble, link at address 0, then turn the raw binary into one
# 32-bit hex word per line for $readmemh (od uses the host's byte order,
# which is little-endian on x86, matching RISC-V)
$(BUILD)/%.hex: $(SW)/%.S
	@mkdir -p $(BUILD)
	$(RV_CC) -c $< -o $(BUILD)/$*.o
	$(RV_LD) $(BUILD)/$*.o -o $(BUILD)/$*.elf
	llvm-objcopy -O binary $(BUILD)/$*.elf $(BUILD)/$*.bin
	od -An -v -tx4 -w4 $(BUILD)/$*.bin | tr -d ' ' > $@
	llvm-objdump -d $(BUILD)/$*.elf > $(BUILD)/$*.dis

test: prog
	@fail=0; \
	for t in $(TOPS); do \
		log=obj_dir/$$t; mkdir -p $$log; \
		if ! $(MAKE) -s --no-print-directory build TOP=$$t > $$log/build.log 2>&1; then \
			printf "  $(RED)$(BOLD)BUILD FAIL$(RESET)  $$t\n"; cat $$log/build.log; fail=1; \
		elif ! ./$$log/V$$t > $$log/run.log 2>&1; then \
			printf "  $(RED)$(BOLD)FAIL$(RESET)        $$t\n"; grep -v '^- ' $$log/run.log; fail=1; \
		else \
			printf "  $(GREEN)PASS$(RESET)        $$t\n"; \
		fi; \
	done; \
	if [ $$fail -eq 0 ]; then printf "$(GREEN)$(BOLD)==> All testbenches passed.$(RESET)\n"; \
	else printf "$(RED)$(BOLD)==> Some testbenches failed.$(RESET)\n"; exit 1; fi

clean:
	@printf "$(YELLOW)==> Cleaning...$(RESET)\n"
	rm -rf obj_dir dump.vcd $(BUILD) prog.hex
	@printf "$(GREEN)==> Clean complete.$(RESET)\n"
