function lifetime_years = calculate_lifetime_years(Cell_Voltage, Cell_Losses, Cell_Current, ...
    duty_cycle, hours_per_day, environment, rth_cooling, heat_capa, Cell_specs)
%CALCULATE_LIFETIME_YEARS Estimate lifetime using thermal/electrical acceleration factors.

    Cell_MaxRatedTemp_degC = Cell_specs.Cell_MaxRatedTemp_degC;
    Cell_VoltRated_V = Cell_specs.Cell_VoltRated_V;
    Cell_RatedLifetime_h = Cell_specs.Cell_RatedLifetime_h;

    try
        if ~isstruct(environment)
            environment = struct('temperature_C', environment, 'monthlyTemps', []);
        end
        if ~isfield(environment, 'temperature_C') || isempty(environment.temperature_C)
            if isfield(environment, 'monthlyTemps') && ~isempty(environment.monthlyTemps)
                environment.temperature_C = mean(environment.monthlyTemps);
            else
                environment.temperature_C = 25;
            end
        end

        periods = lifetime_build_periods(environment);

        f_v = @(u) (u > 2.5) .* 2.^((u - Cell_VoltRated_V) / 0.2) + ...
                   (u <= 2.5) .* 2.^((u - 2.5) / 0.1771) .* 2.^((2.5 - Cell_VoltRated_V) / 0.2);

        f_t = @(u) (u > Cell_MaxRatedTemp_degC) .* 2.^((u - Cell_MaxRatedTemp_degC) / 20) + ...
                   (u <= Cell_MaxRatedTemp_degC) .* 2.^((u - Cell_MaxRatedTemp_degC) / 8.217);

        time_hours.cycling = hours_per_day * duty_cycle;
        time_hours.idle    = hours_per_day * (1 - duty_cycle);
        time_hours.standby = max(0, 24 - hours_per_day);

        af_v_values = f_v(Cell_Voltage.Data);
        AF_V.cycling = trapz(Cell_Current.Time, af_v_values) / Cell_Current.Time(end);
        AF_V.idle    = f_v(Cell_Voltage.Data(1));
        AF_V.standby = f_v(Cell_VoltRated_V * sqrt(0.5));

        total_days = 0;
        weighted_consumption = 0;
        for pIdx = 1:numel(periods)
            env_profile = periods(pIdx).profile;
            days_in_period = periods(pIdx).days;
            if days_in_period <= 0
                continue;
            end
            fraction_per_day = simulation.lifetime_daily_consumption(env_profile, Cell_Losses, duty_cycle, ...
                hours_per_day, rth_cooling, heat_capa, time_hours, AF_V, f_t, Cell_RatedLifetime_h);
            weighted_consumption = weighted_consumption + fraction_per_day * days_in_period;
            total_days = total_days + days_in_period;
        end

        if weighted_consumption <= 0 || total_days <= 0
            lifetime_years = 1000;
            return;
        end

        avg_fraction_per_day = weighted_consumption / total_days;
        if avg_fraction_per_day <= 0
            lifetime_years = 1000;
            return;
        end

        lifetime_years = (1 / avg_fraction_per_day) / 365.25;
    catch ME
        fprintf('Warning: Lifetime calculation failed: %s\n', ME.message);
        lifetime_years = 1000;
    end
end
