function P_R = fiber_incoherent(P_in, B_cell, att)
%FIBER_INCOHERENT  FUT block for conventional OTDR (low-coherence source).
%  Paste this into a MATLAB Function block named "FUT (incoherent)".
%    P_in   : input,  Size [Ns 1], real   (probe POWER frame = |E|^2)
%    B_cell : PARAMETER (scalar)          (backscattered power fraction per cell)
%    att    : PARAMETER (Nz x 1)          (same as the coherent block)
%    P_R    : output, Size [Ns 1], real   (backscattered POWER)
%
%  With a low-coherence source the echoes do not interfere: powers add, not
%  fields. The vibration phase therefore has no effect on the trace — this is
%  exactly why conventional OTDR cannot sense vibration (Shang 2022, Sec. 2.2).
%
%  Change vs the original: the power response uses the AVERAGE scattering power
%  B_cell instead of the random |r|^2. A low-coherence source averages the
%  speckle away, so the trace is a smooth line (slope = 2*alpha).

h   = B_cell .* att.^2;                  % power impulse response (round trip)
y   = conv(P_in, h);
P_R = y(1:numel(P_in));
end
