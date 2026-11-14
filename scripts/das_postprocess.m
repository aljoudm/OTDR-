%% das_postprocess.m — run after the simulation:  out = sim('das_model'); das_postprocess
%  Expects To Workspace variables in "out":  trace_otdr, trace_dd, trace_coh
%  (save format: Array). Logged as Ns x 1 x Np or Np x Ns -> normalised to Ns x Np.
%  Report-standard figures (no in-figure titles, 8.5 cm single column, 8 pt Helvetica, 300 dpi PNG + vector PDF)
%  are written to <project>/background_febus/figures (or figures/<figsub> when the variable figsub is set in the
%  base workspace); an optional suffix tag is added to the file names.
%  The numbers printed below are also stored in the struct "res" (used by the experiments).

if ~exist('Ns','var') || ~exist('Ts_slow','var'), das_init; end   % parameters missing -> load them
if ~exist('figsub','var'), figsub = ''; end
if ~exist('tag','var'),    tag = '';    end
root_ = fullfile(fileparts(mfilename('fullpath')),'..');
if isempty(figsub), figdir = fullfile(root_,'background_febus','figures'); else, figdir = fullfile(root_,'figures',figsub); end
if ~exist(figdir,'dir'), mkdir(figdir); end
if ~exist('nofig','var'), nofig = false; end                  % nofig = true: compute the numbers only
FW = 8.5;  FS = 8;  FN = 'Helvetica';                         % figure width [cm], font size [pt], font
newfig_ = @(h) figure('Units','centimeters','Position',[2 2 FW h],'Color','w','Visible','off');
savefig_ = @(name) local_save(gcf, figdir, [name tag], nofig);
tofr = @(X) local_frames(X, Ns);              % -> Ns x Np
res  = struct();

zax = (0:Ns-1).'*dz;                          % distance axis [m]
zkm = zax/1e3;
D   = tofr(out.trace_dd);                     % Phi-OTDR intensity  (Ns x Np)
C   = tofr(out.trace_coh);                    % COTDR complex I+jQ  (Ns x Np)
Np  = size(D,2);  tax = (0:Np-1)*Ts_slow;     % slow-time axis [s]
tms = tax*1e3;

%% 1) Conventional OTDR trace: straight line with slope -2*alpha (round trip)
P = tofr(out.trace_otdr);
Pw = max(P(:,1)/R_pd, eps);                   % detected optical power [W]
va = Nw:Nz;                                  % valid samples: pulse fully inside the fibre, before the fibre end
fg = newfig_(6); ax = axes; plot(ax, zkm(va), 10*log10(Pw(va)/1e-3), 'LineWidth',0.8);
xlabel(ax,'Distance (km)'); ylabel(ax,'Backscattered power (dBm)'); xlim(ax,[0 L/1e3]);
yl = 10*log10(Pw(va)/1e-3); ylim(ax,[floor(min(yl)-1) ceil(max(yl)+1)]);
style_(ax,FS,FN,'%.0f','%.0f'); savefig_('fig1_otdr_trace');
pf = polyfit(zax(2*Nw:end-2*Nw), 10*log10(Pw(2*Nw:end-2*Nw)), 1);
res.slope = -pf(1)*1e3;
fprintf('OTDR slope = %.3f dB/km (expected %.3f)\n', res.slope, 2*alpha_dB);   % round trip -> 2x

%% 2) Phi-OTDR: one raw trace (speckle) and the waterfall
fg = newfig_(6); ax = axes; plot(ax, zkm, D(:,1)*1e9, 'LineWidth',0.5);
xlabel(ax,'Distance (km)'); ylabel(ax,'Photocurrent (nA)'); xlim(ax,[0 L/1e3]); ylim(ax,[0 max(D(va,1))*1e9*1.05]);
style_(ax,FS,FN,'%.0f','%.0f'); savefig_('fig2_phiotdr_trace');

% the static speckle pattern is removed (mean over time) so that only the temporal changes remain
Dz = (D - mean(D,2))*1e9;
% colour scale from the rows around the events (global percentile would hide them: events are 10 m of 20 km)
nwin = 150;                                  % zoom: +-150 m around each event
zc = z_v;
clim_ = 0;
for q = 1:numel(zc), w = zax >= zc(q)-nwin & zax <= zc(q)+nwin; clim_ = max(clim_, prctile(abs(Dz(w,:)),99.5,'all')); end
fg = newfig_(9.5); tl = tiledlayout(fg,numel(zc),1,'TileSpacing','compact','Padding','compact');
for q = 1:numel(zc)
    ax = nexttile(tl); w = zax >= zc(q)-nwin & zax <= zc(q)+nwin;
    imagesc(ax, tms, zax(w)/1e3, Dz(w,:)); axis(ax,'xy'); clim(ax,[-clim_ clim_]); colormap(ax,parula);
    ylabel(ax,'Distance (km)'); if q==numel(zc), xlabel(ax,'Time (ms)'); else, set(ax,'XTickLabel',[]); end
    style_(ax,FS,FN,'%.0f','%.2f'); box(ax,'on'); set(ax,'Layer','top');
    xlim(ax,[0 30]);                            % first 30 ms: the 200 / 500 Hz oscillations stay resolved
    text(ax,0.02,0.95,sprintf('(%s)',char('a'+q-1)),'Units','normalized','FontSize',FS+1,'FontName',FN,'FontWeight','bold','VerticalAlignment','top','BackgroundColor','w','Margin',1);
end
cb = colorbar(ax); cb.Layout.Tile = 'east'; cb.Label.String = 'Photocurrent change (nA)'; cb.FontSize = FS; cb.FontName = FN;
savefig_('fig3_waterfall');

%% 3) Localisation: standard deviation over slow time at every position
Ev = std(D,0,2);  Ev([1:2*Nw, end-2*Nw+1:end]) = 0;   % ignore fibre ends
fg = newfig_(6); ax = axes; plot(ax, zkm, Ev*1e9, 'LineWidth',0.6);
xlabel(ax,'Distance (km)'); ylabel(ax,'Std. dev. over time (nA)'); xlim(ax,[0 zkm(end)]);
style_(ax,FS,FN,'%.0f','%.0f'); savefig_('fig4_localisation');
[~,k] = max(Ev);
res.loc = zax(k);   res.Ev = Ev;   res.zax = zax;
fprintf('Strongest event detected at %.1f m\n', res.loc);

%% 4) COTDR: differential phase across the event -> vibration waveform
% before / after the section: within +-Nw samples of the nominal points k-2Nw and k+Nw the sample with the
% strongest mean backscatter amplitude is used (avoids a coherent-fading point; amplitude-based selection)
ampC = mean(abs(C),2);
[~,i1] = max(ampC(k-3*Nw:k-Nw));  k1 = k-3*Nw-1+i1;
[~,i2] = max(ampC(k+Nw:k+2*Nw));  k2 = k+Nw-1+i2;
dphi = unwrap(angle(C(k2,:).*conj(C(k1,:)))); % cancels the common laser phase
dphi = dphi - mean(dphi);
sel = tax <= 0.05;                            % first 50 ms
fg = newfig_(6); ax = axes; plot(ax, tms(sel), dphi(sel), 'LineWidth',0.8);
xlabel(ax,'Time (ms)'); ylabel(ax,'Differential phase (rad)'); xlim(ax,[0 50]);
style_(ax,FS,FN,'%.0f','%.1f'); savefig_('fig5_recovered_phase');

Nfft = 16*Np;                                 % zero padding: finer frequency grid (bin = f_rep/Nfft)
F = abs(fft(dphi,Nfft))/Np;  f = (0:Nfft-1)*f_rep/Nfft;  half = 1:floor(Nfft/2);
fg = newfig_(6); ax = axes; plot(ax, f(half), 2*F(half), 'LineWidth',0.8);
xlabel(ax,'Frequency (Hz)'); ylabel(ax,'Phase amplitude (rad)'); xlim(ax,[0 f(half(end))]);
style_(ax,FS,FN,'%.0f','%.1f'); savefig_('fig6_spectrum');
[~,m] = max(F(2:floor(Nfft/2)));
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
res.C1 = C(k1,:);  res.C2 = C(k2,:);          % the two COTDR samples used (for the fading experiment)
close all

%% Local functions
function X = local_frames(X, Ns)
% To Workspace "Array" logs Ns x 1 x Np (2-D frames) or Np x Ns (1-D vectors)
    X = squeeze(X);
    if size(X,1) ~= Ns, X = X.'; end
end
function style_(ax, fs, fn, xf, yf)
% report style: font, ticks outward, light grid, tick labels with at most 2 decimals
    set(ax,'FontSize',fs,'FontName',fn,'TickDir','out','LineWidth',0.5,'Box','off');
    grid(ax,'on'); ax.GridAlpha = 0.15;
    ax.XAxis.TickLabelFormat = xf;  ax.YAxis.TickLabelFormat = yf;
end
function local_save(fg, figdir, name, nofig)
    if ~nofig
        exportgraphics(fg, fullfile(figdir,[name '.png']), 'Resolution',300);
        exportgraphics(fg, fullfile(figdir,[name '.pdf']), 'ContentType','auto','Resolution',300);
    end
    close(fg);
end
