# Asynchronous FIFO Design and Verification using Verilog

## Overview

This project implements a parameterized Asynchronous FIFO (First-In, First-Out) using Verilog HDL to transfer data between two independent clock domains.

The design uses binary and Gray-code pointers, two-stage synchronizers, and full/empty detection logic to support safe clock-domain crossing (CDC). A self-checking testbench was developed to verify data integrity and FIFO boundary conditions through simulation.

## Objectives

- Design an asynchronous FIFO with independent read and write clocks.
- Implement binary-to-Gray-code pointer conversion.
- Synchronize read and write pointers across clock domains.
- Implement FIFO full and empty detection logic.
- Verify reset behavior, data integrity, overflow, and underflow conditions.

## Features

- Parameterized FIFO data width and depth.
- Independent read and write clock domains.
- Binary read and write pointers.
- Gray-code pointer conversion for CDC.
- Two-stage pointer synchronizers.
- Full and empty flag generation.
- Overflow and underflow protection.
- Self-checking Verilog testbench.
- Automated data comparison and simulation failure reporting.

## Design Specifications

| Parameter | Value |
|---|---|
| Hardware Description Language | Verilog HDL |
| Simulation Tool | Xilinx Vivado 2017.4 |
| Data Width | 8 bits |
| Address Width | 4 bits |
| FIFO Depth | 16 entries |
| Write Clock Period | 10 ns |
| Read Clock Period | 14 ns |
| Clock Configuration | Independent clocks |

## Architecture

The FIFO consists of the following functional blocks:

### 1. FIFO Memory

Stores incoming data during valid write operations and provides stored data during valid read operations.

### 2. Write Pointer Logic

Maintains the current write position using a binary pointer. The pointer is converted to Gray code before being synchronized into the read clock domain.

### 3. Read Pointer Logic

Maintains the current read position using a binary pointer. Its Gray-code representation is synchronized into the write clock domain.

### 4. Pointer Synchronizers

Two-stage synchronizers transfer Gray-coded pointers between the independent clock domains, helping reduce the risk of metastability propagating into the destination logic.

### 5. Full Detection Logic

Determines when the FIFO has reached its capacity and prevents additional valid writes.

### 6. Empty Detection Logic

Determines when no unread data remains and prevents invalid read operations.

## Why Gray Code?

Binary counters may change multiple bits during a single increment. If an asynchronous destination samples the counter during a transition, it may observe an inconsistent value.

Gray code changes only one bit between consecutive values. Using Gray-coded pointers for synchronization helps reduce this risk during clock-domain crossing.

## Working Principle

### Write Operation

When `wr_en` is asserted and the FIFO is not full, the input data is written into the FIFO memory. The write pointer advances, and its Gray-code equivalent is synchronized into the read clock domain.

### Read Operation

When `rd_en` is asserted and the FIFO is not empty, the next stored data word is read. The read pointer advances, and its Gray-code equivalent is synchronized into the write clock domain.

### Full and Empty Detection

The full detection logic compares the next write Gray-code pointer with the synchronized read pointer using the asynchronous FIFO full-detection method.

The empty detection logic compares the next read Gray-code pointer with the synchronized write pointer.

These flags control valid read and write operations and help prevent FIFO overflow and underflow.

## Verification and Simulation

A self-checking Verilog testbench was developed using independent write and read clocks.

The testbench maintains expected data values and compares them with the FIFO output during read operations. The `$fatal` system task reports verification failures, while `$display` reports successful test cases.

### Test Cases and Results

| Test Case | Description | Result |
|---|---|---|
| Reset Verification | Checks the initial FIFO status | PASS |
| Full Detection | Verifies the full flag after 16 writes | PASS |
| Overflow Protection | Checks that an extra write is blocked | PASS |
| Data Integrity | Reads back and verifies all 16 stored words | PASS |
| Empty Detection | Verifies the empty flag after all data is read | PASS |
| Underflow Protection | Checks that a read from an empty FIFO is blocked | PASS |

**Simulation Summary: All implemented testbench checks passed.**

These results cover the functional scenarios listed above. Additional testing can be performed for pointer wraparound, simultaneous read/write operations, and randomized traffic.

## Project Structure

```text
Asynchronous-FIFO-Design/
├── rtl/
│   └── async_fifo.v
├── testbench/
│   └── tb_async_fifo.v
└── README.md
```

## Tools and Technologies

- Verilog HDL
- Xilinx Vivado 2017.4
- RTL Design
- Digital Logic Design
- Clock-Domain Crossing (CDC)
- Gray-Code Pointer Synchronization
- Functional Verification
- Self-Checking Testbench

## Future Improvements

- Add pointer wraparound verification.
- Test simultaneous read and write operations.
- Add randomized test scenarios for broader functional coverage.
- Improve memory inference for FPGA block RAM.
- Perform additional CDC analysis and synthesis checks.

## Conclusion

This project demonstrates the RTL implementation and functional simulation of an asynchronous FIFO using Verilog HDL. It provides practical experience with pointer management, Gray-code synchronization, full/empty detection, and self-checking verification.

The project builds a foundation for further work in digital design, FPGA development, and ASIC verification.

## Author

**Ashish Yadav**

M.Tech in Communication System Engineering  
National Institute of Technology, Jamshedpur

