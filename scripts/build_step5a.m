function build_step5a
%BUILD_STEP5A  Step 5, part A: the blocks that feed the fibre (FUT). Safe to re-run.
%  Adds only new blocks, to the right of the circulator (nothing existing is moved):
%    Sine_v1, Sine_v2 -> Mux_vib      the vibration phase of the two events (vib input of the FUT)
%    Abs_inc -> Sq_inc                |E|^2 for the conventional-OTDR fibre
%  The two MATLAB Function blocks (FUT_coherent, FUT_incoherent) are created by hand (new concept),
%  then build_step5b wires everything.

mdl = 'das_model';
load_system(mdl);

names = {'Sine_v1','Sine_v2','Mux_vib','Abs_inc','Sq_inc'};
for i = 1:numel(names)
    blk = [mdl '/' names{i}];
    if getSimulinkBlockHandle(blk) > 0, remove_block_and_lines(blk); end
end
for an = find_system(mdl,'SearchDepth',1,'FindAll','on','Type','annotation').'
    t = get_param(an,'PlainText');
    if any(strcmp(t,{'FUT (coherent): place the MATLAB Function block FUT_coherent here', ...
                     'FUT (incoherent): place the MATLAB Function block FUT_incoherent here', ...
                     'vibration of the 2 events'}))
        delete(an);
    end
end

add_block('simulink/Sources/Sine Wave',[mdl '/Sine_v1'],'Position',[1190 130 1230 150], ...
    'SineType','Time based','Amplitude','Phi0(1)','Frequency','2*pi*f_v(1)','SampleTime','Ts_slow');
add_block('simulink/Sources/Sine Wave',[mdl '/Sine_v2'],'Position',[1190 175 1230 195], ...
    'SineType','Time based','Amplitude','Phi0(2)','Frequency','2*pi*f_v(2)','SampleTime','Ts_slow');
add_block('simulink/Signal Routing/Mux',[mdl '/Mux_vib'],'Inputs','2','Position',[1290 135 1295 190]);
add_line(mdl,'Sine_v1/1','Mux_vib/1','autorouting','on');
add_line(mdl,'Sine_v2/1','Mux_vib/2','autorouting','on');

add_block('simulink/Math Operations/Abs',[mdl '/Abs_inc'],'Position',[1190 290 1230 310]);
add_block('simulink/Math Operations/Math Function',[mdl '/Sq_inc'],'Function','square','Position',[1270 290 1320 310]);
add_line(mdl,'Abs_inc/1','Sq_inc/1','autorouting','on');

a = Simulink.Annotation(mdl,'FUT (coherent): place the MATLAB Function block FUT_coherent here');
a.Position = [1380 -30];
b = Simulink.Annotation(mdl,'FUT (incoherent): place the MATLAB Function block FUT_incoherent here');
b.Position = [1380 255];
c = Simulink.Annotation(mdl,'vibration of the 2 events'); c.Position = [1190 105];

save_system(mdl);
fprintf('Step 5A built and saved.\n');
end

function remove_block_and_lines(blk)
lh = get_param(blk,'LineHandles');
for h = [lh.Inport(:); lh.Outport(:)].'
    if h > 0, delete_line(h); end
end
delete_block(blk);
end
