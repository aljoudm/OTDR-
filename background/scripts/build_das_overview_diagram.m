function build_das_overview_diagram
%BUILD_DAS_OVERVIEW_DIAGRAM  OTDR -> Phi-OTDR -> COTDR evolution as a Simulink block diagram.
%  Adapted from Shang et al., Sensors 2022, Figs. 2-4. Presentation only (empty Subsystems).
%  Builds background/model/das_overview_diagram.slx and exports PDF (vector) + PNG (300 dpi)
%  to background/figures/. Safe to re-run (the model is rebuilt from scratch).

here    = fileparts(mfilename('fullpath'));
mdl     = 'das_overview_diagram';
mfile   = fullfile(here,'..','model',[mdl '.slx']);
figDir  = fullfile(here,'..','figures');
if ~exist(fullfile(here,'..','model'),'dir'), mkdir(fullfile(here,'..','model')); end
if ~exist(figDir,'dir'), mkdir(figDir); end
if bdIsLoaded(mdl), close_system(mdl,0); end
if exist(mfile,'file'), delete(mfile); end
new_system(mdl);
set_param(mdl,'ScreenColor','white','ShowLineDimensions','off','ShowPortDataTypes','off', ...
    'SampleTimeColors','off','ShowStorageClass','off','ShowTestPointIcons','off');

PHI  = char(934);
FONT = 'Helvetica';
GRAY  = '[0.86 0.86 0.86]';      % inherited from the previous system
CORAL = '[0.98 0.76 0.72]';      % new at this stage
CORAL_TXT = [0.75 0.22 0.15];

W = 110;  H = 60;  HD = 90;      % block size; HD = block with two ports on one side
x0 = 70;  pitch = 190;           % column pitch
rowTop = [150 400 650];          % top edge of the blocks in each row
axisY  = rowTop + H/2;           % signal axis of each row

%      name         parameter text      col  new?  nin nout
rows = { ...
  { {'Laser',       '(pulsed)',          1, false, 0, 1}, ...
    {'EDFA',        '(+10 dB)',          3, false, 1, 1}, ...
    {'Circulator',  '(0.8 dB)',          4, false, 1, 1}, ...
    {'FUT',         '(2 km SMF)',        5, false, 1, 1}, ...
    {'PD',          '(intensity)',       6, false, 1, 0} }, ...
  { {'NLL',         '(5 kHz)',           1, true,  0, 1}, ...
    {'AOM',         '(100 ns)',          2, true,  1, 1}, ...
    {'EDFA',        '(+10 dB)',          3, false, 1, 1}, ...
    {'Circulator',  '(0.8 dB)',          4, false, 1, 1}, ...
    {'FUT',         '(2 km SMF)',        5, false, 1, 1}, ...
    {'PD',          '(intensity)',       6, false, 1, 0} }, ...
  { {'NLL',         '(5 kHz)',           1, false, 0, 2}, ...
    {'AOM',         '(100 ns)',          2, false, 1, 1}, ...
    {'EDFA',        '(+10 dB)',          3, false, 1, 1}, ...
    {'Circulator',  '(0.8 dB)',          4, false, 1, 1}, ...
    {'FUT',         '(2 km SMF)',        5, false, 1, 1}, ...
    {'I/Q Rx',      '(LO beat)',         6, true,  2, 0} } };
titles = { 'OTDR: base system', [PHI '-OTDR: adds coherent probe pulses'], 'COTDR: adds a local oscillator' };
% Row 2 of the figure: NLL/AOM are new; row 3: only I/Q Rx and the LO path are new
rows{3}{1}{4} = false;

H_ = cell(3,6);                                          % block handles
for r = 1:3
    % title above the row
    t = Simulink.Annotation(mdl, titles{r});
    t.FontName = FONT; t.FontSize = 15; t.FontWeight = 'bold'; t.Position = [x0 rowTop(r)-62];
    for k = 1:numel(rows{r})
        c = rows{r}{k};
        nm = [c{1} repmat(' ',1,r-1)];                  % unique name; trailing blanks are invisible
        nin = c{5}; nout = c{6};
        hgt = H; if max(nin,nout) == 2, hgt = HD; end
        x = x0 + (c{3}-1)*pitch;
        blk = [mdl '/' strrep(nm,'/','//')];   % '/' in a block name must be escaped as '//'
        add_block('built-in/Subsystem', blk, 'Position',[x rowTop(r) x+W rowTop(r)+hgt]);
        % port structure inside: empty box with just the In/Out ports wired through
        sub = blk;
        Simulink.SubSystem.deleteContents(sub);
        build_inside(sub, nin, nout);
        bg = GRAY; if c{4}, bg = CORAL; end
        set_param(blk,'BackgroundColor',bg,'ForegroundColor','black','ShowPortLabels','none', ...
            'FontName',FONT,'FontSize',12,'DropShadow','off','ContentPreviewEnabled','off');
        % align the first port with the row axis (straight lines)
        ph = get_param(blk,'PortHandles');
        if ~isempty(ph.Inport), py = get_param(ph.Inport(1),'Position');
        else,                   py = get_param(ph.Outport(1),'Position'); end
        pos = get_param(blk,'Position'); dy = axisY(r) - py(2);
        set_param(blk,'Position',pos + [0 dy 0 dy]);
        H_{r,c{3}} = blk;
        % parameter text under the block name
        pos = get_param(blk,'Position');
        a = Simulink.Annotation(mdl, c{2});
        a.FontName = FONT; a.FontSize = 11; a.ForegroundColor = 'black';
        a.Position = [x + W/2 - 2.5*numel(c{2}) pos(4)+26];   % approx. centred under the block name
    end
    % main signal line along the row (straight, block to next block)
    cols = cellfun(@(c) c{3}, rows{r});
    for k = 1:numel(cols)-1
        p1 = get_param(H_{r,cols(k)},'PortHandles'); p2 = get_param(H_{r,cols(k+1)},'PortHandles');
        add_line(mdl, p1.Outport(1), p2.Inport(1));
    end
end

%% LO path (row 3): second output of NLL -> second input of I/Q Rx, routed below the row
nll = get_param(H_{3,1},'PortHandles');  iq = get_param(H_{3,6},'PortHandles');
ps = get_param(nll.Outport(2),'Position'); pe = get_param(iq.Inport(2),'Position');
yLo = rowTop(3) + HD + 75;
pts = [ps; ps(1)+30 ps(2); ps(1)+30 yLo; pe(1)-30 yLo; pe(1)-30 pe(2); pe];
lh = add_line(mdl, pts);
set_param(lh,'Name','');
% coral colour for the LO line (highlight style)
try   % highlight style is the only way to colour a signal line from a script
    set_param(0,'HiliteAncestorsData',struct('HiliteType','user1','ForegroundColor','red','BackgroundColor','white'));
    set_param(lh,'HiliteAncestors','user1');
catch ME
    warning('LO line colour not applied: %s', ME.message);
end
lo = Simulink.Annotation(mdl,'LO path (coupler tap of the laser)');
lo.FontName = FONT; lo.FontSize = 11; lo.ForegroundColor = 'black'; lo.BackgroundColor = CORAL;
lo.Position = [(ps(1)+pe(1))/2-110 yLo+8];

yL = rowTop(3) + HD + 150;
%% White padding so the exported image has a margin around the diagram
for pp = [x0-45 rowTop(1)-110; x0+5*pitch+W+45 yL+60]'
    pad = Simulink.Annotation(mdl,'.'); pad.ForegroundColor = 'white'; pad.Position = pp';
end

%% Legend
yL = rowTop(3) + HD + 150;
g = Simulink.Annotation(mdl,'Inherited from the previous system');
g.FontName = FONT; g.FontSize = 11; g.BackgroundColor = GRAY; g.Position = [x0 yL];
n = Simulink.Annotation(mdl,'New at this stage');
n.FontName = FONT; n.FontSize = 11; n.BackgroundColor = CORAL; n.Position = [x0+300 yL];

save_system(mdl, mfile);

%% Export vector PDF + 300 dpi PNG
open_system(mdl);
set_param(mdl,'PaperOrientation','landscape','PaperPositionMode','auto');
print(['-s' mdl],'-dpdf',fullfile(figDir,'das_overview_diagram.pdf'));
print(['-s' mdl],'-dpng','-r300',fullfile(figDir,'das_overview_diagram.png'));
close_system(mdl,0);
fprintf('Saved %s and exported das_overview_diagram.pdf/.png\n', mfile);
end

function build_inside(sub, nin, nout)
%  Port i of the block = Inport/Outport i. Inport 1 -> Outport 1 when both exist; any
%  unmatched port is closed with a Terminator (inputs) or Ground (outputs).
for i = 1:nin
    add_block('simulink/Sources/In1',[sub '/In' num2str(i)],'Port',num2str(i), ...
        'Position',[40 30+50*(i-1) 70 44+50*(i-1)]);
end
for i = 1:nout
    add_block('simulink/Sinks/Out1',[sub '/Out' num2str(i)],'Port',num2str(i), ...
        'Position',[240 30+50*(i-1) 270 44+50*(i-1)]);
end
for i = 1:max(nin,nout)
    y = 30+50*(i-1);
    if i <= nin && i <= nout
        add_line(sub,['In' num2str(i) '/1'],['Out' num2str(i) '/1']);
    elseif i <= nin
        add_block('simulink/Sinks/Terminator',[sub '/TermIn' num2str(i)],'Position',[140 y 160 y+14]);
        add_line(sub,['In' num2str(i) '/1'],['TermIn' num2str(i) '/1']);
    else
        add_block('simulink/Sources/Ground',[sub '/GndOut' num2str(i)],'Position',[140 y 160 y+14]);
        add_line(sub,['GndOut' num2str(i) '/1'],['Out' num2str(i) '/1']);
    end
end
end
