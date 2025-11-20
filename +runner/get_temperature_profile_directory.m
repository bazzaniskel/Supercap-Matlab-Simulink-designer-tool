function profileDir = get_temperature_profile_directory()
%GET_TEMPERATURE_PROFILE_DIRECTORY Absolute path to temperature_profiles folder.

    runner_root = fileparts(fileparts(mfilename('fullpath')));
    profileDir = fullfile(runner_root, 'temperature_profiles');
    if ~exist(profileDir, 'dir')
        mkdir(profileDir);
    end
end
