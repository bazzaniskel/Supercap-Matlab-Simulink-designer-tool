function print_environment_stats(environment, header)
%PRINT_ENVIRONMENT_STATS Display monthly min/mean/max for an environment profile.

    if nargin < 2 || isempty(header)
        header = 'Ambient temperature statistics';
    end
    env = environment;
    if ~isfield(env, 'dailyProfiles') || isempty(env.dailyProfiles)
        env = config.normalize_environment(env);
    end
    if ~isfield(env, 'dailyProfiles') || isempty(env.dailyProfiles)
        fprintf('\n%s: unavailable (no daily profiles)\n', header);
        return;
    end

    fprintf('\n%s\n', header);
    fprintf('  Month   Min (°C)   Mean (°C)   Max (°C)\n');
    for idx = 1:numel(env.dailyProfiles)
        dp = env.dailyProfiles{idx};
        temps = dp.temps(:)';
        monthLabel = dp.label;
        if isempty(monthLabel)
            monthLabel = sprintf('%02d', idx);
        end
        fprintf('  %3s    %7.2f    %8.2f    %8.2f\n', monthLabel, min(temps), env.monthlyTemps(idx), max(temps));
    end
end
