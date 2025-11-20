function [t_day, T_day] = lifetime_simulate_temperature(env_profile, hours_per_day, rth_cooling, heat_capa, q_active)
%LIFETIME_SIMULATE_TEMPERATURE Analytic RC response for a single-day profile.

    [hours, temps] = prepare_hours(env_profile.hours(:)', env_profile.temps(:)', hours_per_day);
    durations = diff(hours) * 3600;
    ambients = temps(1:end-1);

    tau = max(eps, rth_cooling * heat_capa);
    q_active = max(q_active, 0);

    q_values = zeros(size(durations));
    for k = 1:numel(durations)
        h_start = hours(k);
        q_values(k) = (h_start < hours_per_day - 1e-9) * q_active;
    end

    T = env_profile.meanTemp;
    cycles = 3;
    for cycle = 1:cycles
        if cycle == cycles
            t_day = zeros(1, numel(hours));
            T_day = zeros(1, numel(hours));
            t_day(1) = 0;
            T_day(1) = T;
            t_elapsed = 0;
        end
        for k = 1:numel(durations)
            Tamb = ambients(k);
            Q = q_values(k);
            dt = durations(k);
            T_inf = Tamb + Q * rth_cooling;
            T = T_inf + (T - T_inf) * exp(-dt / tau);
            if cycle == cycles
                t_elapsed = t_elapsed + dt;
                t_day(k+1) = t_elapsed;
                T_day(k+1) = T;
            end
        end
    end
end

function [hours_out, temps_out] = prepare_hours(hours, temps, hours_per_day)
    if isempty(hours)
        hours = 0;
    end
    if isempty(temps)
        temps = 25;
    end

    [hours, ia] = unique(hours, 'stable');
    temps = temps(ia);

    if hours(1) > 0
        hours = [0, hours];
        temps = [temps(1), temps];
    elseif hours(1) < 0
        hours(1) = 0;
    end

    if hours(end) < 24
        hours(end+1) = 24;
        temps(end+1) = temps(end);
    elseif hours(end) > 24
        hours(end) = 24;
    end

    [hours, temps] = insert_boundary(hours, temps, hours_per_day);

    hours_out = hours;
    temps_out = temps;
end

function [hours, temps] = insert_boundary(hours, temps, boundary)
    if boundary <= 0 || boundary >= 24
        return;
    end
    if any(abs(hours - boundary) < 1e-9)
        return;
    end
    for idx = 2:numel(hours)
        if boundary < hours(idx)
            temp_new = interp1(hours([idx-1 idx]), temps([idx-1 idx]), boundary);
            hours = [hours(1:idx-1), boundary, hours(idx:end)];
            temps = [temps(1:idx-1), temp_new, temps(idx:end)];
            return;
        end
    end
    % boundary beyond all points (should not happen because hours end at 24)
    hours(end+1) = boundary;
    temps(end+1) = temps(end);
end
