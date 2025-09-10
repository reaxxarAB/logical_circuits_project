[read_me.txt](https://github.com/user-attachments/files/22250339/read_me.txt)
// 40332329 _ Arian bahari
// 40332363 _ Mohammad ebrahim moein aldini


README — CPU Cache Simulator (short)

Project purpose:
Implement a simple direct-mapped cache model in Verilog.
Used to study hit/miss behavior and basic write policies.

Key specs:
Direct-mapped, NUM_LINES = 16, WORD_PER_LINE = 4 (word = 4 bytes).
Main memory is byte-addressable, MEM_SIZE = 1024 bytes, initialized from memory.list via $readmemb.

Address map:
Index = address[7:4] (select row).
Word offset = address[3:2] (select word in line).
Tag = address[31:8].

Main signals:
Inputs: clk_i, addr_i, rst_i, acc_i, we_i, wdata_i.
Outputs: rdata_o (32-bit), hit_miss_o, accesses_o, misses_o.

Core functions (in code):
is_cached(address) — return 1 if valid bit set and tag matches (HIT), else 0.

read_line_word(row, column) — return 32-bit word from cache line or NULL if invalid.

compose_mem_addr(n, row) — build byte address from stored tag, row, word index, and two low zeros.

load_line(address) — mark valid, store tag, read 4 words from main memory into the cache line, and return requested word.

Runtime logic (process):
On reset: clear valid bits and zero counters.

On each clock, when acc_i is asserted increment accesses_o.

Read (we_i == 0): if is_cached true → HIT: return cached word; else → MISS: increment misses_o, call load_line and return loaded word.

Write (we_i == 1): if is_cached true → HIT: write to cache and write-through to main memory; else → MISS: increment misses_o, load line (write-allocate), then write to cache and main memory.

Data format:
Words are composed from four bytes in little-endian order: {main_mem[addr+3], main_mem[addr+2], main_mem[addr+1], main_mem[addr]}.

Testbench:
Cache_tb generates clock and reset then performs a fixed sequence of 10 accesses (reads/writes).
Each access prints Data_Out, Hit/Miss, Accesses and Misses. Final line prints total accesses, misses, and hit rate.

How to run:
Place memory.list in the simulation working directory. Run the testbench in Vivado XSim (or any Verilog simulator). Observe printed lines for verification.
