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

| Check | Expected | Result |
|------|---------|--------|
| Write-domain async reset asserts immediately | `wr_arst_n` low forces write-side reset state | TODO |
| Read-domain async reset asserts immediately | `rd_arst_n` low forces read-side reset state | TODO |
| Write synchronized reset deasserts on write clock | `wr_srst_n` releases only on `wr_clk` edge | TODO |
| Read synchronized reset deasserts on read clock | `rd_srst_n` releases only on `rd_clk` edge | TODO |
| FIFO enters empty state after reset | `empty = 1` | TODO |
| FIFO not full after reset | `full = 0` | TODO |
| Write pointer reset | `wr_ptr_bin = 0` | TODO |
| Read pointer reset | `rd_ptr_bin = 0` | TODO |

Screenshot  
evidence/waveforms/async_fifo_reset_sync_release.png

---

### First Write Operation

| Check | Expected | Result |
|------|---------|--------|
| Write occurs on write clock edge | `wr_clk` edge triggers pointer increment | TODO |
| Write pointer increments | `wr_ptr_bin` increases by 1 | TODO |
| Data accepted when not full | write accepted | TODO |
| Empty flag eventually deasserts in read domain | `empty` transitions to 0 after CDC latency | TODO |

Screenshot  
evidence/waveforms/async_fifo_first_write1.png  
evidence/waveforms/async_fifo_first_write2.png

---

### First Read Operation

| Check | Expected | Result |
|------|---------|--------|
| Read occurs on read clock edge | `rd_clk` edge triggers pointer increment | TODO |
| Read pointer increments | `rd_ptr_bin` increases by 1 | TODO |
| Read data equals first written value | data integrity preserved | TODO |
| FIFO returns to empty after drain | `empty` becomes 1 eventually | TODO |

Screenshot  
evidence/waveforms/async_fifo_first_read1.png  
evidence/waveforms/async_fifo_first_read2.png

---

### Full Condition

| Check | Expected | Result |
|------|---------|--------|
| FIFO eventually asserts full | `full = 1` | TODO |
| Writes blocked when full | no illegal pointer advance | TODO |
| No invalid writes accepted | memory contents remain stable | TODO |
| Full deasserts only after read-side progress is synchronized back | expected CDC latency observed | TODO |

Screenshot  
evidence/waveforms/async_fifo_full_condition.png

---

### Empty Condition

| Check | Expected | Result |
|------|---------|--------|
| FIFO asserts empty after final read | `empty = 1` | TODO |
| Additional reads ignored | pointer remains stable | TODO |
| Empty deasserts only after write-side progress is synchronized into read domain | expected CDC latency observed | TODO |

Screenshot  
evidence/waveforms/async_fifo_empty_condition.png

---

### CDC Pointer / Flag Behavior

| Check | Expected | Result |
|------|---------|--------|
| Write-domain pointer changes propagate to read domain after sync delay | expected CDC latency | TODO |
| Read-domain pointer changes propagate to write domain after sync delay | expected CDC latency | TODO |
| Gray-coded pointer transitions remain stable across synchronization | no illegal multi-bit sampled jump used in flag logic | TODO |
| No metastability artifacts visible in simulation | stable transitions only | TODO |

Screenshot  
evidence/waveforms/async_fifo_cdc_sync.png

---

### Concurrent Read / Write Behavior

| Check | Expected | Result |
|------|---------|--------|
| Read and write activity overlap in time | both domains active concurrently | TODO |
| FIFO ordering preserved under overlap | sequence remains correct | TODO |
| No unexpected empty/full glitches | stable legal flag behavior | TODO |
| FIFO drains cleanly after traffic stops | final `empty = 1` | TODO |

Screenshot  
evidence/waveforms/async_fifo_concurrent_rw.png

---

### Wraparound Behavior

| Check | Expected | Result |
|------|---------|--------|
| Write pointer wraps correctly | binary/address rollover legal | TODO |
| Read pointer wraps correctly | binary/address rollover legal | TODO |
| Data ordering preserved across wrap | no corruption around boundary | TODO |
| Full/empty still behave correctly after wrap | flags remain consistent | TODO |

Screenshot  
evidence/waveforms/async_fifo_wraparound.png

---

### Mid-Stream Reset Recovery

| Check | Expected | Result |
|------|---------|--------|
| Reset during active traffic returns FIFO to safe empty state | pointers/flags reset correctly | TODO |
| No stale data leaks after reset recovery | old buffered data not read after reset | TODO |
| Post-reset traffic operates correctly | FIFO resumes legal operation | TODO |

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

| Check | Expected | Result |
|------|---------|--------|
| `empty` asserted after reset | `empty = 1` | TODO |
| `full` deasserted after reset | `full = 0` | TODO |
| write pointer reset | `wr_ptr = 0` | TODO |
| read pointer reset | `rd_ptr = 0` | TODO |

Overall Result  
PASS / FAIL / TODO

---

### TC02 Reset Synchronizer Deassertion

Purpose  
Verify asynchronous assertion and synchronous deassertion of reset in both domains.

Stimulus  
Toggle `wr_arst_n` and `rd_arst_n`, observe `wr_srst_n` and `rd_srst_n`.

| Check | Expected | Result |
|------|---------|--------|
| write reset asserts immediately | async behavior visible | TODO |
| write reset deasserts only on write clock edge | synchronous release | TODO |
| read reset asserts immediately | async behavior visible | TODO |
| read reset deasserts only on read clock edge | synchronous release | TODO |

Overall Result  
PASS / FAIL / TODO

---

### TC03 Single Write Single Read

Purpose  
Verify one data word can be written and read back correctly.

Stimulus  
Write `0xA5`, wait for CDC visibility, then perform one read.

| Check | Expected | Result |
|------|---------|--------|
| write accepted | pointer increments | TODO |
| empty eventually deasserts | `empty = 0` after sync delay | TODO |
| read data correct | `rdata = 0xA5` | TODO |
| FIFO empty after read | `empty = 1` eventually | TODO |

Overall Result  
PASS / FAIL / TODO

---

### TC04 Multiple Write Multiple Read

Purpose  
Verify FIFO ordering under sequential traffic.

Stimulus  

Write sequence:

11 22 33 44

Then read four times.

| Check | Expected | Result |
|------|---------|--------|
| first read correct | `11` | TODO |
| second read correct | `22` | TODO |
| third read correct | `33` | TODO |
| fourth read correct | `44` | TODO |

Overall Result  
PASS / FAIL / TODO

---

### TC05 Fill Until Full

Purpose  
Verify correct full detection when FIFO reaches capacity.

Stimulus  
Write until FIFO reaches capacity.

| Check | Expected | Result |
|------|---------|--------|
| full eventually asserted | `full = 1` | TODO |
| additional writes blocked | write pointer stable | TODO |
| last legal write preserved | no data loss before full | TODO |

Overall Result  
PASS / FAIL / TODO

---

### TC06 Drain Until Empty

Purpose  
Verify correct empty detection when FIFO is fully or partially drained.

Stimulus  
Write several values, then read until empty.

| Check | Expected | Result |
|------|---------|--------|
| empty asserted after final read | `empty = 1` | TODO |
| additional reads blocked | read pointer stable | TODO |
| all queued data returned in order | no corruption | TODO |

Overall Result  
PASS / FAIL / TODO

---

### TC07 Concurrent Read Write

Purpose  
Verify correct operation when read and write activity overlap across independent clocks.

Stimulus  
Preload a few entries, then run overlapping read and write traffic concurrently.

| Check | Expected | Result |
|------|---------|--------|
| FIFO ordering preserved | data sequence correct | TODO |
| no dropped or duplicated data | stream integrity maintained | TODO |
| no illegal flag glitches | stable full/empty behavior | TODO |
| FIFO empty at end of balanced transfer | final `empty = 1` | TODO |

Overall Result  
PASS / FAIL / TODO

---

### TC08 Underflow Attempt

Purpose  
Verify safe behavior when reading an empty FIFO.

Stimulus  
Attempt read immediately after reset or after full drain.

| Check | Expected | Result |
|------|---------|--------|
| empty remains asserted | `empty = 1` | TODO |
| read pointer does not increment | `rd_ptr` stable | TODO |
| no invalid data transaction accepted | read ignored | TODO |

Overall Result  
PASS / FAIL / TODO

---

### TC09 Overflow Attempt

Purpose  
Verify safe behavior when writing to a full FIFO.

Stimulus  
Fill FIFO completely, then attempt additional writes.

| Check | Expected | Result |
|------|---------|--------|
| full remains asserted | `full = 1` | TODO |
| write pointer does not increment illegally | `wr_ptr` stable | TODO |
| stored data remains valid | no overwrite corruption | TODO |

Overall Result  
PASS / FAIL / TODO

---

### TC10 Pointer Wraparound

Purpose  
Verify correct FIFO behavior when read and write pointers wrap around memory depth.

Stimulus  
Perform enough writes and reads to force pointer rollover at least once, preferably multiple times.

| Check | Expected | Result |
|------|---------|--------|
| write pointer wraps correctly | address rollover legal | TODO |
| read pointer wraps correctly | address rollover legal | TODO |
| data order maintained across wrap boundary | no misalignment | TODO |
| full/empty behavior still correct | flags consistent | TODO |

Overall Result  
PASS / FAIL / TODO

---

### TC11 Empty Flag Deassertion Latency

Purpose  
Verify that empty flag deassertion in read domain occurs only after write pointer synchronization.

Stimulus  
Write one word into an empty FIFO and watch `empty`.

| Check | Expected | Result |
|------|---------|--------|
| empty does not drop immediately in read domain | sync latency visible | TODO |
| empty deasserts after expected synchronization delay | legal CDC behavior | TODO |
| no early false-not-empty indication | flag correctness maintained | TODO |

Overall Result  
PASS / FAIL / TODO

---

### TC12 Full Flag Deassertion Latency

Purpose  
Verify that full flag deassertion in write domain occurs only after read pointer synchronization.

Stimulus  
Fill FIFO to full, perform one read, and watch `full`.

| Check | Expected | Result |
|------|---------|--------|
| full does not drop immediately in write domain | sync latency visible | TODO |
| full deasserts after expected synchronization delay | legal CDC behavior | TODO |
| no early false-not-full indication | flag correctness maintained | TODO |

Overall Result  
PASS / FAIL / TODO

---

### TC13 Fast Write Slow Read

Purpose  
Stress FIFO when producer is faster than consumer.

Stimulus  
Run with write clock significantly faster than read clock.

| Check | Expected | Result |
|------|---------|--------|
| FIFO accumulates entries legally | occupancy increases correctly | TODO |
| full can assert under sustained pressure | expected backpressure behavior | TODO |
| read data remains ordered and correct | no corruption | TODO |

Overall Result  
PASS / FAIL / TODO

---

### TC14 Fast Read Slow Write

Purpose  
Stress FIFO when consumer is faster than producer.

Stimulus  
Run with read clock significantly faster than write clock.

| Check | Expected | Result |
|------|---------|--------|
| FIFO can drain quickly without corruption | legal empty behavior | TODO |
| empty may assert frequently but legally | expected starvation behavior | TODO |
| no invalid reads accepted while empty | safe under sparse writes | TODO |

Overall Result  
PASS / FAIL / TODO

---

### TC15 Mid-Stream Global Reset Recovery

Purpose  
Verify safe reset recovery when reset is asserted during active traffic.

Stimulus  
Start write/read traffic, assert both resets mid-stream, then release and restart traffic.

| Check | Expected | Result |
|------|---------|--------|
| FIFO returns to reset state | pointers/flags reset | TODO |
| stale data does not leak after reset | post-reset stream clean | TODO |
| FIFO resumes correct operation after release | subsequent data valid | TODO |

Overall Result  
PASS / FAIL / TODO

---

### TC16 Idle Stability

Purpose  
Verify FIFO state remains stable when no read or write activity occurs.

Stimulus  
Hold `wr_en = 0` and `rd_en = 0` for extended time in non-empty and empty conditions.

| Check | Expected | Result |
|------|---------|--------|
| pointers remain stable during idle | no unintended increments | TODO |
| flags remain stable during idle | no glitches | TODO |
| stored data preserved through idle interval | later read returns expected value | TODO |

Overall Result  
PASS / FAIL / TODO

---

### TC17 Data Pattern Sweep

Purpose  
Verify correct handling of useful edge-case data patterns.

Stimulus  
Write/read patterns such as:

00 FF 55 AA 01 80 7F FE

| Check | Expected | Result |
|------|---------|--------|
| all patterns read back correctly | exact data match | TODO |
| no pattern-specific corruption | memory/data path robust | TODO |
| flags remain correct during pattern traffic | legal control behavior | TODO |

Overall Result  
PASS / FAIL / TODO

---

### TC18 Long Burst Stress

Purpose  
Verify robustness over a longer burst of transactions.

Stimulus  
Run a long directed burst or bounded random sequence with many writes and reads.

| Check | Expected | Result |
|------|---------|--------|
| all accepted writes eventually readable | no data loss | TODO |
| no duplicates or reordering | sequence preserved | TODO |
| flags remain legal over extended run | stable control behavior | TODO |

Overall Result  
PASS / FAIL / TODO

---

### TC19 Write-Domain-Only Reset (Advanced)

Purpose  
Verify intended behavior when only write-side reset is asserted.

Stimulus  
During operation, assert `wr_arst_n` only while read domain continues.

| Check | Expected | Result |
|------|---------|--------|
| write-side state resets cleanly | write-side pointers/flags legal | TODO |
| read-side behavior matches documented design intent | no undefined observation | TODO |
| post-release operation is recoverable | FIFO returns to known behavior | TODO |

Overall Result  
PASS / FAIL / TODO

Note  
Keep this testcase only if independent per-domain reset behavior is part of the design contract.

---

### TC20 Read-Domain-Only Reset (Advanced)

Purpose  
Verify intended behavior when only read-side reset is asserted.

Stimulus  
During operation, assert `rd_arst_n` only while write domain continues.

| Check | Expected | Result |
|------|---------|--------|
| read-side state resets cleanly | read-side pointers/flags legal | TODO |
| write-side behavior matches documented design intent | no undefined observation | TODO |
| post-release operation is recoverable | FIFO returns to known behavior | TODO |

Overall Result  
PASS / FAIL / TODO

Note  
Keep this testcase only if independent per-domain reset behavior is part of the design contract.

---

# 3. Verification Status Summary

| Test ID | Name | Status |
|-------|------|-------|
| TC01 | Reset Default State | TODO |
| TC02 | Reset Synchronizer Deassertion | TODO |
| TC03 | Single Write Single Read | TODO |
| TC04 | Multiple Write Multiple Read | TODO |
| TC05 | Fill Until Full | TODO |
| TC06 | Drain Until Empty | TODO |
| TC07 | Concurrent Read Write | TODO |
| TC08 | Underflow Attempt | TODO |
| TC09 | Overflow Attempt | TODO |
| TC10 | Pointer Wraparound | TODO |
| TC11 | Empty Flag Deassertion Latency | TODO |
| TC12 | Full Flag Deassertion Latency | TODO |
| TC13 | Fast Write Slow Read | TODO |
| TC14 | Fast Read Slow Write | TODO |
| TC15 | Mid-Stream Global Reset Recovery | TODO |
| TC16 | Idle Stability | TODO |
| TC17 | Data Pattern Sweep | TODO |
| TC18 | Long Burst Stress | TODO |
| TC19 | Write-Domain-Only Reset (Advanced) | TODO |
| TC20 | Read-Domain-Only Reset (Advanced) | TODO |
