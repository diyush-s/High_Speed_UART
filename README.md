# High-Speed UART Transceiver (4 Mbps @ 64 MHz)

A high-speed, hardware-validated Universal Asynchronous Receiver and Transmitter (UART) core designed in Verilog HDL. This architecture achieves a deterministic serial line rate of **4 Mbps** operating under a high-frequency **64 MHz system clock** framework. It incorporates modular digital sub-blocks, strict 11-bit frame compliance, and an optimized multi-clock domain sampling strategy to eliminate setup/hold time hazards.

---

## 🎯 Design Specifications & Timing Math

The internal frequency division metrics are calculated precisely to match the specifications outlined in the reference implementation:

* **System Master Clock ($sys\_clk$):** $64\text{ MHz}$
* **Target Baud Rate:** $4\text{ Mbps}$
* **Clock Division Factor ($M$):**
    $$M = \frac{f_{sys\_clk}}{\text{Baud Rate}} = \frac{64\text{ MHz}}{4\text{ Mbps}} = 16$$
* **Bit Window Period ($T_{bit}$):** $$T_{bit} = 16 \times \frac{1}{64\text{ MHz}} = 250\text{ ns}$$
* **Total Frame Latency:** 11 bits $\times$ 250 ns = **$2.75\ \mu\text{s}$** per packet.

### 📦 11-Bit Frame Data Layer
Each asynchronous packet transaction maintains a rigid serial layer formatting sequence:
$$\text{[Start Bit: 0]} \longrightarrow \text{[8 Data Bits (LSB First)]} \longrightarrow \text{[1 Odd Parity Bit]} \longrightarrow \text{[Stop Bit: 1]}$$

---

## 🛠️ Architecture Block Diagram

The project is structured partition-by-partition to guarantee minimal physical path delays and maximum clock slack margins:

1.  **Baud Rate Generator (`baud_gen.v`):** A synchronous modulo down-counter acting as a clock divider. It flips internal registers every 8 system clock cycles to output a clean 50% duty-cycle `baud_clk` signal.
2.  **Parity Generator (`parity_gen.v`):** Implements odd-parity check bits dynamically utilizing a geometric reduction-XOR execution product.
3.  **UART Transmitter (`uart_transmitter.v`):** A 4-state Finite State Machine (`IDLE` $\rightarrow$ `LOAD` $\rightarrow$ `SHIFT` $\rightarrow$ `WAIT`) linked to an 11-bit Parallel-In Serial-Out (PISO) shift register pipeline.
4.  **Negative Edge Detector (`edge_detector.v`):** Continuously tracks the raw asynchronous input line at 64 MHz, capturing the start bit's falling transition down-edge within one system cycle window.
5.  **UART Receiver (`uart_receiver.v`):** A Serial-In Parallel-Out (SIPO) array. To mitigate setup/hold violations during ideal synchronous simulation, it is triggered on the **negative edge** of `baud_clk`. This forces sampling to happen precisely at the **midpoint (125 ns)** of every incoming bit frame window.

---

## 🚀 Simulation and Verification

The repository contains a top-level loopback verification suite (`tb_uart_system.v`) that ties the transmitter's `serial_out` directly into the receiver's `serial_data_in` port to track data handling performance.

### 💻 Toolchain Commands (Icarus Verilog & GTKWave)
Run the following steps in your terminal environment to compile the design and launch the waveform analyzer:

```bash
# 1. Compile the top-level testbench (Macro Include Guards handle the rest)
iverilog -o uart_sim.vvp tb_uart_system.v

# 2. Execute simulation to generate the VCD dump file
vvp uart_sim.vvp

# 3. View the timing traces dynamically in GTKWave
gtkwave uart_simulation.vcd
