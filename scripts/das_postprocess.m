%% das_postprocess.m — run after the simulation:  out = sim('das_model'); das_postprocess
%  Expects To Workspace variables in "out":  trace_otdr, trace_dd, trace_coh
%  (save format: Array). Logged as Ns x 1 x Np or Np x Ns -> normalised to Ns x Np.
%  Figures are saved as PNG into <project>/figures.

if ~exist('Ns','var') || ~exist('Ts_slow','var'), das_init; end   % parameters missing -> load them
figdir = fullfile(fileparts(mfilename('fullpath')),'..','figures');
if ~exist(figdir,'dir'), mkdir(figdir); end
tag = '';                                     % set e.g. tag = '_exp1' before running to name experiment figures
savefig_ = @(name) exportgraphics(gcf, fullfile(figdir,[name tag '.png']), 'Resolution',150);
tofr = @(X) local_frames(X, Ns);              % -> Ns x Np

zax = (0:Ns-1).'*dz;                          % distance axis [m]
D   = tofr(out.trace_dd);                     % Phi-OTDR intensity  (Ns x Np)
C   = tofr(out.trace_coh);                    % COTDR complex I+jQ  (Ns x Np)
Np  = size(D,2);  tax = (0:Np-1)*Ts_slow;     % slow-time axis [s]

%% 1) Conventional OTDR trace: straight line with slope -2*alpha (Eq. power)
if ismember('trace_otdr', out.who)
    P = tofr(out.trace_otdr);
    figure; plot(zax, 10*log10(P(:,1)), 'LineWidth',1); grid on
    xlabel('Distance (m)'); ylabel('Detected power (dB)');
    title('Conventional OTDR trace'); savefig_('fig1_otdr_trace');
    pf = polyfit(zax(2*Nw:end-2*Nw), 10*log10(P(2*Nw:end-2*Nw,1)), 1);
    fprintf('OTDR slope = %.3f dB/km (expected %.3f)\n', -pf(1)*1e3, 2*alpha_dB);   % round trip -> 2x
end

%% 2) Phi-OTDR: one raw trace (speckle) and the waterfall
figure; plot(zax, D(:,1)*1e9); grid on
xlabel('Distance (m)'); ylabel('Photocurrent (nA)'); title('Single \Phi-OTDR trace');
savefig_('fig2_phiotdr_trace');

figure; imagesc(tax*1e3, zax, D*1e9); axis xy; colorbar
xlabel('Time (ms)'); ylabel('Distance (m)'); title('\Phi-OTDR waterfall');
savefig_('fig3_waterfall');

%% 3) Localisation: standard deviation over slow time at every position
Ev = std(D,0,2);  Ev([1:2*Nw, end-2*Nw+1:end]) = 0;   % ignore fibre ends
figure; plot(zax, Ev*1e9); grid on
xlabel('Distance (m)'); ylabel('Std over time (nA)'); title('Event localisation');
savefig_('fig4_localisation');
[~,k] = max(Ev);
fprintf('Strongest event detected at %.1f m\n', zax(k));

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
fprintf('Recovered amplitude = %.2f rad, frequency = %.0f Hz\n', (max(dphi)-min(dphi))/2, f(m+1));
% If dphi is noisy, k1 or k2 fell in a fading point (|C| small): move them by a few samples.

%% Local function: To Workspace "Array" logs Ns x 1 x Np (2-D frames) or Np x Ns (1-D vectors)
function X = local_frames(X, Ns)
    X = squeeze(X);
    if size(X,1) ~= Ns, X = X.'; end
end
