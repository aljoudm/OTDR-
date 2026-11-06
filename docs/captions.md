# Captions for report figures

Each entry: image file, then the caption. Diagrams are exported with `scripts/export_diagram.m`
(Signal Dimensions and Port Data Types overlays on); result figures come from `das_postprocess`.

## Block diagrams

### `figures/diagrams/steps1-3_laser_coupler_aom.png`
**Laser, 99:1 coupler and AOM (Steps 1-3; Shang Figs. 2-4 and 16).**
The narrow-linewidth laser (left) is a random-walk phase accumulator (Random Number + Sum + Unit Delay) combined with a constant magnitude sqrt(P_laser) in a Magnitude-Angle to Complex block, so the line leaving it is a complex scalar field (`double (c)`). The 99:1 coupler is two field gains, sqrt(k_sig) toward the signal arm and sqrt(k_lo) toward the local oscillator (LO, used only by COTDR). In the AOM the scalar field is multiplied by `p_frame` (1 for the first Nw samples, 0 elsewhere): after the AOM every signal line carries a full Ns x 1 trace per pulse (one simulation step = one pulse), with one sample per dz = 1.02 m of fibre (Ns = 1969). The dimension labels `[1969x1]` and type labels `double (c)` (complex) are visible on the lines.
