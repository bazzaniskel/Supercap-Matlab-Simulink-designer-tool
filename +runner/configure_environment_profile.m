function [environment, baseTemperature] = configure_environment_profile()
%CONFIGURE_ENVIRONMENT_PROFILE Configure constant or monthly ambient temps.

    fprintf('\n--- AMBIENT TEMPERATURE CONFIGURATION ---\n');

    while true
        fprintf('1. Single constant temperature\n');
        fprintf('2. Load monthly profile from temperature_profiles folder\n');
        fprintf('3. Enter monthly temperatures manually\n');

        choice = runner.get_valid_input('Select option (1-3): ', @(x) any(x == [1, 2, 3]));

        switch choice
            case 1
                temp = runner.get_valid_input('Environmental temperature [°C]: ', @(x) x >= -60 && x <= 120);
                candidate = struct('mode', 'constant', 'temperature_C', temp, ...
                    'monthlyTemps', temp, 'profileName', 'Constant temperature', ...
                    'description', 'User supplied constant ambient temperature', 'source', 'interactive');
            case 2
                candidate = load_profile_from_folder();
            case 3
                candidate = manual_monthly_entry();
        end

        preview = config.normalize_environment(candidate);
        runner.print_environment_stats(preview, sprintf('Preview for profile "%s"', preview.profileName));
        if runner.get_yes_no_input('Use this temperature profile? (y/n): ')
            environment = preview;
            break;
        else
            fprintf('Let''s re-select the ambient profile.\n');
        end
    end

    baseTemperature = environment.temperature_C;
end

function environment = load_profile_from_folder()
    profileDir = runner.get_temperature_profile_directory();
    profiles = runner.list_temperature_profiles(profileDir);

    if isempty(profiles)
        fprintf('No temperature profiles found in %s.\n', profileDir);
        fprintf('Please add *.m files that return a struct with monthlyTemps.\n');
        environment = manual_monthly_entry();
        return;
    end

    fprintf('\nAvailable temperature profiles:\n');
    for idx = 1:numel(profiles)
        fprintf('  %d. %s\n', idx, profiles(idx).displayName);
    end
    selection = runner.get_valid_input(sprintf('Select profile (1-%d): ', numel(profiles)), ...
        @(x) x >= 1 && x <= numel(profiles));

    profile = runner.load_temperature_profile(profiles(selection));
    environment = struct();
    environment.mode = 'monthly';
    environment.profileName = profile.name;
    if isfield(profile, 'description')
        environment.description = profile.description;
    else
        environment.description = '';
    end
    if isfield(profile, 'monthlyTemps')
        environment.monthlyTemps = profile.monthlyTemps(:)';
    else
        environment.monthlyTemps = [];
    end
    if isfield(profile, 'dailyProfiles')
        environment.dailyProfiles = profile.dailyProfiles;
    elseif isfield(profile, 'hourlyTemps')
        environment.dailyProfiles = convert_hourly_matrix_to_profiles(profile.hourlyTemps);
    else
        environment.dailyProfiles = {};
    end
    environment.temperature_C = [];
    environment.source = profile.source;
end

function environment = manual_monthly_entry()
    fprintf('\nEnter average ambient temperature for each month (°C).\n');
    month_names = {'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'};
    temps = zeros(1, 12);
    for idx = 1:12
        prompt = sprintf('  %s average temp [°C]: ', month_names{idx});
        temps(idx) = runner.get_valid_input(prompt, @(x) x >= -60 && x <= 120);
    end
    environment = struct();
    environment.mode = 'monthly';
    environment.profileName = 'Manual entry';
    environment.description = 'User-specified monthly temperatures';
    environment.monthlyTemps = temps;
    environment.dailyProfiles = {};
    environment.temperature_C = [];
    environment.source = 'manual';
end

function profiles = convert_hourly_matrix_to_profiles(hourlyTemps)
    if isempty(hourlyTemps)
        profiles = {};
        return;
    end
    if size(hourlyTemps,2) == 1
        hourlyTemps = hourlyTemps';
    end
    [numMonths, numPoints] = size(hourlyTemps);
    hours = linspace(0, 24, numPoints);
    profiles = cell(1, numMonths);
    month_names = {'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'};
    for idx = 1:numMonths
        profiles{idx} = struct('hours', hours, 'temps', hourlyTemps(idx, :), 'label', month_names{idx});
    end
end
