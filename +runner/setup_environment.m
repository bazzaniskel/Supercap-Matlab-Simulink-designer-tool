function setup_environment()
%SETUP_ENVIRONMENT Configure MATLAB path and shared data for the runner.

    fprintf('Setting up simulation environment...\n');

    required_paths = {
        './optimisation_analysis_functions',...
        './supercap_cell',...
        './CellModel',...
        './power_profiles',...
        '.'
    };

    for idx = 1:numel(required_paths)
        target = required_paths{idx};
        if exist(target, 'dir')
            addpath(genpath(target));
            fprintf('✓ Added %s to path\n', target);
        else
            if strcmp(target, './power_profiles')
                fprintf('⚠  Creating power_profiles folder...\n');
                mkdir('power_profiles');
            else
                fprintf('⚠  Warning: %s not found\n', target);
            end
        end
    end

    if exist('ESR.mat', 'file')
        esrData = load('ESR.mat');
        esrFields = fieldnames(esrData);
        for fIdx = 1:numel(esrFields)
            assignin('base', esrFields{fIdx}, esrData.(esrFields{fIdx}));
        end
        fprintf('✓ Loaded ESR.mat\n');
    else
        fprintf('⚠  Warning: ESR.mat not found\n');
    end

    warning('off', 'all');
end
