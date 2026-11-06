function export_model_sections
%EXPORT_MODEL_SECTIONS  Export the whole das_model and each section (Area annotation) as its own image.
%  Output (figures/model_sections/): 00_full_model, 01_source, 02_circulator_fut, 03_detectors,
%  04_vibration, each as PDF (vector) and PNG (300 dpi), with signal sizes and types shown.
%  The model stays ONE connected model; only the images are split.
%  The section PDFs are the full vector PDF with the page box cropped to the area rectangle
%  (scripts/crop_pdf_sections.py, plain Python 3, no extra packages); the PNGs are cropped
%  from the full 300 dpi image with the same rectangle. Re-run after every step.

mdl  = 'das_model';
here = fileparts(mfilename('fullpath'));
out  = fullfile(here,'..','figures','model_sections');
if ~exist(out,'dir'), mkdir(out); end
tmp  = tempname;  mkdir(tmp);
load_system(mdl);

% the four areas, in order of their numbers (1..4)
slugs = {'01_source','02_circulator_fut','03_detectors','04_vibration'};
ann = find_system(mdl,'SearchDepth',1,'FindAll','on','Type','annotation').';
S = struct('name',{},'slug',{},'color',{},'rect',{},'pdf',{});
for h = ann
    if strcmp(get_param(h,'AnnotationType'),'area_annotation')
        nm = get_param(h,'Name');
        k = str2double(regexp(nm,'^\d+','match','once'));
        c = str2num(get_param(h,'BackgroundColor')); %#ok<ST2NM>
        S(k) = struct('name',nm,'slug',slugs{k},'color',c,'rect',get_param(h,'Position'), ...
                      'pdf',fullfile(out,[slugs{k} '.pdf']));
    end
end
assert(numel(S) == 4, 'Run layout_model first: the four Area annotations are missing.');

% overlays on, compile, print the whole diagram
old.dt = get_param(mdl,'ShowPortDataTypes');  old.dim = get_param(mdl,'ShowLineDimensions');
cleanup = onCleanup(@() set_param(mdl,'ShowPortDataTypes',old.dt,'ShowLineDimensions',old.dim));
set_param(mdl,'ShowPortDataTypes','on','ShowLineDimensions','on');
set_param(mdl,'SimulationCommand','update');
set_param(mdl,'PaperOrientation','landscape','PaperPositionMode','auto');
fullpdf = fullfile(out,'00_full_model.pdf');  fullpng = fullfile(out,'00_full_model.png');
print(['-s' mdl],'-dpdf',fullpdf);
print(['-s' mdl],'-dpng','-r300',fullpng);

% vector crops (Python)
spec = struct('sections',S,'margin',10);
sp = fullfile(tmp,'spec.json');  rp = fullfile(tmp,'result.json');
fid = fopen(sp,'w');  fwrite(fid,jsonencode(spec),'char');  fclose(fid);
cmd = sprintf('python "%s" "%s" "%s" "%s"', fullfile(here,'crop_pdf_sections.py'), fullpdf, sp, rp);
[st,msg] = system(cmd);
if st ~= 0, error('PDF cropping failed (is Python 3 on the PATH?): %s', msg); end
% PNG crops: every area is a flat-coloured rectangle, so find it by its colour in the full image
im = imread(fullpng);  [H,W,~] = size(im);
for k = 1:numel(S)
    rgb = reshape(round(S(k).color*255),1,1,3);
    mask = all(abs(double(im) - double(rgb)) <= 2, 3);
    cols = find(sum(mask,1) > 40);  rows = find(sum(mask,2) > 40);
    scale = (max(cols)-min(cols)+1) / (S(k).rect(3)-S(k).rect(1));        % image pixels per model pixel
    m = round(10*scale);
    x0 = max(1,min(cols)-m);  x1 = min(W,max(cols)+m);
    y0 = max(1,min(rows)-m);  y1 = min(H,max(rows)+m);
    imwrite(im(y0:y1,x0:x1,:), fullfile(out,[S(k).slug '.png']));
end
rmdir(tmp,'s');
fprintf('Exported the full model and %d sections to %s\n', numel(S), out);
end
