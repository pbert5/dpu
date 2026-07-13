dpu
===
The DPU is the Python process you run on your workstation to control an eVOLVER experiment. It is a socket.io **client** that connects to the eVOLVER server running on the Raspberry Pi — there is no DPU server of its own.

The RPi server broadcasts sensor readings (OD, temperature) every 20 seconds. The DPU receives each broadcast, applies calibration fits to convert raw ADC values to physical units, writes data to CSV files, and runs your experiment logic (turbidostat dilutions, chemostat pumping, etc.). Any pump or setpoint commands it decides to send go back to the RPi server, which executes them over serial to the Arduino.

**The only file you need to edit per experiment is `experiment/template/custom_script.py`.** Set your temperature, stir speed, OD thresholds, and operation mode at the top of that file, then start the experiment with:

```bash
python experiment/template/eVOLVER.py --ip-address <RPi IP>
```

`eVOLVER.py` is the framework (connection handling, calibration, data saving). `custom_script.py` is your experiment logic.

## Installation
See the [wiki installation guide](https://khalil-lab.gitbook.io/evolver/getting-started/software-installation/dpu-installation).

## Nix
Run the experiment controller from the DPU repo root:

```bash
nix run .#run-dpu -- -i 127.0.0.1
```

Omit `-i 127.0.0.1` when `experiment/template/eVOLVER_parameters.json`
already supplies the eVOLVER server IP.

The "DPU" is not a fixed piece of hardware or a dedicated machine — it is just
whatever computer runs this script. A laptop, a lab workstation, or a second Pi
all work equally well. You can also write your own client in any language: connect
to port 8081 on the RPi, listen for the `broadcast` socket.io event, and emit
`command` events in response.

## Code Structure
For more information, see the wiki page on [code structure](https://khalil-lab.gitbook.io/evolver/software/dpu-code-structure).

## Questions or Bugs?
Search the [forum](https://www.evolver.bio/c/software/dpu/10) for answers or make a post.
