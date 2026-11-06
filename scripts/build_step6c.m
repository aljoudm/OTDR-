function build_step6c
%BUILD_STEP6C  Step 6, part C: the remaining noise sources and their wiring. Safe to re-run.
%  Needs Noise_otdr (created by hand in Step 6B). Creates, with the same settings but a
%  DIFFERENT, VECTOR Seed each (one seed per fibre sample; a scalar seed would make all samples identical):
%    Noise_dd (Seed 12)                  -> Sum_dd/2
%    Noise_cI (13), Noise_cQ (14) -> Real-Imag to Complex (RI2C_noise) -> Sum_coh/2
%  and connects Noise_otdr -> Sum_otdr/2.

mdl = 'das_model';
load_system(mdl);
assert(getSimulinkBlockHandle([mdl '/Noise_otdr']) > 0, 'Create Noise_otdr first (Step 6B).');

for nm = {'Noise_dd','Noise_cI','Noise_cQ','RI2C_noise'}
    blk = [mdl '/' nm{1}];
    if getSimulinkBlockHandle(blk) > 0, remove_block_and_lines(blk); end
end
lh = get_param([mdl '/Noise_otdr'],'LineHandles');
if lh.Outport(1) > 0, delete_line(lh.Outport(1)); end

noise = @(nm,seed,p) add_block('simulink/Sources/Random Number',[mdl '/' nm],'Position',p, ...
    'Mean','zeros(Ns,1)','Variance','sigma_n^2','Seed',sprintf('%d+(1:Ns).''',10000*seed),'SampleTime','Ts_slow','VectorParams1D','off');

sd = get_param([mdl '/Sum_dd'],'Position');
sc = get_param([mdl '/Sum_coh'],'Position');

noise('Noise_dd', 12, [sd(1)-60 sd(2)+50 sd(1)+10 sd(2)+80]);
noise('Noise_cI', 13, [sc(1)-190 sc(2)+70 sc(1)-120 sc(2)+100]);
noise('Noise_cQ', 14, [sc(1)-190 sc(2)+120 sc(1)-120 sc(2)+150]);
add_block('simulink/Math Operations/Real-Imag to Complex',[mdl '/RI2C_noise'],'Input','Real and imag', ...
    'Position',[sc(1)-80 sc(2)+85 sc(1)-50 sc(2)+135]);

add_line(mdl,'Noise_otdr/1','Sum_otdr/2','autorouting','on');
add_line(mdl,'Noise_dd/1','Sum_dd/2','autorouting','on');
add_line(mdl,'Noise_cI/1','RI2C_noise/1','autorouting','on');
add_line(mdl,'Noise_cQ/1','RI2C_noise/2','autorouting','on');
add_line(mdl,'RI2C_noise/1','Sum_coh/2','autorouting','on');

save_system(mdl);
fprintf('Step 6C wired and saved.\n');
end

function remove_block_and_lines(blk)
lh = get_param(blk,'LineHandles');
for h = [lh.Inport(:); lh.Outport(:)].'
    if h > 0, delete_line(h); end
end
delete_block(blk);
end
