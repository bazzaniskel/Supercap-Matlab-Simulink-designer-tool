function time_domain_analysis(caseConfig, results_folder)
%TIME_DOMAIN_ANALYSIS Fixed power, search max duration vs SOH.

    cfg = caseConfig.performance.timeDomain;
    soh_values = 100:-cfg.soh_step:max(cfg.soh_min, 0);
    soh_values = soh_values(:);

    num_points = numel(soh_values);
    max_durations = nan(num_points, 1);
    max_currents = nan(num_points, 1);
    min_voltages = nan(num_points, 1);

    fprintf('\n[Performance] Time-domain search: %.1f kW request, up to %.1f s duration\n', ...
        cfg.requested_power_kW, cfg.max_duration_s);

    for idx = 1:num_points
        soh = soh_values(idx);
        [best_duration, best_metrics] = performance.search_max_duration(caseConfig, cfg, soh);
        max_durations(idx) = best_duration;
        if ~isempty(best_metrics)
            max_currents(idx) = best_metrics.system_max_current;
            min_voltages(idx) = best_metrics.system_min_voltage;
        end
        fprintf('  SOH %.0f%% -> Max duration %.2f s\n', soh, best_duration);
    end

    data_table = table(soh_values, max_durations, max_currents, min_voltages, ...
        'VariableNames', {'SOH_percent', 'MaxPulseDuration_s', 'MaxSystemCurrent_A', 'MinSystemVoltage_V'});
    csv_path = fullfile(results_folder, 'time_domain_performance.csv');
    writetable(data_table, csv_path);
    fprintf('  ✓ Time-domain CSV saved to %s\n', csv_path);

    power_label = performance.format_power_label(cfg.requested_power_W);
    plot_soh = soh_values;
    plot_duration = max_durations;
    plot_currents = max_currents;
    plot_voltages = min_voltages;

    figure('Position', [200, 200, 900, 600]);
    plot(plot_soh, plot_duration, 'LineWidth', 2);
    grid on;
    xlabel('State of Health (%)');
    ylabel('Max Pulse Duration (s)');
    title(sprintf('Max Pulse Duration vs SOH (Request: %s)', power_label));
    saveas(gcf, fullfile(results_folder, 'time_domain_duration_vs_soh.png'));
    close(gcf);

    figure('Position', [220, 220, 900, 600]);
    yyaxis left;
    plot(plot_soh, plot_currents, 'b-', 'LineWidth', 2);
    hold on;
    plot(plot_soh, plot_duration, 'g--', 'LineWidth', 2);
    ylabel('Current (A) / Duration (s)');
    yyaxis right;
    plot(plot_soh, plot_voltages, 'r-', 'LineWidth', 2);
    ylabel('Minimum System Voltage (V)');
    xlabel('State of Health (%)');
    title(sprintf('Currents, Voltage, Duration vs SOH (Request: %s)', power_label));
    legend({'Max Current', 'Max Pulse Duration', 'Min Voltage'}, 'Location', 'best');
    grid on;
    saveas(gcf, fullfile(results_folder, 'time_domain_combined_vs_soh.png'));
    close(gcf);
end
