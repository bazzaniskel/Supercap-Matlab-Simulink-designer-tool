function environment = normalize_environment(environment)
%NORMALIZE_ENVIRONMENT Standardize environment struct for ambient profiles.
%   Ensures presence of:
%     - temperature_C (overall average)
%     - monthlyTemps (1x12)
%     - dailyProfiles {1x12} with fields hours (0-24), temps, meanTemp, label
%     - mode/profileName/description/source strings

    if nargin == 0 || isempty(environment)
        environment = struct();
    end

    if ~isfield(environment, 'temperature_C')
        environment.temperature_C = [];
    end
    if ~isfield(environment, 'profileName')
        environment.profileName = '';
    end
    if ~isfield(environment, 'description')
        environment.description = '';
    end
    if ~isfield(environment, 'source')
        environment.source = '';
    end
    if ~isfield(environment, 'mode')
        environment.mode = '';
    end
    if ~isfield(environment, 'monthlyTemps') || isempty(environment.monthlyTemps)
        environment.monthlyTemps = [];
    else
        environment.monthlyTemps = environment.monthlyTemps(:)';
    end
    if ~isfield(environment, 'dailyProfiles')
        environment.dailyProfiles = {};
    end

    % Derive monthly temps if missing but daily curves provided.
    if isempty(environment.monthlyTemps) && ~isempty(environment.dailyProfiles)
        environment.monthlyTemps = cellfun(@(dp) mean(extract_daily_temps(dp)), environment.dailyProfiles);
    end

    % If still empty, replicate constant temperature if available.
    if isempty(environment.monthlyTemps) && ~isempty(environment.temperature_C)
        environment.monthlyTemps = repmat(environment.temperature_C, 1, 12);
    end

    % Build daily profiles if missing.
    environment.dailyProfiles = ensure_daily_profiles(environment.dailyProfiles, environment.monthlyTemps);
    environment = solar.apply_cabinet_effect(environment);

    % Recompute monthly temps from daily profiles (ensures consistency).
    if ~isempty(environment.dailyProfiles)
        environment.monthlyTemps = cellfun(@(dp) dp.meanTemp, environment.dailyProfiles);
    elseif isempty(environment.monthlyTemps)
        environment.monthlyTemps = repmat(default_temperature(environment), 1, 12);
    end

    % Average temperature.
    if isempty(environment.temperature_C)
        environment.temperature_C = mean(environment.monthlyTemps);
    end

    if isempty(environment.mode)
        if all(abs(environment.monthlyTemps - environment.monthlyTemps(1)) < 1e-6)
            environment.mode = 'constant';
        else
            environment.mode = 'monthly';
        end
    end
end

function profiles = ensure_daily_profiles(existingProfiles, monthlyTemps)
    month_names = get_month_names();
    num_months = 12;
    if isempty(monthlyTemps)
        monthlyTemps = repmat(default_temperature(), 1, num_months);
    elseif numel(monthlyTemps) < num_months
        monthlyTemps = [monthlyTemps repmat(monthlyTemps(end), 1, num_months - numel(monthlyTemps))];
    else
        monthlyTemps = monthlyTemps(1:num_months);
    end

    if isempty(existingProfiles)
        existingProfiles = {};
    elseif isnumeric(existingProfiles)
        existingProfiles = num2cell(existingProfiles);
    elseif isstruct(existingProfiles)
        existingProfiles = num2cell(existingProfiles);
    elseif ~iscell(existingProfiles)
        existingProfiles = {existingProfiles};
    end

    profiles = cell(1, num_months);
    for idx = 1:num_months
        fallback = monthlyTemps(min(idx, numel(monthlyTemps)));
        if idx <= numel(existingProfiles) && ~isempty(existingProfiles{idx})
            profiles{idx} = normalize_daily_profile_entry(existingProfiles{idx}, fallback, month_names{idx});
        else
            profiles{idx} = build_flat_daily_profile(fallback, month_names{idx});
        end
    end
end

function profile = normalize_daily_profile_entry(entry, fallbackTemp, label)
    if isnumeric(entry)
        temps = entry(:)';
        hours = linspace(0, 24, numel(temps));
    elseif isstruct(entry)
        if isfield(entry, 'temps')
            temps = entry.temps(:)';
        elseif isfield(entry, 'values')
            temps = entry.values(:)';
        elseif isfield(entry, 'temperature')
            temps = entry.temperature(:)';
        else
            error('Daily profile struct must contain ''temps'' or equivalent field.');
        end
        if isfield(entry, 'hours')
            hours = entry.hours(:)';
        elseif isfield(entry, 'time')
            hours = entry.time(:)';
        else
            hours = linspace(0, 24, numel(temps));
        end
    else
        error('Unsupported daily profile entry format.');
    end

    if isempty(temps)
        temps = fallbackTemp;
        hours = [0 24];
    end

    if numel(temps) == 1
        temps = [temps temps];
        hours = [0 24];
    end

    % Ensure hours cover [0, 24].
    [hours, sort_idx] = sort(hours);
    temps = temps(sort_idx);
    if hours(1) > 0
        hours = [0 hours];
        temps = [temps(1) temps];
    end
    if hours(end) < 24
        hours = [hours 24];
        temps = [temps temps(end)];
    end

    profile = struct();
    profile.hours = hours;
    profile.temps = temps;
    profile.meanTemp = trapz(hours, temps) / (hours(end) - hours(1));
    profile.label = label;
end

function profile = build_flat_daily_profile(temp, label)
    profile = struct();
    profile.hours = [0 24];
    profile.temps = [temp temp];
    profile.meanTemp = temp;
    profile.label = label;
end

function temps = extract_daily_temps(entry)
    if isstruct(entry)
        if isfield(entry, 'temps')
            temps = entry.temps;
        elseif isfield(entry, 'values')
            temps = entry.values;
        elseif isfield(entry, 'temperature')
            temps = entry.temperature;
        else
            temps = [];
        end
    else
        temps = entry;
    end
    temps = temps(:)';
end

function temp = default_temperature(environment)
    if nargin == 0 || isempty(environment) || ~isfield(environment, 'temperature_C')
        temp = 25;
    else
        temp = environment.temperature_C;
    end
end

function names = get_month_names()
    names = {'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'};
end
