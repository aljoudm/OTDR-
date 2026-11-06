function build_das_evolution
%BUILD_DAS_EVOLUTION  OTDR -> Phi-OTDR -> COTDR evolution as ONE Simulink figure (Shang Figs. 2-4).
%  Three stacked panels (a), (b), (c) share one column grid, so each component sits in the
%  same column in every panel. Light blue = inherited from the previous panel; coral fill
%  with a thick coral border = new in this panel. Each component is a masked Subsystem whose
%  contents are the das_model blocks. Builds background/model/das_evolution.slx and exports
%  background/figures/das_evolution.{pdf,png}. Safe to re-run.

here = fileparts(mfilename('fullpath'));
mdir = fullfile(here,'..','model');  fdir = fullfile(here,'..','figures');
if ~exist(mdir,'dir'), mkdir(mdir); end
if ~exist(fdir,'dir'), mkdir(fdir); end
mdl = 'das_evolution';  mfile = fullfile(mdir,[mdl '.slx']);
if bdIsLoaded(mdl), close_system(mdl,0); end
if exist(mfile,'file'), delete(mfile); end
new_system(mdl);
set_param(mdl,'ScreenColor','white','ShowLineDimensions','off','ShowPortDataTypes','off', ...
    'SampleTimeColors','off','ShowStorageClass','off','ShowTestPointIcons','off');
set_param(0,'HiliteAncestorsData',[ ...
    struct('HiliteType','user1','ForegroundColor','blue','BackgroundColor','blue'), ...
    struct('HiliteType','user2','ForegroundColor','orange','BackgroundColor','orange')]);

PHI = char(934);
X = struct('laser',40,'cp1',165,'aom',250,'edfa',400,'circ',540,'fut',652,'cp2',650,'pd',740);
AX = [100 350 600];                         % signal axis of the three panels
titles = {'(a) OTDR', ['(b) ' PHI '-OTDR'], '(c) COTDR'};
tags   = {'', '+ NLL, + AOM', '+ 2 couplers, + LO path, + I/Q detection'};
fibre = [];  lo = [];

for p = 1:3
    A = AX(p);  c = struct();
    t = Simulink.Annotation(mdl, titles{p});
    t.FontName = 'Helvetica'; t.FontSize = 15; t.FontWeight = 'bold'; t.Position = [X.laser A-74];
    if ~isempty(tags{p})
        g = Simulink.Annotation(mdl, tags{p});
        g.FontName = 'Helvetica'; g.FontSize = 11; g.BackgroundColor = '[0.98 0.76 0.72]';
        g.Position = [X.laser+170 A-72];
    end
    yRet = A + 115;                                   % row of the detector
    xc   = X.circ + 50;                               % circulator centre (x)

    % ---- source side
    if p == 1
        c.src = comp(mdl,'laser','Laser',   'rect','laser',        X.laser,A,100,50,false);  par(mdl,c.src,'P = 10 mW');
    elseif p == 2
        c.src = comp(mdl,'nll','NLL',       'rect','narrow|linewidth laser',X.laser,A,100,50,true); par(mdl,c.src,'5 kHz');
    else
        c.cp1 = comp(mdl,'coupler1','coupler','ell','',   X.cp1,A,40,30,true,'out1');       par(mdl,c.cp1,'99:1');
        ip = get_param(get_param(c.cp1,'PortHandles').Inport(1),'Position');
        c.src = comp(mdl,'nll','NLL',       'rect','narrow|linewidth laser',X.laser,ip(2),100,50,false); par(mdl,c.src,'5 kHz');
        cap(mdl,c.cp1,'coupler');
    end
    if p >= 2
        c.aom = comp(mdl,'aom','AOM',       'rect','AOM',          X.aom,A,100,50,p==2);      par(mdl,c.aom,'100 ns');
    end
    c.edfa = comp(mdl,'edfa','EDFA',        'tri', 'EDFA',         X.edfa,A, 80,50,false);    par(mdl,c.edfa,'+10 dB');
    c.circ = comp(mdl,'circ','Circulator',  'ell', 'circulator',   X.circ,A,100,50,false);
    c.fut  = comp(mdl,iff(p==1,'fut_inc','fut_coh'),'FUT','fut','FUT',X.fut,A,198,50,false);  par(mdl,c.fut,'2 km SMF');
    % circulator parameter sits beside the return line, not on top of it
    a = Simulink.Annotation(mdl,'0.8 dB'); a.FontName='Helvetica'; a.FontSize=10; a.Position=[xc-8-31 A+25+8];

    % ---- detector side
    if p < 3
        kind = 'pd_pow'; if p == 2, kind = 'pd_int'; end
        c.pd = comp(mdl,kind,'PD','rect','PD',X.pd,yRet,90,50,false);
        par(mdl,c.pd,'intensity');
    else
        c.cp2 = comp(mdl,'coupler2','coupler','ell','',X.cp2,yRet,40,30,true,'out1');  par(mdl,c.cp2,'beat with LO');
        cap(mdl,c.cp2,'coupler');
        c.pd  = comp(mdl,'pd_iq','PD','rect','PD',X.pd,yRet,90,50,true);                par(mdl,c.pd,'I/Q');
    end

    % ---- pulsed light: complete pulse sitting on the line, label just above
    pulse(mdl, 375, A, p);

    % ---- lines (straight, same dark colour; fibre in blue)
    if p == 1
        link(mdl,c.src,c.edfa);
    else
        if p == 3
            link(mdl,c.src,c.cp1); link(mdl,c.cp1,c.aom);
        else
            link(mdl,c.src,c.aom);
        end
        link(mdl,c.aom,c.edfa);
    end
    link(mdl,c.edfa,c.circ);
    fibre(end+1) = link(mdl,c.circ,c.fut);            %#ok<AGROW>
    % return: leaves the circulator from its bottom, goes down, then right (L -> R)
    if p < 3
        ipd = pos(get_param(c.pd,'PortHandles').Inport(1));
        ap = anchor(mdl, xc, A+25, p);
        add_line(mdl,[ap; ap(1) ipd(2); ipd]);
    else
        p2 = get_param(c.cp2,'PortHandles');
        i1 = pos(p2.Inport(1)); i2 = pos(p2.Inport(2));
        ap = anchor(mdl, xc, A+25, p);
        add_line(mdl,[ap; ap(1) i1(2); i1]);
        add_line(mdl, p2.Outport(1), get_param(c.pd,'PortHandles').Inport(1));
        % LO path: second output of the first coupler -> bottom -> second input of coupler 2
        o2 = pos(get_param(c.cp1,'PortHandles').Outport(2));
        yLO = yRet + 62;  xv = i2(1) - 20;
        lo(end+1) = add_line(mdl,[o2; o2(1)+14 o2(2); o2(1)+14 yLO; xv yLO; xv i2(2); i2]); %#ok<AGROW>
        l = Simulink.Annotation(mdl,'LO path (coupler tap of the laser)');
        l.FontName='Helvetica'; l.FontSize=11; l.ForegroundColor='[0.80 0.30 0.22]'; l.Position=[X.aom+20 yLO+8];
    end
end
for h = fibre, set_param(h,'HiliteAncestors','user1'); end
for h = lo,    set_param(h,'HiliteAncestors','user2'); end

% legend
yL = AX(3) + 222;
swatch(mdl,'legend_inherited',X.laser,yL,false);
k1 = Simulink.Annotation(mdl,'Inherited from the previous panel'); k1.FontName='Helvetica'; k1.FontSize=11;
k1.Position=[X.laser+42 yL+2];
swatch(mdl,'legend_new',X.laser+260,yL,true);
k2 = Simulink.Annotation(mdl,'New in this panel'); k2.FontName='Helvetica'; k2.FontSize=11;
k2.Position=[X.laser+302 yL+2];
% white padding so the exported image keeps a margin
for pp = [10 10; 900 yL+40]'
    pad = Simulink.Annotation(mdl,'.'); pad.ForegroundColor = 'white'; pad.Position = pp';
end

save_system(mdl, mfile);
open_system(mdl);
set_param(mdl,'PaperOrientation','portrait','PaperPositionMode','auto');
print(['-s' mdl],'-dpdf',fullfile(fdir,[mdl '.pdf']));
print(['-s' mdl],'-dpng','-r300',fullfile(fdir,[mdl '.png']));
close_system(mdl,0);
fprintf('Built and exported %s\n', mdl);
end

%% ------------------------------------------------------------------ helpers
function r = iff(c,a,b), if c, r = a; else, r = b; end, end
function p = pos(portHandle), p = get_param(portHandle,'Position'); end

function h = link(mdl, a, b)
h = add_line(mdl, get_param(a,'PortHandles').Outport(1), get_param(b,'PortHandles').Inport(1));
end

function par(mdl, blk, txt)
%  parameter text directly under its block: same offset and font everywhere
p = get_param(blk,'Position');
a = Simulink.Annotation(mdl, txt);
a.FontName = 'Helvetica'; a.FontSize = 10;
a.Position = [(p(1)+p(3))/2 - 2.45*numel(txt)  p(4)+8];
end

function cap(mdl, blk, txt)
p = get_param(blk,'Position');
a = Simulink.Annotation(mdl, txt);
a.FontName = 'Helvetica'; a.FontSize = 10;
a.Position = [(p(1)+p(3))/2 - 2.45*numel(txt)  p(2)-24];
end

function ap = anchor(mdl, xc, y, panel)
%  invisible source block whose output port sits at the circulator's bottom edge, so the
%  return line leaves the circulator from below (Simulink blocks only have side ports)
blk = [mdl '/ret' num2str(panel)];
add_block('built-in/Subsystem', blk, 'Position',[xc-1 y-2 xc+1 y]);
Simulink.SubSystem.deleteContents(blk);
add_block('simulink/Sources/Constant',[blk '/c'],'Position',[20 20 50 40]);
add_block('simulink/Sinks/Out1',[blk '/Out1'],'Position',[100 25 130 39]);
add_line(blk,'c/1','Out1/1');
set_param(blk,'Orientation','down','ShowName','off','BackgroundColor','white','ForegroundColor','black','ShowPortLabels','none');
m = Simulink.Mask.create(blk); m.Display = '';
set_param(blk,'MaskIconFrame','off');
ap = get_param(get_param(blk,'PortHandles').Outport(1),'Position');
end

function pulse(mdl, xc, axisY, panel)
%  small complete rectangular pulse standing on the line, label just above it
blk = [mdl '/pulse' num2str(panel)];
add_block('built-in/Subsystem', blk, 'Position',[xc-15 axisY-22 xc+15 axisY-2]);
Simulink.SubSystem.deleteContents(blk);
set_param(blk,'ShowName','off','BackgroundColor','white','ForegroundColor','white');
m = Simulink.Mask.create(blk);
m.Display = "color('black');plot([0.02 0.2 0.2 0.8 0.8 0.98],[0.04 0.04 0.96 0.96 0.04 0.04]);";
try, set_param(blk,'MaskIconFrame','off'); catch, end
a = Simulink.Annotation(mdl,'pulsed light');
a.FontName = 'Helvetica'; a.FontSize = 10; a.Position = [xc-30 axisY-42];
end

function blk = comp(mdl, kind, name, shape, label, x, axisY, w, h, isNew, ref)
%  One masked Subsystem. The reference port is aligned to axisY so signal lines are straight.
if nargin < 11, ref = 'default'; end
nm  = [name repmat(' ', 1, numel(find_system(mdl,'SearchDepth',1,'BlockType','SubSystem')))];
blk = [mdl '/' nm];
add_block('built-in/Subsystem', blk, 'Position',[x axisY-h/2 x+w axisY+h/2]);
Simulink.SubSystem.deleteContents(blk);
fill_inside(blk, kind, struct('scr',fullfile(fileparts(mfilename('fullpath')),'..','..','scripts')));
set_param(blk,'ShowName','off','ShowPortLabels','none','FontName','Helvetica','FontSize',11,'ForegroundColor','black');
ph = get_param(blk,'PortHandles');
q  = get_param(blk,'Position');  hh = q(4) - q(2);
cyF = 0.5;                                          % icon centre (fraction from the bottom)
if strcmp(kind,'coupler1'), cp = ph.Inport(1); elseif strcmp(kind,'coupler2'), cp = ph.Outport(1); else, cp = []; end
if ~isempty(cp), pp = get_param(cp,'Position'); cyF = 1 - (pp(2)-q(2))/hh; end   % ellipse centred on the signal port
icon(blk, shape, label, isNew, cyF, 0.04, 0.08);
switch ref
    case 'out1', r = ph.Outport(1);
    otherwise
        if ~isempty(ph.Inport), r = ph.Inport(1); else, r = ph.Outport(1); end
end
rp = get_param(r,'Position');  dy = axisY - rp(2);
set_param(blk,'Position',q + [0 dy 0 dy]);
end

function swatch(mdl, name, x, y, isNew)
%  legend box drawn exactly like the component boxes
blk = [mdl '/' name];
add_block('built-in/Subsystem', blk, 'Position',[x y x+32 y+20]);
Simulink.SubSystem.deleteContents(blk);
set_param(blk,'ShowName','off','ForegroundColor','black');
icon(blk,'rect','',isNew,0.5,0.10,0.16);
end

function icon(blk, shape, label, isNew, cyF, ix, iy)
%  inherited = light blue + thin black outline; new = coral fill inside ONE thick orange border
blue = '[0.78 0.87 0.97]';  coral = '[0.98 0.76 0.72]';  orng = '[0.98 0.55 0.10]';
th = 'linspace(0,2*pi,61)';
switch shape
    case 'rect', xs = [0.01 0.99 0.99 0.01 0.01];   ys = [0.01 0.01 0.99 0.99 0.01];
    case 'tri',  xs = [0.02 0.02 0.98 0.02];         ys = [0.02 0.98 0.5 0.02];
    otherwise,   xs = []; ys = [];
end
if strcmp(shape,'ell')
    rx = 0.49; ry = 0.46; c0 = num2str(cyF);
    cx = ['0.5+' num2str(rx) '*cos(' th ')'];  cy = [c0 '+' num2str(ry) '*sin(' th ')'];
    if isNew
        cx2 = ['0.5+' num2str(rx-ix*1.7) '*cos(' th ')'];  cy2 = [c0 '+' num2str(ry-iy*1.5) '*sin(' th ')'];
        d = ['patch(' cx ',' cy ',' orng ');patch(' cx2 ',' cy2 ',' coral ');'];
    else
        d = ['patch(' cx ',' cy ',[1 1 1]);color(''black'');plot(' cx ',' cy ');'];
    end
elseif strcmp(shape,'fut')
    loops = '';
    for k = 0:3
        loops = [loops 'plot(' num2str(0.50+0.06*k) '+0.06*cos(' th '),0.74+0.22*sin(' th '));']; %#ok<AGROW>
    end
    d = ['color(''blue'');plot([0 1],[0.5 0.5]);' loops];
elseif isNew          % one thick border = orange patch with a smaller coral patch on top
    c = [mean(xs(1:end-1)) mean(ys(1:end-1))];
    fx = 1 - 2*ix;  fy = 1 - 2*iy;
    if strcmp(shape,'rect'), xi = c(1)+fx*(xs(1:end-1)-c(1)); yi = c(2)+fy*(ys(1:end-1)-c(2)); else, xi = xs; yi = ys; end
    d = ['patch(' mat2str(xs(1:end-1)) ',' mat2str(ys(1:end-1)) ',' orng ');patch(' mat2str(xi) ',' mat2str(yi) ',' coral ');'];
else
    d = ['patch(' mat2str(xs(1:end-1)) ',' mat2str(ys(1:end-1)) ',' blue ');color(''black'');plot(' mat2str(xs) ',' mat2str(ys) ');'];
end
parts = strsplit(label,'|');
tx = 0.5; if strcmp(shape,'tri'), tx = 0.33; end
if strcmp(shape,'fut'), parts = {label}; end
for k = 1:numel(parts)
    yy = 0.5 + 0.17*(numel(parts)-1) - 0.34*(k-1);
    if strcmp(shape,'fut'), yy = 0.16; end
    if ~isempty(parts{k})
        d = [d 'color(''black'');text(' num2str(tx) ',' num2str(yy) ',''' parts{k} ''',''horizontalAlignment'',''center'',''verticalAlignment'',''middle'');']; %#ok<AGROW>
    end
end
set_param(blk,'BackgroundColor','white');
m = Simulink.Mask.create(blk);
m.Display = d;
try, m.IconUnits = 'normalized'; catch, end
set_param(blk,'MaskIconFrame','off');
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
    io(1,0);
    A('Math Operations/Abs','ab',[100 30 130 50]);
    A('Math Operations/Math Function','sq',[160 30 200 50],'Function','square');
    mf = matlab_function(sub,'fiber_incoherent',[240 25 330 75],cfg,{'B_cell','att'});
    add_line(sub,'In1/1','ab/1'); add_line(sub,'ab/1','sq/1'); add_line(sub,'sq/1',[mf '/1']);
    A('Sinks/Terminator','t',[360 40 380 60]); add_line(sub,[mf '/1'],'t/1');
case 'fut_coh'      % Phi-OTDR / COTDR: coherent sum of echoes (Shang Eq. 4)
    io(1,0);
    A('Sources/Sine Wave','v1',[20 90 60 110],'Amplitude','Phi0(1)','Frequency','2*pi*f_v(1)','SampleTime','Ts_slow');
    A('Sources/Sine Wave','v2',[20 130 60 150],'Amplitude','Phi0(2)','Frequency','2*pi*f_v(2)','SampleTime','Ts_slow');
    A('Signal Routing/Mux','mx',[100 100 105 140],'Inputs','2');
    mf = matlab_function(sub,'fiber_coherent',[200 30 300 120],cfg,{'r','att','g_vib'});
    add_line(sub,'v1/1','mx/1'); add_line(sub,'v2/1','mx/2');
    add_line(sub,'In1/1',[mf '/1']); add_line(sub,'mx/1',[mf '/2'],'autorouting','on');
    A('Sinks/Terminator','t',[360 40 380 60]); add_line(sub,[mf '/1'],'t/1');
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
