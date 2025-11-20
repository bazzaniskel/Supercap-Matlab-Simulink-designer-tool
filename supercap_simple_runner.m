%% INTERACTIVE SUPERCAPACITOR SIMULATION RUNNER WITH DESIGN CAPABILITY
% Refactored runner that orchestrates modular components for clarity

clear; clc; close all;

runner.print_banner();
runner.setup_environment();

caseConfig = runner.maybe_load_saved_case();
if isempty(caseConfig)
    caseConfig = runner.build_case();
else
    if isfield(caseConfig, 'metadata') && isfield(caseConfig.metadata, 'name')
        fprintf('\nLoaded configuration: %s\n', caseConfig.metadata.name);
    else
        fprintf('\nLoaded saved configuration.\n');
    end
end

if strcmp(caseConfig.operation.mode, 'design')
    caseConfig = design.optimize_case(caseConfig);
end

caseConfig = config.finalize_case(caseConfig);

runner.print_configuration_summary(caseConfig);

if ~runner.confirm_execution()
    fprintf('Simulation cancelled by user.\n');
    return;
end

if strcmp(caseConfig.operation.mode, 'lifetime')
    lifetime.run_mode(caseConfig);
    return;
end

simOutput = simulation.run_case(caseConfig);

results_folder = results.create_folder(caseConfig);
results.generate_plots(simOutput.Results, results_folder, caseConfig, simOutput.metrics);
results.save_data(results_folder, caseConfig, simOutput);
performance.run_analyses(caseConfig, results_folder);

fprintf('\n===============================================================\n');
fprintf('                    SIMULATION COMPLETE                       \n');
fprintf('===============================================================\n');
fprintf('Total simulation time: %.1f seconds\n', simOutput.elapsed_time);
fprintf('Results saved to: %s\n', results_folder);

results.display_key_results(caseConfig, simOutput);
