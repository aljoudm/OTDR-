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
