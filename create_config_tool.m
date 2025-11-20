%% SUPERCAP CONFIGURATION CREATOR
% Use the interactive runner flow to build a caseConfig and save it for reuse.

clear; clc; close all;

runner.print_banner();
runner.setup_environment();

fprintf('\n===============================================================\n');
fprintf('                  CONFIGURATION CREATION TOOL                 \n');
fprintf('===============================================================\n');

fprintf('\nYou can optionally start from an existing saved configuration.\n');
caseConfig = runner.maybe_load_saved_case();
if isempty(caseConfig)
    fprintf('\nProceeding with interactive inputs to build a new configuration.\n');
    caseConfig = runner.build_case();
else
    if isfield(caseConfig, 'metadata') && isfield(caseConfig.metadata, 'name')
        fprintf('\nLoaded configuration: %s\n', caseConfig.metadata.name);
    else
        fprintf('\nLoaded saved configuration.\n');
    end
end

caseConfig = config.finalize_case(caseConfig);
runner.print_configuration_summary(caseConfig);

runner.prompt_save_config(caseConfig);

fprintf('\nConfiguration tool finished. You can now use supercap_simple_runner to load the saved file.\n');
