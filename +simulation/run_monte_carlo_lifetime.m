function stats = run_monte_carlo_lifetime(Cell_Voltage, Cell_Losses, Cell_Current, ...
    duty_cycle, hours_per_day, environment, rth_cooling, heat_capa, Cell_specs, options)
%RUN_MONTE_CARLO_LIFETIME Perturb ambient curves and evaluate lifetime distribution.

    stats = struct('enabled', false);
    if ~isfield(options, 'enabled') || ~options.enabled
        return;
    end

    Cell_MaxRatedTemp_degC = Cell_specs.Cell_MaxRatedTemp_degC;
    Cell_VoltRated_V = Cell_specs.Cell_VoltRated_V;
    Cell_RatedLifetime_h = Cell_specs.Cell_RatedLifetime_h;

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

    periods = lifetime_build_periods(environment);
    numPeriods = numel(periods);
    if numPeriods == 0
        stats.enabled = false;
        return;
    end

    options = apply_mc_defaults(options);

    prev_rng = [];
    if ~isempty(options.randomSeed)
        prev_rng = rng;
        rng(options.randomSeed, 'twister');
    end

    lifetimes = zeros(options.numTrials, 1);

    jitter = config.resolve_temperature_jitter(options);

    for trial = 1:options.numTrials
        total_fraction = 0;
        total_days = 0;
        for pIdx = 1:numPeriods
            period = periods(pIdx);
            total_days = total_days + period.days;
            day_weight = period.days / options.daysPerMonth;
            for sampleIdx = 1:options.daysPerMonth
                perturbed_profile = simulation.lifetime_perturb_profile(period.profile, jitter);
                fraction = simulation.lifetime_daily_consumption(perturbed_profile, Cell_Losses, duty_cycle, ...
                    hours_per_day, rth_cooling, heat_capa, time_hours, AF_V, f_t, Cell_RatedLifetime_h);
                total_fraction = total_fraction + fraction * day_weight;
            end
        end
        avg_fraction = total_fraction / max(total_days, eps);
        if avg_fraction <= 0
            lifetimes(trial) = 1000;
        else
            lifetimes(trial) = (1 / avg_fraction) / 365.25;
        end
    end

    if ~isempty(prev_rng)
        rng(prev_rng);
    end

    stats.enabled = true;
    stats.numTrials = options.numTrials;
    stats.daysPerMonth = options.daysPerMonth;
    if isfield(options, 'temperatureJitter_99pct_C')
        stats.temperatureJitter_99pct_C = options.temperatureJitter_99pct_C;
    end
    stats.temperatureJitter_pct = options.temperatureJitter_pct;
    stats.smoothingHours = options.smoothingHours;
    stats.randomSeed = options.randomSeed;
    stats.lifetimes_years = lifetimes;
    stats.mean_years = mean(lifetimes);
    stats.min_years = min(lifetimes);
    stats.max_years = max(lifetimes);
    stats.std_years = std(lifetimes);
    stats.p05_years = prctile(lifetimes, 5);
    stats.p50_years = median(lifetimes);
    stats.p95_years = prctile(lifetimes, 95);
end

function options = apply_mc_defaults(options)
    if ~isfield(options, 'numTrials') || options.numTrials <= 0
        options.numTrials = 100;
    end
    if ~isfield(options, 'daysPerMonth') || options.daysPerMonth <= 0
        options.daysPerMonth = 30;
    end
    if ~isfield(options, 'temperatureJitter_99pct_C') || options.temperatureJitter_99pct_C < 0
        options.temperatureJitter_99pct_C = 6;
    end
    if ~isfield(options, 'temperatureJitter_pct') || options.temperatureJitter_pct < 0
        options.temperatureJitter_pct = options.temperatureJitter_99pct_C;
    end
    if ~isfield(options, 'smoothingHours') || options.smoothingHours < 0
        options.smoothingHours = 2;
    end
    if ~isfield(options, 'randomSeed')
        options.randomSeed = [];
    end
end
