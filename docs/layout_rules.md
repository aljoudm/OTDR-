# Layout rules for das_model (report quality)

`scripts/layout_model.m` applies them to the whole model; run it after every step (add the new blocks to its tables).

1. Room between connected blocks for the signal labels ("double (c) [1969x1]", about 120 px with the overlays on).
2. Blocks of the same kind have the same size (Gains, Abs/Square/Conj, Sums, Goto/From tags, Random Numbers, Terminators).
3. Every chain sits on one horizontal axis (the signal port is aligned to it); the three detector branches are stacked with equal spacing and share the columns From | Abs | Square | Gain | Sum | output.
4. Lines are straight with minimal bends; long links use Goto/From tags (E_fwd, E_back, E_R_det, LO_det, vib, P_R), so nothing crosses.
5. Section titles are annotations above their section, never on a line or another annotation.
6. Noise blocks sit directly under their Sum block (round Sum with "|++": input 1 left, input 2 bottom), connected straight up. The complex noise uses a Real-Imag to Complex block.
7. Block names are below the blocks (above for the Sums, whose input comes from below).
8. The model flows left to right and top to bottom without large empty areas.

Frames are `[1969x1]` everywhere: Random Number blocks use "Interpret vector parameters as 1-D = off".
