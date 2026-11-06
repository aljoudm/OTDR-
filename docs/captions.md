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

### `figures/diagrams/steps1-5_model.png`
**Model after Step 5: the fibre under test (FUT) in its two forms (Shang Figs. 2-4, Eq. 4).** Top: `FUT_coherent` (MATLAB Function `fiber_coherent`) takes the complex probe frame E_in (`double (c) [1969x1]`) from the circulator and the vibration phases of the two events (Sine_v1, Sine_v2 combined by Mux_vib into a 2-element vector), and returns the backscattered field E_R, which re-enters the circulator through its second input. It implements Shang's Eq. (4): every fibre cell is one random reflector delayed by one sample, so the sum of all echoes is a convolution of the probe with the fibre impulse response h = r * att * exp(j*phi). r, att and g_vib are Parameters read from the workspace. Bottom: `FUT_incoherent` (`fiber_incoherent`) receives |E|^2 (Abs_inc, Sq_inc): powers add instead of fields, so the vibration phase has no effect, which is why conventional OTDR is phase-insensitive. Term_bwd and Term_otdr are temporary and are replaced by the detectors in Step 6.

### `figures/diagrams/steps1-6_model.png`
**Complete model after Step 6 (Shang Figs. 2-4 and 16), with signal sizes and types shown.** Top row: narrow-linewidth laser (random-walk phase), 99:1 coupler (signal arm and local-oscillator arm), AOM (pulse frame), EDFA, circulator and the coherent fibre under test (`fiber_coherent`, Shang Eq. 4); below it, the conventional-OTDR fibre (`fiber_incoherent`) fed with |E|². Every signal line carries a full Ns x 1 trace per pulse (`[1969x1]`, one sample per 1.02 m of fibre). Goto/From tags carry the long links (forward field, backscatter, local oscillator, vibration phases). Bottom: the three detection branches stacked in shared columns: OTDR (power x R_pd + noise), Φ-OTDR (|E_R|² x R_pd + noise) and COTDR (E_R x conj(LO) x R_pd + complex noise made of an independent real and imaginary part). The vibration source (two sine waves, one per event) is at the bottom left. The Terminators are replaced by the DAQ in Step 7.

## Model sections (`figures/model_sections/`, PDF vector + PNG 300 dpi, signal sizes and types shown)

The model is ONE connected model; the four light-coloured areas only group the blocks, and each image is a crop of the same diagram. **Goto and From blocks that carry the same tag name are connected**: `E_fwd`, `E_back`, `E_R_det`, `LO_det`, `vib` and `P_R` replace long wires.

### `00_full_model.pdf` / `00_full_model.png`
**Complete das_model (Shang Figs. 2, 3, 4 and 16).** One simulation step is one optical pulse, so every signal line carries a full `[1969x1]` trace (one sample per 1.02 m of fibre). Left to right and top to bottom: source (1), circulator and fibre (2), detectors (3), vibration sources (4).

### `01_source.pdf` / `01_source.png`
**Section 1, source (Shang Fig. 16 for the 99:1 coupler; the source side of Figs. 2-4).** The narrow-linewidth laser is a random-walk phase (Random Number, Sum, Unit Delay) combined with the constant magnitude sqrt(P_laser) into the complex field. The 99:1 coupler is two field gains, sqrt(k_sig) towards the signal arm and sqrt(k_lo) towards the local oscillator (tag `LO_det`, used only by the COTDR). The AOM multiplies the scalar field by the pulse frame p_frame, giving one `[1969x1]` pulse frame per step, and the EDFA applies the field gain g_edfa (+10 dB).

### `02_circulator_fut.pdf` / `02_circulator_fut.png`
**Section 2, circulator and fibre under test (Shang Figs. 2-4; Eq. 4).** The circulator is a loss g_cir in each direction: forward (input 1, towards the fibre) and backward (input 2, backscatter towards the detectors, tag `E_R_det`). `FUT_coherent` sums the field echoes of all fibre cells (one random reflector per sample, a convolution with h = r·att·exp(jφ)); the vibration phases of the two events enter through tag `vib`, and the returning field E_R goes back into the circulator through tag `E_back`. `FUT_incoherent` receives |E|² through tag `E_fwd` (Abs, Square): powers add, so the vibration phase has no effect and the output `P_R` is the conventional OTDR trace.

### `03_detectors.pdf` / `03_detectors.png`
**Section 3, detectors: OTDR (Fig. 2), Φ-OTDR (Fig. 3) and COTDR (Fig. 4), stacked in shared columns.** Every branch ends with the responsivity R_pd and receiver noise (independent Random Number frames, one seed each). OTDR: the backscattered power `P_R` passes the backward circulator loss g_cir² (the same loss the coherent field suffers on its way back), then R_pd and noise. Φ-OTDR: |E_R|² (direct detection) · R_pd + noise. COTDR: E_R · conj(LO) · R_pd + complex noise (independent real and imaginary parts combined by Real-Imag to Complex); the product with the conjugate local oscillator gives the complex I + jQ signal (homodyne detection) and cancels the common laser phase.

### `04_vibration.pdf` / `04_vibration.png`
**Section 4, vibration sources.** One sine wave per vibration event (amplitude Phi0, frequency f_v; Sample time Ts_slow = one pulse) combined by a Mux into the 2-element vibration vector sent to `FUT_coherent` through tag `vib`.

### Step 7: DAQ (see `figures/model_sections/03_detectors.png` and `00_full_model.png`)
**Data acquisition.** Each detector branch ends in a To Workspace block (Save format Array, Sample time Ts_slow = one pulse): `DAQ_otdr` -> `trace_otdr`, `DAQ_dd` -> `trace_dd` (Φ-OTDR intensity) and `DAQ_coh` -> `trace_coh` (COTDR, complex I + jQ). Each variable is logged as Ns x 1 x Np = 1969 x 1 x 2001 (samples along the fibre x pulses); the COTDR variable is complex.
