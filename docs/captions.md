# Captions for report figures

Each entry: image file, then the caption. Diagrams are exported with `scripts/export_diagram.m`
(Signal Dimensions and Port Data Types overlays on); result figures come from `das_postprocess`.

## Block diagrams

### `figures/diagrams/steps1-3_laser_coupler_aom.png`
**Laser, 99:1 coupler and AOM (Steps 1-3; Shang Figs. 2-4 and 16).**
The narrow-linewidth laser (left) is a random-walk phase accumulator (Random Number + Sum + Unit Delay) combined with a constant magnitude sqrt(P_laser) in a Magnitude-Angle to Complex block, so the line leaving it is a complex scalar field (`double (c)`). The 99:1 coupler is two field gains, sqrt(k_sig) toward the signal arm and sqrt(k_lo) toward the local oscillator (LO, used only by COTDR). In the AOM the scalar field is multiplied by `p_frame` (1 for the first Nw samples, 0 elsewhere): after the AOM every signal line carries a full Ns x 1 trace per pulse (one simulation step = one pulse), with one sample per dz = 1.02 m of fibre (Ns = 1969). The dimension labels `[1969x1]` and type labels `double (c)` (complex) are visible on the lines.

### `figures/diagrams/steps1-4_model.png`
**Model after Step 4: laser, 99:1 coupler, AOM, EDFA and circulator (Shang Figs. 2-4 and 16).** The line from the AOM onward carries a complex Ns x 1 trace per pulse (`double (c) [1969x1]`). The EDFA and the circulator are Subsystems named as in Shang's diagrams. The circulator has two paths: forward (input 1 to output 1, towards the fibre) and backward (input 2 to output 2, towards the detectors). Ground_bwd and the two Terminators are temporary and are replaced by the fibre and the detectors in Steps 5-6.

### `figures/diagrams/step4_edfa_subsystem.png`
**EDFA subsystem.** The erbium-doped fibre amplifier is modelled as a field gain g_edfa = sqrt(10^(G/10)) (G = 10 dB). The signal keeps its size, Ns x 1, and stays complex.

### `figures/diagrams/step4_circulator_subsystem.png`
**Circulator subsystem.** The circulator is modelled as a loss of g_cir = sqrt(10^(-IL/10)) (IL = 0.8 dB) in each direction: the forward path (top) leads to the fibre, the backward path (bottom) leads from the fibre to the photodetectors.
