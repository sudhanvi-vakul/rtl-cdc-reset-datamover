# Verification Notes

## Project
Async FIFO – CDC Reset-Safe Data Mover

## DUT
Top-level DUT: async_fifo_reset_safe
Core FIFO: async_fifo

## Simulator
XSim (Vivado 2019.2)

## Primary Verification Goal
Verify correct FIFO behavior across independent clock domains, including reset synchronization, safe reset recovery, ordering guarantees, full/empty flag correctness, concurrent traffic behavior, pointer wraparound, and CDC flag/data propagation latency.

---

# 1. Waveform Debug

Waveform artifact:

reports/run_<timestamp>/work.sim.wdb

Screenshots stored in:

evidence/waveforms/

---

## Waveform Debug Checklist

### Reset Assertion and Deassertion Behavior

| Check                                             | Expected                                      | Result |
|---------------------------------------------------|-----------------------------------------------|--------|
| Write-domain async reset asserts immediately      | `wr_arst_n` low forces write-side reset state | PASS   |
| Read-domain async reset asserts immediately       | `rd_arst_n` low forces read-side reset state  | PASS   |
| Write synchronized reset deasserts on write clock | `wr_srst_n` releases only on `wr_clk` edge    | PASS   |
| Read synchronized reset deasserts on read clock   | `rd_srst_n` releases only on `rd_clk` edge    | PASS   |
| FIFO enters empty state after reset               | `empty = 1`                                   | PASS   | 
| FIFO not full after reset                         | `full = 0`                                    | PASS   |
| Write pointer reset                               | `wr_ptr_bin = 0`                              | PASS   |
| Read pointer reset                                | `rd_ptr_bin = 0`                              | PASS   |

Screenshot  
evidence/waveforms/async_fifo_reset_sync_release.png

---

### First Write Operation

| Check                                          | Expected                                   | Result |
|------------------------------------------------|--------------------------------------------|--------|
| Write occurs on write clock edge               | `wr_clk` edge triggers pointer increment   | PASS   |
| Write pointer increments                       | `wr_ptr_bin` increases by 1                | PASS   |
| Data accepted when not full                    | write accepted                             | PASS   |
| Empty flag eventually deasserts in read domain | `empty` transitions to 0 after CDC latency | PASS   |

Screenshot  
evidence/waveforms/async_fifo_first_write1.png  
evidence/waveforms/async_fifo_first_write2.png

---

### First Read Operation

| Check                                | Expected                                 | Result |
|--------------------------------------|------------------------------------------|--------|
| Read occurs on read clock edge       | `rd_clk` edge triggers pointer increment | PASS   |
| Read pointer increments              | `rd_ptr_bin` increases by 1              | PASS   |
| Read data equals first written value | data integrity preserved                 | PASS   |
| FIFO returns to empty after drain    | `empty` becomes 1 eventually             | PASS   |

Screenshot  
evidence/waveforms/async_fifo_first_read.png  


---

### Full Condition

| Check                                                             | Expected                      | Result |
|-------------------------------------------------------------------|-------------------------------|--------|
| FIFO eventually asserts full                                      | `full = 1`                    | PASS   |
| Writes blocked when full                                          | no illegal pointer advance    | PASS   |
| No invalid writes accepted                                        | memory contents remain stable | PASS   |
| Full deasserts only after read-side progress is synchronized back | expected CDC latency observed | PASS   |

Screenshot  
evidence/waveforms/async_fifo_full_condition1.png
evidence/waveforms/async_fifo_full_condition2.png
evidence/waveforms/async_fifo_full_condition3.png

---

### Empty Condition

| Check                                                                           | Expected                      | Result |
|---------------------------------------------------------------------------------|-------------------------------|--------|
| FIFO asserts empty after final read                                             | `empty = 1`                   | PASS   |
| Additional reads ignored                                                        | pointer remains stable        | PASS   |
| Empty deasserts only after write-side progress is synchronized into read domain | expected CDC latency observed | PASS   |

Screenshot  
evidence/waveforms/async_fifo_empty_condition.png
evidence/waveforms/async_fifo_empty_condition1.png
evidence/waveforms/async_fifo_empty_condition2.png
evidence/waveforms/async_fifo_empty_condition3.png
---

### CDC Pointer / Flag Behavior

| Check                                                               | Expected                                             | Result |
|---------------------------------------------------------------------|------------------------------------------------------|--------|
| Write-domain pointer changes propagate to read domain after syncdly | expected CDC latency                                 | PASS   |
| Read-domain pointer changes propagate to write domain after syncdly | expected CDC latency                                 | PASS   |
| Gray-coded pointer transitions remain stable across synchronization | no illegal multi-bit sampled jump used in flag logic | PASS   |
| No metastability artifacts visible in simulation                    | stable transitions only                              | PASS   |

Screenshot  
evidence/waveforms/async_fifo_cdc_sync1.png
evidence/waveforms/async_fifo_cdc_sync2.png
evidence/waveforms/async_fifo_cdc_sync3.png
evidence/waveforms/async_fifo_cdc_sync4.png

---

### Concurrent Read / Write Behavior

| Check                                   | Expected                         | Result |
|-----------------------------------------|----------------------------------|--------|
| Read and write activity overlap in time | both domains active concurrently | PASS   |
| FIFO ordering preserved under overlap   | sequence remains correct         | PASS   |
| No unexpected empty/full glitches       | stable legal flag behavior       | PASS   |
| FIFO drains cleanly after traffic stops | final `empty = 1`                | PASS   |

Screenshot  
evidence/waveforms/async_fifo_concurrent_rw.png
evidence/waveforms/async_fifo_concurrent_rw_drain.png
---

### Wraparound Behavior

| Check                                        | Expected                      | Result |
|----------------------------------------------|-------------------------------|--------|
| Write pointer wraps correctly                | binary/address rollover legal | PASS   |
| Read pointer wraps correctly                 | binary/address rollover legal | PASS   |
| Data ordering preserved across wrap          | no corruption around boundary | PASS   |
| Full/empty still behave correctly after wrap | flags remain consistent       | PASS   |

Screenshot  
evidence/waveforms/async_fifo_wraparound_wr_rollover.png
evidence/waveforms/async_fifo_wraparound_rd_rollover.png
evidence/waveforms/async_fifo_wraparound.png

---

### Mid-Stream Reset Recovery

| Check                                                        | Expected                               | Result |
|--------------------------------------------------------------|----------------------------------------|--------|
| Reset during active traffic returns FIFO to safe empty state | pointers/flags reset correctly         | PASS   |
| No stale data leaks after reset recovery                     | old buffered data not read after reset | PASS   |
| Post-reset traffic operates correctly                        | FIFO resumes legal operation           | PASS   |

Screenshot  
evidence/waveforms/async_fifo_midstream_reset.png

---

# 2. Directed Testcases

Testcases validate functional behavior beyond waveform inspection.

---

## Test Execution Command

Example smoke run:

```bash
python3 -m scripts.run --tool xsim --suite smoke --test async_fifo --waves
```

Artifacts generated:

```text
reports/run_<timestamp>/
```

---

## Directed Testcases

### TC01 Reset Default State

Purpose  
Verify reset initializes FIFO into a valid empty state.

Stimulus  
Assert both asynchronous resets, then release them and observe synchronized reset release per domain.

| Check                         | Expected     | Result |
|-------------------------------|--------------|--------|
| `empty` asserted after reset  | `empty = 1`  | PASS   |
| `full` deasserted after reset | `full = 0`   | PASS   |
| write pointer reset           | `wr_ptr = 0` | PASS   |
| read pointer reset            | `rd_ptr = 0` | PASS   |

Overall Result  
PASS
evidence/waveforms/testlog.png
evidence/waveforms/async_fifo_reset_sync_release.png
reports/logs/run_20260403_080533/xsim.log
---

### TC02 Reset Synchronizer Deassertion

Purpose  
Verify asynchronous assertion and synchronous deassertion of reset in both domains.

Stimulus  
Toggle `wr_arst_n` and `rd_arst_n`, observe `wr_srst_n` and `rd_srst_n`.

| Check                                          | Expected               | Result |
|------------------------------------------------|------------------------|--------|
| write reset asserts immediately                | async behavior visible | PASS   |
| write reset deasserts only on write clock edge | synchronous release    | PASS   |
| read reset asserts immediately                 | async behavior visible | PASS   |
| read reset deasserts only on read clock edge   | synchronous release    | PASS   |

Overall Result  
PASS
evidence/waveforms/testlog.png
evidence/waveforms/tc02.png
reports/logs/run_20260403_080533/xsim.log
---

### TC03 Single Write Single Read

Purpose  
Verify one data word can be written and read back correctly.

Stimulus  
Write `0xA5`, wait for CDC visibility, then perform one read.

| Check                               | Expected                     | Result |
|-------------------------------------|------------------------------|--------|
| write accepted                      | pointer increments           | PASS   |
| empty eventually deasserts          | `empty = 0` after sync delay | PASS   |
| read data correct                   | `rdata = 0xA5`               | PASS   |
| FIFO empty after read               | `empty = 1` eventually       | PASS   |

Overall Result  
PASS
evidence/waveforms/testlog.png
evidence/waveforms/tc03.png
reports/logs/run_20260403_080533/xsim.log
---

### TC04 Multiple Write Multiple Read

Purpose  
Verify FIFO ordering under sequential traffic.

Stimulus  

Write sequence:

11 22 33 44

Then read four times.

| Check               | Expected | Result |
|---------------------|----------|--------|
| first read correct  | `11`     | PASS   |
| second read correct | `22`     | PASS   |
| third read correct  | `33`     | PASS   |
| fourth read correct | `44`     | PASS   |

Overall Result  
PASS
evidence/waveforms/testlog.png
evidence/waveforms/tc04.png
reports/logs/run_20260403_080533/xsim.log
---

### TC05 Fill Until Full

Purpose  
Verify correct full detection when FIFO reaches capacity.

Stimulus  
Write until FIFO reaches capacity.

| Check                      | Expected                 | Result |
|----------------------------|--------------------------|--------|
| full eventually asserted   | `full = 1`               | PASS   |
| additional writes blocked  | write pointer stable     | PASS   |
| last legal write preserved | no data loss before full | PASS   |

Overall Result  
PASS
evidence/waveforms/testlog.png
evidence/waveforms/tc05.png
reports/logs/run_20260403_080533/xsim.log
---

### TC06 Drain Until Empty

Purpose  
Verify correct empty detection when FIFO is fully or partially drained.

Stimulus  
Write several values, then read until empty.

| Check                             | Expected            | Result |
|-----------------------------------|---------------------|--------|
| empty asserted after final read   | `empty = 1`         | PASS   |
| additional reads blocked          | read pointer stable | PASS   |
| all queued data returned in order | no corruption       | PASS   |

Overall Result  
PASS
evidence/waveforms/testlog.png
evidence/waveforms/tc06.png
reports/logs/run_20260403_080533/xsim.log
---

### TC07 Concurrent Read Write

Purpose  
Verify correct operation when read and write activity overlap across independent clocks.

Stimulus  
Preload a few entries, then run overlapping read and write traffic concurrently.

| Check                                  | Expected                    | Result |
|----------------------------------------|-----------------------------|--------|
| FIFO ordering preserved                | data sequence correct       | PASS   |
| no dropped or duplicated data          | stream integrity maintained | PASS   |
| no illegal flag glitches               | stable full/empty behavior  | PASS   |
| FIFO empty at end of balanced transfer | final `empty = 1`           | PASS   |

Overall Result  
PASS
evidence/waveforms/testlog.png
evidence/waveforms/tc07.png
reports/logs/run_20260403_080533/xsim.log
---

### TC08 Underflow Attempt

Purpose  
Verify safe behavior when reading an empty FIFO.

Stimulus  
Attempt read immediately after reset or after full drain.

| Check                                | Expected        | Result |
|--------------------------------------|-----------------|--------|
| empty remains asserted               | `empty = 1`     | PASS   |
| read pointer does not increment      | `rd_ptr` stable | PASS   |
| no invalid data transaction accepted | read ignored    | PASS   |

Overall Result  
PASS
evidence/waveforms/testlog.png
evidence/waveforms/tc08.png
reports/logs/run_20260403_080533/xsim.log
---

### TC09 Overflow Attempt

Purpose  
Verify safe behavior when writing to a full FIFO.

Stimulus  
Fill FIFO completely, then attempt additional writes.

| Check                                      | Expected                | Result |
|--------------------------------------------|-------------------------|--------|
| full remains asserted                      | `full = 1`              | PASS   |
| write pointer does not increment illegally | `wr_ptr` stable         | PASS   |
| stored data remains valid                  | no overwrite corruption | PASS   |

Overall Result  
PASS
evidence/waveforms/testlog.png
evidence/waveforms/tc09.png
reports/logs/run_20260403_080533/xsim.log
---

### TC10 Pointer Wraparound

Purpose  
Verify correct FIFO behavior when read and write pointers wrap around memory depth.

Stimulus  
Perform enough writes and reads to force pointer rollover at least once, preferably multiple times.

| Check                                      | Expected               | Result |
|--------------------------------------------|------------------------|--------|
| write pointer wraps correctly              | address rollover legal | PASS   |
| read pointer wraps correctly               | address rollover legal | PASS   |
| data order maintained across wrap boundary | no misalignment        | PASS   |
| full/empty behavior still correct          | flags consistent       | PASS   |

Overall Result  
PASS
evidence/waveforms/testlog.png
evidence/waveforms/tc10.png
reports/logs/run_20260403_080533/xsim.log
---

### TC11 Empty Flag Deassertion Latency

Purpose  
Verify that empty flag deassertion in read domain occurs only after write pointer synchronization.

Stimulus  
Write one word into an empty FIFO and watch `empty`.

| Check                                                | Expected                    | Result |
|------------------------------------------------------|-----------------------------|--------|
| empty does not drop immediately in read domain       | sync latency visible        | PASS   |
| empty deasserts after expected synchronization delay | legal CDC behavior          | PASS   |
| no early false-not-empty indication                  | flag correctness maintained | PASS   |

Overall Result  
PASS
evidence/waveforms/testlog.png
evidence/waveforms/tc11.png
reports/logs/run_20260403_080533/xsim.log
---

### TC12 Full Flag Deassertion Latency

Purpose  
Verify that full flag deassertion in write domain occurs only after read pointer synchronization.

Stimulus  
Fill FIFO to full, perform one read, and watch `full`.

| Check                                               | Expected                    | Result |
|-----------------------------------------------------|-----------------------------|--------|
| full does not drop immediately in write domain      | sync latency visible        | PASS   |
| full deasserts after expected synchronization delay | legal CDC behavior          | PASS   |
| no early false-not-full indication                  | flag correctness maintained | PASS   |

Overall Result  
PASS
evidence/waveforms/testlog.png
evidence/waveforms/tc12.png
reports/logs/run_20260403_080533/xsim.log
---

### TC13 Fast Write Slow Read

Purpose  
Stress FIFO when producer is faster than consumer.

Stimulus  
Run with write clock significantly faster than read clock.

| Check                                    | Expected                       | Result |
|------------------------------------------|--------------------------------|--------|
| FIFO accumulates entries legally         | occupancy increases correctly  | PASS   |
| full can assert under sustained pressure | expected backpressure behavior | PASS   |
| read data remains ordered and correct    | no corruption                  | PASS   |

Overall Result  
PASS
evidence/waveforms/testlog.png
evidence/waveforms/tc13.png
evidence/waveforms/tc13_1.png
reports/logs/run_20260403_080533/xsim.log
---

### TC14 Fast Read Slow Write

Purpose  
Stress FIFO when consumer is faster than producer.

Stimulus  
Run with read clock significantly faster than write clock.

| Check                                     | Expected                     | Result |
|-------------------------------------------|------------------------------|--------|
| FIFO can drain quickly without corruption | legal empty behavior         | PASS   |
| empty may assert frequently but legally   | expected starvation behavior | PASS   |
| no invalid reads accepted while empty     | safe under sparse writes     | PASS   |

Overall Result  
PASS
evidence/waveforms/testlog.png
evidence/waveforms/tc14.png
reports/logs/run_20260403_080533/xsim.log
---

### TC15 Mid-Stream Global Reset Recovery

Purpose  
Verify safe reset recovery when reset is asserted during active traffic.

Stimulus  
Start write/read traffic, assert both resets mid-stream, then release and restart traffic.

| Check                                        | Expected                | Result |
|----------------------------------------------|-------------------------|--------|
| FIFO returns to reset state                  | pointers/flags reset    | PASS   |
| stale data does not leak after reset         | post-reset stream clean | PASS   |
| FIFO resumes correct operation after release | subsequent data valid   | PASS   |

Overall Result  
PASS
evidence/waveforms/testlog.png
evidence/waveforms/TC15.png
reports/logs/run_20260403_080533/xsim.log
---

### TC16 Idle Stability

Purpose  
Verify FIFO state remains stable when no read or write activity occurs.

Stimulus  
Hold `wr_en = 0` and `rd_en = 0` for extended time in non-empty and empty conditions.

| Check                                       | Expected                          | Result |
|---------------------------------------------|-----------------------------------|--------|
| pointers remain stable during idle          | no unintended increments          | PASS   |
| flags remain stable during idle             | no glitches                       | PASS   |
| stored data preserved through idle interval | later read returns expected value | PASS   |

Overall Result  
PASS
evidence/waveforms/testlog.png
evidence/waveforms/tc16.png
reports/logs/run_20260403_080533/xsim.log
---

### TC17 Data Pattern Sweep

Purpose  
Verify correct handling of useful edge-case data patterns.

Stimulus  
Write/read patterns such as:

00 FF 55 AA 01 80 7F FE

| Check                                       | Expected                | Result |
|---------------------------------------------|-------------------------|--------|
| all patterns read back correctly            | exact data match        | PASS   |
| no pattern-specific corruption              | memory/data path robust | PASS   |
| flags remain correct during pattern traffic | legal control behavior  | PASS   |

Overall Result  
PASS
evidence/waveforms/testlog.png
evidence/waveforms/tc17.png
reports/logs/run_20260403_080533/xsim.log
---

### TC18 Long Burst Stress

Purpose  
Verify robustness over a longer burst of transactions.

Stimulus  
Run a long directed burst or bounded random sequence with many writes and reads.

| Check                                   | Expected                | Result |
|-----------------------------------------|-------------------------|--------|
| all accepted writes eventually readable | no data loss            | PASS   |
| no duplicates or reordering             | sequence preserved      | PASS   |
| flags remain legal over extended run    | stable control behavior | PASS   |

Overall Result  
PASS
evidence/waveforms/testlog.png
evidence/waveforms/tc18.png
reports/logs/run_20260403_080533/xsim.log

---

### TC19 Write-Domain-Only Reset (Advanced)

Purpose  
Verify intended behavior when only write-side reset is asserted.

Stimulus  
During operation, assert `wr_arst_n` only while read domain continues.

| Check                                               | Expected                        | Result |
|-----------------------------------------------------|---------------------------------|--------|
| write-side state resets cleanly                     | write-side pointers/flags legal | PASS   |
| read-side behavior matches documented design intent | no undefined observation        | PASS   |
| post-release operation is recoverable               | FIFO returns to known behavior  | PASS   |

Overall Result  
PASS
evidence/waveforms/testlog2.png
evidence/waveforms/tc19.png
reports/logs/run_20260404_164450/xsim.log

Note  
Keep this testcase only if independent per-domain reset behavior is part of the design contract.

---

### TC20 Read-Domain-Only Reset (Advanced)

Purpose  
Verify intended behavior when only read-side reset is asserted.

Stimulus  
During operation, assert `rd_arst_n` only while write domain continues.

| Check                                                | Expected                       | Result |
|------------------------------------------------------|--------------------------------|--------|
| read-side state resets cleanly                       | read-side pointers/flags legal | PASS   |
| write-side behavior matches documented design intent | no undefined observation       | PASS   |
| post-release operation is recoverable                | FIFO returns to known behavior | PASS   |

Overall Result  
PASS
evidence/waveforms/testlog2.png
evidence/waveforms/tc20.png
reports/logs/run_20260404_164450/xsim.log

Note  
Keep this testcase only if independent per-domain reset behavior is part of the design contract.

---

# 3. Verification Status Summary

| Test ID | Name                                | Stat |
|---------|-------------------------------------|----- |
| TC01    | Reset Default State                 | PASS |
| TC02    | Reset Synchronizer Deassertion      | PASS |
| TC03    | Single Write Single Read            | PASS |
| TC04    | Multiple Write Multiple Read        | PASS |
| TC05    | Fill Until Full                     | PASS |
| TC06    | Drain Until Empty                   | PASS |
| TC07    | Concurrent Read Write               | PASS |
| TC08    | Underflow Attempt                   | PASS |
| TC09    | Overflow Attempt                    | PASS |
| TC10    | Pointer Wraparound                  | PASS |
| TC11    | Empty Flag Deassertion Latency      | PASS |
| TC12    | Full Flag Deassertion Latency       | PASS |
| TC13    | Fast Write Slow Read                | PASS |
| TC14    | Fast Read Slow Write                | PASS |
| TC15    | Mid-Stream Global Reset Recovery    | PASS |
| TC16    | Idle Stability                      | PASS |
| TC17    | Data Pattern Sweep                  | PASS |
| TC18    | Long Burst Stress                   | PASS |
| TC19    | Write-Domain-Only Reset (Advanced)  | PASS |
| TC20    | Read-Domain-Only Reset (Advanced)   | PASS |
