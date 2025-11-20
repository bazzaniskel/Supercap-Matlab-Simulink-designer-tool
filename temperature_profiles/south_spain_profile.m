function profile = south_spain_profile()
%SOUTH_SPAIN_PROFILE Representative coastal Southern Spain hourly temperatures.
%   Provides monthly averages plus a detailed 24-point daily profile per month.

    profile = struct();
    profile.name = 'South Spain';
    profile.description = 'Average monthly ambient temperatures for coastal Andalusia (°C)';

    % Monthly averages (°C) from historical climate normals.
    % profile.monthlyTemps = [13 14 15 18 21 25 28 28 25 20 15 12];
    profile.monthlyTemps = [13 14 18 24 36 44 57 56 44 31 18 12];

    % Expected diurnal swing (°C peak-to-peak) per month.
    daily_range = [6 6 7 8 9 11 12 12 10 8 7 6];

    hours = 0:23;
    norm_shape = sin((hours - 6) / 24 * 2*pi); % peaks mid-afternoon, lows pre-dawn
    profile.hourlyTemps = zeros(12, numel(hours));

    month_labels = {'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'};
    profile.dailyProfiles = cell(1, 12);

    for idx = 1:12
        base_temp = profile.monthlyTemps(idx);
        amplitude = daily_range(idx) / 2;
        hourly_curve = base_temp + amplitude * norm_shape;
        profile.hourlyTemps(idx, :) = hourly_curve;
        profile.dailyProfiles{idx} = struct( ...
            'hours', hours, ...
            'temps', hourly_curve, ...
            'label', month_labels{idx});
    end
end
