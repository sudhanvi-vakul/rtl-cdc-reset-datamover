# Design Notes

## Why asynchronous FIFO
An asynchronous FIFO is used when producer and consumer operate in different clock domains and data must cross safely.

## Pointer strategy
The design uses extended pointers with an extra MSB to distinguish wrap-around and help derive full/empty conditions.

## Why synchronizers are needed
Directly sampling multi-bit pointers across unrelated clock domains is unsafe. Synchronized versions of Gray-coded pointers reduce CDC risk.

## Reset approach
Reset is applied per clock domain and synchronized locally to avoid reset release hazards.

## Current assumptions
- Single writer and single reader
- FIFO depth is power of 2
- No ECC/parity yet
- No almost_full/almost_empty yet

## Future extensions
- Add assertions
- Add randomized testcases
- Add overflow/underflow checking
- Add occupancy visibility for debug