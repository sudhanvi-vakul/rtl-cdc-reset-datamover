# Async FIFO Block Diagram

## Purpose
This project implements an asynchronous FIFO to safely transfer data from a write clock domain to a read clock domain.

## Top-level blocks
- async_fifo
- sync_2ff
- reset_sync
- async_fifo_tb

## High-level data flow
wdata + wr_en -> async_fifo write side -> storage array -> async_fifo read side -> rdata + rd_en

## Clock domains
- Write domain: wr_clk
- Read domain: rd_clk

## Reset domains
- wr_rst_n enters write-side reset synchronizer
- rd_rst_n enters read-side reset synchronizer

## CDC points
- Read pointer synchronized into write clock domain
- Write pointer synchronized into read clock domain

## Status generation
- full generated in write domain
- empty generated in read domain

                 +----------------------+
 wr_clk -------->|                      |
 wr_rst_n ------>|                      |
 wr_en --------->|                      |
 wdata --------->|      async_fifo      |----> rdata
 rd_en --------->|                      |
 rd_clk -------->|                      |
 rd_rst_n ------>|                      |
                 +----------------------+
                    ^              ^
                    |              |
             synchronized     synchronized
              rd pointer       wr pointer

              