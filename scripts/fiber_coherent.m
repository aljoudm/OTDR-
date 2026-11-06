function E_R = fiber_coherent(E_in, vib, r, att, g_vib)
%FIBER_COHERENT  FUT block for Phi-OTDR and COTDR (coherent laser).
%  Paste this into a MATLAB Function block named "FUT (coherent)".
%  Ports and Data Manager settings (set Size explicitly, it avoids dimension errors):
%    E_in  : input,  Size [Ns 1], Complexity complex  (probe frame after EDFA + circulator)
%    vib   : input,  Size [K 1] (or [1 K] from the Mux), real  (vibration phase of each event)
%    r     : PARAMETER (Nz x 1 complex), att : PARAMETER (Nz x 1), g_vib : PARAMETER (Nz x K)
%    E_R   : output, Size [Ns 1], Complexity complex
%
%  Model (Shang 2022, Eq. 4): the received field is the sum of the echoes of
%  all scatterers. Each fibre cell is one scatterer, delayed by its round trip
%  (one sample per cell), so the sum becomes a convolution of the probe with
%  the fibre impulse response h.  A vibration adds a phase to every cell at
%  and beyond the disturbed section.

phi = g_vib * vib(:);                    % Nz x 1 extra phase [rad]  (vib(:) forces a column)
h   = r .* att .* exp(1j*phi);           % fibre impulse response
y   = conv(E_in, h);                     % coherent sum of all echoes
E_R = y(1:numel(E_in));
end
