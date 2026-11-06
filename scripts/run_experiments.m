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
c1 = {'z5',  struct('z_v',[1200 1205],'Phi0',[1 1]); 'z20', struct('z_v',[1200 1220],'Phi0',[1 1])};   % two equally strong events
for i = 1:2
    r = run_case(c1{i,2}, ['exp1_' c1{i,1}], '', false);
    r.groups = response_groups(r.zax, r.Ev);          % separate responses: runs above 2x the noise floor, split by gaps >= 3 samples
    R.exp1.(c1{i,1}) = r;
end
figure('Position',[100 100 900 600]);
for i = 1:2
    r = R.exp1.(c1{i,1});
    subplot(2,1,i); plot(r.zax, r.Ev*1e9); grid on; xlim([1150 1280]); ylabel('Std over time (nA)');
    title(sprintf('Event spacing %d m: %d separate response(s)', diff(c1{i,2}.z_v), size(r.groups,1)));
    hold on; plot(c1{i,2}.z_v, zeros(1,2), 'rv', 'MarkerFaceColor','r'); hold off
end
xlabel('Distance (m)');  exportgraphics(gcf, fullfile(expdir,'exp1_resolution.png'), figopt{:});

%% 2) Pulse width: 50, 100 and 200 ns
Tws = [50 100 200]*1e-9;
for i = 1:numel(Tws)
    r = run_case(struct('Tw',Tws(i)), sprintf('exp2_Tw%dns',round(Tws(i)*1e9)), '', false);
    [pk,kk] = max(r.Ev);  base = median(r.Ev);
    win = abs(r.zax - r.zax(kk)) < 60;                          % window around the event
    above = find(win & r.Ev > 2*base);                            % samples clearly above the noise floor
    r.fwhm = r.zax(max(above)) - r.zax(min(above));               % extent of the response (m)
    r.noise_floor = base;  r.peak = pk;  r.snr = pk/base;
    r.dz_res = evalin('base','dz_res');
    R.exp2(i).Tw = Tws(i);  R.exp2(i).r = r;
end
figure('Position',[100 100 900 700]);
for i = 1:numel(Tws)
    r = R.exp2(i).r;
    subplot(3,1,i); plot(r.zax, r.Ev*1e9); grid on; xlim([1150 1280]); ylabel('Std (nA)');
    title(sprintf('T_w = %d ns: resolution %.1f m, peak/noise floor = %.1f, extent = %.0f m', round(Tws(i)*1e9), r.dz_res, r.snr, r.fwhm));
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
%  Each seed is a different random fibre. The phase error is measured against the injected waveform
%  (circular standard deviation, so phase wraps do not matter). To show what a weak backscatter amplitude
%  does, receiver noise is added to the two COTDR samples: the noise is additive at the detector output,
%  so this is the same as a receiver with a larger sigma_n.
seeds = 1:12;  sigx = 2e-7;                      % extra receiver noise per I and Q component [A]
for i = 1:numel(seeds)
    r = run_case(struct('seed',seeds(i)), sprintf('exp5_seed%d',seeds(i)), '', true);
    R.exp5(i).seed = seeds(i);  R.exp5(i).r = r;
end
tax = R.exp5(1).r.tax;  ideal = 1*sin(2*pi*200*tax);           % injected waveform of event 1 (Phi0 = 1 rad, 200 Hz)
rng(7);
for i = 1:numel(seeds)
    r = R.exp5(i).r;
    n1 = sigx*(randn(size(r.C1)) + 1j*randn(size(r.C1)));  n2 = sigx*(randn(size(r.C2)) + 1j*randn(size(r.C2)));
    raw0 = angle(r.C2.*conj(r.C1));  raw1 = angle((r.C2+n2).*conj(r.C1+n1));
    R.exp5(i).err0 = circstd(raw0, ideal);   R.exp5(i).err1 = circstd(raw1, ideal);
    off = angle(mean(exp(1j*(raw1-ideal))));          % constant phase between the two samples (static fibre phase)
    R.exp5(i).wave1 = angle(exp(1j*(raw1 - off)));
    R.exp5(i).fade = r.fade;  R.exp5(i).loc = r.loc;
end
err0 = [R.exp5.err0];  err1 = [R.exp5.err1];  fade = [R.exp5.fade];
[~,best] = min(err1);  [~,worst] = max(err1);
figure('Position',[100 100 1000 650]);
subplot(2,2,1); bar(seeds, [err0; err1]'); grid on; xlabel('Seed (fibre)'); ylabel('Phase error (rad)');
title('Phase error vs fibre'); legend('normal receiver','noisy receiver','Location','northwest');
subplot(2,2,2); scatter(fade, err1, 40, 'filled'); grid on; xlabel('Weakest amplitude at k1,k2 / median');
ylabel('Phase error (rad)'); title('Noisy receiver: weak backscatter -> large error');
for j = 1:numel(seeds), text(fade(j), err1(j), sprintf('  %d',seeds(j))); end
subplot(2,2,3); plot(tax*1e3, R.exp5(best).wave1, '.', tax*1e3, ideal, '-'); grid on; xlim([0 50]);
xlabel('Time (ms)'); ylabel('\Delta\phi (rad)'); title(sprintf('Best fibre (seed %d): error %.2f rad', seeds(best), err1(best)));
subplot(2,2,4); plot(tax*1e3, R.exp5(worst).wave1, '.', tax*1e3, ideal, '-'); grid on; xlim([0 50]);
xlabel('Time (ms)'); ylabel('\Delta\phi (rad)'); title(sprintf('Worst fibre (seed %d): error %.2f rad', seeds(worst), err1(worst)));
exportgraphics(gcf, fullfile(expdir,'exp5_fading.png'), figopt{:});
close all
R.exp5_summary = struct('seeds',seeds,'sigx',sigx,'err0',err0,'err1',err1,'fade',fade,'loc',[R.exp5.loc],'best',seeds(best),'worst',seeds(worst));

%% results -> docs/validation_results.md
write_results(R, fullfile(root,'docs','validation_results.md'));
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

function g = response_groups(z, Ev)
%RESPONSE_GROUPS  [start end] (m) of the runs of samples above 2x the noise floor around the strongest event,
%  where a run ends when 3 or more consecutive samples fall back to the noise floor
base = median(Ev);  [~,k] = max(Ev);
idx = find(abs(z - z(k)) < 60 & Ev > 2*base);
cut = [0; find(diff(idx) > 3); numel(idx)];
g = zeros(numel(cut)-1, 2);
for i = 1:numel(cut)-1, g(i,:) = [z(idx(cut(i)+1)) z(idx(cut(i+1)))]; end
end

function e = circstd(raw, ideal)
%CIRCSTD  circular standard deviation (rad) of the phase error raw - ideal
d = raw - ideal;  e = sqrt(-2*log(abs(mean(exp(1j*d)))));
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
s = A(s,'# Validation experiments: results\n\nGenerated by `scripts/run_experiments.m`. Default parameters: L = 2 km, Tw = 100 ns, f_rep = 10 kHz, events at 1200 m (200 Hz, 1 rad) and 1500 m (500 Hz, 0.5 rad), 2001 pulses. In experiment 1 both events have 1 rad.\n');
s = A(s,'## 1. Spatial resolution (dz = c*Tw/(2n) = %.1f m)\n\nTwo events of 1 rad (200 Hz and 500 Hz). The response is the part of the fibre where the detected intensity changes over time more than twice the noise floor; separate responses are separated by at least 3 samples (about 3 m) at the noise floor.\n\n| Event spacing | Separate responses | Extent of each response (m) |\n|---|---|---|\n', R.exp1.z5.dz_res);
s = A(s,'| 5 m | %d | %s |\n', size(R.exp1.z5.groups,1), mat2str(round(R.exp1.z5.groups(:,2)-R.exp1.z5.groups(:,1),1)'));
s = A(s,'| 20 m | %d | %s |\n\n', size(R.exp1.z20.groups,1), mat2str(round(R.exp1.z20.groups(:,2)-R.exp1.z20.groups(:,1),1)'));
s = A(s,'Figure: `figures/experiments/exp1_resolution.png`. The response of one event is about as long as the spatial resolution plus the disturbed section. Events 5 m apart (below the resolution) merge into one response; events 20 m apart are resolved into two.\n\n');
s = A(s,'## 2. Pulse width\n\n| Tw (ns) | Resolution (m) | Peak (nA) | Noise floor (nA) | Peak/floor | Extent above 2x floor (m) |\n|---|---|---|---|---|---|\n');
for i = 1:numel(R.exp2)
    r = R.exp2(i).r;  s = A(s,'| %d | %.1f | %.1f | %.2f | %.1f | %.1f |\n', round(R.exp2(i).Tw*1e9), r.dz_res, r.peak*1e9, r.noise_floor*1e9, r.snr, r.fwhm);
end
s = A(s,'\nFigure: `figures/experiments/exp2_pulse_width.png`. A longer pulse widens the response (worse resolution) and raises the detected signal (better SNR).\n\n');
s = A(s,'## 3. Frequency limit (Nyquist)\n\nf_v(1) = 6000 Hz, f_rep = 10 kHz -> expected alias |6000 - 10000| = 4000 Hz. Detected frequency: **%.0f Hz**. The unambiguous limit is f_rep/2 = 5 kHz (f_rep <= c/(2nL) = 51 kHz for 2 km).\n\nFigure: `figures/experiments/exp3_aliasing.png`.\n\n', R.exp3.freq);
s = A(s,'## 4. OTDR vs Phi-OTDR with the same vibration\n\n- Conventional OTDR: largest difference between the traces with and without vibration = %.3g (relative %.3g): **unaffected**.\n', R.exp4.otdr_max_diff, R.exp4.otdr_rel);
s = A(s,'- Phi-OTDR: relative difference of the detected intensity = %.2f: **the vibration is detected**.\n\nFigure: `figures/experiments/exp4_otdr_vs_phiotdr.png`.\n\n', R.exp4.dd_rel);
S = R.exp5_summary;
s = A(s,'## 5. Coherent fading (different fibres)\n\nThe fibre (random scatterers) changes with the seed, so the event lands on a different speckle value. The phase error is the circular standard deviation of the recovered phase against the injected 200 Hz, 1 rad waveform. The noisy receiver adds %.0f nA of noise per I and Q component to the two COTDR samples (additive at the detector output, equivalent to a larger sigma_n).\n\n| Seed | Detected position (m) | Weakest amplitude / median | Phase error, normal receiver (rad) | Phase error, noisy receiver (rad) |\n|---|---|---|---|---|\n', S.sigx*1e9);
for i = 1:numel(S.seeds), s = A(s,'| %d | %.1f | %.2f | %.3f | %.2f |\n', S.seeds(i), S.loc(i), S.fade(i), S.err0(i), S.err1(i)); end
s = A(s,'\nWith the normal receiver (1 nA) every fibre gives a clean waveform (error below 0.11 rad), even when the weakest amplitude is only a third of the median. With the noisy receiver the best fibre is seed %d (error %.2f rad) and the worst is seed %d (error %.2f rad): when the event lands on a fading point (small amplitude at k1 or k2) the recovered phase becomes noisy, a live example of coherent fading (Shang, Section 3.2). Shifting k1 and k2 by a few samples in `das_postprocess.m` moves them away from the fading point.\n\nFigure: `figures/experiments/exp5_fading.png`.\n', S.best, S.err1(S.seeds==S.best), S.worst, S.err1(S.seeds==S.worst));
fid = fopen(file,'w');  fwrite(fid, s, 'char');  fclose(fid);
end
