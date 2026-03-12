# Debug Log

## 2026-03-11 - XSim elaboration failure

### Symptom
Smoke run failed during xelab.
Command:
python3 -m scripts.run --tool xsim --suite smoke --test async_fifo --waves

### Evidence
elab.log reported:
Module async_fifo_default doesn't have a timescale but at least one module in design has a timescale.

### Root cause
Timescale declaration was inconsistent across RTL/testbench files. XSim 2019.2 requires consistency when some modules declare timescale.

### Fix
Added/aligned:
`timescale 1ns/1ps

in:
- rtl/async_fifo.sv
- rtl/reset_sync.sv
- rtl/sync_2ff.sv
- tb/async_fifo_tb.sv

### Result
Smoke run passed.
Waveform generated:
reports/run_20260311_215224/work.sim.wdb

