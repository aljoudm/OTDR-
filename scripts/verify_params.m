function verify_params()
%VERIFY_PARAMS  Expected backscatter power and coherent SNR at 0, 10, 20 km (run BEFORE simulating).
%  Reference (DAS-Simulation): 61.8 / 24.6 / 9.8 nW and SNR 34.8 / 30.8 / 26.8 dB. Stops if off by > 5 dB.
p = otdr_params();
zk = [0 10 20];  ref_P = [61.8 24.6 9.8]*1e-9;  ref_S = [34.8 30.8 26.8];
P = p.P_bs(zk*1e3);  S = 10*log10(p.SNR_coh_fn(zk*1e3));
fprintf('tau_pulse = %.2f ns | f_s = %.2f MHz | f_rep = %.3f kHz | P_noise = %.2f pW\n', p.tau_pulse*1e9, p.f_s/1e6, p.f_rep/1e3, p.P_noise*1e12);
fprintf('  z [km] | P_bs [nW] (ref) | SNR [dB] (ref)\n');
for i = 1:3, fprintf('  %5.0f  | %7.2f (%5.1f) | %6.2f (%5.1f)\n', zk(i), P(i)*1e9, ref_P(i)*1e9, S(i), ref_S(i)); end
assert(all(abs(10*log10(P./ref_P)) < 5) && all(abs(S-ref_S) < 5), 'Expected values are off by more than 5 dB');
end
