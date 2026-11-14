# DAS simulation in Simulink: OTDR, Φ-OTDR and COTDR

Simulink model of a Distributed Acoustic Sensing system after Shang et al., *Sensors* 2022 (Figs. 2, 3, 4 and 16). Every optical block is a complex-baseband model and **one simulation step is one optical pulse**: each step outputs a full trace of Ns = 1969 samples (one per 1.02 m of a 2 km fibre).

## Structure
- `model/das_model.slx`: the model (one connected model, four coloured sections)
- `scripts/`: parameters (`das_init.m`), fibre models (`fiber_coherent.m`, `fiber_incoherent.m`), post-processing (`das_postprocess.m`), the build scripts of every step (`build_step*.m`), the layout and export tools (`layout_model.m`, `export_model_sections.m`, `export_diagram.m`, `crop_pdf_sections.py`) and the experiments (`run_experiments.m`)
- `figures/`: result figures `fig1..fig6`; `figures/experiments/`: validation experiments; `figures/model_sections/`: the model as a whole and per section (PDF + PNG); `figures/diagrams/`: step-by-step model images
- `docs/`: `captions.md` (a caption for every figure), `validation_results.md`, `file-changes.md`, `layout_rules.md`, `physics_check_cir_loss.md`
- `background/`: figures for the paper that are not part of the simulation (DAS timeline, OTDR → Φ-OTDR → COTDR evolution diagram)

## How to run
Open MATLAB with the project root as current folder, then:
```matlab
cd model
out = sim('das_model'); das_postprocess
```
The model's InitFcn adds `scripts/` to the path and runs `das_init`, which defines all the parameters. `run_experiments` runs the five validation experiments (about 15 minutes); `layout_model` followed by `export_model_sections` rearranges the model and re-exports its images.

## Mapping to Shang's figures
| Model part | Shang |
|---|---|
| Section 1: narrow-linewidth laser (phase random walk), 99:1 coupler, AOM (pulse frame), EDFA | Figs. 3, 4 and 16 |
| Section 2: circulator, `FUT_coherent` (sum of echoes, Eq. 4), `FUT_incoherent` (powers add) | Figs. 2, 3, 4 |
| Section 3: OTDR detector | Fig. 2 |
| Section 3: Φ-OTDR detector (|E|², direct detection) | Fig. 3 |
| Section 3: COTDR detector (E_R · conj(LO), homodyne, complex noise) | Fig. 4 |
| Section 4: vibration sources (two events) | disturbance in Figs. 3, 4 |

## Main results (default parameters, `figures/fig1..fig6`)
- Conventional OTDR trace: straight line, slope **0.400 dB/km** (twice the 0.2 dB/km attenuation, round trip)
- Single Φ-OTDR trace: random speckle (coherent fading); waterfall shows the two events at 1200 m and 1500 m
- Event localisation: strongest event at **1209 m** (perturbed section starts at 1200 m)
- Recovered phase (COTDR): sine of **1.00 rad** (residual 0.03 rad); spectrum: single line at **200 Hz**

## Validation experiments (`docs/validation_results.md`, `figures/experiments/`)
1. **Spatial resolution** (Δz = 10.2 m): events 5 m apart give one response, 20 m apart two.
2. **Pulse width**: 50 / 100 / 200 ns give resolutions 5.1 / 10.2 / 20.4 m; the response widens (7 / 15 / 28 m) and the signal over the noise floor rises (5 / 14 / 36).
3. **Frequency limit**: a 6 kHz vibration at f_rep = 10 kHz shows up at **3998 Hz** (alias of 4 kHz).
4. **OTDR vs Φ-OTDR**: with and without the vibration the conventional OTDR traces are identical (difference 0); the Φ-OTDR shows the events.
5. **Coherent fading** (12 fibres): with a noisy receiver the phase error grows from 0.10 rad to 0.53 rad as the backscatter at the sampled points weakens.

## Simplifications (for the report)
- COTDR uses homodyne detection (I and Q directly) instead of heterodyne at f0, so no high sample rate is needed.
- The circulator is a loss in each direction; the EDFA a field gain; the laser phase noise a random walk.
- The incoherent (OTDR) fibre uses the mean scattering power instead of the random one (a low-coherence source averages the speckle).
- The model keeps one frame per pulse, so fast time (along the fibre) is the vector index and slow time the simulation time.

## FEBUS A1-NEO parameters (branch `febus-a1neo`)
All physical and signal parameters now live in **one file**, `scripts/otdr_params.m` (returns the struct `p`; the model InitFcn runs `p = otdr_params(); das_init`, and `das_init` only unpacks `p` for the blocks). Run `scripts/run_febus.m` to check the expected values, simulate the three techniques and regenerate the report figures in `background_febus/figures/` (PNG 300 dpi + PDF, no in-figure titles). `scripts/verify_params.m` prints the expected backscatter power and SNR (0 / 10 / 20 km: 61.8 / 24.6 / 9.8 nW, 34.8 / 30.8 / 26.8 dB) and stops if any is off by more than 5 dB.

Tags: [FEBUS] vendor value, [DATASHEET], [DERIVED], [CHOSEN], [ASSUMED], [SIM SETTING].

| Parameter | Value | Unit | Tag |
|---|---|---|---|
| Wavelength λ | 1550e-9 | m | DATASHEET |
| Simulated fibre length L | 20e3 | m | DATASHEET |
| Attenuation α | 0.2 | dB/km | DATASHEET |
| Channel spacing Δz_samp | 2 | m | DATASHEET |
| Spatial resolution Δz_res | 10 | m | CHOSEN: inside the datasheet range 1–50 m; 2 m collapses the SNR (DAS-Simulation); 10 m as Zeng 2024 |
| Group index n_g | 1.4682 | – | ASSUMED: Corning SMF-28 Ultra PI-1424 |
| Backscatter coefficient R_bs (1 ns) | −82 | dB | ASSUMED: Corning PI-1424 |
| Peak pulse power P0 | 0.1 | W | ASSUMED: Thevenaz 2025; Liu 2016 |
| Laser linewidth (Φ-OTDR, COTDR) | 3e3 | Hz | ASSUMED: Zeng 2024; Juarez 2005 |
| Noise floor P_noise_ref at B_ref | 0.2e-9 at 100e6 | W, Hz | ASSUMED: Thevenaz 2025 |
| Strain-optic coefficient ξ | 0.78 | – | ASSUMED: He & Liu 2021 (not used by the model) |
| Coupler k_sig / k_lo, EDFA gain, circulator loss, R_pd, vibration lengths/frequencies/amplitudes, gauge length | 0.99/0.01, 10 dB, 0.8 dB, 0.9 A/W, 10 m, 200/500 Hz, 1/0.5 rad, 10 samples | – | ASSUMED: Shang 2022 |
| Vibration positions | 12 and 15 km | m | CHOSEN: former 1.2/1.5 km scaled to the 20 km fibre |
| Seeds, N_pulses = 1000, f_rep fraction 0.9, rectangular pulse, sine phase 0 | – | – | SIM SETTING |
| Pulse width τ | 97.9 | ns | DERIVED |
| Sampling rate f_s | 51.05 | MHz | DERIVED |
| Round trip T_rt | 195.9 | µs | DERIVED |
| f_rep_max / f_rep / f_vib_max | 5.10 / 4.59 / 2.30 | kHz | DERIVED |
| Receiver bandwidth B_rx; P_noise | 10.2 MHz; 20.4 pW | – | DERIVED |
| CW laser power P_laser; LO power | 12.1 mW; 0.12 mW | – | DERIVED (pulse power at the fibre input = P0) |

Derivations:
- τ = 2·n_g·Δz_res/c (Δz = c·τ/(2n_g), Liu 2016); f_s = c/(2·n_g·Δz_samp); T_rt = 2·n_g·L/c; f_rep_max = 1/T_rt; f_rep = 0.9·f_rep_max; f_vib_max = f_rep/2 (Wang 2020).
- B_rx = 1/τ; P_noise = P_noise_ref·B_rx/B_ref (Palmieri 2013).
- P_bs(z) = P0 · 10^((R_bs + 10·log10(τ/1 ns))/10) · 10^(−2·α·z/1e4), z in m. In the model the per-cell backscatter fraction is R_bs,pulse/N_w.
- P_laser = P0/(k_sig · g_edfa² · g_cir²); coherent noise: σ_coh = R_pd·√(P_LO·P_noise/2) per I and Q (so SNR = P_bs/P_noise); direct detection and OTDR: σ_dd = R_pd·P_noise.
- Override rule: if τ is given by FEBUS and Δz_res is not, Δz_res = c·τ/(2·n_g); otherwise values are used as given.

**Solver:** one Simulink step is one optical pulse (frame-based model), so the fixed step is 1/f_rep, not 1/f_s; f_s enters through Δz = c/(2·n_g·f_s) = 2 m and the frame length (10 005 samples). Stop time = N_pulses/f_rep (0.218 s for 1000 pulses); one trace takes T_rt = 195.9 µs. A run of all three techniques takes about 1.5–3 minutes. Simulink builds code in a path that must stay under 260 characters: `run_febus` moves the cache to `C:/sl`.

## Sources
1. FEBUS A1-NEO datasheet, rev. 20260618.
2. Corning SMF-28 Ultra optical fiber, product information PI-1424.
3. Thevenaz, 2025 (peak power, coherent noise floor).
4. Liu et al., 2016 (pulse width and resolution, mutual-information power limit, OTDR vs Φ-OTDR sources).
5. Zeng et al., 2024 (perimeter DAS, 10 m resolution, laser linewidth).
6. Juarez et al., 2005 (narrow-linewidth laser for Φ-OTDR).
7. Palmieri et al., 2013 (noise vs bandwidth).
8. Wang et al., 2020 (vibration frequency limit f_rep/2).
9. He and Liu, 2021 (strain-optic coefficient).
10. Shang et al., *Sensors* 2022 (model structure, Figs. 2–4).

## Model limitations
- One frame per pulse: no sample-by-sample (1/f_s) solver; fast time is the vector index.
- Homodyne COTDR (I and Q directly); no heterodyne carrier, no frequency-shifted LO, no balanced detector or polarisation diversity.
- Scalar field: no polarisation fading, no birefringence, no non-linear effects (modulation instability, SRS), no dispersion.
- Constant attenuation with a single Rayleigh coefficient; no connectors, splices, reflections or fibre end reflection.
- Circulator and EDFA are gains/losses only: no ASE noise, no gain saturation, no extinction-ratio leakage of the AOM.
- Laser phase noise is a random walk (Lorentzian line); no relative intensity noise, no frequency drift.
- Receiver noise is white Gaussian (shot and thermal noise are not modelled separately); ADC quantisation and anti-alias filter are not modelled; the pulse is rectangular.
- Vibration acts as a pure phase on the fibre beyond the event; strain transfer, the strain-optic coefficient ξ and the sensor response are not modelled.
- `scripts/run_experiments.m` is the validation of the original 2 km / 10 kHz model; it has not been adapted to 20 km (f_rep = 10 kHz exceeds f_rep_max) and the `figures/` results are the Shang-based ones.

## When vendor data arrives
Edit only the FEBUS overrides block in `scripts/otdr_params.m`.
