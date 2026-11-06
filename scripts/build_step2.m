function build_step2
%BUILD_STEP2  Step 2: 99:1 coupler (Shang Fig. 16). Safe to re-run.
%  Adds Gain_k_sig (signal arm, sqrt(k_sig)) and Gain_k_lo (LO arm, sqrt(k_lo)),
%  both fed from the laser output, each with a temporary Display for checking.
%  Usage:  build_step2   (with das_model open, scripts/ on the path)

mdl = 'das_model';
load_system(mdl);

% Find the laser output block from Step 1 (Magnitude-Angle to Complex)
laser = find_system(mdl, 'SearchDepth',1, 'BlockType','MagnitudeAngleToComplex');
assert(~isempty(laser), 'Laser block (Magnitude-Angle to Complex) not found: finish Step 1 first.');
laser = laser{1};

% Remove previous versions of this step's blocks (and their lines)
names = {'Gain_k_sig','Gain_k_lo','Disp_sig','Disp_lo'};
for i = 1:numel(names)
    blk = [mdl '/' names{i}];
    if getSimulinkBlockHandle(blk) > 0
        lh = get_param(blk,'LineHandles');
        for h = [lh.Inport(:); lh.Outport(:)].'
            if h > 0, delete_line(h); end
        end
        delete_block(blk);
    end
end

% Layout: two arms to the right of the existing blocks
p  = get_param(laser,'Position');
x0 = p(3) + 300;
ySig = p(2) - 110;   yLo = p(2) + 150;
sz = [60 36];

add_block('simulink/Math Operations/Gain', [mdl '/Gain_k_sig'], ...
    'Gain','sqrt(k_sig)', 'Position',[x0 ySig x0+sz(1) ySig+sz(2)]);
add_block('simulink/Math Operations/Gain', [mdl '/Gain_k_lo'], ...
    'Gain','sqrt(k_lo)',  'Position',[x0 yLo  x0+sz(1) yLo+sz(2)]);
add_block('simulink/Sinks/Display', [mdl '/Disp_sig'], ...
    'Position',[x0+120 ySig x0+200 ySig+sz(2)]);
add_block('simulink/Sinks/Display', [mdl '/Disp_lo'], ...
    'Position',[x0+120 yLo  x0+200 yLo+sz(2)]);

% Wiring: laser -> both gains (automatic branch), gains -> displays
add_line(mdl, [get_param(laser,'Name') '/1'], 'Gain_k_sig/1', 'autorouting','on');
add_line(mdl, [get_param(laser,'Name') '/1'], 'Gain_k_lo/1',  'autorouting','on');
add_line(mdl, 'Gain_k_sig/1', 'Disp_sig/1', 'autorouting','on');
add_line(mdl, 'Gain_k_lo/1',  'Disp_lo/1',  'autorouting','on');

% Label like Shang's figure
add_block('built-in/Note', [mdl '/Note_coupler'], 'MakeNameUnique','on', ...
    'Position',[x0 ySig-40]);
set_param([mdl '/Note_coupler'],'Text','99:1 Coupler (Shang Fig. 16)');

set_param(mdl,'Dirty','on');
fprintf('Step 2 built. Save the model (Ctrl+S) and run it.\n');
end
