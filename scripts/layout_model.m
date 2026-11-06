function layout_model
%LAYOUT_MODEL  Place every block of das_model on a clean grid and re-route all lines.
%  Run it after each step (add the new blocks to the tables below). It
%   - renames the three default-named laser blocks,
%   - gives blocks of the same kind the same size,
%   - puts every chain on one horizontal axis (the signal port is aligned to the axis),
%   - stacks the three detector branches with equal spacing and shared columns,
%   - replaces long wires by Goto/From tags,
%   - deletes and re-creates ALL lines and annotations from the connection/annotation tables.
%  Layout rules (report quality): room for the signal labels ("double (c) [1969x1]") between
%  connected blocks, titles above their section, names below the blocks, noise straight under
%  its Sum block, no crossings.

mdl = 'das_model';
load_system(mdl);

%% 0) names and leftovers
ren = {sprintf('Random\nNumber'),'Rand_phase'; sprintf('Magnitude-Angle\nto Complex'),'MagAng_laser'; 'Constant','Const_mag'};
for i = 1:size(ren,1)
    if getSimulinkBlockHandle([mdl '/' ren{i,1}]) > 0, set_param([mdl '/' ren{i,1}],'Name',ren{i,2}); end
end
if getSimulinkBlockHandle([mdl '/Disp_lo']) > 0, delete_block([mdl '/Disp_lo']); end   % Step-2 check display
for h = find_system(mdl,'SearchDepth',1,'FindAll','on','Type','line').'
    if ishandle(h), try, delete_line(h); catch, end, end                                    %#ok<*TRYNC>
end
for a = find_system(mdl,'SearchDepth',1,'FindAll','on','Type','annotation').'
    if ishandle(a), delete(a); end
end

%% 1) tag blocks (long links)
tags = { 'Goto_Efwd','From_Efwd','E_fwd'; 'Goto_vib','From_vib','vib'; 'Goto_Eback','From_Eback','E_back'; 'Goto_PR','From_PR','P_R' };
for i = 1:size(tags,1)
    g = [mdl '/' tags{i,1}];  f = [mdl '/' tags{i,2}];
    if getSimulinkBlockHandle(g) > 0, delete_block(g); end
    if getSimulinkBlockHandle(f) > 0, delete_block(f); end
    add_block('simulink/Signal Routing/Goto', g, 'GotoTag', tags{i,3}, 'TagVisibility','local');
    add_block('simulink/Signal Routing/From', f, 'GotoTag', tags{i,3});
end

%% 2) sizes (same kind -> same size)
S.gain = [60 30];  S.math = [50 30];  S.sum = [30 30];  S.tag = [70 20];  S.rnd = [70 30];
S.term = [20 20]; S.sine = [50 30];  S.const = [60 30];  S.prod = [40 40];

%% 1b) OTDR power must see the same backward circulator loss as the coherent field: g_cir^2 on power
if getSimulinkBlockHandle([mdl '/Gain_g_cir2']) < 0 || getSimulinkBlockHandle([mdl '/Gain_g_cir2']) == 0
    add_block('simulink/Math Operations/Gain',[mdl '/Gain_g_cir2'],'Gain','g_cir^2');
end

%% 2b) block settings that affect the geometry
for nm = {'Sum_otdr','Sum_dd','Sum_coh'}
    set_param([mdl '/' nm{1}],'Inputs','|++','NamePlacement','alternate');   % in1 left, in2 bottom; name above
end
set_param([mdl '/Sum'],'NamePlacement','alternate');
for nm = {'Noise_otdr','Noise_dd','Noise_cI','Noise_cQ'}
    try, set_param([mdl '/' nm{1}],'VectorParams1D','off'); end              % frames are [1969x1], not 1-D
end

%% 2c) detector outputs: the DAQ (To Workspace) blocks of Step 7 replace the temporary Terminators
nO = outname(mdl,'DAQ_otdr','Term_det_otdr');
nD = outname(mdl,'DAQ_dd','Term_det_dd');
nC = outname(mdl,'DAQ_coh','Term_det_coh');
S.daq = [90 30];

%% 3) grid
Ya = 300;                                       % axis of laser, coupler, signal arm
% -- laser section (axis rows 280 / 320 around the Mag-Angle block)
place(mdl,'Rand_phase', 40, Ya+20, S.rnd, {});
place(mdl,'Sum',        170, Ya+20, S.sum, {});
place(mdl,'Unit Delay', 150, Ya+110, [40 30], {}, 'left');
place(mdl,'Const_mag',  240, Ya-20, S.const, {});
place(mdl,'Scope',      240, Ya-130, [50 45], {});
place(mdl,'MagAng_laser',350, Ya, [50 120], {});
% -- coupler arms, AOM, EDFA, circulator (signal arm on Ya, then on the AOM output axis)
place(mdl,'Gain_k_sig', 480, Ya,      S.gain, {});
place(mdl,'Gain_k_lo',  480, Ya+130,  S.gain, {});
place(mdl,'Goto_LO',    630, Ya+130,  S.tag,  {});
place(mdl,'p_frame',    630, Ya+80,   S.const, {});
place(mdl,'AOM',        770, Ya,      S.prod, {'in',1});
pa = pport(mdl,'AOM','out',1);  Y1 = pa(2);       % axis of everything downstream
place(mdl,'EDFA',       960, Y1, [60 60], {'in',1});
place(mdl,'From_Eback', 1180, Y1+27, S.tag, {});
place(mdl,'Circulator', 1370, Y1, [60 80], {'in',1});
pc2 = pport(mdl,'Circulator','out',2);
place(mdl,'Goto_ER',    1550, pc2(2), S.tag, {});
place(mdl,'Goto_Efwd',  1490, Y1-70, S.tag, {});
place(mdl,'FUT_coherent',1710, Y1, [120 70], {'in',1});
pf = pport(mdl,'FUT_coherent','out',1);
place(mdl,'Goto_Eback', 1950, pf(2), S.tag, {});
pv = pport(mdl,'FUT_coherent','in',2);
place(mdl,'From_vib',   1500, Y1+90, S.tag, {});
% -- incoherent chain (axis Yi)
Yi = Y1 + 170;
place(mdl,'From_Efwd',     1180, Yi, S.tag, {});
place(mdl,'Abs_inc',       1370, Yi, S.math, {});
place(mdl,'Sq_inc',        1540, Yi, S.math, {});
place(mdl,'FUT_incoherent',1710, Yi, [120 70], {'in',1});
pi_ = pport(mdl,'FUT_incoherent','out',1);
place(mdl,'Goto_PR',       1950, pi_(2), S.tag, {});
% -- vibration sources (bottom left)
Yv = Y1 + 450;
place(mdl,'Sine_v1', 60,  Yv-25, S.sine, {});
place(mdl,'Sine_v2', 60,  Yv+25, S.sine, {});
place(mdl,'Mux_vib', 180, Yv,    [8 60], {});
place(mdl,'Goto_vib',250, Yv,    S.tag, {});
% -- detector branches: equal spacing, shared columns
C  = [400 590 780 970 1220 1400];             % From | Abs | Square | Gain | Sum | output
Yo = Yi + 170;  Yd = Yo + 150;  Yc = Yd + 150;  dn = 80;
place(mdl,'From_PR',      C(1), Yo, S.tag, {});
place(mdl,'Gain_g_cir2',  C(2), Yo, S.gain, {});
place(mdl,'Gain_R_otdr',  C(4), Yo, S.gain, {});
place(mdl,'Sum_otdr',     C(5), Yo, S.sum, {});
place(mdl,nO, C(6), Yo, iff(startsWith(nO,'DAQ'),S.daq,S.term), {});
place(mdl,'Noise_otdr',   C(5)+15-S.rnd(1)/2, Yo+dn, S.rnd, {}, 'up');
place(mdl,'From_ER_dd',   C(1), Yd, S.tag, {});
place(mdl,'Abs_dd',       C(2), Yd, S.math, {});
place(mdl,'Sq_dd',        C(3), Yd, S.math, {});
place(mdl,'Gain_R_dd',    C(4), Yd, S.gain, {});
place(mdl,'Sum_dd',       C(5), Yd, S.sum, {});
place(mdl,nD, C(6), Yd, iff(startsWith(nD,'DAQ'),S.daq,S.term), {});
place(mdl,'Noise_dd',     C(5)+15-S.rnd(1)/2, Yd+dn, S.rnd, {}, 'up');
place(mdl,'From_ER_coh',  C(1), Yc, S.tag, {});
place(mdl,'From_LO',      C(1), Yc+60, S.tag, {});
place(mdl,'Conj_LO',      C(2), Yc+60, S.math, {});
place(mdl,'Prod_coh',     C(3), Yc, S.prod, {'in',1});
place(mdl,'Gain_R_coh',   C(4), Yc, S.gain, {});
place(mdl,'Sum_coh',      C(5), Yc, S.sum, {});
place(mdl,nC, C(6), Yc, iff(startsWith(nC,'DAQ'),S.daq,S.term), {});
place(mdl,'RI2C_noise',   C(5)-120, Yc+dn+20, [50 40], {});
place(mdl,'Noise_cI',     C(5)-310, Yc+dn+5,  S.rnd, {});
place(mdl,'Noise_cQ',     C(5)-310, Yc+dn+55, S.rnd, {});

%% 4) lines
% source, output port, destination, input port
L = { 'Rand_phase',1,'Sum',1;            'Sum',1,'Unit Delay',1;        'Unit Delay',1,'Sum',2
      'Sum',1,'MagAng_laser',2;          'Const_mag',1,'MagAng_laser',1; 'Sum',1,'Scope',1
      'MagAng_laser',1,'Gain_k_sig',1;   'MagAng_laser',1,'Gain_k_lo',1; 'Gain_k_lo',1,'Goto_LO',1
      'Gain_k_sig',1,'AOM',1;            'p_frame',1,'AOM',2;            'AOM',1,'EDFA',1
      'EDFA',1,'Circulator',1;           'From_Eback',1,'Circulator',2;  'Circulator',2,'Goto_ER',1
      'Circulator',1,'FUT_coherent',1;   'Circulator',1,'Goto_Efwd',1;   'From_vib',1,'FUT_coherent',2
      'FUT_coherent',1,'Goto_Eback',1
      'From_Efwd',1,'Abs_inc',1;         'Abs_inc',1,'Sq_inc',1;         'Sq_inc',1,'FUT_incoherent',1
      'FUT_incoherent',1,'Goto_PR',1
      'Sine_v1',1,'Mux_vib',1;           'Sine_v2',1,'Mux_vib',2;        'Mux_vib',1,'Goto_vib',1
      'From_PR',1,'Gain_g_cir2',1;       'Gain_g_cir2',1,'Gain_R_otdr',1; 'Gain_R_otdr',1,'Sum_otdr',1;   'Sum_otdr',1,nO,1
      'Noise_otdr',1,'Sum_otdr',2
      'From_ER_dd',1,'Abs_dd',1;         'Abs_dd',1,'Sq_dd',1;           'Sq_dd',1,'Gain_R_dd',1
      'Gain_R_dd',1,'Sum_dd',1;          'Sum_dd',1,nD,1;     'Noise_dd',1,'Sum_dd',2
      'From_ER_coh',1,'Prod_coh',1;      'From_LO',1,'Conj_LO',1;        'Conj_LO',1,'Prod_coh',2
      'Prod_coh',1,'Gain_R_coh',1;       'Gain_R_coh',1,'Sum_coh',1;     'Sum_coh',1,nC,1
      'Noise_cI',1,'RI2C_noise',1;       'Noise_cQ',1,'RI2C_noise',2;    'RI2C_noise',1,'Sum_coh',2 };
for i = 1:size(L,1)
    ps = get_param([mdl '/' L{i,1}],'PortHandles');
    pd = get_param([mdl '/' L{i,3}],'PortHandles');
    add_line(mdl, ps.Outport(L{i,2}), pd.Inport(L{i,4}), 'autorouting','smart');
end

%% 5) annotations: titles above their section, never on a line
note = @(txt,x,y) set_pos(Simulink.Annotation(mdl,txt),[x y]);
note(sprintf('NLL: phase\nrandom walk'), 40, 215);
note('99:1 coupler (Shang Fig. 16)',  480, Ya-60);
note('AOM (pulse cutting)',           745, Ya-60);
note('EDFA',                          965, Ya-60);
note('Circulator',                    1370, Ya-60);
note('FUT (coherent): sum of echoes, Shang Eq. 4', 1710, Y1-70);
note('FUT (incoherent): powers add, no phase',     1180, Yi-70);
note('OTDR detector (Fig. 2): backward circulator loss g_cir^2, then R_pd and noise', C(1), Yo-50);
note('Phi-OTDR detector (Fig. 3)',      C(1), Yd-50);
note('COTDR detector (Fig. 4)',         C(1), Yc-50);
note(sprintf(['Goto/From tags: E_fwd = forward field to the incoherent branch, E_back = backscatter returning into the circulator,\n' ...
              'E_R_det = backscatter to the detectors, LO_det = local oscillator, vib = vibration phases, P_R = OTDR backscattered power']), 60, Yc+200);

%% 6) section areas (light backgrounds behind the blocks)
groups = struct( ...
  'title', {'1  Source: NLL, 99:1 coupler, AOM, EDFA (Shang Figs. 2-4 and 16)', ...
            '2  Circulator and fibre under test: coherent (Eq. 4) and incoherent', ...
            '3  Detectors: OTDR (Fig. 2), Phi-OTDR (Fig. 3), COTDR (Fig. 4), with receiver noise', ...
            '4  Vibration sources: two events'}, ...
  'color', {[0.90 0.93 1.00], [0.90 0.97 0.92], [0.99 0.92 0.90], [0.97 0.95 0.86]}, ...
  'blocks', {{'Rand_phase','Sum','Unit Delay','Const_mag','Scope','MagAng_laser','Gain_k_sig','Gain_k_lo','Goto_LO','p_frame','AOM','EDFA'}, ...
             {'From_Eback','Circulator','Goto_ER','Goto_Efwd','FUT_coherent','Goto_Eback','From_vib','From_Efwd','Abs_inc','Sq_inc','FUT_incoherent','Goto_PR'}, ...
             {'From_PR','Gain_g_cir2','Gain_R_otdr','Sum_otdr',nO,'Noise_otdr','From_ER_dd','Abs_dd','Sq_dd','Gain_R_dd','Sum_dd',nD,'Noise_dd', ...
              'From_ER_coh','From_LO','Conj_LO','Prod_coh','Gain_R_coh','Sum_coh',nC,'RI2C_noise','Noise_cI','Noise_cQ'}, ...
             {'Sine_v1','Sine_v2','Mux_vib','Goto_vib'}});
for g = 1:numel(groups)
    P = zeros(numel(groups(g).blocks),4);
    for k = 1:numel(groups(g).blocks), P(k,:) = get_param([mdl '/' groups(g).blocks{k}],'Position'); end
    groups(g).rect = [min(P(:,1))-15, min(P(:,2))-55, max(P(:,3))+15 + 115*(g==1), max(P(:,4))+40];   % area 1: room for the EDFA output label
end
save_system(mdl);
add_areas(mdl, groups);
fprintf('Layout done and saved.\n');
end

%% ------------------------------------------------------------------ helpers
function a = set_pos(a,p), a.Position = p; end

function p = pport(mdl, name, kind, k)
ph = get_param([mdl '/' name],'PortHandles');
if strcmp(kind,'in'), p = get_param(ph.Inport(k),'Position'); else, p = get_param(ph.Outport(k),'Position'); end
end

function place(mdl, name, x, yc, sz, ref, orient)
%  Block of size sz with its left edge at x and centre on yc; ref = {'in'|'out', k} aligns that
%  port to yc instead (straight lines).
blk = [mdl '/' name];
if nargin >= 7 && ~isempty(orient), set_param(blk,'Orientation',orient); else, set_param(blk,'Orientation','right'); end
set_param(blk,'Position',[x yc-sz(2)/2 x+sz(1) yc+sz(2)/2]);
if ~isempty(ref)
    pp = pport(mdl,name,ref{1},ref{2});
    d = yc - pp(2);
    set_param(blk,'Position',get_param(blk,'Position') + [0 d 0 d]);
end
end

function add_areas(mdl, groups)
%  Simulink has no API to create Area annotations, so they are written into the model file:
%  save, unzip the .slx, replace the area_annotation elements in system_root.xml, zip, reload.
f = get_param(mdl,'FileName');
close_system(mdl);
tmp = tempname;  mkdir(tmp);  unzip(f,tmp);
p = fullfile(tmp,'simulink','systems','system_root.xml');
fid = fopen(p,'r','n','UTF-8');  s = fread(fid,'*char').';  fclose(fid);
old = regexp(s,'\s*<Annotation SID="[^"]*">.*?</Annotation>','match');
for i = 1:numel(old)
    if contains(old{i},'area_annotation'), s = strrep(s,old{i},''); end
end
sid = max([0 str2double(regexp(s,'(?<=<Annotation SID=")\d+','match'))]);
xml = '';
for g = 1:numel(groups)
    sid = sid + 1;  r = round(groups(g).rect);  c = groups(g).color;
    col = sprintf('[%f, %f, %f]',c);
    rows = { sprintf('  <Annotation SID="%d">',sid)
             ['    <P Name="Name">' xmlesc(groups(g).title) '</P>']
             sprintf('    <P Name="Position">[%d, %d, %d, %d]</P>',r)
             '    <P Name="InternalMargins">[0, 0, 0, 0]</P>'
             '    <P Name="FixedHeight">on</P>'
             '    <P Name="FixedWidth">on</P>'
             ['    <P Name="ForegroundColor">' col '</P>']
             ['    <P Name="BackgroundColor">' col '</P>']
             '    <P Name="DropShadow">off</P>'
             '    <P Name="AnnotationType">area_annotation</P>'
             '    <P Name="ZOrder">-1</P>'
             '    <P Name="FontSize">14</P>'
             '    <P Name="FontWeight">bold</P>'
             '  </Annotation>' };
    xml = [xml strjoin(rows.', newline) newline]; %#ok<AGROW>
end
k = strfind(s,'</System>');  k = k(end);
s = [s(1:k-1) xml s(k:end)];
fid = fopen(p,'w','n','UTF-8');  fwrite(fid,s,'char');  fclose(fid);
d = dir(tmp);  names = {d(~ismember({d.name},{'.','..'})).name};
zf = [tempname '.zip'];  zip(zf,names,tmp);  movefile(zf,f,'f');
rmdir(tmp,'s');
load_system(f);
end

function t = xmlesc(t)
t = strrep(strrep(strrep(t,'&','&amp;'),'<','&lt;'),'>','&gt;');
end

function r = iff(c,a,b), if c, r = a; else, r = b; end, end

function n = outname(mdl, daq, term)
if getSimulinkBlockHandle([mdl '/' daq]) > 0, n = daq; else, n = term; end
end
