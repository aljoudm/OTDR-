%% das_init.m — Parameters for the Simulink OTDR / Phi-OTDR / COTDR model
%  Lives in /scripts. The model's InitFcn adds this folder to the path and runs it:
%    Model Settings > Model Properties > Callbacks > InitFcn :
%      addpath(fullfile(fileparts(get_param(bdroot,'FileName')),'..','scripts')); das_init
%  Every block reads its values from these variables (no hard-coded numbers).
%  NOTE: no "clear" here — InitFcn runs in the base workspace and would wipe "out".

rng(1);                                % fixed seed -> repeatable fibre

%% Physical constants and fibre
c        = 2.998e8;                    % speed of light in vacuum [m/s]
n        = 1.468;                      % group index of standard SMF (assumed)
lambda   = 1550e-9;                    % wavelength [m]
L        = 2000;                       % fibre length [m]
alpha_dB = 0.2;                        % attenuation [dB/km] (typical SMF)
alpha_p  = alpha_dB/(10*log10(exp(1)))/1000;   % power attenuation [1/m]

%% Fast time (along the fibre) — Eq. (1) of Shang 2022: z = c*sigma/(2n)
fs   = 100e6;                          % ADC sample rate [S/s]
dz   = c/(2*n*fs);                     % distance per sample (~1.02 m)
Nz   = ceil(L/dz);                     % number of fibre cells
z    = (0:Nz-1).'*dz;                  % cell positions [m]

%% Probe pulse (AOM) — spatial resolution Eq. (5): dz_res = c*Tw/(2n)
Tw      = 100e-9;                      % pulse width [s]
Nw      = round(Tw*fs);                % pulse length in samples
dz_res  = c*Tw/(2*n);                  % spatial resolution (~10.2 m)
Ns      = Nz + Nw;                     % samples per trace (frame length)
p_frame = zeros(Ns,1); p_frame(1:Nw) = 1;      % rectangular pulse frame

%% Slow time (pulse to pulse)
f_rep   = 10e3;                        % pulse repetition frequency [Hz]
Ts_slow = 1/f_rep;                     % Simulink fixed step = one pulse
f_rep_max = c/(2*n*L);                 % ~51 kHz for 2 km
assert(f_rep <= f_rep_max, 'f_rep is above c/(2nL): traces would overlap');
T_sim   = 0.2;                         % stop time -> T_sim*f_rep + 1 pulses (step at t=0 counts)

%% Laser (narrow linewidth, Shang: < 100 kHz)
P_laser = 10e-3;                       % CW power [W]
dnu     = 5e3;                         % linewidth [Hz]
var_phL = 2*pi*dnu*Ts_slow;            % phase-noise variance per pulse [rad^2]

%% Coupler (laser split: signal / LO), EDFA, circulator
k_sig   = 0.99;  k_lo = 0.01;          % 99:1 coupler
G_edfa_dB = 10;                        % EDFA gain [dB]
IL_cir_dB = 0.8;                       % circulator insertion loss per pass [dB]
g_edfa  = sqrt(10^(G_edfa_dB/10));     % FIELD gains (sqrt of power gain)
g_cir   = sqrt(10^(-IL_cir_dB/10));

%% Rayleigh scatterers: one complex Gaussian reflector per cell
S       = 1.5e-3;                      % backscatter capture fraction (typical)
alpha_s = 0.15/(10*log10(exp(1)))/1000;% Rayleigh scattering loss [1/m]
B_cell  = S*alpha_s*dz;                % backscattered power fraction per cell
r       = sqrt(B_cell)*(randn(Nz,1)+1j*randn(Nz,1))/sqrt(2);
att     = exp(-alpha_p*z);             % round-trip FIELD attenuation

%% Vibration events (intruders) — round-trip phase amplitude
z_v   = [1200 1500];                   % start positions [m]
L_v   = [10 10];                       % disturbed lengths [m]
f_v   = [200 500];                     % vibration frequencies [Hz]
Phi0  = [1 0.5];                       % phase amplitudes [rad]
g_vib = zeros(Nz,numel(z_v));          % 0 before, ramps 0->1 inside, 1 after
for e = 1:numel(z_v)
    g_vib(:,e) = min(max((z - z_v(e))/L_v(e),0),1);
end

%% Photodetector
R_pd    = 0.9;                         % responsivity [A/W]
sigma_n = 1e-9;                        % receiver noise current (rms) [A]

%% Processing
GL = 10;                               % gauge length [samples]

fprintf('dz=%.2f m | resolution=%.1f m | Ns=%d | pulses=%d | f_rep_max=%.1f kHz\n', ...
        dz, dz_res, Ns, round(T_sim*f_rep)+1, f_rep_max/1e3);
