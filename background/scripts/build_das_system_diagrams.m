function build_das_system_diagrams
%BUILD_DAS_SYSTEM_DIAGRAMS  Shang Figs. 2-4 redrawn as Simulink diagrams (OTDR, Phi-OTDR, COTDR).
%  Builds background/model/das_otdr.slx, das_phiotdr.slx, das_cotdr.slx and exports each to
%  background/figures/das_otdr.*, das_phiotdr.*, das_cotdr.* (PDF vector + 300 dpi PNG).
%  Every component is a masked Subsystem with a drawn icon (rectangle, amplifier triangle,
%  circulator ellipse, black coupler ellipse, fibre coil) and holds the same blocks as das_model.
%  Safe to re-run: each model is rebuilt from scratch.

here   = fileparts(mfilename('fullpath'));
scr    = fullfile(here,'..','..','scripts');
mdir   = fullfile(here,'..','model');   fdir = fullfile(here,'..','figures');
if ~exist(mdir,'dir'), mkdir(mdir); end
if ~exist(fdir,'dir'), mkdir(fdir); end
cfg = struct('scr',scr,'mdir',mdir,'fdir',fdir);

build_one('otdr',   cfg);
build_one('phiotdr',cfg);
build_one('cotdr',  cfg);
end

%% ------------------------------------------------------------------ one diagram
function build_one(kind, cfg)
mdl = ['das_' kind];
mfile = fullfile(cfg.mdir,[mdl '.slx']);
if bdIsLoaded(mdl), close_system(mdl,0); end
if exist(mfile,'file'), delete(mfile); end
new_system(mdl);
set_param(mdl,'ScreenColor','white','ShowLineDimensions','off','ShowPortDataTypes','off', ...
    'SampleTimeColors','off','ShowStorageClass','off','ShowTestPointIcons','off');
set_param(0,'HiliteAncestorsData',struct('HiliteType','user1','ForegroundColor','blue','BackgroundColor','white'));

A = 150;                                   % axis (y) of the main upper row
fibre = [];                                % handles of lines drawn in blue

switch kind
case 'otdr'
    c.laser = comp(mdl,'laser','Laser',    'rect', 'laser',  60,A,110,false,cfg);
    c.edfa  = comp(mdl,'edfa', 'EDFA',     'tri',  'EDFA',  240,A, 90,false,cfg);
    c.circ  = comp(mdl,'circ', 'Circulator','ell', 'circulator',420,A,110,false,cfg);
    c.fut   = comp(mdl,'fut_inc','FUT',    'fut',  'FUT',   600,A,200,false,cfg);
    c.pd    = comp(mdl,'pd_pow','PD',      'rect', 'PD',    420,A+130,110,true,cfg);
    param(mdl,c.laser,'(pulsed, P = 10 mW)'); param(mdl,c.edfa,'+10 dB'); param(mdl,c.circ,'0.8 dB');
    param(mdl,c.fut,'2 km SMF'); param(mdl,c.pd,'(power, R = 0.9 A/W)');
    pulse(mdl,205,A);
    link(mdl,c.laser,c.edfa); link(mdl,c.edfa,c.circ);
    fibre(end+1) = link(mdl,c.circ,c.fut);
    fibre(end+1) = back(mdl,c.fut,c.pd,40);
case 'phiotdr'
    c.nll   = comp(mdl,'nll','NLL',        'rect', 'narrow|linewidth laser',60,A,110,false,cfg);
    c.aom   = comp(mdl,'aom','AOM',        'rect', 'AOM',   240,A,110,false,cfg);
    c.edfa  = comp(mdl,'edfa','EDFA',      'tri',  'EDFA',  420,A, 90,false,cfg);
    c.circ  = comp(mdl,'circ','Circulator','ell',  'circulator',600,A,110,false,cfg);
    c.fut   = comp(mdl,'fut_coh','FUT',    'fut',  'FUT',   780,A,200,false,cfg);
    c.pd    = comp(mdl,'pd_int','PD',      'rect', 'PD',    600,A+130,110,true,cfg);
    param(mdl,c.nll,'(5 kHz)'); param(mdl,c.aom,'100 ns'); param(mdl,c.edfa,'+10 dB'); param(mdl,c.circ,'0.8 dB');
    param(mdl,c.fut,'2 km SMF'); param(mdl,c.pd,'(intensity, R = 0.9 A/W)');
    pulse(mdl,385,A);
    link(mdl,c.nll,c.aom); link(mdl,c.aom,c.edfa); link(mdl,c.edfa,c.circ);
    fibre(end+1) = link(mdl,c.circ,c.fut);
    fibre(end+1) = back(mdl,c.fut,c.pd,40);
case 'cotdr'
    Ym = A+140;                                     % axis of the laser + first coupler
    c.nll   = comp(mdl,'nll','NLL',        'rect', 'narrow|linewidth laser',60,Ym,110,false,cfg);
    c.cp1   = comp(mdl,'coupler1','coupler','blk', '',        240,Ym, 50,false,cfg);
    c.aom   = comp(mdl,'aom','AOM',        'rect', 'AOM',   340,A,110,false,cfg);
    c.edfa  = comp(mdl,'edfa','EDFA',      'tri',  'EDFA',  520,A, 90,false,cfg);
    c.circ  = comp(mdl,'circ','Circulator','ell',  'circulator',700,A,110,false,cfg);
    c.fut   = comp(mdl,'fut_coh','FUT',    'fut',  'FUT',   880,A,200,false,cfg);
    c.cp2   = comp(mdl,'coupler2','coupler','blk', '',      830,A+250,50,true,cfg);
    c.pd    = comp(mdl,'pd_iq','PD',       'rect', 'PD',    600,A+250,110,true,cfg);
    param(mdl,c.nll,'(5 kHz)'); param(mdl,c.cp1,'99:1'); param(mdl,c.aom,'100 ns'); param(mdl,c.edfa,'+10 dB');
    param(mdl,c.circ,'0.8 dB'); param(mdl,c.fut,'2 km SMF'); param(mdl,c.cp2,'(beat with LO)');
    param(mdl,c.pd,'(I/Q, R = 0.9 A/W)');
    label(mdl,c.cp1,'coupler'); label(mdl,c.cp2,'coupler');
    pulse(mdl,495,A);
    link(mdl,c.nll,c.cp1);
    % coupler 1: output 1 -> upper branch (up to AOM), output 2 -> LO path along the bottom
    p1 = ports(c.cp1); pa = ports(c.aom); p2 = ports(c.cp2);
    o1 = pos(p1.Outport(1)); o2 = pos(p1.Outport(2)); ia = pos(pa.Inport(1));
    add_line(mdl,[o1; o1(1)+22 o1(2); o1(1)+22 ia(2); ia]);
    yLO = A+250+95;                                  % LO runs along the bottom
    i2 = pos(p2.Inport(2)); xr = i2(1)+30;
    add_line(mdl,[o2; o2(1)+34 o2(2); o2(1)+34 yLO; xr yLO; xr i2(2); i2]);
    link(mdl,c.aom,c.edfa); link(mdl,c.edfa,c.circ);
    fibre(end+1) = link(mdl,c.circ,c.fut);
    % backscatter leaves the FUT, goes down and into the second coupler (input 1)
    pf = ports(c.fut); of = pos(pf.Outport(1)); i1 = pos(p2.Inport(1));
    fibre(end+1) = add_line(mdl,[of; of(1)+30 of(2); of(1)+30 i1(2); i1]);
    % coupler 2 -> PD (both mirrored: output on the left, input on the right)
    add_line(mdl, p2.Outport(1), ports(c.pd).Inport(1));
    pdf = Simulink.Annotation(mdl,'LO path (tap of the laser)');
    pdf.FontName='Helvetica'; pdf.FontSize=11; pdf.Position=[420 yLO+8];
end
for h = fibre, set_param(h,'HiliteAncestors','user1'); end

% white padding so the exported image keeps a margin
padY = A+260;  if strcmp(kind,'cotdr'), padY = A+420; end
for pp = [20 40; 1180 padY]'
    pad = Simulink.Annotation(mdl,'.'); pad.ForegroundColor = 'white'; pad.Position = pp';
end

save_system(mdl, mfile);
open_system(mdl);
set_param(mdl,'PaperOrientation','landscape','PaperPositionMode','auto');
print(['-s' mdl],'-dpdf',fullfile(cfg.fdir,[mdl '.pdf']));
print(['-s' mdl],'-dpng','-r300',fullfile(cfg.fdir,[mdl '.png']));
close_system(mdl,0);
fprintf('Built and exported %s\n', mdl);
end

%% ------------------------------------------------------------------ helpers
function p = pos(portHandle), p = get_param(portHandle,'Position'); end
function p = ports(blk),      p = get_param(blk,'PortHandles');    end

function h = link(mdl, a, b)
h = add_line(mdl, ports(a).Outport(1), ports(b).Inport(1));
end

function h = back(mdl, fut, pd, dx)
%  backscatter: FUT output -> right -> down -> left into the (mirrored) PD input
of = pos(ports(fut).Outport(1));  ip = pos(ports(pd).Inport(1));
h = add_line(mdl,[of; of(1)+dx of(2); of(1)+dx ip(2); ip]);
end

function param(mdl, blk, txt)
p = get_param(blk,'Position');
a = Simulink.Annotation(mdl, txt);
a.FontName = 'Helvetica'; a.FontSize = 11;
a.Position = [(p(1)+p(3))/2 - 2.7*numel(txt)  p(4)+24];
end

function label(mdl, blk, txt)
p = get_param(blk,'Position');
a = Simulink.Annotation(mdl, txt);
a.FontName = 'Helvetica'; a.FontSize = 11;
a.Position = [(p(1)+p(3))/2 - 2.7*numel(txt)  p(2)-26];
end

function pulse(mdl, xc, axisY)
%  rectangular-pulse icon and "pulsed light" label above the line
blk = [mdl '/pulse_' num2str(xc)];
add_block('built-in/Subsystem', blk, 'Position',[xc-20 axisY-38 xc+20 axisY-6]);
Simulink.SubSystem.deleteContents(blk);
set_param(blk,'ShowName','off','BackgroundColor','white','ForegroundColor','white');
m = Simulink.Mask.create(blk);
m.Display = "color('black');plot([0 0.2 0.2 0.8 0.8 1],[0.05 0.05 0.95 0.95 0.05 0.05]);";
a = Simulink.Annotation(mdl,'pulsed light');
a.FontName = 'Helvetica'; a.FontSize = 11; a.Position = [xc-38 axisY-62];
end

function blk = comp(mdl, kind, name, shape, label, x, axisY, w, mirror, cfg)
%  Create one masked Subsystem with the das_model implementation inside.
%  The reference port (the one that must sit on the signal axis) is aligned to axisY.
nm  = [name repmat(' ', 1, numel(find_system(mdl,'SearchDepth',1,'BlockType','SubSystem')))];
blk = [mdl '/' nm];
h = 60;  if any(strcmp(shape,{'blk'})), h = 40; end
add_block('built-in/Subsystem', blk, 'Position',[x axisY-h/2 x+w axisY+h/2]);
Simulink.SubSystem.deleteContents(blk);
fill_inside(blk, kind, cfg);
set_param(blk,'ShowName','off','ShowPortLabels','none','FontName','Helvetica','FontSize',11,'ForegroundColor','black');
icon(blk, shape, label);
if mirror, set_param(blk,'BlockMirror','on'); end
% align the reference port to the axis
ph = get_param(blk,'PortHandles');
if strcmp(kind,'coupler2'),   ref = ph.Outport(1);
elseif ~isempty(ph.Inport),   ref = ph.Inport(1);
else,                         ref = ph.Outport(1); end
rp = get_param(ref,'Position');  dy = axisY - rp(2);
p  = get_param(blk,'Position');  set_param(blk,'Position',p + [0 dy 0 dy]);
end

function icon(blk, shape, label)
blue = '[0.78 0.87 0.97]';
th = 'linspace(0,2*pi,41)';
switch shape
case 'rect'
    parts = strsplit(label,'|');  txt = '';
    for k = 1:numel(parts)
        yy = 0.5 + 0.17*(numel(parts)-1) - 0.34*(k-1);
        txt = [txt 'text(0.5,' num2str(yy) ',''' parts{k} ''',''horizontalAlignment'',''center'',''verticalAlignment'',''middle'');']; %#ok<AGROW>
    end
    d = ['color(''black'');patch([0 1 1 0],[0 0 1 1],' blue ');' txt];
    set_param(blk,'BackgroundColor','white');
case 'tri'
    d = ['color(''black'');patch([0.02 0.02 0.98],[0.02 0.98 0.5],' blue ');plot([0.02 0.02 0.98 0.02],[0.02 0.98 0.5 0.02]);text(0.33,0.5,''' label ''',''horizontalAlignment'',''center'',''verticalAlignment'',''middle'');'];
    set_param(blk,'BackgroundColor','white');
case 'ell'
    d = ['color(''black'');patch(0.5+0.49*cos(' th '),0.5+0.49*sin(' th '),[1 1 1]);plot(0.5+0.49*cos(' th '),0.5+0.49*sin(' th '));text(0.5,0.5,''' label ''',''horizontalAlignment'',''center'',''verticalAlignment'',''middle'');'];
    set_param(blk,'BackgroundColor','white');
case 'blk'
    d = ['color(''black'');patch(0.5+0.49*cos(' th '),0.5+0.49*sin(' th '),[0 0 0]);'];
    set_param(blk,'BackgroundColor','white');
case 'fut'
    loops = '';
    for k = 0:3
        loops = [loops 'plot(' num2str(0.40+0.07*k) '+0.07*cos(' th '),0.62+0.28*sin(' th '));']; %#ok<AGROW>
    end
    d = ['color(''blue'');plot([0 1],[0.34 0.34]);' loops 'color(''black'');text(0.5,0.10,''' label ''',''horizontalAlignment'',''center'');'];
    set_param(blk,'BackgroundColor','white');
end
m = Simulink.Mask.create(blk);
m.Display = d;
try, m.IconUnits = 'normalized'; catch, end
if ~strcmp(shape,'rect'), set_param(blk,'MaskIconFrame','off'); end
end

%% ------------------------------------------------------------------ block contents (as in das_model)
function fill_inside(sub, kind, cfg)
A = @(lib,nm,p,varargin) add_block(['simulink/' lib],[sub '/' nm],'Position',p,varargin{:});
io = @(nin,nout) add_ports(sub,nin,nout);
switch kind
case 'laser'        % pulsed CW source: sqrt(P_laser) * p_frame
    A('Sources/Constant','P',[30 30 100 50],'Value','sqrt(P_laser)','SampleTime','Ts_slow');
    A('Sources/Constant','pf',[30 80 100 100],'Value','p_frame','SampleTime','Ts_slow','VectorParams1D','off');
    A('Math Operations/Product','x',[160 45 190 85],'Inputs','**');
    A('Sinks/Out1','Out1',[240 55 270 69]);
    add_line(sub,'P/1','x/1'); add_line(sub,'pf/1','x/2'); add_line(sub,'x/1','Out1/1');
case 'nll'          % random-walk phase + constant magnitude -> complex field
    A('Sources/Random Number','rn',[20 20 80 50],'Mean','0','Variance','var_phL','SampleTime','Ts_slow');
    A('Math Operations/Sum','S',[120 25 140 45],'Inputs','++');
    A('Discrete/Unit Delay','z',[120 80 150 110],'InitialCondition','0','SampleTime','Ts_slow');
    A('Sources/Constant','mag',[120 130 190 150],'Value','sqrt(P_laser)','SampleTime','Ts_slow');
    A('Math Operations/Magnitude-Angle to Complex','M',[230 40 260 100]);
    A('Sinks/Out1','Out1',[310 65 340 79]);
    add_line(sub,'rn/1','S/1'); add_line(sub,'S/1','z/1'); add_line(sub,'z/1','S/2','autorouting','on');
    add_line(sub,'S/1','M/2','autorouting','on'); add_line(sub,'mag/1','M/1','autorouting','on');
    add_line(sub,'M/1','Out1/1');
case 'aom'
    io(1,1); delete_line(sub,'In1/1','Out1/1');
    A('Sources/Constant','pf',[30 90 100 110],'Value','p_frame','SampleTime','Ts_slow','VectorParams1D','off');
    A('Math Operations/Product','x',[150 40 180 80],'Inputs','**');
    add_line(sub,'In1/1','x/1'); add_line(sub,'pf/1','x/2'); add_line(sub,'x/1','Out1/1');
case 'edfa'
    io(1,1); delete_line(sub,'In1/1','Out1/1');
    A('Math Operations/Gain','g',[120 30 170 60],'Gain','g_edfa');
    add_line(sub,'In1/1','g/1'); add_line(sub,'g/1','Out1/1');
case 'circ'
    io(1,1); delete_line(sub,'In1/1','Out1/1');
    A('Math Operations/Gain','g',[120 30 170 60],'Gain','g_cir');
    add_line(sub,'In1/1','g/1'); add_line(sub,'g/1','Out1/1');
case 'coupler1'
    io(1,2); delete_line(sub,'In1/1','Out1/1');
    A('Math Operations/Gain','gs',[120 20 170 50],'Gain','sqrt(k_sig)');
    A('Math Operations/Gain','gl',[120 90 170 120],'Gain','sqrt(k_lo)');
    add_line(sub,'In1/1','gs/1'); add_line(sub,'In1/1','gl/1','autorouting','on');
    add_line(sub,'gs/1','Out1/1'); add_line(sub,'gl/1','Out2/1','autorouting','on');
case 'coupler2'     % beat of the backscatter with the local oscillator
    io(2,1); delete_line(sub,'In1/1','Out1/1'); delete_line(sub,'In2/1','TermIn2/1'); delete_block([sub '/TermIn2']);
    A('Math Operations/Math Function','cj',[110 90 160 120],'Function','conj');
    A('Math Operations/Product','x',[200 40 230 80],'Inputs','**');
    add_line(sub,'In1/1','x/1','autorouting','on'); add_line(sub,'In2/1','cj/1','autorouting','on');
    add_line(sub,'cj/1','x/2','autorouting','on'); add_line(sub,'x/1','Out1/1','autorouting','on');
case 'fut_inc'      % conventional OTDR: |E|^2 then power impulse response
    io(1,1); delete_line(sub,'In1/1','Out1/1');
    A('Math Operations/Abs','ab',[100 30 130 50]);
    A('Math Operations/Math Function','sq',[160 30 200 50],'Function','square');
    mf = matlab_function(sub,'fiber_incoherent',[240 25 330 75],cfg,{'B_cell','att'});
    add_line(sub,'In1/1','ab/1'); add_line(sub,'ab/1','sq/1'); add_line(sub,'sq/1',[mf '/1']);
    add_line(sub,[mf '/1'],'Out1/1');
case 'fut_coh'      % Phi-OTDR / COTDR: coherent sum of echoes (Shang Eq. 4)
    io(1,1); delete_line(sub,'In1/1','Out1/1');
    A('Sources/Sine Wave','v1',[20 90 60 110],'Amplitude','Phi0(1)','Frequency','2*pi*f_v(1)','SampleTime','Ts_slow');
    A('Sources/Sine Wave','v2',[20 130 60 150],'Amplitude','Phi0(2)','Frequency','2*pi*f_v(2)','SampleTime','Ts_slow');
    A('Signal Routing/Mux','mx',[100 100 105 140],'Inputs','2');
    mf = matlab_function(sub,'fiber_coherent',[200 30 300 120],cfg,{'r','att','g_vib'});
    add_line(sub,'v1/1','mx/1'); add_line(sub,'v2/1','mx/2');
    add_line(sub,'In1/1',[mf '/1']); add_line(sub,'mx/1',[mf '/2'],'autorouting','on');
    add_line(sub,[mf '/1'],'Out1/1');
case 'pd_pow'       % conventional OTDR: power x responsivity
    io(1,0);
    A('Math Operations/Gain','g',[120 30 170 60],'Gain','R_pd');
    A('Sinks/Terminator','t',[220 35 240 55]);
    add_line(sub,'In1/1','g/1'); add_line(sub,'g/1','t/1');
case 'pd_int'       % Phi-OTDR: |E|^2 x responsivity
    io(1,0);
    A('Math Operations/Abs','ab',[100 30 130 50]);
    A('Math Operations/Math Function','sq',[150 30 190 50],'Function','square');
    A('Math Operations/Gain','g',[220 30 270 60],'Gain','R_pd');
    A('Sinks/Terminator','t',[310 35 330 55]);
    add_line(sub,'In1/1','ab/1'); add_line(sub,'ab/1','sq/1'); add_line(sub,'sq/1','g/1'); add_line(sub,'g/1','t/1');
case 'pd_iq'        % COTDR: responsivity on the complex (I + jQ) beat signal
    io(1,0);
    A('Math Operations/Gain','g',[120 30 170 60],'Gain','R_pd');
    A('Sinks/Terminator','t',[220 35 240 55]);
    add_line(sub,'In1/1','g/1'); add_line(sub,'g/1','t/1');
end
end

function add_ports(sub, nin, nout)
for i = 1:nin
    add_block('simulink/Sources/In1',[sub '/In' num2str(i)],'Port',num2str(i),'Position',[30 30+50*(i-1) 60 44+50*(i-1)]);
end
for i = 1:nout
    add_block('simulink/Sinks/Out1',[sub '/Out' num2str(i)],'Port',num2str(i),'Position',[400 30+50*(i-1) 430 44+50*(i-1)]);
end
for i = 1:max(nin,nout)
    if i <= nin && i <= nout
        add_line(sub,['In' num2str(i) '/1'],['Out' num2str(i) '/1']);
    elseif i <= nin && ~(nout == 0 && i == 1)
        add_block('simulink/Sinks/Terminator',[sub '/TermIn' num2str(i)],'Position',[200 30+50*(i-1) 220 44+50*(i-1)]);
        add_line(sub,['In' num2str(i) '/1'],['TermIn' num2str(i) '/1']);
    end
end
end

function nm = matlab_function(sub, fname, p, cfg, paramNames)
%  MATLAB Function block with the das_model code; r/att/g_vib/B_cell become Parameters.
nm = ['FUT_' fname];
blk = [sub '/' nm];
add_block('simulink/User-Defined Functions/MATLAB Function', blk, 'Position', p);
try
    ch = sfroot().find('-isa','Stateflow.EMChart','Path',blk);
    ch.Script = fileread(fullfile(cfg.scr,[fname '.m']));
    for k = 1:numel(paramNames)
        d = ch.find('-isa','Stateflow.Data','Name',paramNames{k});
        if ~isempty(d), d.Scope = 'Parameter'; end
    end
catch ME
    warning('MATLAB Function setup for %s incomplete: %s', fname, ME.message);
end
end
