# Verification Notes

## Project
Async FIFO – CDC Reset Data Mover

## DUT
async_fifo

## Simulator
XSim (Vivado 2019.2)

## Primary Verification Goal
Verify correct FIFO behavior across independent clock domains including reset behavior, ordering guarantees, and full/empty flag correctness.

---

# 1. Waveform Debug

Waveform artifact:

reports/run_<timestamp>/work.sim.wdb

Screenshots stored in:

evidence/waveforms/

---

## Waveform Debug Checklist

### Reset Behavior

| Check                               | Expected       | Result |
|-------------------------------------|----------------|--------|
| FIFO enters empty state after reset | empty = 1      | PASS   |
| FIFO not full after reset           | full = 0       | PASS   |
| Write pointer reset                 | wr_ptr_bin = 0 | PASS   |
| Read pointer reset                  | rd_ptr_bin = 0 | PASS   |

Screenshot  
evidence/waveforms/async_fifo_reset_state.png
referred to report -> 
---

### First Write Operation

| Check                            | Expected                               | Result |
|----------------------------------|----------------------------------------|--------|
| Write occurs on write clock edge | wr_clk edge triggers pointer increment | PASS   |
| Write pointer increments         | wr_ptr_bin increases by 1              | PASS   |
| Data accepted when not full      | write accepted                         | PASS   |
| Empty flag eventually deasserts  | empty transitions to 0 eventually      | PASS   |

Screenshot  
evidence/waveforms/async_fifo_first_write1.png
evidence/waveforms/async_fifo_first_write2.png
---

### First Read Operation

| Check                                | Expected                               | Result |
|--------------------------------------|----------------------------------------|--------|
| Read occurs on read clock edge       | rd_clk edge triggers pointer increment | PASS   |
| Read pointer increments              | rd_ptr_bin increases by 1              | PASS   |
| Read data equals first written value | data integrity preserved               | PASS   |
| FIFO returns to empty after drain    | empty becomes 1 eventually             | PASS   |

Screenshot  
evidence/waveforms/async_fifo_first_read1.png
evidence/waveforms/async_fifo_first_read2.png
---

### Full Condition

| Check                        | Expected              | Result |
|------------------------------|-----------------------|--------|
| FIFO eventually asserts full | full = 1              | TODO   |
| Writes blocked when full     | no pointer corruption | TODO   |
| No invalid writes accepted   | memory stable         | TODO   |

Screenshot  
evidence/waveforms/async_fifo_full_condition.png

---

### Empty Condition

| Check                               | Expected               | Result |
|-------------------------------------|------------------------|--------|
| FIFO asserts empty after final read | empty = 1              | TODO   |
| Additional reads ignored            | pointer remains stable | TODO   |

Screenshot  
evidence/waveforms/async_fifo_empty_condition.png

---

### CDC Behavior

| Check                                                          | Expected             | Result |
|----------------------------------------------------------------|----------------------|--------|
| Write domain changes propagate to read domain after sync delay | expected CDC latency | PASS   |
| Read domain changes propagate to write domain after sync delay | expected CDC latency | PASS   |
| No metastability artifacts visible in simulation               | stable transitions   | PASS   |

Screenshot  
evidence/waveforms/async_fifo_cdc_sync.png

---

# 2. Directed Testcases

Testcases validate functional behavior beyond waveform inspection.

---

## Test Execution Command

Example smoke run:

```
python3 -m scripts.run --tool xsim --suite smoke --test async_fifo --waves
```

Artifacts generated:

```
reports/run_<timestamp>/
```

---

## Directed Testcases

### TC01 Reset Default State

Purpose  
Verify reset initializes FIFO into a valid empty state.

| Check | Expected | Result |
|------|---------|--------|
| empty asserted after reset | empty = 1 | TODO |
| full deasserted after reset | full = 0 | TODO |
| write pointer reset | wr_ptr = 0 | TODO |
| read pointer reset | rd_ptr = 0 | TODO |

Overall Result  
PASS / FAIL / TODO

---

### TC02 Single Write Single Read

Purpose  
Verify one data word can be written and read back correctly.

Stimulus  
Write 0xA5 then perform one read.

| Check | Expected | Result |
|------|---------|--------|
| write accepted | pointer increments | TODO |
| read data correct | rdata = 0xA5 | TODO |
| FIFO empty after read | empty = 1 | TODO |

Overall Result  
PASS / FAIL / TODO

---

### TC03 Multiple Write Multiple Read

Purpose  
Verify FIFO ordering.

Stimulus  

Write sequence:

```
11 22 33 44
```

Then read four times.

| Check | Expected | Result |
|------|---------|--------|
| first read correct | 11 | TODO |
| second read correct | 22 | TODO |
| third read correct | 33 | TODO |
| fourth read correct | 44 | TODO |

Overall Result  
PASS / FAIL / TODO

---

### TC04 Fill Until Full

Purpose  
Verify correct full detection.

Stimulus  
Write until FIFO reaches capacity.

| Check | Expected | Result |
|------|---------|--------|
| full eventually asserted | full = 1 | TODO |
| additional writes blocked | pointer stable | TODO |

Overall Result  
PASS / FAIL / TODO

---

### TC05 Drain Until Empty

Purpose  
Verify empty flag detection after draining.

Stimulus  
Write several values then read until empty.

| Check | Expected | Result |
|------|---------|--------|
| empty asserted after final read | empty = 1 | TODO |
| no invalid reads allowed | pointer stable | TODO |

Overall Result  
PASS / FAIL / TODO

---

### TC06 Simultaneous Read Write

Purpose  
Verify correct operation when reads and writes overlap.

Stimulus  
Write and read in overlapping cycles.

| Check | Expected | Result |
|------|---------|--------|
| FIFO ordering preserved | data sequence correct | TODO |
| no flag glitches | stable full/empty behavior | TODO |

Overall Result  
PASS / FAIL / TODO

---

### TC07 Underflow Attempt

Purpose  
Verify safe behavior when reading an empty FIFO.

Stimulus  
Attempt read immediately after reset.

| Check | Expected | Result |
|------|---------|--------|
| empty remains asserted | empty = 1 | TODO |
| read pointer does not increment | rd_ptr stable | TODO |

Overall Result  
PASS / FAIL / TODO

---

### TC08 Overflow Attempt

Purpose  
Verify safe behavior when writing to a full FIFO.

Stimulus  
Fill FIFO completely then attempt additional writes.

| Check | Expected | Result |
|------|---------|--------|
| full remains asserted | full = 1 | TODO |
| write pointer does not increment illegally | wr_ptr stable | TODO |

Overall Result  
PASS / FAIL / TODO

---

# Verification Status Summary

| Test ID | Name | Status |
|-------|------|-------|
| TC01 | Reset Default State | TODO |
| TC02 | Single Write Single Read | TODO |
| TC03 | Multiple Write Multiple Read | TODO |
| TC04 | Fill Until Full | TODO |
| TC05 | Drain Until Empty | TODO |
| TC06 | Simultaneous Read Write | TODO |
| TC07 | Underflow Attempt | TODO |
| TC08 | Overflow Attempt | TODO |

---

# Notes

Waveform screenshots should be stored in:

```
evidence/waveforms/
```

Example files:

```
async_fifo_reset_state.png
async_fifo_first_write.png
async_fifo_first_read.png
async_fifo_full_condition.png
async_fifo_empty_condition.png
async_fifo_cdc_sync.png
```