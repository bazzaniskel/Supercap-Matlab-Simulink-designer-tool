function results_folder = create_folder(caseConfig)
%CREATE_FOLDER Create descriptive folder for storing outputs.

    if ~exist('results', 'dir')
        mkdir('results');
    end

    timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    if strcmp(caseConfig.operation.mode, 'design')
        mode_str = 'DESIGN';
    else
        mode_str = 'SIM';
    end

    profile_type = caseConfig.profile.mode;
    profile_units = caseConfig.profile.units;
    subfolder_name = sprintf('%s_%s_%s_%dx%d_%.0fV_%.0f%s_%s', ...
        timestamp, ...
        mode_str, ...
        caseConfig.cell.name, ...
        caseConfig.system.seriesModules, ...
        caseConfig.system.parallelModules, ...
        caseConfig.operating.startVoltage, ...
        caseConfig.profile.maxValue, ...
        profile_units, ...
        profile_type);

    subfolder_name = strrep(subfolder_name, ' ', '_');
    subfolder_name = strrep(subfolder_name, '.', 'p');
    subfolder_name = strrep(subfolder_name, '-', 'm');

    results_folder = fullfile('results', subfolder_name);
    if ~exist(results_folder, 'dir')
        mkdir(results_folder);
    end
end
