# File changes vs. the original helper files

| File | Change | Why |
|---|---|---|
| `das_init.m` | Removed `clear;` | InitFcn runs in the base workspace; `clear` would wipe variables (including `out`) every time the model compiles. |
| `das_init.m` | Header explains the path-safe InitFcn; pulse count printed as `T_sim*f_rep + 1` | `/model` and `/scripts` are separate folders, so MATLAB needs `addpath`. Simulink also runs a step at t = 0, so 0.2 s at 10 kHz = 2001 pulses. |
| `fiber_incoherent.m` | Input `r` replaced by scalar `B_cell`; `h = B_cell .* att.^2` | A low-coherence source averages speckle, so the OTDR trace should be smooth. Random `|r|^2` gave ±1.4 dB noise. Slope is still 2·alpha = 0.4 dB/km. |
| `fiber_coherent.m` | `vib(:)` and explicit port sizes in the header | Avoids row/column dimension errors when the Mux output is a 1-D vector. Physics unchanged (Shang Eq. 4). |
| `das_postprocess.m` | Auto-run `das_init` if parameters are missing; normalise frame orientation; save figures to `/figures` | To Workspace may log `Ns x 1 x Np` or `Np x Ns`. PNGs go straight to the repo. |

## Simplifications (for the report)
- COTDR uses homodyne detection (I and Q directly) instead of heterodyne at f0, so no high sample rate is needed.
- One simulation step = one optical pulse (slow-time sampling).
- The circulator and EDFA are modelled as pure field gains/losses.
