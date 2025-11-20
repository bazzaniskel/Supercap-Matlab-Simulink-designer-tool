function configDir = get_config_directory()
%GET_CONFIG_DIRECTORY Return the absolute path to the configs folder.
%   Ensures the folder exists so users can drop saved configurations there.

    runner_root = fileparts(fileparts(mfilename('fullpath')));
    configDir = fullfile(runner_root, 'configs');

    if ~exist(configDir, 'dir')
        mkdir(configDir);
    end
end
