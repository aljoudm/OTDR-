%% run_experiments.m — the five validation experiments (run from the model folder or with scripts/ on the path)
%    run_experiments
%  Each experiment changes parameters through the override struct "ovr" read by das_init, runs the
%  simulation, runs das_postprocess and stores the numbers. Comparison figures go to
%  figures/experiments/, the standard six figures of every case to figures/experiments/<case>/.
%  The results are written to docs/validation_results.md.

root = fullfile(fileparts(mfilename('fullpath')),'..');
expdir = fullfile(root,'figures','experiments');
if ~exist(expdir,'dir'), mkdir(expdir); end
R = struct();                                                   % results
figopt = {'Resolution',150};

%% 1) Spatial resolution: two events 5 m apart (below dz_res ~ 10 m) and 20 m apart
c1 = {'z5',  struct('z_v',[1200 1205]); 'z20', struct('z_v',[1200 1220])};
for i = 1:2
    r = run_case(c1{i,2}, ['exp1_' c1{i,1}], '', false);
    r.clusters = clusters(r.zax, r.Ev, 5e-9, 8);
    R.exp1.(c1{i,1}) = r;
end
figure('Position',[100 100 900 600]);
for i = 1:2
    r = R.exp1.(c1{i,1});
    subplot(2,1,i); plot(r.zax, r.Ev*1e9); grid on; xlim([1150 1280]); ylabel('Std over time (nA)');
    title(sprintf('Event spacing %d m: %d peak(s) found', diff(c1{i,2}.z_v), numel(r.clusters)));
    hold on; plot(c1{i,2}.z_v, zeros(1,2), 'rv', 'MarkerFaceColor','r'); hold off
end
xlabel('Distance (m)');  exportgraphics(gcf, fullfile(expdir,'exp1_resolution.png'), figopt{:});

%% 2) Pulse width: 50, 100 and 200 ns
Tws = [50 100 200]*1e-9;
for i = 1:numel(Tws)
    r = run_case(struct('Tw',Tws(i)), sprintf('exp2_Tw%dns',round(Tws(i)*1e9)), '', false);
    [pk,kk] = max(r.Ev);  base = median(r.Ev);
    half = pk - (pk-base)/2;                                     % full width at half maximum of the peak
    lo = kk; while lo > 1 && r.Ev(lo) > half, lo = lo - 1; end
    hi = kk; while hi < numel(r.Ev) && r.Ev(hi) > half, hi = hi + 1; end
    r.fwhm = r.zax(hi) - r.zax(lo);  r.noise_floor = base;  r.peak = pk;  r.snr = pk/base;
    r.dz_res = evalin('base','dz_res');
    R.exp2(i).Tw = Tws(i);  R.exp2(i).r = r;
end
figure('Position',[100 100 900 700]);
for i = 1:numel(Tws)
    r = R.exp2(i).r;
    subplot(3,1,i); plot(r.zax, r.Ev*1e9); grid on; xlim([1150 1280]); ylabel('Std (nA)');
    title(sprintf('T_w = %d ns: resolution %.1f m, peak/noise floor = %.1f, FWHM = %.1f m', round(Tws(i)*1e9), r.dz_res, r.snr, r.fwhm));
end
xlabel('Distance (m)');  exportgraphics(gcf, fullfile(expdir,'exp2_pulse_width.png'), figopt{:});

%% 3) Frequency limit: f_v(1) = 6000 Hz with f_rep = 10 kHz (Nyquist limit 5 kHz)
r = run_case(struct('f_v',[6000 500]), 'exp3_aliasing', '', false);
R.exp3 = r;
figure('Position',[100 100 900 450]);
plot(r.f, r.spec); grid on; hold on
xline(4000,'r--','alias 4000 Hz'); xline(5000,'k:','Nyquist f_{rep}/2');
xlabel('Frequency (Hz)'); ylabel('|\Delta\phi| (rad)');
title(sprintf('Vibration at 6000 Hz sampled at f_{rep} = 10 kHz: peak found at %.0f Hz', r.freq));
exportgraphics(gcf, fullfile(expdir,'exp3_aliasing.png'), figopt{:});

%% 4) OTDR vs Phi-OTDR with the same vibration (on and off)
on  = run_case(struct(), 'exp4_vibration_on',  '', false, true);
off = run_case(struct('Phi0',[0 0]), 'exp4_vibration_off', '', false, true);
R.exp4.otdr_max_diff = max(abs(on.otdr(:) - off.otdr(:)));
R.exp4.otdr_rel = R.exp4.otdr_max_diff / max(abs(on.otdr(:)));
R.exp4.dd_rel   = max(abs(on.D(:) - off.D(:))) / max(abs(on.D(:)));
sO_on = std(on.otdr,0,2);  sO_off = std(off.otdr,0,2);
figure('Position',[100 100 900 600]);
subplot(2,1,1); plot(on.zax, sO_on*1e9); hold on; plot(off.zax, sO_off*1e9,'--'); grid on; xlim([0 2000]);
ylabel('Std over time (nA)'); legend('vibration on','vibration off'); title('Conventional OTDR: unaffected by the vibration');
subplot(2,1,2); plot(on.zax, std(on.D,0,2)*1e9); hold on; plot(off.zax, std(off.D,0,2)*1e9,'--'); grid on; xlim([0 2000]);
xlabel('Distance (m)'); ylabel('Std over time (nA)'); legend('vibration on','vibration off'); title('\Phi-OTDR: the vibration is detected');
exportgraphics(gcf, fullfile(expdir,'exp4_otdr_vs_phiotdr.png'), figopt{:});

%% 5) Coherent fading: different fibres (seeds)
seeds = 1:12;
for i = 1:numel(seeds)
    r = run_case(struct('seed',seeds(i)), sprintf('exp5_seed%d',seeds(i)), '', true);
    R.exp5(i).seed = seeds(i);  R.exp5(i).r = r;
end
resid = arrayfun(@(e) e.r.resid, R.exp5);   fade = arrayfun(@(e) e.r.fade, R.exp5);
amp = arrayfun(@(e) e.r.amp, R.exp5);       loc = arrayfun(@(e) e.r.loc, R.exp5);
[~,best] = min(resid);  [~,worst] = max(resid);
figure('Position',[100 100 1000 650]);
subplot(2,2,1); bar(seeds, resid); grid on; xlabel('Seed (fibre)'); ylabel('Residual (rad)'); title('Waveform error vs seed');
subplot(2,2,2); scatter(fade, resid, 40, 'filled'); grid on; xlabel('Weakest |C| at k1,k2 / median |C|'); ylabel('Residual (rad)');
title('Fading: weak backscatter -> noisy phase');
for j = 1:numel(seeds), text(fade(j), resid(j), sprintf('  %d',seeds(j))); end
subplot(2,2,3); plot(R.exp5(best).r.tax*1e3, R.exp5(best).r.dphi); grid on; xlim([0 50]);
xlabel('Time (ms)'); ylabel('\Delta\phi (rad)'); title(sprintf('Best fibre (seed %d): residual %.2f rad', seeds(best), resid(best)));
subplot(2,2,4); plot(R.exp5(worst).r.tax*1e3, R.exp5(worst).r.dphi); grid on; xlim([0 50]);
xlabel('Time (ms)'); ylabel('\Delta\phi (rad)'); title(sprintf('Worst fibre (seed %d): residual %.2f rad', seeds(worst), resid(worst)));
exportgraphics(gcf, fullfile(expdir,'exp5_fading.png'), figopt{:});
close all
R.exp5_summary = struct('seeds',seeds,'resid',resid,'fade',fade,'amp',amp,'loc',loc,'best',seeds(best),'worst',seeds(worst));

%% results -> docs/validation_results.md
write_results(R, fullfile(root,'docs','validation_results.md'));
save(fullfile(root,'docs','validation_results.mat'),'R');
evalin('base','clear ovr figsub tag nofig');
fprintf('All experiments done.\n');

%% ------------------------------------------------------------------ helpers
function r = run_case(ovr, sub, tag, nofig, keep)
%RUN_CASE  one simulation + das_postprocess with the given override struct
assignin('base','ovr',ovr);  assignin('base','figsub',fullfile('experiments',sub));
assignin('base','tag',tag);  assignin('base','nofig',nofig);
out = sim('das_model');   assignin('base','out',out);
evalin('base','das_postprocess; close all');
r = evalin('base','res');
if nargin >= 5 && keep
    Ns = evalin('base','Ns');
    X = squeeze(out.trace_otdr);  if size(X,1) ~= Ns, X = X.'; end
    r.otdr = X;
end
r.Tsim = evalin('base','T_sim');  r.dz_res = evalin('base','dz_res');
fprintf('%-18s loc %.1f m | amp %.2f rad | f %.0f Hz | resid %.2f | fade %.2f\n', sub, r.loc, r.amp, r.freq, r.resid, r.fade);
end

function c = clusters(z, Ev, thr, gap)
%CLUSTERS  positions of the peaks of Ev above thr, merged when closer than gap metres
idx = find(Ev > thr);  c = [];
while ~isempty(idx)
    grp = idx(z(idx) - z(idx(1)) <= gap);  [~,m] = max(Ev(grp));  c(end+1) = z(grp(m)); %#ok<AGROW>
    idx(ismember(idx,grp)) = [];
end
end

function write_results(R, file)
s = '';  A = @(s,varargin) [s sprintf(varargin{:})];
s = A(s,'# Validation experiments: results\n\nGenerated by `scripts/run_experiments.m`. Default parameters: L = 2 km, Tw = 100 ns, f_rep = 10 kHz, events at 1200 m (200 Hz, 1 rad) and 1500 m (500 Hz, 0.5 rad), 2001 pulses.\n');
s = A(s,'## 1. Spatial resolution (dz = c*Tw/(2n) = %.1f m)\n\n| Event spacing | Peaks found | Positions (m) |\n|---|---|---|\n', R.exp1.z5.dz_res);
s = A(s,'| 5 m | %d | %s |\n', numel(R.exp1.z5.clusters), mat2str(round(R.exp1.z5.clusters,1)));
s = A(s,'| 20 m | %d | %s |\n\n', numel(R.exp1.z20.clusters), mat2str(round(R.exp1.z20.clusters,1)));
s = A(s,'Figure: `figures/experiments/exp1_resolution.png`. Events closer than the resolution merge into one peak; farther apart they are resolved.\n\n');
s = A(s,'## 2. Pulse width\n\n| Tw (ns) | Resolution (m) | Peak (nA) | Noise floor (nA) | Peak/floor | FWHM (m) |\n|---|---|---|---|---|---|\n');
for i = 1:numel(R.exp2)
    r = R.exp2(i).r;  s = A(s,'| %d | %.1f | %.1f | %.2f | %.1f | %.1f |\n', round(R.exp2(i).Tw*1e9), r.dz_res, r.peak*1e9, r.noise_floor*1e9, r.snr, r.fwhm);
end
s = A(s,'\nFigure: `figures/experiments/exp2_pulse_width.png`. A longer pulse widens the peak (worse resolution) and raises the detected signal (better SNR).\n\n');
s = A(s,'## 3. Frequency limit (Nyquist)\n\nf_v(1) = 6000 Hz, f_rep = 10 kHz -> expected alias |6000 - 10000| = 4000 Hz. Detected frequency: **%.0f Hz**. The unambiguous limit is f_rep/2 = 5 kHz (f_rep <= c/(2nL) = 51 kHz for 2 km).\n\nFigure: `figures/experiments/exp3_aliasing.png`.\n\n', R.exp3.freq);
s = A(s,'## 4. OTDR vs Phi-OTDR with the same vibration\n\n- Conventional OTDR: largest difference between the traces with and without vibration = %.3g (relative %.3g): **unaffected**.\n', R.exp4.otdr_max_diff, R.exp4.otdr_rel);
s = A(s,'- Phi-OTDR: relative difference of the detected intensity = %.2f: **the vibration is detected**.\n\nFigure: `figures/experiments/exp4_otdr_vs_phiotdr.png`.\n\n', R.exp4.dd_rel);
S = R.exp5_summary;
s = A(s,'## 5. Coherent fading (different fibres)\n\n| Seed | Detected position (m) | Amplitude (rad) | Weakest |C| / median | Residual (rad) |\n|---|---|---|---|---|\n');
for i = 1:numel(S.seeds), s = A(s,'| %d | %.1f | %.2f | %.2f | %.2f |\n', S.seeds(i), S.loc(i), S.amp(i), S.fade(i), S.resid(i)); end
s = A(s,'\nBest seed: %d, worst seed: %d. A low weakest-|C| ratio (the event lands on a fading point) goes with a noisy recovered phase; shifting k1/k2 by a few samples in `das_postprocess.m` restores it.\n\nFigure: `figures/experiments/exp5_fading.png`.\n', S.best, S.worst);
fid = fopen(file,'w');  fwrite(fid, s, 'char');  fclose(fid);
end
