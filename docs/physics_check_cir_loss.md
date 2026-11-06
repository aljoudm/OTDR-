# Physics check: backward circulator loss in the three detection branches

Question: the coherent branch (E_back / E_R_det) passes the circulator's backward gain g_cir, but the OTDR branch (P_R) did not.

Answer: yes, it was an inconsistency. The circulator costs the signal g_cir in field on the way out (all branches, because the OTDR chain takes |E|^2 after the forward gain) and g_cir again on the way back. Field gain g_cir is a power factor g_cir^2.
- Coherent / Phi-OTDR / COTDR: E_R re-enters the circulator (input 2) and leaves through output 2 with the backward gain g_cir (field), so power is multiplied by g_cir^2.
- OTDR: fiber_incoherent works on power and its output P_R skipped the backward pass.

Fix: a Gain `Gain_g_cir2` (value g_cir^2) in the OTDR detector branch, before R_pd (`scripts/layout_model.m` creates it). All three detectors now see the same circulator losses. The local oscillator of the COTDR does not pass through the circulator, as in Shang Fig. 4.
