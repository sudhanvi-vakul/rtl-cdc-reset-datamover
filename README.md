# RTL CDC and Reset-Safe Multi-Clock Data Mover

![SystemVerilog](https://img.shields.io/badge/Language-SystemVerilog-blue)
![CDC](https://img.shields.io/badge/Focus-Clock%20Domain%20Crossing-success)
![Verification](https://img.shields.io/badge/Verification-Directed%20%2B%20Self--Checking-orange)
![Status](https://img.shields.io/badge/Project-Completed-brightgreen)

A reset-safe multi-clock data mover built in **SystemVerilog** using:
- **2-flop synchronizers** for single-bit CDC
- **reset synchronizers** for safe per-domain reset release
- a **Gray-code asynchronous FIFO** for multi-bit transfer across unrelated clocks

This project demonstrates practical RTL design for **clock-domain crossing**, **reset safety**, and **structured verification** under mismatched clocks, reset skew, burst traffic, boundary conditions, and stress scenarios.

---

## Table of Contents

- [Overview](#overview)
- [Project Goals](#project-goals)
- [Architecture](#architecture)
- [Implemented Modules](#implemented-modules)
- [Key Design Ideas](#key-design-ideas)
- [Verification Strategy](#verification-strategy)
- [Test Results Summary](#test-results-summary)
- [Testcase Coverage](#testcase-coverage)
- [Waveform Inspection Goals](#waveform-inspection-goals)
- [Repository Structure](#repository-structure)
- [How to Run](#how-to-run)
- [Expected Outputs](#expected-outputs)
- [Key Learnings](#key-learnings)
- [Future Improvements](#future-improvements)
- [Summary](#summary)

---

## Overview

Crossing signals between unrelated clock domains is one of the most common and error-prone problems in digital design.
This project builds a safe producer-consumer path between independent write and read domains by combining standard CDC techniques into one reusable RTL block.

The design supports:
- safe transfer of **single-bit control signals**
- safe release of reset within each clock domain
- safe transfer of **multi-bit data** using an asynchronous FIFO
- verification across different clock ratios, reset events, and traffic patterns

This makes the project a strong foundational block for larger **SoC**, **subsystem**, and **multi-clock RTL** designs.

---

## Project Goals

- Build a reset-safe multi-clock data path
- Safely transfer data across unrelated write and read clocks
- Use standard CDC techniques for both control and data paths
- Verify correctness under clock-ratio stress and reset skew
- Check ordering, stability, empty/full behavior, and recovery from reset events
- Produce structured verification evidence using logs and waveforms

---

## Architecture

```text
                +-------------------+
 write domain   |   reset_sync      |
 wr_arst_n ---> | async assert      | ---> wr_srst_n
                | sync release      |
                +-------------------+

                +-------------------+
 read domain    |   reset_sync      |
 rd_arst_n ---> | async assert      | ---> rd_srst_n
                | sync release      |
                +-------------------+


         wr_clk domain                             rd_clk domain
   +-----------------------+                +-----------------------+
   |   write pointer logic |                |   read pointer logic  |
   |   binary + Gray ptr   |                |   binary + Gray ptr   |
   +-----------+-----------+                +-----------+-----------+
               |                                            |
               v                                            v
        +----------------------------------------------------------+
        |                    async_fifo.sv                         |
        |                                                          |
        |  - dual-domain FIFO storage                              |
        |  - Gray-coded pointers                                   |
        |  - synchronized remote pointers                          |
        |  - full / empty flag generation                          |
        +----------------------------------------------------------+
               ^                                            ^
               |                                            |
   +-----------+-----------+                +-----------+-----------+
   | sync_2ff / pointer    |                | sync_2ff / pointer    |
   | synchronization path  |                | synchronization path  |
   +-----------------------+                +-----------------------+
```

---

## Implemented Modules

### RTL

#### `rtl/sync_2ff.sv`
Two-flop synchronizer for single-bit CDC signals.

**Purpose**
- safely capture a single-bit signal in a destination clock domain
- reduce metastability propagation risk

---

#### `rtl/reset_sync.sv`
Reset synchronizer with:
- **asynchronous assertion**
- **synchronous deassertion**

**Purpose**
- allow reset to assert immediately
- ensure reset release happens cleanly on the local clock edge

---

#### `rtl/async_fifo.sv`
Gray-pointer asynchronous FIFO with:
- separate write and read clock domains
- binary and Gray-coded pointers
- synchronized remote pointers
- full and empty detection

**Purpose**
- safely transfer multi-bit data between unrelated clocks
- preserve ordering and correctness under clock mismatch

---

### Testbenches

#### `tb/async_fifo_tb.sv`
Basic self-checking FIFO testbench.

#### `tb/async_fifo_integrated_tb.sv`
Main integrated directed testbench covering reset, ordering, flags, latency, burst traffic, and clock-ratio scenarios.

#### `tb/async_fifo_integrated_adv_tb.sv`
Advanced verification and waveform-oriented debug testbench covering long stress runs and domain-specific reset scenarios.

---

## Key Design Ideas

### Why a 2-flop synchronizer?
A 2-flop synchronizer is appropriate for **single-bit control signals** crossing into a new clock domain. It reduces the chance that metastability propagates into downstream logic.

### Why an async FIFO?
A simple synchronizer is **not sufficient for multi-bit data streams**. For multi-bit transfers across unrelated clocks, an asynchronous FIFO is the standard safe architecture.

### Why Gray-coded pointers?
Binary counters can change multiple bits at once. When sampled across clock domains, that can cause unsafe intermediate observations.
Gray code changes only **one bit per increment**, making pointer synchronization safer.

### Why reset synchronization?
Direct reset release can violate timing relative to a clock edge. Using synchronized release ensures each domain exits reset cleanly and predictably.

### Why waveform inspection matters?
Self-checking tests prove functional correctness, but waveforms help confirm the **internal CDC behavior**:
- pointer propagation delay
- flag transitions
- Gray-code movement
- reset alignment to local clocks

---

## Verification Strategy

Verification uses **directed self-checking simulation** plus **waveform-based inspection**.

### Functional checks include
- reset default state
- reset synchronizer deassertion behavior
- single-transfer and multi-transfer data correctness
- fill and drain boundary behavior
- concurrent read/write operation
- underflow and overflow handling
- pointer wraparound correctness
- empty and full flag deassertion latency
- fast-write slow-read stress
- fast-read slow-write stress
- mid-stream reset recovery
- idle stability
- data-pattern robustness
- long-burst stress behavior
- write-domain-only and read-domain-only reset recovery

### Structural waveform checks include
- pointer increments in the correct domains
- synchronized visibility of pointers in the opposite domains
- expected CDC latency for flag and pointer behavior
- clean reset deassertion on local clock edges
- stable flag behavior around empty/full boundaries
- no unintended changes during idle windows

---

## Test Results Summary

- **Total testcases:** 20
- **Pass:** 20
- **Fail:** 0
- **Status:** Complete functional regression pass for the current directed verification suite

---

## Testcase Coverage

| Test ID | Name | Status |
|---------|------|--------|
| TC01 | Reset Default State | PASS |
| TC02 | Reset Synchronizer Deassertion | PASS |
| TC03 | Single Write Single Read | PASS |
| TC04 | Multiple Write Multiple Read | PASS |
| TC05 | Fill Until Full | PASS |
| TC06 | Drain Until Empty | PASS |
| TC07 | Concurrent Read Write | PASS |
| TC08 | Underflow Attempt | PASS |
| TC09 | Overflow Attempt | PASS |
| TC10 | Pointer Wraparound | PASS |
| TC11 | Empty Flag Deassertion Latency | PASS |
| TC12 | Full Flag Deassertion Latency | PASS |
| TC13 | Fast Write Slow Read | PASS |
| TC14 | Fast Read Slow Write | PASS |
| TC15 | Mid-Stream Global Reset Recovery | PASS |
| TC16 | Idle Stability | PASS |
| TC17 | Data Pattern Sweep | PASS |
| TC18 | Long Burst Stress | PASS |
| TC19 | Write-Domain-Only Reset (Advanced) | PASS |
| TC20 | Read-Domain-Only Reset (Advanced) | PASS |

---

## Waveform Inspection Goals

Waveform evidence is used to inspect:
- reset assertion and synchronized deassertion
- write pointer increment behavior
- read pointer increment behavior
- synchronized pointer propagation across domains
- expected CDC delay between source and synchronized destination
- empty flag deassertion behavior after write-side activity
- full flag deassertion behavior after read-side activity
- pointer wraparound behavior
- idle windows with no unintended activity

Suggested screenshot categories:
- reset default state
- reset synchronizer release timing
- first write and first read behavior
- fill until full
- drain until empty
- concurrent read/write activity
- pointer wraparound
- flag deassertion latency
- fast-write slow-read stress
- fast-read slow-write stress
- mid-stream reset recovery
- idle stability

---

## Repository Structure

```text
rtl-cdc-reset-datamover/
├── ci/
├── docs/
│   └── verification_notes.md
├── evidence/
│   └── waveforms/
├── reports/
│   └── run_*/
├── rtl/
│   ├── async_fifo.sv
│   ├── reset_sync.sv
│   └── sync_2ff.sv
├── scripts/
├── tb/
│   ├── assertions/
│   ├── async_fifo_tb.sv
│   ├── async_fifo_integrated_tb.sv
│   ├── async_fifo_integrated_adv_tb.sv
│   └── tests/
├── tests/
├── tools/
├── tests.yaml
├── README.md
└── requirements.txt
```

---

## How to Run

Example simulation command:

```bash
python3 -m scripts.run --tool xsim --suite smoke --test async_fifo --waves
```

### Typical workflow
1. Compile RTL and testbench
2. Run simulation
3. Generate logs and waveform database
4. Inspect `.wdb` in XSim GUI
5. Capture verification evidence in `docs/verification_notes.md`

---

## Expected Outputs

Typical generated artifacts include:
- compile logs
- simulation logs
- waveform database (`.wdb`)
- TCL replay/debug scripts
- run-specific report folders under `reports/run_*`

Example artifact types:
- `xsim.log`
- `xvlog.log`
- `work.sim.wdb`
- `run.tcl`

---

## What This Project Demonstrates

- safe **single-bit CDC**
- safe **multi-bit CDC** using an async FIFO
- **Gray-code pointer** methodology
- **reset-safe release** in multi-clock logic
- structured **RTL verification**
- practical **waveform-driven debug**
- reusable design patterns for larger SoC-style subsystems

---

## Key Learnings

- Single-bit and multi-bit CDC require different design approaches
- Reset behavior must be handled carefully in multi-clock designs
- Gray-coded pointers are central to async FIFO safety
- Verification should check both outputs and internal CDC behavior
- Clock-ratio stress testing reveals corner cases not visible in simple equal-clock tests
- Boundary cases such as underflow, overflow, and wraparound are critical for FIFO confidence

---

## Future Improvements

- add SystemVerilog assertions for pointer and flag correctness
- add functional coverage for traffic and boundary combinations
- add randomized stress sequences
- support wider data widths and deeper FIFO parameter sweeps
- add formal checks for selected FIFO safety properties
- compare behavior across multiple simulators or CI targets

---

## Summary

This project implements a **reset-safe multi-clock data mover** using synchronizers, reset synchronization, and a Gray-code asynchronous FIFO. The design and verification flow demonstrate practical CDC methodology for multi-clock systems and provide a strong foundational RTL project for larger subsystem and SoC integration work.
