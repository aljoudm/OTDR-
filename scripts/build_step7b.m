function build_step7b
%BUILD_STEP7B  Step 7, part B: the other two DAQ blocks (To Workspace). Safe to re-run.
%  Needs DAQ_otdr (created by hand in Step 7A). Creates DAQ_dd and DAQ_coh with the same settings
%  (Save format Array, Sample time Ts_slow, Variable names trace_dd and trace_coh), removes the
%  temporary Terminators of the detector outputs and calls layout_model to place and wire them.

mdl = 'das_model';
load_system(mdl);
assert(getSimulinkBlockHandle([mdl '/DAQ_otdr']) > 0, 'Create DAQ_otdr first (Step 7A).');

for nm = {'DAQ_dd','DAQ_coh','Term_det_otdr','Term_det_dd','Term_det_coh'}
    blk = [mdl '/' nm{1}];
    if getSimulinkBlockHandle(blk) > 0
        lh = get_param(blk,'LineHandles');
        for h = [lh.Inport(:); lh.Outport(:)].', if h > 0, delete_line(h); end, end
        delete_block(blk);
    end
end

cfg = {'SaveFormat','Array','SampleTime','Ts_slow','MaxDataPoints','inf','Decimation','1'};
add_block('simulink/Sinks/To Workspace',[mdl '/DAQ_dd'],  'VariableName','trace_dd',  cfg{:});
add_block('simulink/Sinks/To Workspace',[mdl '/DAQ_coh'], 'VariableName','trace_coh', cfg{:});
set_param([mdl '/DAQ_otdr'],'VariableName','trace_otdr','SaveFormat','Array','SampleTime','Ts_slow');
save_system(mdl);
layout_model;
fprintf('Step 7B built and saved.\n');
end
