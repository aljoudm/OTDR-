function build_step4
%BUILD_STEP4  Step 4: EDFA + circulator gains (Shang Figs. 2-4). Safe to re-run.
%  Adds ONLY new blocks, to the right of the AOM; existing blocks and lines are not moved.
%  The three Gains are later grouped into Subsystems by hand (Ctrl+G):
%    Gain_edfa     -> subsystem "EDFA"        (field gain g_edfa)
%    Gain_cir_fwd  -> together with Gain_cir_bwd -> subsystem "Circulator"
%    Gain_cir_bwd  -> return path fibre -> photodetector (g_cir per direction)
%  Term_AOM (Step 3) is replaced by the new chain; temporary Ground/Terminators
%  keep the open ends tidy until the fibre exists (Step 5).

mdl = 'das_model';
load_system(mdl);

%% Remove old versions of this step's blocks, and Term_AOM
for nm = {'Term_AOM','Gain_edfa','Gain_cir_fwd','Gain_cir_bwd','Term_fwd','Ground_bwd','Term_bwd'}
    blk = [mdl '/' nm{1}];
    if getSimulinkBlockHandle(blk) > 0, remove_block_and_lines(blk); end
end
for an = find_system(mdl,'SearchDepth',1,'FindAll','on','Type','annotation').'
    if any(strcmp(get_param(an,'PlainText'),{'EDFA','Circulator (forward = to fibre, backward = to detectors)'}))
        delete(an);
    end
end

%% Layout: continue to the right of the AOM, return path below it
a  = get_param([mdl '/AOM'],'Position');
x0 = a(3) + 130;   y0 = a(2) + 5;    sz = [60 36];
yB = y0 + 330;                                         % backward (return) path row
pos = @(x,y) [x y x+sz(1) y+sz(2)];

add_block('simulink/Math Operations/Gain',[mdl '/Gain_edfa'],    'Gain','g_edfa','Position',pos(x0,y0));
add_block('simulink/Math Operations/Gain',[mdl '/Gain_cir_fwd'], 'Gain','g_cir', 'Position',pos(x0+170,y0));
add_block('simulink/Sinks/Terminator',    [mdl '/Term_fwd'],     'Position',[x0+300 y0+8 x0+320 y0+28]);
add_block('simulink/Sources/Ground',      [mdl '/Ground_bwd'],   'Position',[x0 yB+8 x0+20 yB+28]);
add_block('simulink/Math Operations/Gain',[mdl '/Gain_cir_bwd'], 'Gain','g_cir', 'Position',pos(x0+170,yB));
add_block('simulink/Sinks/Terminator',    [mdl '/Term_bwd'],     'Position',[x0+300 yB+8 x0+320 yB+28]);

%% Wiring
add_line(mdl,'AOM/1',         'Gain_edfa/1',   'autorouting','on');
add_line(mdl,'Gain_edfa/1',   'Gain_cir_fwd/1','autorouting','on');
add_line(mdl,'Gain_cir_fwd/1','Term_fwd/1',    'autorouting','on');
add_line(mdl,'Ground_bwd/1',  'Gain_cir_bwd/1','autorouting','on');
add_line(mdl,'Gain_cir_bwd/1','Term_bwd/1',    'autorouting','on');

n1 = Simulink.Annotation(mdl,'EDFA');                n1.Position = [x0+10 y0-35];
n2 = Simulink.Annotation(mdl,'Circulator (forward = to fibre, backward = to detectors)');
n2.Position = [x0+110 y0-35];

save_system(mdl);
fprintf('Step 4 built and saved.\n');
end

function remove_block_and_lines(blk)
lh = get_param(blk,'LineHandles');
for h = [lh.Inport(:); lh.Outport(:)].'
    if h > 0, delete_line(h); end
end
delete_block(blk);
end
