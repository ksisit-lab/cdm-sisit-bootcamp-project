import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

@cocotb.test()
async def test_lfsr_cipher(dut):
    dut._log.info("Start test")

    # Start a clock
    clock = Clock(dut.clk, 10, units="us")
    cocotb.start_soon(clock.start())

    # Reset the module. 
    # We send an input of 20 (Binary: 0001_0100).
    # This sets the Key to 0001 and the Data to 0100.
    dut._log.info("Resetting the DUT")
    dut.ena.value = 1
    dut.ui_in.value = 20
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1

    # Wait one cycle for reset to clear
    await ClockCycles(dut.clk, 1)

    # CHECK 1:
    # Key = 0001. Data = 0100.
    # Ciphertext = Data ^ Key = 0100 ^ 0001 = 0101.
    # Expected Output = {Key, Ciphertext} = 0001_0101 (Decimal 21)
    dut._log.info("Checking first encryption cycle")
    assert dut.uo_out.value == 21, f"Expected 21, got {dut.uo_out.value}"

    # CHECK 2 (Next Clock Cycle):
    # The LFSR shifts internally. The new Key state becomes 0010.
    # Ciphertext = 0100 ^ 0010 = 0110.
    # Expected Output = {0010, 0110} = 0010_0110 (Decimal 38)
    await ClockCycles(dut.clk, 1)
    dut._log.info("Checking second encryption cycle")
    assert dut.uo_out.value == 38, f"Expected 38, got {dut.uo_out.value}"
