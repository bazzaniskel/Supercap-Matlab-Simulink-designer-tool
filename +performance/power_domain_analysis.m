function power_domain_analysis(caseConfig, results_folder)
%POWER_DOMAIN_ANALYSIS Fixed duration, search max power vs SOH.

    cfg = caseConfig.performance.powerDomain;
    soh_values = 100:-cfg.soh_step:max(cfg.soh_min, 0);
    soh_values = soh_values(:);

    num_points = numel(soh_values);
    max_powers = nan(num_points, 1);
    max_currents = nan(num_points, 1);
    min_voltages = nan(num_points, 1);

    fprintf('\n[Performance] Power-domain search: %.2f s pulse, up to %.1f kW\n', ...
        cfg.pulse_duration_s, cfg.max_power_kW);

    for idx = 1:num_points
        soh = soh_values(idx);
        [best_power, best_metrics] = performance.search_max_power(caseConfig, cfg, soh);
        max_powers(idx) = best_power;
        if ~isempty(best_metrics)
            max_currents(idx) = best_metrics.system_max_current;
            min_voltages(idx) = best_metrics.system_min_voltage;
        end
        fprintf('  SOH %.0f%% -> Max power %.1f kW\n', soh, best_power/1e3);
    end

    data_table = table(soh_values, max_powers/1e3, max_currents, min_voltages, ...
        'VariableNames', {'SOH_percent', 'MaxPower_kW', 'MaxSystemCurrent_A', 'MinSystemVoltage_V'});
    csv_path = fullfile(results_folder, 'power_domain_performance.csv');
    writetable(data_table, csv_path);
    fprintf('  ✓ Power-domain CSV saved to %s\n', csv_path);

    power_values = max_powers;
    [plot_values, plot_units] = performance.scale_power_for_plot(power_values);
    power_label = sprintf('Pulse %.2f s', cfg.pulse_duration_s);
    title_suffix = sprintf('%s (Unit: %s)', power_label, plot_units);

    plot_soh = soh_values;
    plot_power = plot_values;
    plot_currents = max_currents;
    plot_voltages = min_voltages;

    figure('Position', [240, 240, 900, 600]);
    plot(plot_soh, plot_power, 'LineWidth', 2);
    grid on;
    xlabel('State of Health (%)');
    ylabel(sprintf('Max Power (%s)', plot_units));
    title(sprintf('Max Deliverable Power vs SOH (%s)', power_label));
    saveas(gcf, fullfile(results_folder, 'power_domain_power_vs_soh.png'));
    close(gcf);

    figure('Position', [260, 260, 900, 600]);
    yyaxis left;
    plot(plot_soh, plot_currents, 'b-', 'LineWidth', 2);
    hold on;
    plot(plot_soh, plot_power, 'g--', 'LineWidth', 2);
    ylabel(sprintf('Current (A) / Power (%s)', plot_units));
    yyaxis right;
    plot(plot_soh, plot_voltages, 'r-', 'LineWidth', 2);
    ylabel('Minimum System Voltage (V)');
    xlabel('State of Health (%)');
    title(sprintf('Currents, Voltage, Power vs SOH (%s)', title_suffix));
    legend({'Max Current', sprintf('Max Power (%s)', plot_units), 'Min Voltage'}, 'Location', 'best');
    grid on;
    saveas(gcf, fullfile(results_folder, 'power_domain_combined_vs_soh.png'));
    close(gcf);
end
