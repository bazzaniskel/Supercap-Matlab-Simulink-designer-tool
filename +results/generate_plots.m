function generate_plots(Results, results_folder, caseConfig, metrics)
%GENERATE_PLOTS Create visual outputs for the simulation.

    Cell_Current = Results.Sim_Electrical_Ouput.Cell_Current_A;
    Cell_Voltage = Results.Sim_Electrical_Ouput.Cell_Voltage_V;
    Cell_Power = Results.Sim_Electrical_Ouput.Cell_Power_W;
    Cell_Losses = Results.Sim_Electrical_Ouput.Cell_Ploss_W;

    Sim_NumSeriesModules = caseConfig.system.seriesModules;
    user_parallel_modules = caseConfig.system.parallelModules;
    Module_NumCellSeries = caseConfig.system.moduleNumCellSeries;

    System_Voltage = Cell_Voltage.Data * Sim_NumSeriesModules * Module_NumCellSeries;
    System_Current = Cell_Current.Data * user_parallel_modules;
    System_Power = Cell_Power.Data * user_parallel_modules * Sim_NumSeriesModules * Module_NumCellSeries;

    time_vector = Cell_Current.Time;

    figure('Position', [100, 100, 1200, 800]);
    subplot(3,1,1);
    plot(time_vector, System_Current/1e3, 'k-', 'LineWidth', 2);
    ylabel('System Current (kA)');
    title('System Current');
    grid on;
    subplot(3,1,2);
    plot(time_vector, System_Power/1e6, 'b-', 'LineWidth', 2);
    ylabel('System Power (MW)');
    title('System Power');
    grid on;
    subplot(3,1,3);
    plot(time_vector, System_Voltage, 'r-', 'LineWidth', 2);
    hold on;
    yline(caseConfig.operating.systemVoltage.min, 'k--', 'Min Limit', 'LineWidth', 1.5);
    yline(caseConfig.operating.systemVoltage.max, 'k--', 'Max Limit', 'LineWidth', 1.5);
    yline(caseConfig.operating.startVoltage, 'b:', 'Starting V', 'LineWidth', 2);
    xlabel('Time (s)');
    ylabel('System Voltage (V)');
    title('System Voltage');
    legend('Voltage', 'Min Limit', 'Max Limit', 'Start V', 'Location', 'best');
    grid on;
    sgtitle(sprintf('System-Level Analysis - %s (%ds%dp configuration, SOH: %.1f%%)', ...
        caseConfig.cell.name, Sim_NumSeriesModules, user_parallel_modules, caseConfig.operating.SOH_percent), ...
        'FontSize', 14, 'FontWeight', 'bold');
    saveas(gcf, fullfile(results_folder, 'system_analysis.png'));
    savefig(gcf, fullfile(results_folder, 'system_analysis.fig'));
    close(gcf);

    figure('Position', [200, 200, 1200, 800]);
    subplot(3,1,1);
    plot(time_vector, Cell_Current.Data, 'k-', 'LineWidth', 2);
    ylabel('Cell Current (A)');
    title('Cell Current');
    grid on;
    subplot(3,1,2);
    plot(time_vector, Cell_Power.Data, 'b-', 'LineWidth', 2);
    ylabel('Cell Power (W)');
    title('Cell Power');
    grid on;
    subplot(3,1,3);
    plot(time_vector, Cell_Voltage.Data, 'r-', 'LineWidth', 2);
    hold on;
    yline(caseConfig.limits.cellVoltage(1), 'r--', 'Min Limit', 'LineWidth', 1.5);
    yline(caseConfig.limits.cellVoltage(2), 'r--', 'Max Limit', 'LineWidth', 1.5);
    xlabel('Time (s)');
    ylabel('Cell Voltage (V)');
    title('Cell Voltage');
    legend('Voltage', 'Min Limit', 'Max Limit', 'Location', 'best');
    grid on;
    sgtitle('Cell-Level Analysis', 'FontSize', 14, 'FontWeight', 'bold');
    saveas(gcf, fullfile(results_folder, 'cell_analysis.png'));
    close(gcf);

    figure('Position', [300, 300, 1200, 800]);
    R_th = caseConfig.cooling.rthCooling;
    C_th = caseConfig.cell.specs.Cell_HeatCapa_JpK;
    T_amb = caseConfig.operating.environment.temperature_C;
    Q_func = @(t) (t >= 0 && mod(t, 3600*24) <= caseConfig.operating.hoursPerDay*3600)*mean(Cell_Losses.Data)*caseConfig.operating.dutyCycle;
    thermal_ode = @(t, T) (T_amb - T)/(R_th*C_th) + Q_func(t)/C_th;
    [t, T] = ode45(thermal_ode, [0 3600*48], T_amb);
    T = T(t >= 3600*24);
    t = t(t >= 3600*24) - 3600*24;
    h_cell = plot(t/3600, T, 'r-', 'LineWidth', 2);
    hold on;
    handles = h_cell;
    labels = {'Cell Temperature'};
    dailyProfiles = get_env_daily_profiles(caseConfig.operating.environment);
    if ~isempty(dailyProfiles)
        colors = lines(numel(dailyProfiles));
        for idx = 1:numel(dailyProfiles)
            prof = dailyProfiles{idx};
            h = plot(prof.hours, prof.temps, '--', 'Color', colors(idx,:), 'LineWidth', 1.1);
            handles(end+1) = h; %#ok<AGROW>
            labels{end+1} = sprintf('Ambient %s', prof.label); %#ok<AGROW>
        end
    else
        h_amb = yline(T_amb, 'k--', 'Ambient Temperature', 'LineWidth', 1.5);
        handles(end+1) = h_amb;
        labels{end+1} = 'Ambient Temperature';
    end
    h_oper = xline(caseConfig.operating.hoursPerDay, 'g--', 'Operating Hours', 'LineWidth', 1.5);
    handles(end+1) = h_oper;
    labels{end+1} = 'Operating Hours';
    xlabel('Time (hours)');
    ylabel('Temperature (°C)');
    title(sprintf('Thermal Analysis - %s (%d×%d configuration)\nOperating Hours: %.1f h/day', ...
        caseConfig.cell.name, Sim_NumSeriesModules, user_parallel_modules, caseConfig.operating.hoursPerDay), ...
        'FontSize', 14, 'FontWeight', 'bold');
    legend(handles, labels, 'Location', 'bestoutside');
    grid on;
    xlim([0, 24]);
    saveas(gcf, fullfile(results_folder, 'thermal_analysis.png'));
    close(gcf);

    figure('Position', [400, 400, 1200, 800]);
    plot(time_vector, System_Power/1e6, 'b-', 'LineWidth', 2);
    ylabel('System Power (MW)');
    title('System Power Profile');
    grid on;
    saveas(gcf, fullfile(results_folder, 'system_power_profile.png'));
    close(gcf);

    maybe_save_temperature_profile(caseConfig, results_folder);
    maybe_plot_temperature_envelope(caseConfig, metrics, results_folder);
    maybe_plot_lifetime_monte_carlo(metrics, results_folder);
end

function maybe_save_temperature_profile(caseConfig, results_folder)
%MAYBE_SAVE_TEMPERATURE_PROFILE Persist the ambient profile if available.

    if ~isfield(caseConfig.operating, 'environment')
        return;
    end
    environment = caseConfig.operating.environment;
    [month_labels, temps] = get_monthly_temperature_data(environment);
    if isempty(temps)
        temps = repmat(environment.temperature_C, 1, numel(month_labels));
    end
    if isfield(environment, 'profileName') && ~isempty(environment.profileName)
        profile_name = environment.profileName;
    else
        profile_name = 'Constant ambient';
    end

    figure('Position', [300, 300, 1000, 400]);
    bar(1:numel(month_labels), temps, 'FaceColor', [0.2 0.6 0.9]);
    set(gca, 'XTick', 1:numel(month_labels), 'XTickLabel', month_labels);
    ylabel('Temperature (°C)');
    if isfield(environment, 'description') && ~isempty(environment.description)
        title({sprintf('Ambient temperature profile: %s', profile_name); environment.description}, ...
            'FontSize', 14, 'FontWeight', 'bold');
    else
        title(sprintf('Ambient temperature profile: %s', profile_name), 'FontSize', 14, 'FontWeight', 'bold');
    end
    grid on;
    saveas(gcf, fullfile(results_folder, 'ambient_temperature_monthly.png'));
    close(gcf);

    dailyProfiles = get_env_daily_profiles(environment);
    if isempty(dailyProfiles)
        return;
    end

    plot_hourly_profiles(dailyProfiles, results_folder);
    plot_temperature_histograms(dailyProfiles, results_folder);
end

function [month_labels, temps] = get_monthly_temperature_data(environment)
    month_labels = {'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'};
    if isfield(environment, 'monthlyTemps') && ~isempty(environment.monthlyTemps)
        temps = environment.monthlyTemps(:)';
    else
        temps = [];
    end
    if numel(temps) < numel(month_labels)
        temps = [temps repmat(environment.temperature_C, 1, numel(month_labels) - numel(temps))];
    end
end

function dailyProfiles = get_env_daily_profiles(environment)
    if ~isfield(environment, 'dailyProfiles') || isempty(environment.dailyProfiles)
        dailyProfiles = {};
        return;
    end
    dailyProfiles = environment.dailyProfiles;
    month_labels = {'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'};
    for idx = 1:numel(dailyProfiles)
        if ~isfield(dailyProfiles{idx}, 'hours')
            dailyProfiles{idx}.hours = [0 24];
        end
        if ~isfield(dailyProfiles{idx}, 'temps')
            val = environment.temperature_C;
            dailyProfiles{idx}.temps = [val val];
        end
        if ~isfield(dailyProfiles{idx}, 'label') || isempty(dailyProfiles{idx}.label)
            dailyProfiles{idx}.label = month_labels{min(idx, numel(month_labels))};
        end
    end
end

function plot_hourly_profiles(dailyProfiles, results_folder)
    figure('Position', [300, 300, 1100, 500]);
    hold on;
    numProfiles = numel(dailyProfiles);
    colors = lines(numProfiles);
    legend_entries = cell(1, numProfiles);
    for idx = 1:numProfiles
        prof = dailyProfiles{idx};
        plot(prof.hours, prof.temps, 'LineWidth', 1.4, 'Color', colors(idx,:));
        legend_entries{idx} = prof.label;
    end
    xlabel('Hour of day');
    ylabel('Temperature (°C)');
    title('Hourly temperature evolution per month');
    legend(legend_entries, 'Location', 'bestoutside');
    grid on;
    saveas(gcf, fullfile(results_folder, 'ambient_temperature_hourly.png'));
    close(gcf);
end

function plot_temperature_histograms(dailyProfiles, results_folder)
    figure('Position', [200, 200, 1200, 800]);
    numProfiles = numel(dailyProfiles);
    rows = 3;
    cols = 4;
    for idx = 1:min(numProfiles, rows*cols)
        subplot(rows, cols, idx);
        histogram(dailyProfiles{idx}.temps, 'FaceColor', [0.3 0.6 0.8]);
        title(dailyProfiles{idx}.label);
        xlabel('Temperature (°C)');
        ylabel('Count');
        grid on;
    end
    sgtitle('Temperature histograms per month');
    saveas(gcf, fullfile(results_folder, 'ambient_temperature_histograms.png'));
    close(gcf);
end

function maybe_plot_lifetime_monte_carlo(metrics, results_folder)
    if ~isfield(metrics, 'lifetime_monteCarlo') || ~isstruct(metrics.lifetime_monteCarlo)
        return;
    end
    mc = metrics.lifetime_monteCarlo;
    if ~isfield(mc, 'enabled') || ~mc.enabled || ~isfield(mc, 'lifetimes_years') || isempty(mc.lifetimes_years)
        return;
    end

    lifetimes = mc.lifetimes_years;
    figure('Position', [250, 250, 1000, 500]);
    bins = max(10, round(sqrt(numel(lifetimes))));
    histogram(lifetimes, bins, 'FaceColor', [0.5 0.3 0.8]);
    xlabel('Lifetime (years)');
    ylabel('Frequency');
    title(sprintf('Monte Carlo Lifetime Distribution (N = %d)', mc.numTrials));
    grid on;
    xline(mc.p05_years, 'r--', sprintf('5th pct %.1f y', mc.p05_years), 'LineWidth', 1.2);
    xline(mc.mean_years, 'k-', sprintf('Mean %.1f y', mc.mean_years), 'LineWidth', 1.2);
    xline(mc.p95_years, 'g--', sprintf('95th pct %.1f y', mc.p95_years), 'LineWidth', 1.2);
    saveas(gcf, fullfile(results_folder, 'lifetime_montecarlo_hist.png'));
    close(gcf);
end

function maybe_plot_temperature_envelope(caseConfig, metrics, results_folder)
    if ~isfield(metrics, 'lifetime_monteCarlo') || ~isstruct(metrics.lifetime_monteCarlo)
        return;
    end
    mc = metrics.lifetime_monteCarlo;
    if ~isfield(mc, 'enabled') || ~mc.enabled
        return;
    end
    options = mc;
    options.daysPerMonth = max(1, options.daysPerMonth);
    if ~isfield(options, 'temperatureJitter_99pct_C') && isfield(options, 'temperatureJitter_pct')
        options.temperatureJitter_99pct_C = options.temperatureJitter_pct;
    end
    dataset = sample_temperature_envelope(caseConfig.operating.environment, options, options.daysPerMonth);
    if isempty(dataset)
        return;
    end

    months = 0:11;
    figure('Position', [250, 250, 1100, 500]);
    hold on;
    plot_envelope(months, dataset.high, [0.85 0.3 0.3]);
    plot_envelope(months, dataset.low, [0.2 0.4 0.9]);
    xlabel('Month');
    ylabel('Temperature (°C)');
    title('Monthly Temperature Envelope with Monte Carlo Jitter');
    legend({'High 10-90%','High 25-75%','High Mean', ...
        'Low 10-90%','Low 25-75%','Low Mean'}, 'Location', 'best');
    grid on;
    xticks(months);
    xticklabels({'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'});
    saveas(gcf, fullfile(results_folder, 'ambient_temperature_envelope.png'));
    close(gcf);
end

function dataset = sample_temperature_envelope(environment, options, numSamples)
    dataset = struct();
    env = config.normalize_environment(environment);
    if ~isfield(env, 'dailyProfiles') || isempty(env.dailyProfiles)
        dataset = [];
        return;
    end

    if ~isempty(options.randomSeed)
        prev = rng;
        rng(options.randomSeed, 'twister');
        resetRng = true;
    else
        resetRng = false;
    end

    numMonths = numel(env.dailyProfiles);
    highs = zeros(numMonths, numSamples);
    lows = zeros(numMonths, numSamples);
    baseHigh = zeros(1, numMonths);
    baseLow = zeros(1, numMonths);

    jitter = config.resolve_temperature_jitter(options);

    for m = 1:numMonths
        prof = env.dailyProfiles{m};
        baseHigh(m) = max(prof.temps);
        baseLow(m) = min(prof.temps);

        for s = 1:numSamples
            perturbed = simulation.lifetime_perturb_profile(prof, jitter);
            highs(m, s) = max(perturbed.temps);
            lows(m, s) = min(perturbed.temps);
        end
    end

    if resetRng
        rng(prev);
    end

    dataset.high = compute_stats(baseHigh, highs);
    dataset.low = compute_stats(baseLow, lows);
end

function stats = compute_stats(baseLine, samples)
    stats = struct();
    if isempty(samples)
        stats.mean = baseLine;
        stats.p10 = baseLine;
        stats.p25 = baseLine;
        stats.p75 = baseLine;
        stats.p90 = baseLine;
    else
        stats.mean = mean(samples, 2)';
        stats.p10 = prctile(samples, 10, 2)';
        stats.p25 = prctile(samples, 25, 2)';
        stats.p75 = prctile(samples, 75, 2)';
        stats.p90 = prctile(samples, 90, 2)';
    end
end

function plot_envelope(months, stats, color)
    fill_between(months, stats.p10, stats.p90, color, 0.15);
    fill_between(months, stats.p25, stats.p75, color, 0.35);
    plot(months, stats.mean, '-', 'Color', color, 'LineWidth', 2);
end

function fill_between(x, lower, upper, color, alpha)
    fill([x fliplr(x)], [upper fliplr(lower)], color, 'FaceAlpha', alpha, 'EdgeColor', 'none');
end
