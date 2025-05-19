![Board Schematic](./schematic.png)

# FPGA Reaction Time Tester

This project implements a reaction time tester on an FPGA. It measures reaction time in milliseconds and displays statistics (average, minimum, maximum) for the last three attempts.

## Project Structure

*   `NewRefactoredCode/RT_vivadoProject/`: Vivado project files.
    *   `.../sources_1/new/`: VHDL source files.
    *   `.../constrs_1/new/`: Constraints file.
    *   `.../sim_1/new/`: VHDL testbench files.

## Prerequisites

*   Xilinx Vivado Design Suite (e.g., 2022.2 or similar).
*   Compatible FPGA board (e.g., Digilent Basys 3).
*   USB cable.

## 1. Programming the FPGA

1.  **Open Project:** Launch Vivado, select `Open Project`, and navigate to `NewRefactoredCode/RT_vivadoProject/RT_vivadoProject.xpr`.
2.  **Generate Bitstream:** In Flow Navigator (left pane) -> `Program and Debug` -> `Generate Bitstream`. Wait for synthesis and implementation.
3.  **Connect Board:** Connect your FPGA board via USB and power it on. Ensure drivers are installed.
4.  **Program Device:**
    *   After bitstream generation, select `Open Hardware Manager` (or open it from Flow Navigator).
    *   Click `Open target` -> `Auto Connect`. Vivado should detect your board.
    *   Right-click the FPGA device -> `Program device`.
    *   Ensure the `Bitstream file` field points to `.../RT_vivadoProject.runs/impl_1/Display_Controller_ms.bit`.
    *   Click `Program`.
5.  **Verify:** The FPGA's 7-segment display should activate.

## 2. Using the Reaction Time Tester

Uses the 7-segment display, 5 pushbuttons (Center, Right, Up, Down, Left), and LEDs.

### Display & LEDs Overview:

*   **7-Segment Display:** Shows reaction times (ms), countdowns, stats, or "Err ".
*   **LEDs:**
    *   `LED0-LED1`: Number of stored times (0-3, binary).
    *   `LED4`: Average time displayed.
    *   `LED5`: Maximum time displayed.
    *   `LED6`: Minimum time displayed.
    *   `LED15`: Error occurred.

### Button Functions:

*   **BTNC (Center):**
    *   Starts a new test (from waiting state).
    *   Stops timer when visual cue appears (during test).
    *   Returns to waiting state (from result/error/stats display).
*   **BTNR (Right):** Shows/cycles to average time.
*   **BTNU (Up):** Shows/cycles to maximum time.
*   **BTND (Down):** Shows/cycles to minimum time.
*   **BTNL (Left):** Clears all stored times and returns to waiting (from stats display).

### Testing Your Reaction Time:

1.  **Start:** Press **BTNC** from the waiting state.
2.  **Countdown:** Observe decimal points on the display:
    *   Prompt 1: `0.0.0.`
    *   Prompt 2: `0.0. .`
    *   Prompt 3: `0. . .`
    *   **Do NOT press BTNC during countdown** (causes "Err").
3.  **React:** After a random delay post-Prompt 3, decimal points turn OFF. Press **BTNC** quickly.
4.  **Result:** Your reaction time (ms) is displayed and stored. `LED0-LED1` update.
5.  **Next:**
    *   Press **BTNC** for a new test.
    *   Press **BTNR/U/D** for statistics.

### Viewing Statistics:

*   From waiting or result display:
    *   **BTNR** for average (`LED4` on).
    *   **BTNU** for maximum (`LED5` on).
    *   **BTND** for minimum (`LED6` on).
*   While viewing stats:
    *   Use **BTNR/U/D** to switch stats.
    *   **BTNL** to clear all stats and return to waiting.
    *   **BTNC** to return to waiting without clearing.

### Error State ("Err "):

*   Caused by pressing **BTNC** during countdown. `LED15` on, DPs flash.
*   Press **BTNC** to return to waiting.

## Troubleshooting

*   **FPGA Not Programming:** Check USB, power, drivers. Try `Close target` then `Auto Connect` in Hardware Manager. Verify bitstream file.
*   **Display/Behavior Issues:** Re-program FPGA. Check `.xdc` constraints file for board pinout match. Review VHDL for errors if modified.

Enjoy testing your reaction speed!
