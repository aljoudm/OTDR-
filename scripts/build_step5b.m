function build_step5b
%BUILD_STEP5B  Step 5, part B: wire the two FUT blocks. Safe to re-run.
%  Needs the MATLAB Function blocks FUT_coherent and FUT_incoherent (created by hand).
%  Wiring (nothing existing is moved):
%    Circulator/1 -> FUT_coherent/1 (E_in)        Mux_vib -> FUT_coherent/2 (vib)
%    FUT_coherent/1 (E_R) -> Circulator/2  (backscatter returns through the circulator)
%    Circulator/1 -> Abs_inc -> Sq_inc -> FUT_incoherent/1 (P_in) -> Term_otdr (temporary)
%  The temporary Term_fwd and Ground_bwd of Step 4 are removed.

mdl = 'das_model';
load_system(mdl);
fc = [mdl '/FUT_coherent'];  fi = [mdl '/FUT_incoherent'];
assert(getSimulinkBlockHandle(fc) > 0 && getSimulinkBlockHandle(fi) > 0, ...
    'Create the MATLAB Function blocks FUT_coherent and FUT_incoherent first (see the Step 5 instructions).');

% Step 4 leftovers and previous run of this script
for nm = {'Term_fwd','Ground_bwd','Term_otdr'}
    blk = [mdl '/' nm{1}];
    if getSimulinkBlockHandle(blk) > 0, remove_block_and_lines(blk); end
end
clear_lines(fc); clear_lines(fi);                      % any previous wiring of the two FUT blocks
lh = get_param([mdl '/Abs_inc'],'LineHandles');          % old input line of the |E|^2 chain
if lh.Inport(1) > 0, delete_line(lh.Inport(1)); end
add_line(mdl,'Mux_vib/1',[get_param(fc,'Name') '/2'],'autorouting','on');   % vib input of the FUT

pc = get_param([mdl '/Circulator'],'PortHandles');
pf = get_param(fc,'PortHandles');   pi_ = get_param(fi,'PortHandles');
% forward: circulator -> FUT (coherent) and -> |E|^2 chain
add_line(mdl, pc.Outport(1), pf.Inport(1), 'autorouting','on');
pa = get_param([mdl '/Abs_inc'],'PortHandles');
add_line(mdl, pc.Outport(1), pa.Inport(1), 'autorouting','on');
ps = get_param([mdl '/Sq_inc'],'PortHandles');
add_line(mdl, ps.Outport(1), pi_.Inport(1), 'autorouting','on');
% backward: E_R returns into the circulator (second input), routed below the row
of = get_param(pf.Outport(1),'Position');  ic = get_param(pc.Inport(2),'Position');
add_line(mdl,[of; of(1)+25 of(2); of(1)+25 105; ic(1)-30 105; ic(1)-30 ic(2); ic]);
% temporary end of the incoherent branch
po = get_param(pi_.Outport(1),'Position');
add_block('simulink/Sinks/Terminator',[mdl '/Term_otdr'],'Position',[po(1)+40 po(2)-10 po(1)+60 po(2)+10]);
pt = get_param([mdl '/Term_otdr'],'PortHandles');
add_line(mdl,pi_.Outport(1),pt.Inport(1),'autorouting','on');

% the placeholder notes of part A become real labels (an annotation's text is replaced by a new one)
for an = find_system(mdl,'SearchDepth',1,'FindAll','on','Type','annotation').'
    t = get_param(an,'PlainText');  newt = '';
    if startsWith(t,'FUT (coherent)'),   newt = 'FUT (coherent): sum of echoes, Shang Eq. 4'; end
    if startsWith(t,'FUT (incoherent)'), newt = 'FUT (incoherent): powers add, no phase'; end
    if ~isempty(newt)
        p = get_param(an,'Position');  delete(an);
        n = Simulink.Annotation(mdl,newt);  n.Position = p(1:2);
    end
end

save_system(mdl);
fprintf('Step 5B wired and saved.\n');
end

function clear_lines(blk)
lh = get_param(blk,'LineHandles');
for h = [lh.Inport(:); lh.Outport(:)].'
    if h > 0, delete_line(h); end
end
end

function remove_block_and_lines(blk)
clear_lines(blk);
delete_block(blk);
end
