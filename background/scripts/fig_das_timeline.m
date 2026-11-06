function fig_das_timeline
%FIG_DAS_TIMELINE  DAS development timeline, adapted from Shang et al., Sensors 2022, Fig. 1.
%  16 x 7 cm, Helvetica, exported to background/figures/das_timeline.{pdf,png}.
%  Labels of later events are right-aligned and sit on higher tiers than earlier
%  ones, so no stem ever crosses a label.

outdir = fullfile(fileparts(mfilename('fullpath')),'..','figures');
if ~exist(outdir,'dir'), mkdir(outdir); end

fnt = 'Helvetica';  fsz = 8;  fszT = 8;
ink = [0.15 0.15 0.15];
fig = figure('Units','centimeters','Position',[2 2 16 7],'Color','w','MenuBar','none', ...
    'PaperUnits','centimeters','PaperSize',[16 7],'PaperPosition',[0 0 16 7]);
ax = axes('Parent',fig,'Units','normalized','Position',[0.005 0.01 0.99 0.98]);
hold(ax,'on'); axis(ax,'off');
yl = [-10.5 14.5];
xlim(ax,[1975 2022]); ylim(ax,yl);

%% Background bands (flat light colours) with bold titles at the top
bands = { 1976 2005 [0.90 0.90 0.90]
          2013 2016 [0.84 0.91 0.98]
          2017 2021 [0.98 0.84 0.82] };
for i = 1:size(bands,1)
    patch(ax,[bands{i,1} bands{i,2} bands{i,2} bands{i,1}],yl([1 1 2 2]), ...
        bands{i,3},'EdgeColor','none');
end
ty = yl(2) - 0.4;
text(ax,1990.5,ty,'Qualitative stage','FontName',fnt,'FontSize',fszT,'FontWeight','bold', ...
    'HorizontalAlignment','center','VerticalAlignment','top');
text(ax,2015.4,ty,{'Quantitative','stage'},'FontName',fnt,'FontSize',fszT,'FontWeight','bold', ...
    'HorizontalAlignment','right','VerticalAlignment','top');
text(ax,2016.3,ty,{'Performance','enhancement'},'FontName',fnt,'FontSize',fszT,'FontWeight','bold', ...
    'HorizontalAlignment','left','VerticalAlignment','top');

%% Time axis with ticks
plot(ax,[1975 2022],[0 0],'-','Color',ink,'LineWidth',1);
for yr = 1980:10:2020
    plot(ax,[yr yr],[-0.25 0.25],'-','Color',ink,'LineWidth',0.6);
    text(ax,yr,-0.45,num2str(yr),'FontName',fnt,'FontSize',6,'Color',[0.4 0.4 0.4], ...
        'HorizontalAlignment','center','VerticalAlignment','top');
end

%% Events: year, label lines, side (+1 above / -1 below), stem height, alignment
y = @(yr) ['\bf' num2str(yr) '\rm '];
ev = { 1976 {[y(1976) 'Barnoski:'],'OTDR'}                              +1 1.2 'left'
       1982 {[y(1982) 'Healey:'],'COTDR'}                               -1 1.2 'center'
       1993 {[y(1993) 'Taylor:'],'\Phi-OTDR'}                           +1 1.2 'center'
       2005 {[y(2005) '\Phi-OTDR applied'],'to intrusion detection'}    -1 1.2 'center'
       2013 {[y(2013) 'Newson:'],'3x3 coupler','demodulation'}          +1 0.8 'right'
       2015 {[y(2015) 'Li: PGC'],'demodulation'}                        -1 1.2 'right'
       2016 {[y(2016) 'Dong:'],'IQ demodulation'}                       +1 5.0 'right'
       2017 {[y(2017) 'Ultrafast laser'],'for sensitivity'}              -1 4.2 'right'
       2018 {[y(2018) 'Shang: UWFBG for'],'frequency response'}         +1 8.2 'right'
       2021 {[y(2021) 'Zhang: FDM against'],'coherent fading'}          -1 7.2 'right' };
for i = 1:size(ev,1)
    yr = ev{i,1}; s = ev{i,3}; h = ev{i,4};
    plot(ax,[yr yr],[0 s*h],'-','Color',ink,'LineWidth',0.6);
    plot(ax,yr,0,'o','MarkerSize',4.5,'MarkerFaceColor','w','MarkerEdgeColor',ink,'LineWidth',0.9);
    if s > 0, va = 'bottom'; else, va = 'top'; end
    dx = 0.25 * (strcmp(ev{i,5},'right') - strcmp(ev{i,5},'left'));   % keep text off the stem
    text(ax,yr+dx,s*h+s*0.15,ev{i,2},'FontName',fnt,'FontSize',fsz,'Interpreter','tex', ...
        'HorizontalAlignment',ev{i,5},'VerticalAlignment',va,'Color',ink);
end

%% Export: vector PDF + 300 dpi PNG
print(fig,'-dpdf','-painters',fullfile(outdir,'das_timeline.pdf'));
print(fig,'-dpng','-r300',fullfile(outdir,'das_timeline.png'));
fprintf('Saved das_timeline.pdf / .png in %s\n', outdir);
end
