%% das_postprocess.m — run after the simulation:  out = sim('das_model'); das_postprocess
%  Expects To Workspace variables in "out":  trace_otdr, trace_dd, trace_coh
%  (save format: Array). Logged as Ns x 1 x Np or Np x Ns -> normalised to Ns x Np.
%  Six figures are saved as PNG into <project>/figures (or figures/<figsub> when the variable
%  figsub is set in the base workspace); an optional suffix tag is added to the file names.
%  The numbers printed below are also stored in the struct "res" (used by the experiments).

if ~exist('Ns','var') || ~exist('Ts_slow','var'), das_init; end   % parameters missing -> load them
if ~exist('figsub','var'), figsub = ''; end
if ~exist('tag','var'),    tag = '';    end
figdir = fullfile(fileparts(mfilename('fullpath')),'..','figures',figsub);
if ~exist(figdir,'dir'), mkdir(figdir); end
if ~exist('nofig','var'), nofig = false; end                  % nofig = true: compute the numbers only
if nofig, savefig_ = @(name) []; else, savefig_ = @(name) exportgraphics(gcf, fullfile(figdir,[name tag '.png']), 'Resolution',150); end
tofr = @(X) local_frames(X, Ns);              % -> Ns x Np
res  = struct();

zax = (0:Ns-1).'*dz;                          % distance axis [m]
D   = tofr(out.trace_dd);                     % Phi-OTDR intensity  (Ns x Np)
C   = tofr(out.trace_coh);                    % COTDR complex I+jQ  (Ns x Np)
Np  = size(D,2);  tax = (0:Np-1)*Ts_slow;     % slow-time axis [s]

%% 1) Conventional OTDR trace: straight line with slope -2*alpha (Eq. power)
P = tofr(out.trace_otdr);
figure; plot(zax, 10*log10(P(:,1)), 'LineWidth',1); grid on
xlabel('Distance (m)'); ylabel('Detected power (dB)'); xlim([0 zax(end)]);
title('Conventional OTDR trace'); savefig_('fig1_otdr_trace');
pf = polyfit(zax(2*Nw:end-2*Nw), 10*log10(P(2*Nw:end-2*Nw,1)), 1);
res.slope = -pf(1)*1e3;
fprintf('OTDR slope = %.3f dB/km (expected %.3f)\n', res.slope, 2*alpha_dB);   % round trip -> 2x

%% 2) Phi-OTDR: one raw trace (speckle) and the waterfall
figure; plot(zax, D(:,1)*1e9); grid on
xlabel('Distance (m)'); ylabel('Photocurrent (nA)'); title('Single \Phi-OTDR trace'); xlim([0 zax(end)]);
savefig_('fig2_phiotdr_trace');

% the static speckle pattern is removed (mean over time) so that only the temporal changes remain
Dz = (D - mean(D,2))*1e9;
figure; imagesc(tax*1e3, zax, Dz); axis xy; colorbar
clim_ = prctile(abs(Dz(:)),99.5);  clim([-clim_ clim_]);  colormap(parula)
xlabel('Time (ms)'); ylabel('Distance (m)'); title('\Phi-OTDR waterfall (mean over time removed)');
savefig_('fig3_waterfall');

%% 3) Localisation: standard deviation over slow time at every position
Ev = std(D,0,2);  Ev([1:2*Nw, end-2*Nw+1:end]) = 0;   % ignore fibre ends
figure; plot(zax, Ev*1e9); grid on
xlabel('Distance (m)'); ylabel('Std over time (nA)'); title('Event localisation'); xlim([0 zax(end)]);
savefig_('fig4_localisation');
[~,k] = max(Ev);
res.loc = zax(k);   res.Ev = Ev;   res.zax = zax;
fprintf('Strongest event detected at %.1f m\n', res.loc);

%% 4) COTDR: differential phase across the event -> vibration waveform
k1 = k - 2*Nw;  k2 = k + Nw;                  % before / after the section
dphi = unwrap(angle(C(k2,:).*conj(C(k1,:)))); % cancels the common laser phase
dphi = dphi - mean(dphi);
figure; plot(tax*1e3, dphi); grid on
xlabel('Time (ms)'); ylabel('\Delta\phi (rad)'); title('Recovered vibration (COTDR)');
savefig_('fig5_recovered_phase');

F = abs(fft(dphi))/Np;  f = (0:Np-1)*f_rep/Np;  half = 1:floor(Np/2);
figure; plot(f(half), 2*F(half)); grid on
xlabel('Frequency (Hz)'); ylabel('|\Delta\phi| (rad)'); title('Vibration spectrum');
savefig_('fig6_spectrum');
[~,m] = max(F(2:floor(Np/2)));
res.amp = (max(dphi)-min(dphi))/2;   res.freq = f(m+1);   res.f = f(half);   res.spec = 2*F(half);
res.dphi = dphi;  res.tax = tax;
% fading indicator: weakest of the two backscatter amplitudes used, relative to the median amplitude
amp = mean(abs(C),2);   res.fade = min(amp([k1 k2]))/median(amp);
% waveform quality: residual of a sine fit at the detected frequency
t = tax(:);   Aq = [sin(2*pi*res.freq*t) cos(2*pi*res.freq*t)];
cf = Aq\dphi(:);   res.resid = std(dphi(:) - Aq*cf);
fprintf('Recovered amplitude = %.2f rad, frequency = %.0f Hz (residual %.2f rad, fading ratio %.2f)\n', ...
        res.amp, res.freq, res.resid, res.fade);
% If dphi is noisy, k1 or k2 fell in a fading point (|C| small): move them by a few samples.
res.D = D;  res.k = k;

%% Local function: To Workspace "Array" logs Ns x 1 x Np (2-D frames) or Np x Ns (1-D vectors)
function X = local_frames(X, Ns)
    X = squeeze(X);
    if size(X,1) ~= Ns, X = X.'; end
end
