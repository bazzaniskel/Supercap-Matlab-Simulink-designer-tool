function profile = template_temperature_profile()
%TEMPLATE_TEMPERATURE_PROFILE Example ambient temperature profile definition.
%   Copy this file, rename it (e.g., south_spain_profile.m), and customise
%   the metadata/temperature values. You can supply:
%     - profile.monthlyTemps : 12 monthly averages (°C)
%     - profile.dailyProfiles : cell array of 12 structs with fields
%           .hours (0-24) and .temps (same size)
%     - profile.hourlyTemps : 12xN matrix with hourly samples per month

    profile = struct();
    profile.name = 'Template profile';
    profile.description = 'Replace with a short description (location, assumptions, etc.)';
    profile.monthlyTemps = [0 0 0 0 0 0 0 0 0 0 0 0]; % 12 entries (Jan -> Dec)

    % Example: simple daily curves (min at 5:00, max at 15:00) for each month.
    hours = [0 5 15 24];
    profile.dailyProfiles = cell(1, 12);
    for idx = 1:12
        avg = profile.monthlyTemps(idx);
        amplitude = 5; % adjust per month if needed
        temps = avg + [-amplitude, -amplitude, amplitude, -amplitude];
        profile.dailyProfiles{idx} = struct('hours', hours, 'temps', temps, ...
            'label', sprintf('Month %02d', idx));
    end
end
