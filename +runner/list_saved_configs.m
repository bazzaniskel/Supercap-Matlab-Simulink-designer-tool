function configs = list_saved_configs(configDir)
%LIST_SAVED_CONFIGS Discover saved configuration files in the configs folder.

    if nargin < 1 || isempty(configDir)
        configDir = runner.get_config_directory();
    end

    configs = struct('displayName', {}, 'path', {}, 'type', {}, 'typeLabel', {}, 'functionName', {});
    if ~exist(configDir, 'dir')
        return;
    end

    mat_files = dir(fullfile(configDir, '*.mat'));
    json_files = dir(fullfile(configDir, '*.json'));
    m_files = dir(fullfile(configDir, '*.m'));

    configs = [convert_entries(mat_files, 'mat'); ...
        convert_entries(json_files, 'json'); ...
        convert_entries(m_files, 'm')]; %#ok<AGROW>
    configs = sort_configs(configs);
end

function entries = convert_entries(fileList, fileType)
    entries = struct('displayName', {}, 'path', {}, 'type', {}, 'typeLabel', {}, 'functionName', {});
    if isempty(fileList)
        return;
    end
    idx = 1;
    for f = 1:numel(fileList)
        [~, name, ext] = fileparts(fileList(f).name);
        if startsWith(lower(name), 'template')
            continue;
        end
        entries(idx).displayName = name;
        entries(idx).path = fullfile(fileList(f).folder, fileList(f).name);
        entries(idx).type = fileType;
        switch fileType
            case 'mat'
                entries(idx).typeLabel = 'MAT-file';
                entries(idx).functionName = '';
            case 'json'
                entries(idx).typeLabel = 'JSON file';
                entries(idx).functionName = '';
            otherwise
                entries(idx).typeLabel = sprintf('Function (%s)', ext);
                entries(idx).functionName = name;
        end
        idx = idx + 1;
    end
    if idx == 1
        entries = struct('displayName', {}, 'path', {}, 'type', {}, 'typeLabel', {}, 'functionName', {});
    end
end

function sorted = sort_configs(configs)
    if isempty(configs)
        sorted = configs;
        return;
    end
    [~, order] = sort({configs.displayName});
    sorted = configs(order);
end
