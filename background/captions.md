# Captions for the background figures (research paper)

Each entry: image file, then the caption.

### `figures/das_timeline.pdf` / `figures/das_timeline.png`
**Development of distributed acoustic sensing (DAS) as three steps.** Adapted from Shang et al., Sensors 2022, Fig. 1. The double line climbs through the qualitative stage (1976 OTDR, 1982 COTDR, 1993 Φ-OTDR, 2005 first intrusion-detection use), the quantitative stage (2013 3×3, 2015 PGC and 2016 IQ demodulation, which recover the vibration waveform) and the performance-enhancement stage (2017 ultrafast laser for sensitivity, 2018 UWFBG for frequency response, 2021 FDM against coherent fading). Each open circle marks one milestone and its label sits directly above its own stem. Script: `scripts/fig_das_timeline.m`.

### `figures/das_otdr.pdf` / `figures/das_otdr.png`
**Conventional OTDR (Shang Fig. 2), as built in Simulink.** A pulsed laser (sqrt(P_laser) times the pulse frame p_frame) feeds an EDFA (+10 dB), a circulator (0.8 dB per pass) and the fibre under test (2 km SMF, blue). The backscatter returns to the photodetector placed below the circulator. The FUT block squares the field and applies the power impulse response of `fiber_incoherent`, so powers add and the trace is insensitive to the vibration phase. Every block is a masked Subsystem containing the same blocks as `das_model`; the return pass through the circulator is drawn as the blue line from the FUT to the PD. Model: `model/das_otdr.slx`; script: `scripts/build_das_system_diagrams.m`.

### `figures/das_phiotdr.pdf` / `figures/das_phiotdr.png`
**Φ-OTDR (Shang Fig. 3).** The pulsed laser is replaced by a narrow-linewidth laser (5 kHz, random-walk phase) followed by an acousto-optic modulator (100 ns) that cuts the pulses. The coherent FUT (`fiber_coherent`, Shang Eq. 4) sums the field echoes of all scatterers, so the vibration phase changes the received intensity, which the PD converts with |E|² and R = 0.9 A/W.

### `figures/das_cotdr.pdf` / `figures/das_cotdr.png`
**COTDR (Shang Fig. 4).** A 99:1 coupler splits the laser: 99 % goes through AOM, EDFA, circulator and FUT, 1 % is the local oscillator (LO) that runs along the bottom. A second coupler beats the backscatter with the LO (E_R times conj(LO)), and the PD (I/Q, homodyne) delivers the complex signal I + jQ from which the vibration phase is recovered. In this view the coupler-beat product stands in for the optical mixing of the physical receiver.
