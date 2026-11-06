function build_step3
%BUILD_STEP3  Step 3: AOM = pulse cutting (Shang Figs. 2-4). Safe to re-run.
%  p_frame (Ns x 1: 1 for the first Nw samples, then 0) multiplies the scalar
%  signal field coming out of the coupler -> one pulse frame per simulation step.
%  Also removes the temporary Displays from Steps 1-2 (Disp_sig is replaced by the AOM).

mdl = 'das_model';
load_system(mdl);

%% Clean up: old Display on the laser output + Disp_sig, and this step's own blocks
laser = find_system(mdl,'SearchDepth',1,'BlockType','MagnitudeAngleToComplex');
assert(~isempty(laser), 'Laser block not found: finish Step 1 first.');
laser = laser{1};
lh = get_param(laser,'LineHandles');
for d = find_system(mdl,'SearchDepth',1,'BlockType','Display').'
    blk = d{1};
    if strcmp(get_param(blk,'Name'),'Disp_lo'), continue; end   % keep the LO check
    src = get_param(get_param(blk,'LineHandles').Inport,'SrcBlockHandle');
    if strcmp(get_param(blk,'Name'),'Disp_sig') || isequal(src, get_param(laser,'Handle'))
        remove_block_and_lines(blk);
    end
end
for nm = {'p_frame','AOM','Term_AOM'}
    blk = [mdl '/' nm{1}];
    if getSimulinkBlockHandle(blk) > 0, remove_block_and_lines(blk); end
end
for an = find_system(mdl,'SearchDepth',1,'FindAll','on','Type','annotation').'
    if strcmp(get_param(an,'PlainText'),'AOM (pulse cutting)'), delete(an); end
end

%% Blocks
g  = get_param([mdl '/Gain_k_sig'],'Position');
x0 = g(3) + 80;  y0 = g(2);
add_block('simulink/Sources/Constant', [mdl '/p_frame'], ...
    'Value','p_frame', 'SampleTime','Ts_slow', 'VectorParams1D','off', ...
    'Position',[x0 y0+70 x0+60 y0+100]);
add_block('simulink/Math Operations/Product', [mdl '/AOM'], ...
    'Inputs','**', 'Position',[x0+120 y0-2 x0+150 y0+48]);
add_block('simulink/Sinks/Terminator', [mdl '/Term_AOM'], ...
    'Position',[x0+210 y0+13 x0+230 y0+33]);

%% Wiring
add_line(mdl,'Gain_k_sig/1','AOM/1','autorouting','on');
add_line(mdl,'p_frame/1','AOM/2','autorouting','on');
add_line(mdl,'AOM/1','Term_AOM/1','autorouting','on');

note = Simulink.Annotation(mdl,'AOM (pulse cutting)');
note.Position = [x0+60 y0-45];

%% Sanity check: compile and print the signal dimensions
feval(mdl,[],[],[],'compile');
dp = get_param([mdl '/p_frame'],'CompiledPortDimensions');
da = get_param([mdl '/AOM'],'CompiledPortDimensions');
feval(mdl,[],[],[],'term');
Ns = evalin('base','Ns');
% format of each list: [ndims dim1 dim2 ...] for every port, one after another
fprintf('Ns = %d | p_frame out = %s | AOM in = %s | AOM out = %s\n', Ns, ...
    mat2str(dp.Outport), mat2str(da.Inport), mat2str(da.Outport));

save_system(mdl);
fprintf('Step 3 built and saved.\n');
end

function remove_block_and_lines(blk)
lh = get_param(blk,'LineHandles');
for h = [lh.Inport(:); lh.Outport(:)].'
    if h > 0, delete_line(h); end
end
delete_block(blk);
end
