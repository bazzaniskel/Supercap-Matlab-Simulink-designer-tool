function caseConfig = load_case_from_file(configInfo)
%LOAD_CASE_FROM_FILE Load a case configuration from a saved file record.

    if ~isstruct(configInfo) || ~isfield(configInfo, 'path')
        error('Invalid configuration descriptor supplied.');
    end

    [~, ~, ext] = fileparts(configInfo.path);
    switch lower(ext)
        case '.mat'
            data = load(configInfo.path, 'caseConfig');
            if ~isfield(data, 'caseConfig')
                error('MAT-file %s does not contain a ''caseConfig'' variable.', configInfo.path);
            end
            caseConfig = data.caseConfig;
        case '.json'
            raw = fileread(configInfo.path);
            caseConfig = jsondecode(raw);
        case '.m'
            configDir = fileparts(configInfo.path);
            addpath(configDir);
            cleanup = onCleanup(@() rmpath(configDir));
            if isempty(configInfo.functionName)
                error('Configuration function name missing for %s.', configInfo.path);
            end
            caseConfig = feval(str2func(configInfo.functionName));
        otherwise
            error('Unsupported configuration file type: %s', ext);
    end

    if ~isstruct(caseConfig)
        error('Configuration %s did not return a struct.', configInfo.path);
    end

    if ~isfield(caseConfig, 'metadata') || ~isstruct(caseConfig.metadata)
        caseConfig.metadata = struct();
    end
    if ~isfield(caseConfig.metadata, 'name') || isempty(caseConfig.metadata.name)
        caseConfig.metadata.name = configInfo.displayName;
    end
    caseConfig.metadata.source = configInfo.path;
end
