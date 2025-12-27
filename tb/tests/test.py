
import cocotb
from cocotb.types import Logic
from cocotb.types import LogicArray
from cocotb.triggers import Timer
from cocotbext.i2c import I2cMaster

async def i2c_write(dut, i2c_master, slave_address, address, data):
  dut._log.info(f"I2C write to address {address} data {data}")
  payload = bytes([address]) + bytes([data])
  await i2c_master.write(slave_address, payload)
  await i2c_master.send_stop()

async def i2c_read (dut, i2c_master, slave_address, address):
  dut._log.info(f"I2C read to address {address}")
  payload = bytes([address])
  await i2c_master.write(slave_address, payload)
  data = await i2c_master.read(slave_address, 1)
  await i2c_master.send_stop()
  return data

def default_pin_drive(dut):
  dut._log.info("Drive default values for peripheral interfaces and reset")

  # Start in reset
  dut.rstb.value = 0

  # Default values all input ports
  dut.ready.value   = Logic(1)
  dut.data_in.value = LogicArray("111111111")
  dut.scl_in.value  = Logic(1)
  dut.sda_in.value  = Logic(1)

async def assert_reset(dut):
  dut._log.info("Asserting reset")
  dut.rst_n.value = 0
  await Timer(1, unit="us")

async def release_reset(dut):
  dut._log.info("Releasing reset")
  dut.rstb.value = Logic(1)
  await Timer(1, unit="us")

@cocotb.test()
async def test_project(dut):
  dut._log.info("Start")

  # Create i2C master with clk speed of 100kHz (100kHz = 200000 due to clk invert manually)
  i2c_master = I2cMaster(dut.i2c_sda, dut.i2c_sda_i, dut.i2c_scl_i, dut.i2c_scl_i, 200000)

  # Default values for spi and i2c peripherals interface
  default_pin_drive(dut)

  # Randomize value for oscillator compensation
  #osc_program = rand_osc_ctrl_trim(dut)

  # Reset
  await assert_reset(dut)

  # Reset release
  await release_reset(dut)

  # Randomize data
  data0 = random.randint(0x00, 0xFF)

  # Write one byte
  await i2c_write(dut, i2c_master, 0x70, 0, data0)

  # Read one byte
  reg0 = await i2c_read(dut, i2c_master, 0x70, 0)

  # Compare results
  assert bytes([data0]) == reg0