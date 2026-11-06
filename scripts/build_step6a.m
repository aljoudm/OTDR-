function build_step6a
%BUILD_STEP6A  Step 6, part A: the three detection branches (Shang Figs. 2, 3, 4). Safe to re-run.
%  Adds only new blocks, to the right of the FUT blocks (nothing existing is moved). The
%  noise blocks are created later (Noise_otdr by hand, the rest by build_step6c).
%    OTDR     : FUT_incoherent/P_R -> Gain R_pd -> Sum_otdr (+ Noise_otdr)
%    Phi-OTDR : Circulator/2 (E_R) -> |.|^2 -> Gain R_pd -> Sum_dd (+ Noise_dd)
%    COTDR    : Circulator/2 (E_R) x conj(LO) -> Gain R_pd -> Sum_coh (+ complex noise)
%  The backscatter E_R and the local oscillator LO reach the detectors through Goto/From tags
%  ('E_R_det', 'LO_det'), which keeps the long wires out of the picture.

mdl = 'das_model';
load_system(mdl);

old = {'Term_otdr','Term_bwd','Goto_ER','Goto_LO','Gain_R_otdr','Sum_otdr','Term_det_otdr', ...
       'From_ER_dd','Abs_dd','Sq_dd','Gain_R_dd','Sum_dd','Term_det_dd', ...
       'From_ER_coh','From_LO','Conj_LO','Prod_coh','Gain_R_coh','Sum_coh','Term_det_coh'};
for i = 1:numel(old)
    blk = [mdl '/' old{i}];
    if getSimulinkBlockHandle(blk) > 0, remove_block_and_lines(blk); end
end
mine = {'OTDR detector (Fig. 2)','Phi-OTDR detector (Fig. 3)','COTDR detector (Fig. 4)', ...
        'E_R and LO reach the detectors through Goto/From tags'};
for an = find_system(mdl,'SearchDepth',1,'FindAll','on','Type','annotation').'
    if any(strcmp(get_param(an,'PlainText'), mine)), delete(an); end
end

add = @(lib,nm,p,varargin) add_block(['simulink/' lib],[mdl '/' nm],'Position',p,varargin{:});
X = 1700;                                   % detectors start here (right of the FUT blocks)

%% Goto tags: E_R (circulator backward output) and LO (second coupler output)
add('Signal Routing/Goto','Goto_ER',[1180 40 1250 60],'GotoTag','E_R_det','TagVisibility','local');
add_line(mdl,'Circulator/2','Goto_ER/1','autorouting','on');
add('Signal Routing/Goto','Goto_LO',[660 275 730 295],'GotoTag','LO_det','TagVisibility','local');
add_line(mdl,'Gain_k_lo/1','Goto_LO/1','autorouting','on');

%% (1) OTDR branch: power x R_pd, then noise
yo = 200;                                   % axis of FUT_incoherent's output
add('Math Operations/Gain','Gain_R_otdr',[X-10 yo-15 X+50 yo+15],'Gain','R_pd');
add('Math Operations/Sum','Sum_otdr',[X+130 yo-10 X+150 yo+10],'Inputs','|++');
add('Sinks/Terminator','Term_det_otdr',[X+210 yo-10 X+230 yo+10]);
add_line(mdl,'FUT_incoherent/1','Gain_R_otdr/1','autorouting','on');
add_line(mdl,'Gain_R_otdr/1','Sum_otdr/1','autorouting','on');
add_line(mdl,'Sum_otdr/1','Term_det_otdr/1','autorouting','on');

%% (2) Phi-OTDR branch: |E_R|^2 x R_pd, then noise
yd = 400;
add('Signal Routing/From','From_ER_dd',[X-10 yd-10 X+60 yd+10],'GotoTag','E_R_det');
add('Math Operations/Abs','Abs_dd',[X+90 yd-10 X+120 yd+10]);
add('Math Operations/Math Function','Sq_dd',[X+150 yd-10 X+200 yd+10],'Function','square');
add('Math Operations/Gain','Gain_R_dd',[X+230 yd-15 X+290 yd+15],'Gain','R_pd');
add('Math Operations/Sum','Sum_dd',[X+350 yd-10 X+370 yd+10],'Inputs','|++');
add('Sinks/Terminator','Term_det_dd',[X+430 yd-10 X+450 yd+10]);
add_line(mdl,'From_ER_dd/1','Abs_dd/1','autorouting','on');
add_line(mdl,'Abs_dd/1','Sq_dd/1','autorouting','on');
add_line(mdl,'Sq_dd/1','Gain_R_dd/1','autorouting','on');
add_line(mdl,'Gain_R_dd/1','Sum_dd/1','autorouting','on');
add_line(mdl,'Sum_dd/1','Term_det_dd/1','autorouting','on');

%% (3) COTDR branch: E_R x conj(LO) x R_pd, then complex noise
yc = 640;
add('Signal Routing/From','From_ER_coh',[X-10 yc-10 X+60 yc+10],'GotoTag','E_R_det');
add('Signal Routing/From','From_LO',[X-10 yc+50 X+60 yc+70],'GotoTag','LO_det');
add('Math Operations/Math Function','Conj_LO',[X+90 yc+50 X+140 yc+70],'Function','conj');
add('Math Operations/Product','Prod_coh',[X+190 yc-15 X+220 yc+40],'Inputs','**');
add('Math Operations/Gain','Gain_R_coh',[X+260 yc-5 X+320 yc+25],'Gain','R_pd');
add('Math Operations/Sum','Sum_coh',[X+380 yc+5 X+400 yc+25],'Inputs','|++');
add('Sinks/Terminator','Term_det_coh',[X+460 yc+5 X+480 yc+25]);
add_line(mdl,'From_ER_coh/1','Prod_coh/1','autorouting','on');
add_line(mdl,'From_LO/1','Conj_LO/1','autorouting','on');
add_line(mdl,'Conj_LO/1','Prod_coh/2','autorouting','on');
add_line(mdl,'Prod_coh/1','Gain_R_coh/1','autorouting','on');
add_line(mdl,'Gain_R_coh/1','Sum_coh/1','autorouting','on');
add_line(mdl,'Sum_coh/1','Term_det_coh/1','autorouting','on');

%% Labels
labels = { 'OTDR detector (Fig. 2)',      [X-10  yo-60]
           'Phi-OTDR detector (Fig. 3)',  [X-10  yd-60]
           'COTDR detector (Fig. 4)',     [X-10  yc-60]
           'E_R and LO reach the detectors through Goto/From tags', [1100 100] };
for k = 1:size(labels,1)
    a = Simulink.Annotation(mdl,labels{k,1}); a.Position = labels{k,2};
end

save_system(mdl);
fprintf('Step 6A built and saved.\n');
end

function remove_block_and_lines(blk)
lh = get_param(blk,'LineHandles');
for h = [lh.Inport(:); lh.Outport(:)].'
    if h > 0, delete_line(h); end
end
delete_block(blk);
end
