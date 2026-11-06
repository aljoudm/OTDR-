function export_diagram(sys, outname)
%EXPORT_DIAGRAM  Save a model or subsystem diagram as a high-resolution PNG.
%  export_diagram('das_model', 'steps1-3_laser_coupler_aom')
%  export_diagram('das_model/EDFA', 'edfa_subsystem')
%  Turns on the Signal Dimensions and Port Data Types overlays, updates the
%  diagram so the sizes/types are known, prints to figures/diagrams/<outname>.png
%  and then restores the overlay settings. The model file is NOT saved.

mdl = strtok(sys,'/');
load_system(mdl);
outdir = fullfile(fileparts(mfilename('fullpath')),'..','figures','diagrams');
if ~exist(outdir,'dir'), mkdir(outdir); end

old.dt  = get_param(mdl,'ShowPortDataTypes');
old.dim = get_param(mdl,'ShowLineDimensions');
cleanup = onCleanup(@() restore(mdl, old));
set_param(mdl,'ShowPortDataTypes','on','ShowLineDimensions','on');
set_param(mdl,'SimulationCommand','update');         % compile -> sizes and types appear

file = fullfile(outdir,[outname '.png']);
print(['-s' sys], '-dpng', '-r300', file);
fprintf('Saved %s\n', file);
end

function restore(mdl, old)
set_param(mdl,'ShowPortDataTypes',old.dt,'ShowLineDimensions',old.dim);
end
