function p = otdr_params()
%OTDR_PARAMS  Single source of all physical / signal parameters of the OTDR, Phi-OTDR and COTDR model.
%  Interrogator: FEBUS A1-NEO (datasheet rev. 20260618); consistent with repo DAS-Simulation, branch febus-a1neo.
%  Called by the model InitFcn:   p = otdr_params(); das_init
%  Source tags:  [FEBUS] [DATASHEET] [DERIVED] [CHOSEN: reason] [ASSUMED: source] [SIM SETTING]
%  When vendor data arrives, edit ONLY the FEBUS overrides block below (NaN = not received yet).

p = struct();

%% ----- FEBUS overrides: NaN = not received yet; if set, replaces the value -----
p.tau_pulse_febus = NaN;   % [s]  pulse width                                  [FEBUS]
p.dz_res_febus    = NaN;   % [m]  spatial resolution                           [FEBUS]
p.f_s_febus       = NaN;   % [Hz] sampling rate                                [FEBUS]
p.f_rep_febus     = NaN;   % [Hz] pulse repetition rate                        [FEBUS]
p.P0_febus        = NaN;   % [W]  peak pulse power                             [FEBUS]
p.linewidth_febus = NaN;   % [Hz] laser linewidth                              [FEBUS]

%% ----- [DATASHEET] FEBUS A1-NEO -----
p.lambda      = 1550e-9;   % [m]                                               [DATASHEET]
p.L_fiber_sim = 20e3;      % [m] 20 km range option (same as DAS-Simulation)   [DATASHEET]
p.alpha_dB_km = 0.2;       % [dB/km] attenuation assumed by the datasheet      [DATASHEET]
p.dz_samp     = 2;         % [m] channel spacing ("typically every 2 m")       [DATASHEET]
p.dz_res      = 10;        % [m] [CHOSEN: within datasheet range 1-50 m; resolution study in DAS-Simulation
                           %  showed 2 m collapses SNR; 10 m matches Zeng 2024 perimeter DAS]

%% ----- [ASSUMED: source] -----
p.n_g       = 1.4682;      % [ASSUMED: Corning SMF-28 Ultra (G.652.D) datasheet PI-1424]
p.R_bs_dB   = -82;         % [dB] Rayleigh backscatter coeff., 1 ns pulse, 1550 nm [ASSUMED: Corning PI-1424]
p.P0        = 0.1;         % [W] peak pulse power [ASSUMED: Thevenaz 2025; MI limit, Liu 2016]
p.linewidth = 3e3;         % [Hz] narrow-linewidth laser for Phi-OTDR/COTDR [ASSUMED: Zeng 2024; Juarez 2005]
% Conventional OTDR keeps a BROADBAND source (Liu 2016: OTDR uses a broadband source, Phi-OTDR a narrow-linewidth
% laser). In the model this is the incoherent fibre block (powers add, no phase, no linewidth parameter).
% [ASSUMED: Liu 2016] (unchanged from the Shang-based model)
p.P_noise_ref = 0.2e-9;    % [W]  coherent noise floor at B_ref: 10 dB SNR at ~2 nW [ASSUMED: Thevenaz 2025]
p.B_ref       = 100e6;     % [Hz] reference bandwidth of P_noise_ref            [ASSUMED: Thevenaz 2025]
p.xi          = 0.78;      % [-]  strain-optic coefficient K_eps                [ASSUMED: He & Liu 2021] (not used by the model)

%% ----- Shang-based values with no other source (kept from the previous model) -----
p.k_sig     = 0.99;        % [-]  99:1 coupler, signal arm                      [ASSUMED: Shang 2022]
p.k_lo      = 0.01;        % [-]  99:1 coupler, local-oscillator arm            [ASSUMED: Shang 2022]
p.G_edfa_dB = 10;          % [dB] EDFA gain                                     [ASSUMED: Shang 2022]
p.IL_cir_dB = 0.8;         % [dB] circulator insertion loss per pass            [ASSUMED: Shang 2022]
p.R_pd      = 0.9;         % [A/W] photodetector responsivity                   [ASSUMED: Shang 2022]
p.z_v       = [12e3 15e3]; % [m]  vibration start positions [CHOSEN: 12 and 15 km, the former 1.2/1.5 km events scaled to the 20 km fibre]
p.L_v       = [10 10];     % [m]  disturbed length                              [ASSUMED: Shang 2022]
p.f_v       = [200 500];   % [Hz] vibration frequencies (< f_vib_max)           [ASSUMED: Shang 2022]
p.Phi0      = [1 0.5];     % [rad] vibration phase amplitudes                   [ASSUMED: Shang 2022]
p.GL        = 10;          % [samples] gauge length (20 m at 2 m spacing)       [ASSUMED: Shang 2022]

%% ----- [SIM SETTING] purely numerical choices -----
p.seed        = 1;         % fibre / laser random seed                          [SIM SETTING]
p.seed_noise  = [110000 120000 130000 140000];  % noise-block seed offsets (OTDR, dd, I, Q)  [SIM SETTING]
p.seed_laser  = 1;         % laser phase-noise block seed                       [SIM SETTING]
p.N_pulses    = 1000;      % pulses of one Phi-OTDR / COTDR time series         [SIM SETTING]
p.pulse_shape = 'rect';    % rectangular probe pulse (frame of ones)            [SIM SETTING]
p.sine_phase  = 0;         % initial phase of the vibration sources [rad]       [SIM SETTING]
p.f_rep_frac  = 0.9;       % f_rep as a fraction of f_rep_max                   [SIM SETTING]

%% ----- [DERIVED] (overrides applied first) -----
p.c = 299792458;                                   % [m/s] speed of light in vacuum [DERIVED: exact SI value]
if ~isnan(p.P0_febus),        p.P0        = p.P0_febus;        end
if ~isnan(p.linewidth_febus), p.linewidth = p.linewidth_febus; end
if ~isnan(p.f_s_febus),       p.dz_samp   = p.c/(2*p.n_g*p.f_s_febus); end     % dz_samp from the FEBUS sample rate
% Override logic: tau given and dz_res not -> dz_res = c*tau/(2 n_g); otherwise values are used as given
if ~isnan(p.dz_res_febus),    p.dz_res    = p.dz_res_febus;    end
if ~isnan(p.tau_pulse_febus)
    p.tau_pulse = p.tau_pulse_febus;
    if isnan(p.dz_res_febus), p.dz_res = p.c*p.tau_pulse/(2*p.n_g); end
else
    p.tau_pulse = 2*p.n_g*p.dz_res/p.c;            % ~97.9 ns (dz = 0.5 c Tp / n_g, Liu 2016)  [DERIVED]
end
p.v_g       = p.c/p.n_g;                           % [m/s] group velocity                      [DERIVED]
p.f_s       = p.c/(2*p.n_g*p.dz_samp);             % ~51 MHz                                   [DERIVED]
p.T_rt      = 2*p.n_g*p.L_fiber_sim/p.c;           % ~196 us round trip                        [DERIVED]
p.f_rep_max = 1/p.T_rt;                            %                                           [DERIVED]
if ~isnan(p.f_rep_febus), p.f_rep = p.f_rep_febus; else, p.f_rep = p.f_rep_frac*p.f_rep_max; end  % ~4.59 kHz [DERIVED]
p.f_vib_max = p.f_rep/2;                           % Nyquist (Wang 2020)                       [DERIVED]
p.B_rx      = 1/p.tau_pulse;                       % [Hz] receiver bandwidth                   [DERIVED]
p.P_noise   = p.P_noise_ref*(p.B_rx/p.B_ref);      % [W] noise ∝ bandwidth (Palmieri 2013)     [DERIVED]
p.alpha_lin = p.alpha_dB_km/(10*log10(exp(1)))/1e3;% [1/m] power attenuation                  [DERIVED]
p.T_stop    = p.N_pulses/p.f_rep;                  % [s] stop time (N pulses + t=0 pulse)      [DERIVED]
assert(p.f_rep < p.f_rep_max)
assert(all(p.f_v < p.f_vib_max), 'vibration frequency above f_rep/2: aliasing')

%% ----- [DERIVED] model-chain quantities (power budget of the Simulink blocks) -----
p.g_edfa = sqrt(10^(p.G_edfa_dB/10));              % field gain                                [DERIVED]
p.g_cir  = sqrt(10^(-p.IL_cir_dB/10));             % field gain per circulator pass            [DERIVED]
% pulse power at the fibre input equals P0:  P_laser * k_sig * g_edfa^2 * g_cir^2 = P0
p.P_laser = p.P0/(p.k_sig*p.g_edfa^2*p.g_cir^2);   % [W] CW laser power                        [DERIVED]
p.P_LO    = p.k_lo*p.P_laser;                      % [W] local-oscillator power                [DERIVED]
p.var_phL_fn = @(Ts) 2*pi*p.linewidth*Ts;          % phase-noise variance per pulse [rad^2]    [DERIVED]
% Backscattered power fraction of one pulse (Corning R_bs, scaled to the pulse width)
p.R_bs_pulse = 10^((p.R_bs_dB + 10*log10(p.tau_pulse/1e-9))/10);  %                           [DERIVED]
% Backscatter: P_bs(z) = P0 * R_bs_pulse * 10^(-2*alpha_dB_km*z/1e4)   (z in m)
p.P_bs = @(z) p.P0*p.R_bs_pulse*10.^(-2*p.alpha_dB_km*z/1e4);
% Receiver noise currents (power-equivalent, referred to the receiver input) [DERIVED]
%   direct detection / OTDR : noise-equivalent power P_noise   -> sigma = R_pd*P_noise
%   coherent (I and Q)      : SNR = R^2 P_R P_LO/(2 sigma^2) = P_R/P_noise -> sigma = R_pd*sqrt(P_LO*P_noise/2)
p.sigma_n_dd  = p.R_pd*p.P_noise;
p.sigma_n_coh = p.R_pd*sqrt(p.P_LO*p.P_noise/2);
p.SNR_coh_fn  = @(z) p.P_bs(z)/p.P_noise;          % expected coherent SNR (power ratio)       [DERIVED]
end
