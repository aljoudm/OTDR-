function run_febus()
%RUN_FEBUS  Verify the parameters, run the model (OTDR, Phi-OTDR, COTDR in one run), print the final
%  parameter table with source tags and regenerate the report figures in background_febus/figures.
%  Simulink's code-build path must stay below 260 characters: the cache folder is moved to C:/sl.
here = fileparts(mfilename('fullpath'));  addpath(here);
verify_params();                                           % expected P_bs and SNR first
if ~exist('C:/sl','dir'), mkdir('C:/sl'); end
Simulink.fileGenControl('set','CacheFolder','C:/sl','CodeGenFolder','C:/sl','createDir',true);
cd(fullfile(here,'..','model'));
tic; out = sim('das_model'); fprintf('Simulation (OTDR + Phi-OTDR + COTDR): %.0f s\n', toc);
assignin('base','out',out);
evalin('base','das_postprocess');
print_param_table(otdr_params());
end

function print_param_table(p)
T = {
 'lambda','m','DATASHEET'; 'L_fiber_sim','m','DATASHEET'; 'alpha_dB_km','dB/km','DATASHEET'; 'dz_samp','m','DATASHEET'
 'dz_res','m','CHOSEN: within datasheet 1-50 m; 2 m collapses SNR; 10 m as Zeng 2024'
 'n_g','-','ASSUMED: Corning PI-1424'; 'R_bs_dB','dB','ASSUMED: Corning PI-1424'; 'P0','W','ASSUMED: Thevenaz 2025'
 'linewidth','Hz','ASSUMED: Zeng 2024; Juarez 2005'; 'P_noise_ref','W','ASSUMED: Thevenaz 2025'; 'B_ref','Hz','ASSUMED: Thevenaz 2025'
 'xi','-','ASSUMED: He & Liu 2021 (not used)'
 'k_sig','-','ASSUMED: Shang 2022'; 'k_lo','-','ASSUMED: Shang 2022'; 'G_edfa_dB','dB','ASSUMED: Shang 2022'
 'IL_cir_dB','dB','ASSUMED: Shang 2022'; 'R_pd','A/W','ASSUMED: Shang 2022'; 'L_v','m','ASSUMED: Shang 2022'
 'f_v','Hz','ASSUMED: Shang 2022'; 'Phi0','rad','ASSUMED: Shang 2022'; 'GL','samples','ASSUMED: Shang 2022'
 'z_v','m','CHOSEN: Shang positions scaled to the 20 km fibre'
 'seed','-','SIM SETTING'; 'seed_noise','-','SIM SETTING'; 'seed_laser','-','SIM SETTING'; 'N_pulses','-','SIM SETTING'
 'sine_phase','rad','SIM SETTING'; 'f_rep_frac','-','SIM SETTING'
 'c','m/s','DERIVED'; 'tau_pulse','s','DERIVED (override: FEBUS)'; 'v_g','m/s','DERIVED'; 'f_s','Hz','DERIVED'; 'T_rt','s','DERIVED'
 'f_rep_max','Hz','DERIVED'; 'f_rep','Hz','DERIVED'; 'f_vib_max','Hz','DERIVED'; 'B_rx','Hz','DERIVED'; 'P_noise','W','DERIVED'
 'alpha_lin','1/m','DERIVED'; 'T_stop','s','DERIVED'; 'P_laser','W','DERIVED'; 'P_LO','W','DERIVED'; 'R_bs_pulse','-','DERIVED'
 'sigma_n_dd','A','DERIVED'; 'sigma_n_coh','A','DERIVED'};
fprintf('\n%-14s %-22s %-8s %s\n','name','value','unit','source tag');
for i = 1:size(T,1)
    v = p.(T{i,1});  s = mat2str(v,5);
    fprintf('%-14s %-22s %-8s [%s]\n', T{i,1}, s, T{i,2}, T{i,3});
end
end
