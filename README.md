# Synchronous FIFO in Verilog

## 📌 Overview

This project implements a **synchronous FIFO (First-In-First-Out)** memory buffer using Verilog. The FIFO operates on a single clock domain and supports parameterizable depth and data width.
A detailed testbench is provided to verify various functional scenarios such as read, write, overflow, underflow, wraparound, and simultaneous read/write operations.

---

## ⚙ Features

* **Parameterized design** for `DEPTH` and `WIDTH`.
* **Full** and **empty** flag generation.
* Handles **wraparound** correctly.
* **Simultaneous read/write** support.
* **Reset** clears FIFO pointers and data.
* Protection against **overflow** and **underflow**.
* Comprehensive **testbench** with automated checks.

---

## 🗂 File Structure

```
├── fifo.v        # Main FIFO design file
├── fifotb.v               # Testbench file
└── README.md          # Documentation
```

---

## 🖥 Design Details

### Parameters

| Parameter | Description                 | Default |
| --------- | --------------------------- | ------- |
| `DEPTH`   | Number of FIFO entries      | 16      |
| `WIDTH`   | Bit-width of each data word | 8       |

### Ports

#### Inputs:

* `clk` : Clock signal.
* `rst` : Asynchronous reset (active high).
* `wr_en` : Write enable.
* `rd_en` : Read enable.
* `din[WIDTH-1:0]` : Data input.

#### Outputs:

* `dout[WIDTH-1:0]` : Data output.
* `full` : FIFO is full.
* `empty` : FIFO is empty.

---

## 🔍 Functional Description

* **Write Operation**: Data is stored at `wr_ptr` location if `wr_en` is high and FIFO is not full.
* **Read Operation**: Data from `rd_ptr` is output to `dout` if `rd_en` is high and FIFO is not empty.
* **Full Flag**: Asserted when write pointer catches up to read pointer after wraparound.
* **Empty Flag**: Asserted when both pointers are equal.
* **Reset**: Clears both pointers and output data.

---

## 🧪 Testbench Details

The provided testbench (`tb.v`) verifies the FIFO through the following tasks:

| Task                         | Description                                          |
| ---------------------------- | ---------------------------------------------------- |
| `tc_write`                   | Verifies write operation and empty flag deassertion. |
| `tc_read`                    | Verifies read operation and correct output data.     |
| `tc_full`                    | Checks full flag assertion after filling FIFO.       |
| `tc_empty`                   | Checks empty flag assertion after draining FIFO.     |
| `tc_wraparound`              | Tests correct wraparound behavior of pointers.       |
| `tc_simultaneous_read_write` | Verifies simultaneous read and write operation.      |
| `tc_overflow`                | Detects and reports overflow attempts.               |
| `tc_underflow`               | Detects and reports underflow attempts.              |
| `tc_reset`                   | Validates FIFO behavior after reset.                 |



---

## 📊 Expected Output

The simulation should display PASS/ERROR messages for each test case.
Flags (`full`/`empty`) and data values should match expected behavior across all scenarios.

Example (partial):

```
===== sync_fifo Tests Start =====
Write operation test
PASS: FIFO not empty after write.
Read operation test
PASS: Read data = 124 as expected.
Full Condition test
PASS: full flag asserted after 16 writes.
FIFO empty flag set correctly
...


