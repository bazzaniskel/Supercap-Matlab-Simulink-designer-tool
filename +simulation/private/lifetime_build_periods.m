function periods = lifetime_build_periods(environment)
%LIFETIME_BUILD_PERIODS Convert environment struct into weighted monthly periods.

    days_in_month = [31 28 31 30 31 30 31 31 30 31 30 31];
    month_names = {'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'};

    if isfield(environment, 'dailyProfiles') && ~isempty(environment.dailyProfiles)
        profiles = environment.dailyProfiles;
        % Normalise to cell array for consistent indexing
        if ~iscell(profiles)
            profiles = num2cell(profiles);
        end
    else
        profiles = {};
    end
    if isfield(environment, 'monthlyTemps') && ~isempty(environment.monthlyTemps)
        monthlyTemps = environment.monthlyTemps(:)';
    else
        monthlyTemps = [];
    end

    n = 12;
    periods = repmat(struct('profile', [], 'days', 0), 1, n);
    for i = 1:n
        if i <= numel(profiles) && ~isempty(profiles{i})
            dp = profiles{i};
        else
            if ~isempty(monthlyTemps)
                temp = monthlyTemps(min(i, numel(monthlyTemps)));
            else
                temp = environment.temperature_C;
            end
            dp = struct('hours', [0 24], 'temps', [temp temp], 'meanTemp', temp, 'label', month_names{i});
        end
        if ~isfield(dp, 'hours') || isempty(dp.hours)
            dp.hours = [0 24];
        end
        if ~isfield(dp, 'temps') || isempty(dp.temps)
            dp.temps = [environment.temperature_C environment.temperature_C];
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
