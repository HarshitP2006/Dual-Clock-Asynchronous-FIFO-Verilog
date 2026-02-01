Dual-Clock Asynchronous FIFO (Verilog)

This project implements a Dual-Clock Asynchronous FIFO in Verilog, designed to safely transfer data between two independent clock domains using industry-standard Clock Domain Crossing (CDC) techniques.

📌 Project Overview

An asynchronous FIFO allows data transfer between two subsystems running on different clock frequencies. This design uses:

Dual-Port RAM for storage

Binary counters for memory addressing

Gray code pointers for safe clock-domain crossing

2-Flip-Flop synchronizers for metastability protection

FULL / EMPTY and ALMOST flags

This architecture is commonly used in SoCs, communication systems, and high-speed digital designs.


Major Blocks
Block	Description
Write Pointer Handler	Maintains write pointer in binary and Gray format
Read Pointer Handler	Maintains read pointer in binary and Gray format
Dual-Port RAM	Stores FIFO data using binary addresses
2-FF Synchronizers	Safely transfer Gray pointers across clock domains
Full Flag Logic	Detects FIFO full condition in write domain
Empty Flag Logic	Detects FIFO empty condition in read domain
🔄 FIFO Operation
Write Clock Domain (wr_clk)

wr_en writes din into memory

Binary write pointer increments

Binary pointer converted to Gray

Gray pointer sent to read domain via 2-FF synchronizer

FULL and ALMOST_FULL flags generated

Read Clock Domain (rd_clk)

rd_en reads data from memory into dout

Binary read pointer increments

Binary pointer converted to Gray

Gray pointer sent to write domain via 2-FF synchronizer

EMPTY and ALMOST_EMPTY flags generated

⚙️ CDC Safety
Signal Type	CDC Method
Pointers	Gray coding (1 bit changes at a time)
Cross-domain transfer	2-Flip-Flop synchronizers
Full/Empty detection	Gray pointer comparison

⚠️ Note: almost_full and almost_empty use Gray→Binary conversion for arithmetic comparison. This is safe for FPGA/student projects but not strictly CDC-clean for advanced ASIC flows. FULL and EMPTY flags remain CDC-safe.

🧪 Verification

The FIFO is verified using a self-checking testbench with:

Independent write and read clocks

Randomized write/read bursts

Scoreboard-based data integrity check

Waveform inspection

✅ Verification Result

✔ No data loss
✔ No duplication
✔ Correct order maintained

🛠 Tools Used
Tool	Purpose
Icarus Verilog	Simulation
GTKWave	Waveform viewing
VS Code / Any Editor	RTL coding
GitHub	Version control & project hosting
📂 Project Structure
async-fifo/
│
├── rtl/
│   └── async_fifo.v
│
├── tb/
│   └── async_fifo_tb.v
│
├── waves/
│   └── async_fifo.vcd
│
├── docs/
│   ├── fifo_block_diagram.png
│   └── waveform_screenshot.png
│
└── README.md

▶️ How to Run Simulation
iverilog -o fifo_sim rtl/async_fifo.v tb/async_fifo_tb.v
vvp fifo_sim
gtkwave async_fifo.vcd

🖼 Where to Upload Images
Image	Upload Folder	Purpose
Block Diagram	/docs/fifo_block_diagram.png	Architecture explanation
Waveform Screenshot	/docs/waveform_screenshot.png	Verification proof

Then reference them in README like this:

![FIFO Block Diagram](docs/fifo_block_diagram.png)
![Simulation Waveform](docs/waveform_screenshot.png)

🚀 Skills Demonstrated

Clock Domain Crossing (CDC)

Asynchronous FIFO architecture

Gray code pointer design

RTL design in Verilog

Digital verification methodology