dpu
===
The Data Processing Module (DPU) portion of the eVOLVER code are Python scripts used to interface with the machine. This is where experimental scripts can be written, feedback loops between parameters can be programmed, or calibration files can be updated on eVOLVER.

## Installation
See the [wiki installation guide](https://khalil-lab.gitbook.io/evolver/getting-started/software-installation/dpu-installation).

## Nix
Run the experiment controller from the DPU repo root:

```bash
nix run .#run-dpu -- -i 127.0.0.1
```

Omit `-i 127.0.0.1` when `experiment/template/eVOLVER_parameters.json`
already supplies the eVOLVER server IP.

## Code Structure
For more information, see the wiki page on [code structure](https://khalil-lab.gitbook.io/evolver/software/dpu-code-structure).

## Questions or Bugs?
Search the [forum](https://www.evolver.bio/c/software/dpu/10) for answers or make a post.
