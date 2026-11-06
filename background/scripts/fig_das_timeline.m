function fig_das_timeline
%FIG_DAS_TIMELINE  DAS development as a staircase, adapted from Shang et al., Sensors 2022, Fig. 1.
%  16 x 7 cm. Exports background/figures/das_timeline.{pdf,png}.
%  A double-line "road" climbs three steps (qualitative, quantitative, performance
%  enhancement). Every event is an open circle on the upper line with a vertical stem
%  to a label centred directly above it; stem heights are staggered inside each step.

outdir = fullfile(fileparts(mfilename('fullpath')),'..','figures');
if ~exist(outdir,'dir'), mkdir(outdir); end

fnt = 'Helvetica';  fsz = 8;
fig = figure('Units','centimeters','Position',[2 2 16 7],'Color','w','MenuBar','none', ...
    'PaperUnits','centimeters','PaperSize',[16 7],'PaperPosition',[0 0 16 7]);
ax = axes('Parent',fig,'Units','normalized','Position',[0 0 1 1]);
hold(ax,'on'); axis(ax,'off'); xlim(ax,[0 160]); ylim(ax,[0 72]);

%% The road: upper line and a parallel lower line
S0 = 5;  S1 = 12;  S2 = 19;  S3 = 26;                 % height of each step
up = [  1 S0;  17 S0;  26 S1;  66 S1;  75 S2; 112 S2; 121 S3; 159 S3 ];
gap = 3.5;
lw = 1.1;
plot(ax, up(:,1), up(:,2),       '-k','LineWidth',lw);
plot(ax, up(:,1), up(:,2)-gap,   '-k','LineWidth',lw);
plot(ax, [1 1],[S0-gap S0],'-k','LineWidth',lw);                     % close the left end
plot(ax, [159 159],[S3-gap S3],'-k','LineWidth',lw);

%% Frame with "DAS" and the stage names
rectangle(ax,'Position',[0.4 0.4 159.2 71.2],'LineStyle','--','EdgeColor',[0.25 0.25 0.25],'LineWidth',0.6);
text(ax,3,69,'DAS','FontName','Times New Roman','FontSize',13,'VerticalAlignment','top');
text(ax,46, S1-gap-3.2,'Qualitative stage',      'FontName',fnt,'FontSize',fsz,'HorizontalAlignment','center');
text(ax,93.5,S2-gap-3.2,'Quantitative stage',    'FontName',fnt,'FontSize',fsz,'HorizontalAlignment','center');
text(ax,140,S3-gap-3.2,'Performance enhancement','FontName',fnt,'FontSize',fsz,'HorizontalAlignment','center');

%% Events: x, step height, stem top (= label bottom), label lines
times = char(215);
ev = { 11   S0 14 {'1976, Barnoski','proposed','OTDR','technology'}
       29   S1 20 {'1982, Healey','proposed','COTDR','technology'}
       46   S1 32 {'1993, Taylor','proposed','\Phi-OTDR','technology'}
       63.5 S1 24 {'2005, Taylor','applied','\Phi-OTDR','technology to','intrusion','detection'}
       81   S2 25 {'2013, Newson',['proposed 3' times '3'],'demodulation','algorithm'}
       95   S2 44 {'2015, Li','proposed PGC','demodulation','algorithm'}
       109  S2 25 {'2016, Dong','proposed IQ','demodulation','algorithm'}
       127  S3 30 {'2017, Kevin','used ultrafast','laser to','enhance','sensitivity'}
       140  S3 50 {'2018, Shang','used UWFBG','to improve','frequency','response'}
       148.5 S3 31 {'2021, Zhang','used FDM to','suppress','coherent fading'} };
for i = 1:size(ev,1)
    x = ev{i,1}; y0 = ev{i,2}; y1 = ev{i,3};
    plot(ax,[x x],[y0 y1],'-k','LineWidth',0.7);
    plot(ax,x,y0,'o','MarkerSize',6,'MarkerFaceColor','w','MarkerEdgeColor','k','LineWidth',1);
    text(ax,x,y1+0.6,ev{i,4},'FontName',fnt,'FontSize',fsz,'Interpreter','tex', ...
        'HorizontalAlignment','center','VerticalAlignment','bottom');
end

print(fig,'-dpdf','-painters',fullfile(outdir,'das_timeline.pdf'));
print(fig,'-dpng','-r300',fullfile(outdir,'das_timeline.png'));
fprintf('Saved das_timeline.pdf / .png in %s\n', outdir);
end
