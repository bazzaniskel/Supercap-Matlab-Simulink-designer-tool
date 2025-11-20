function periods = build_periods(environment)
%BUILD_PERIODS Convert environment struct into weighted monthly periods.

    if nargin == 0 || isempty(environment)
        environment = struct('temperature_C', 25);
    end
    environment = config.normalize_environment(environment);

    days_in_month = [31 28 31 30 31 30 31 31 30 31 30 31];
    month_names = {'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'};

    profiles = environment.dailyProfiles;
    if isempty(profiles)
        profiles = cell(1, 12);
    end
    monthlyTemps = environment.monthlyTemps;
    if isempty(monthlyTemps)
        monthlyTemps = repmat(environment.temperature_C, 1, 12);
    end

    n = 12;
    periods = repmat(struct('profile', [], 'days', 0), 1, n);
    for i = 1:n
        if i <= numel(profiles) && ~isempty(profiles{i})
            dp = profiles{i};
        else
            temp = monthlyTemps(min(i, numel(monthlyTemps)));
            dp = struct('hours', [0 24], 'temps', [temp temp], 'meanTemp', temp, 'label', month_names{i});
        end
        if ~isfield(dp, 'hours') || isempty(dp.hours)
            dp.hours = [0 24];
        end
        if ~isfield(dp, 'temps') || isempty(dp.temps)
            fallback = environment.temperature_C;
            dp.temps = [fallback fallback];
        end
        if ~isfield(dp, 'meanTemp') || isempty(dp.meanTemp)
            dp.meanTemp = trapz(dp.hours, dp.temps) / max(dp.hours(end) - dp.hours(1), eps);
        end
        if ~isfield(dp, 'label') || isempty(dp.label)
            dp.label = month_names{i};
        end
        periods(i).profile = dp;
        periods(i).days = days_in_month(i);
    end
end
