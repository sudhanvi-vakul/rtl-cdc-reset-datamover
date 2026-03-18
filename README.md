# RTL CDC and Reset-Safe Multi-Clock Data Mover

Reset-safe multi-clock data mover using synchronizers and a Gray-code asynchronous FIFO.

## Project Summary
This project implements a CDC-focused RTL block that safely transfers data between unrelated write and read clock domains.  
The design consists:
- a 2-flop synchronizer for single-bit CDC
- reset synchronizers for safe reset release per clock domain
- a Gray-pointer asynchronous FIFO for multi-bit data transfer across clock domains

The goal is to build a data path that is safe under unrelated clocks, reset skew, and clock-ratio stress.

## Project Goal
Building a multi-clock producer-consumer path with:
- reset synchronization
- safe CDC logic
- async FIFO based data transfer
- verification under different clock ratios and reset sequences

## What Is Implemented
- `sync_2ff.sv`  
  Two-flop synchronizer for single-bit CDC signals

- `reset_sync.sv`  
  Asynchronous assert, synchronous release reset synchronizer

- `async_fifo.sv`  
  Gray-pointer asynchronous FIFO with separate write/read clock domains

- `async_fifo_tb.sv`  
  Self-checking testbench with:
  - unrelated write/read clocks
  - reset sequencing
  - write/read ordering checks
  - fill/drain behavior
  - interleaved traffic

## Key Design Ideas
### Why async FIFO?
A 2-flop synchronizer is suitable for single-bit control signals, but not for multi-bit streaming data.  
For data transfer across unrelated clocks, an async FIFO is the standard safe solution.

### Why Gray code?
Binary counters can change multiple bits at once, which is unsafe to sample across domains.  
Gray-coded pointers change only one bit at a time, making pointer synchronization safer.

### Why reset synchronizers?
Each clock domain must come out of reset cleanly with respect to its own clock.  
This prevents unsafe reset release behavior in multi-clock logic.

## Repository Structure
```text
rtl-cdc-reset-mover/
├── ci/                       
├── docs/                     
├── evidence/
│   └── waveforms/            
├── reports/
│   └── logs/                 
├── rtl/
│   ├── async_fifo.sv        
│   ├── reset_sync.sv         
│   └── sync_2ff.sv           
├── scripts/                 
├── tb/
│   ├── assertions/         
│   ├── async_fifo_tb.sv
|   ├── async_fifo_integrated_tb.sv    
│   └── tests/            
├── tests/                
├── tools/            
├── README.md             
├── requirements.txt   
└── tests.yaml 