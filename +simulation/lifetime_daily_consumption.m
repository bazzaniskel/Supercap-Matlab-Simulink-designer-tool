function [fraction, info] = lifetime_daily_consumption(env_profile, Cell_Losses, duty_cycle, hours_per_day, ...
    rth_cooling, heat_capa, time_hours, AF_V, f_t, Cell_RatedLifetime_h)
%LIFETIME_DAILY_CONSUMPTION Fraction of lifetime consumed in a single day.

    if nargout > 1
        info = struct('steadyTemp', NaN, 'meanTemp', NaN, 'maxTemp', NaN);
    end

    if ~isfield(env_profile, 'hours') || isempty(env_profile.hours)
        env_profile.hours = [0 24];
    end
    if ~isfield(env_profile, 'temps') || isempty(env_profile.temps)
        repValue = lifetime_environment_fallback(env_profile);
        env_profile.temps = repmat(repValue, size(env_profile.hours));
    end
    if ~isfield(env_profile, 'meanTemp') || isempty(env_profile.meanTemp)
        env_profile.meanTemp = trapz(env_profile.hours, env_profile.temps) / max(env_profile.hours(end) - env_profile.hours(1), eps);
    end

    q_active = mean(Cell_Losses.Data) * duty_cycle;
    [t_day, T_day] = lifetime_simulate_temperature(env_profile, hours_per_day, rth_cooling, heat_capa, q_active);

    segment_seconds.cycling = time_hours.cycling * 3600;
    segment_seconds.idle    = time_hours.idle * 3600;
    segment_seconds.standby = time_hours.standby * 3600;

    masks.cycling = t_day < segment_seconds.cycling;
    masks.idle    = t_day >= segment_seconds.cycling & t_day < (segment_seconds.cycling + segment_seconds.idle);
    masks.standby = t_day >= (segment_seconds.cycling + segment_seconds.idle);

    AF_T.cycling = lifetime_compute_temperature_af(t_day, T_day, masks.cycling, env_profile.meanTemp, f_t);
    AF_T.idle    = lifetime_compute_temperature_af(t_day, T_day, masks.idle,    env_profile.meanTemp, f_t);
    AF_T.standby = lifetime_compute_temperature_af(t_day, T_day, masks.standby, env_profile.meanTemp, f_t);

    if nargout > 1
        if any(masks.cycling)
            info.steadyTemp = mean(T_day(masks.cycling));
        else
            info.steadyTemp = mean(T_day);
        end
        info.meanTemp = mean(T_day);
        info.maxTemp = max(T_day);
    end

    fraction = 0;
    segments = fieldnames(time_hours);
    for idx = 1:numel(segments)
        name = segments{idx};
        hours_in_segment = time_hours.(name);
        if hours_in_segment <= 0
            continue;
        end
        AF_tot = AF_T.(name) * AF_V.(name);
        if AF_tot <= 0
            continue;
        end
        lifetime_segment_h = Cell_RatedLifetime_h / AF_tot;
        fraction = fraction + hours_in_segment / lifetime_segment_h;
    end
end
