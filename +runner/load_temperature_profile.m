function profile = load_temperature_profile(profileInfo)
%LOAD_TEMPERATURE_PROFILE Execute a temperature profile function file.

    if ~isstruct(profileInfo) || ~isfield(profileInfo, 'path')
        error('Invalid temperature profile descriptor.');
    end

    [~, ~, ext] = fileparts(profileInfo.path);
    if ~strcmpi(ext, '.m')
        error('Unsupported temperature profile file type: %s', ext);
    end

    profileDir = fileparts(profileInfo.path);
    addpath(profileDir);
    cleanup = onCleanup(@() rmpath(profileDir)); %#ok<NASGU>

    if isempty(profileInfo.functionName)
        error('Temperature profile function name missing for %s.', profileInfo.path);
    end

    profile = feval(str2func(profileInfo.functionName));
    if ~isstruct(profile)
        error('Temperature profile %s must return a struct.', profileInfo.functionName);
    end

    hasMonthly = isfield(profile, 'monthlyTemps') && ~isempty(profile.monthlyTemps);
    hasDaily = isfield(profile, 'dailyProfiles') && ~isempty(profile.dailyProfiles);
    hasHourlyMatrix = isfield(profile, 'hourlyTemps') && ~isempty(profile.hourlyTemps);

    if ~hasMonthly && ~hasDaily && ~hasHourlyMatrix
        error('Temperature profile %s must define monthlyTemps, dailyProfiles, or hourlyTemps.', profileInfo.functionName);
    end

    if hasMonthly
        if numel(profile.monthlyTemps) ~= 12
            error('Temperature profile %s must provide 12 monthly values.', profileInfo.functionName);
        end
        profile.monthlyTemps = profile.monthlyTemps(:)';
    end

    if hasHourlyMatrix
        profile.dailyProfiles = convert_hourly_matrix_to_profiles(profile.hourlyTemps);
        if ~hasMonthly
            profile.monthlyTemps = cellfun(@(dp) mean(dp.temps), profile.dailyProfiles);
        end
    end

    if hasDaily
        if ~iscell(profile.dailyProfiles)
            error('dailyProfiles field in %s must be a cell array.', profileInfo.functionName);
        end
        if ~hasMonthly
            profile.monthlyTemps = cellfun(@(dp) mean(extract_daily_temps(dp)), profile.dailyProfiles);
        end
    end

    if ~isfield(profile, 'name') || isempty(profile.name)
        profile.name = profileInfo.displayName;
    end
    profile.source = profileInfo.path;
end

function profiles = convert_hourly_matrix_to_profiles(hourlyTemps)
    if isempty(hourlyTemps)
        profiles = {};
        return;
    end
    [numMonths, numPoints] = size(hourlyTemps);
    hours = linspace(0, 24, numPoints);
    month_names = {'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'};
    profiles = cell(1, numMonths);
    for idx = 1:numMonths
        label = month_names{min(idx, numel(month_names))};
        profiles{idx} = struct('hours', hours, 'temps', hourlyTemps(idx, :), 'label', label);
    end
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
