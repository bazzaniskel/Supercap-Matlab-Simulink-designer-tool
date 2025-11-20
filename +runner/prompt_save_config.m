function prompt_save_config(caseConfig)
%PROMPT_SAVE_CONFIG Persist the current configuration for reuse.

    if nargin < 1 || isempty(caseConfig)
        fprintf('No configuration available to save.\n');
        return;
    end

    if ~runner.get_yes_no_input('Save this configuration to the configs folder for future runs? (y/n): ')
        fprintf('Configuration not saved.\n');
        return;
    end

    configDir = runner.get_config_directory();
    if ~exist(configDir, 'dir')
        mkdir(configDir);
    end

    defaultDisplayName = '';
    if isfield(caseConfig, 'metadata') && isfield(caseConfig.metadata, 'name')
        defaultDisplayName = caseConfig.metadata.name;
    elseif isfield(caseConfig, 'cell') && isfield(caseConfig.cell, 'name')
        defaultDisplayName = sprintf('%s_%s', caseConfig.cell.name, datestr(now, 'yyyymmdd'));
    else
        defaultDisplayName = sprintf('Config_%s', datestr(now, 'yyyymmdd_HHMMSS'));
    end

    display_prompt = sprintf('Display name for saved configuration [%s]: ', defaultDisplayName);
    display_name = strtrim(input(display_prompt, 's'));
    if isempty(display_name)
        display_name = defaultDisplayName;
    end

    description_prompt = 'Short description (optional): ';
    description = strtrim(input(description_prompt, 's'));

    defaultFileName = lower(regexprep(display_name, '[^a-zA-Z0-9]+', '_'));
    defaultFileName = regexprep(defaultFileName, '_+', '_');
    defaultFileName = strip(defaultFileName, '_');
    if isempty(defaultFileName)
        defaultFileName = sprintf('config_%s', datestr(now, 'yyyymmdd_HHMMSS'));
    end

    file_prompt = sprintf('File name (without extension) [%s]: ', defaultFileName);
    file_name = strtrim(input(file_prompt, 's'));
    if isempty(file_name)
        file_name = defaultFileName;
    end

    file_name = regexprep(file_name, '[^a-zA-Z0-9_]', '_');
    file_path = fullfile(configDir, [file_name '.json']);

    if exist(file_path, 'file')
        overwrite = runner.get_yes_no_input(sprintf('File %s already exists. Overwrite? (y/n): ', file_path));
        if ~overwrite
            fprintf('Save cancelled.\n');
            return;
        end
    end

    if ~isfield(caseConfig, 'metadata') || ~isstruct(caseConfig.metadata)
        caseConfig.metadata = struct();
    end
    caseConfig.metadata.name = display_name;
    caseConfig.metadata.description = description;
    caseConfig.metadata.saved_on = datestr(now);
    caseConfig.metadata.source = file_path;

    try
        jsonStr = jsonencode(caseConfig, 'PrettyPrint', true);
    catch
        jsonStr = jsonencode(caseConfig);
    end
    fid = fopen(file_path, 'w');
    if fid == -1
        error('Could not write configuration file %s', file_path);
    end
    fprintf(fid, '%s\n', jsonStr);
    fclose(fid);
    fprintf('✓ Configuration saved to %s\n', file_path);
end
