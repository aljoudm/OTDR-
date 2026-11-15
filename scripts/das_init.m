%% das_init.m — Unpacks the parameter struct p (scripts/otdr_params.m) into the variables used by the Simulink blocks
%  Lives in /scripts. The model's InitFcn runs it:
%    Model Settings > Model Properties > Callbacks > InitFcn :
%      addpath(fullfile(fileparts(get_param(bdroot,'FileName')),'..','scripts')); p = otdr_params(); das_init
%  ALL physical values live in otdr_params.m (edit the FEBUS overrides block there). Nothing is defined here
%  except what is derived from p for the block diagram (frames, fibre scatterers, noise variances).
%  NOTE: no "clear" here — InitFcn runs in the base workspace and would wipe "out".

%  Optional overrides for the validation experiments: put a struct called ovr in the base workspace
%  (fields: seed, Tw, f_rep, T_sim, z_v, L_v, f_v, Phi0, sigma_n), e.g. ovr = struct('Tw',50e-9);
if ~exist('ovr','var') || ~isstruct(ovr), ovr = struct(); end
if ~exist('p','var') || ~isstruct(p) || ~isfield(p,'f_s'), p = otdr_params(); end

rng(pick(ovr,'seed',p.seed));          % fixed seed -> repeatable fibre

%% Physical constants and fibre
c        = p.c;   n = p.n_g;   lambda = p.lambda;   L = p.L_fiber_sim;
alpha_dB = p.alpha_dB_km;   alpha_p = p.alpha_lin;

%% Fast time (along the fibre) — Eq. (1) of Shang 2022: z = c*sigma/(2n)
fs   = p.f_s;                          % sample rate [S/s]  (dz = c/(2 n fs) = p.dz_samp)
dz   = c/(2*n*fs);                     % distance per sample [m]
Nz   = ceil(L/dz - 1e-9);              % number of fibre cells
z    = (0:Nz-1).'*dz;                  % cell positions [m]

%% Probe pulse (AOM) — spatial resolution Eq. (5): dz_res = c*Tw/(2n)
Tw      = pick(ovr,'Tw',p.tau_pulse);  % pulse width [s]
Nw      = round(Tw*fs);                % pulse length in samples
dz_res  = c*Tw/(2*n);                  % spatial resolution [m]
Ns      = Nz + Nw;                     % samples per trace (frame length)
p_frame = zeros(Ns,1); p_frame(1:Nw) = 1;      % rectangular pulse frame

%% Slow time (pulse to pulse): ONE Simulink step = ONE pulse (frame-based model), step = 1/f_rep
f_rep   = pick(ovr,'f_rep',p.f_rep);   % pulse repetition frequency [Hz]
Ts_slow = 1/f_rep;
f_rep_max = p.f_rep_max;               % c/(2 n L)
assert(f_rep <= f_rep_max, 'f_rep is above c/(2nL): traces would overlap');
T_sim   = pick(ovr,'T_sim',p.N_pulses/f_rep);  % stop time -> T_sim*f_rep + 1 pulses (step at t=0 counts)
T_rt    = p.T_rt;                      % one-trace time (stop time for a single trace)

%% Laser, coupler, EDFA, circulator (pulse power at the fibre input = p.P0)
P_laser = p.P_laser;                   % CW power [W]
dnu     = p.linewidth;                 % linewidth [Hz]
var_phL = 2*pi*dnu*Ts_slow;            % phase-noise variance per pulse [rad^2]
k_sig   = p.k_sig;  k_lo = p.k_lo;
g_edfa  = p.g_edfa;  g_cir = p.g_cir;  % FIELD gains

%% Rayleigh scatterers: one complex Gaussian reflector per cell
%  backscattered power fraction of the whole pulse = R_bs (Corning, scaled to Tw); spread over the Nw samples
R_bs_pulse = 10^((p.R_bs_dB + 10*log10(Tw/1e-9))/10);
B_cell  = R_bs_pulse/Nw;               % backscattered power fraction per cell
r       = sqrt(B_cell)*(randn(Nz,1)+1j*randn(Nz,1))/sqrt(2);
att     = exp(-alpha_p*z);             % round-trip FIELD attenuation

%% Vibration events (intruders) — round-trip phase amplitude
z_v   = pick(ovr,'z_v',p.z_v);         % start positions [m]
L_v   = pick(ovr,'L_v',p.L_v);         % disturbed lengths [m]
f_v   = pick(ovr,'f_v',p.f_v);         % vibration frequencies [Hz]
Phi0  = pick(ovr,'Phi0',p.Phi0);       % phase amplitudes [rad]
g_vib = zeros(Nz,numel(z_v));          % 0 before, ramps 0->1 inside, 1 after
for e = 1:numel(z_v)
    g_vib(:,e) = min(max((z - z_v(e))/L_v(e),0),1);
end

%% Photodetector (noise currents derived in otdr_params from P_noise)
R_pd       = p.R_pd;
sigma_n_dd  = pick(ovr,'sigma_n',p.sigma_n_dd);     % OTDR and Phi-OTDR (direct detection) [A rms]
sigma_n_coh = pick(ovr,'sigma_n',p.sigma_n_coh);    % COTDR, per I and Q [A rms]

%% Processing
GL = p.GL;                             % gauge length [samples]

fprintf('dz=%.2f m | resolution=%.1f m | Ns=%d | pulses=%d | f_rep=%.2f kHz (max %.2f) | T_rt=%.1f us\n', ...
        dz, dz_res, Ns, round(T_sim*f_rep)+1, f_rep/1e3, f_rep_max/1e3, T_rt*1e6);

function v = pick(o, name, default)
%PICK  value of the override field if present, else the default
if isfield(o,name), v = o.(name); else, v = default; end
end
