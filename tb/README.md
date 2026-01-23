# Setup environment for digital flow

## Use Python3.12
## Requires libpython3.12-dev
## Use IcarusVerilog v12.0+

## Use tcsh shell
```sh
tcsh
```

## Create python virtual environment
```sh
source ./bin/venv.src.me
```

## Activate virtual environment
```sh
source .venv/bin/activate.csh
```



# Sample testbench

This is a sample testbench for a digital project. It uses [cocotb](https://docs.cocotb.org/en/stable/) to drive the DUT and check the outputs.

## How to run

To run the RTL simulation:

```sh
make -B
```

TBD TODO TO be updated for gatelevel simulation
To run gatelevel simulation, first harden your project and copy `../runs/wokwi/results/final/verilog/gl/{your_module_name}.v` to `gate_level_netlist.v`.

Then run:

```sh
make -B GATES=yes
```

If you wish to save the waveform in VCD format instead of FST format, edit tb.v to use `$dumpfile("tb.vcd");` and then run:

```sh
make -B FST=
```

This will generate `tb.vcd` instead of `tb.fst`.

## How to view the waveform file

Using GTKWave

```sh
gtkwave tb.fst tb.gtkw
```

Using Surfer

```sh
surfer tb.fst
```