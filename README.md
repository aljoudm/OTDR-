# OTDR / Φ-OTDR / COTDR (DAS) Simulink model

Simulink simulation of a Distributed Acoustic Sensing system based on the block diagrams in Shang et al. (Figs. 2, 3, 4, 16).
Every optical block is a complex-baseband model; **one simulation step = one optical pulse** (a trace of Ns samples per step).

## Structure
- `model/` — `das_model.slx`
- `scripts/` — `das_init.m`, `fiber_coherent.m`, `fiber_incoherent.m`, `das_postprocess.m`
- `figures/` — PNG figures exported by `das_postprocess`
- `docs/` — notes for the report (file changes, simplifications, validation results)

## How to run
1. Open MATLAB with the project root as the current folder.
2. The model's InitFcn adds `scripts/` to the path and runs `das_init`.
3. ```matlab
   out = sim('das_model'); das_postprocess
   ```

## Mapping to Shang
_To be filled as the model is built._

## Validation experiments
_To be filled after the experiments._
