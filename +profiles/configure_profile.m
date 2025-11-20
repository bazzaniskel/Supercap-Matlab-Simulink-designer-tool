function profile = configure_profile()
%CONFIGURE_PROFILE Prompt the user to build or load a power/current profile.

    fprintf('\n--- POWER PROFILE CONFIGURATION ---\n');

    fprintf('\n--- POWER PROFILE TYPE ---\n');
    fprintf('1. Current profile\n');
    fprintf('2. Power profile\n');
    profile_type_choice = runner.get_valid_input('Select profile type (1-2): ', @(x) any(x == [1, 2]));

    if profile_type_choice == 1
        profile.mode = 'current';
        profile.switchCurrentOrPower = 1;
        profile.units = 'A';
        profile.name = 'Current';
    else
        profile.mode = 'power';
        profile.switchCurrentOrPower = -1;
        profile.units = 'W';
        profile.name = 'Power';
    end

    fprintf('\n--- PROFILE SOURCE ---\n');
    fprintf('1. Standard pulse\n');
    fprintf('2. Custom profile from file\n');
    source_choice = runner.get_valid_input('Select profile source (1-2): ', @(x) any(x == [1, 2]));

    if source_choice == 1
        profile = configure_standard_pulse(profile);
    else
        profile = load_custom_profile(profile);
    end
end

function profile = configure_standard_pulse(profile)
    fprintf('\n--- STANDARD PULSE CONFIGURATION ---\n');
    
    pulse_duration = runner.get_valid_input('Pulse duration [s]: ', @(x) x > 0);
    magnitude_prompt = sprintf('Pulse magnitude [%s]: ', profile.units);
    pulse_magnitude = runner.get_valid_input(magnitude_prompt, @(x) x ~= 0);
    
    padding_duration = pulse_duration * 0.1;
    total_duration = pulse_duration + 2 * padding_duration;
    time_points = max(round(total_duration * 10000), 5);
    time_vector = linspace(0, total_duration, time_points);

    pulse_start_idx = find(time_vector >= padding_duration, 1);
    pulse_end_idx = find(time_vector >= (padding_duration + pulse_duration), 1);

    system_input = zeros(size(time_vector));
    if ~isempty(pulse_start_idx) && ~isempty(pulse_end_idx)
        system_input(pulse_start_idx:pulse_end_idx-1) = pulse_magnitude;
    end

    profile.time = time_vector;
    profile.systemInput = system_input;
    profile.maxValue = abs(pulse_magnitude);
    profile.description = sprintf('%s pulse: %.1fs duration, %.2f %s magnitude', ...
        profile.name, pulse_duration, pulse_magnitude, profile.units);

    fprintf('Created standard pulse: %s\n', profile.description);
end

function profile = load_custom_profile(profile)
    fprintf('\n--- CUSTOM PROFILE SELECTION ---\n');

    if ~exist('power_profiles', 'dir')
        error('power_profiles folder not found. Please create it and add .m files.');
    end

    profile_files = dir(fullfile('power_profiles', '*.m'));
    if isempty(profile_files)
        error('No power profile files found in power_profiles folder.');
    end

    fprintf('Available power profiles:\n');
    for idx = 1:numel(profile_files)
        fprintf('%d. %s\n', idx, profile_files(idx).name);
    end

    prompt = sprintf('Select profile (1-%d): ', numel(profile_files));
    profile_choice = runner.get_valid_input(prompt, @(x) x >= 1 && x <= numel(profile_files));

    selected_file = profile_files(profile_choice).name;
    [~, file_name] = fileparts(selected_file);
    profile_struct_name = [file_name '_pp'];

    previous_dir = pwd;
    try
        cd('power_profiles');
        run(file_name);
        if ~exist(profile_struct_name, 'var')
            error('Profile script %s did not create %s variable.', selected_file, profile_struct_name);
        end
        profile_data = eval(profile_struct_name);
    catch ME
        cd(previous_dir);
        rethrow(ME);
    end
    cd(previous_dir);

    if ~(isstruct(profile_data) && isfield(profile_data, 'time_data') && isfield(profile_data, 'power_data'))
        error('Invalid profile data structure. Expected time_data and power_data fields.');
    end

    profile.time = profile_data.time_data;
    profile.systemInput = profile_data.power_data;
    profile.maxValue = max(abs(profile_data.power_data));
    if isfield(profile_data, 'description')
        profile.description = profile_data.description;
    else
        profile.description = sprintf('Custom %s profile from %s', profile.name, selected_file);
    end

    fprintf('Successfully loaded profile: %s\n', profile.description);
end
