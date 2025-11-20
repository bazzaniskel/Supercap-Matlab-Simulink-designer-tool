function display_key_results(caseConfig, simOutput)
%DISPLAY_KEY_RESULTS Print concise summary to console.

    metrics = simOutput.metrics;

    fprintf('\n===============================================================\n');
    fprintf('                    KEY RESULTS SUMMARY                       \n');
    fprintf('===============================================================\n');
    fprintf('Configuration: %s - %ds × %dp\n', caseConfig.cell.name, caseConfig.system.seriesModules, caseConfig.system.parallelModules);
    fprintf('SOH: %.1f%% | Start Voltage: %.1f V | Duty: %.1f%% | Hours/Day: %.1f\n', ...
        caseConfig.operating.SOH_percent, caseConfig.operating.startVoltage, caseConfig.operating.dutyCycle*100, caseConfig.operating.hoursPerDay);
    fprintf('System Current: Max %.1f A, RMS %.1f A | Cell Current: Max %.2f A, RMS %.2f A\n', ...
        metrics.system_max_current, metrics.system_rms_current, metrics.cell_max_current, metrics.cell_rms_current);
    fprintf('System Voltage: %.1f - %.1f V (limits %.1f - %.1f V)\n', ...
        metrics.system_min_voltage, metrics.system_max_voltage, caseConfig.operating.systemVoltage.min, caseConfig.operating.systemVoltage.max);
    fprintf('System Power: Max %.2f MW\n', metrics.system_max_power/1e6);
    fprintf('Losses: Cell Avg %.3f W | Cell Max %.3f W | System Avg %.2f kW | System Max %.2f kW\n', ...
        metrics.cell_average_losses, metrics.cell_max_losses, metrics.system_average_losses/1e3, metrics.system_max_losses/1e3);
    fprintf('Estimated Steady Temp: %.2f°C (Rise %.2f°C)\n', metrics.estimated_steady_temp, metrics.estimated_temp_rise);
    fprintf('Lifetime estimate: %.1f years\n', metrics.lifetime_years);
    if isfield(metrics, 'lifetime_monteCarlo') && isstruct(metrics.lifetime_monteCarlo) ...
            && isfield(metrics.lifetime_monteCarlo, 'enabled') && metrics.lifetime_monteCarlo.enabled
        mc = metrics.lifetime_monteCarlo;
        fprintf('Monte Carlo (N=%d): mean %.1f y, 5th pct %.1f y, min %.1f y\n', ...
            mc.numTrials, mc.mean_years, mc.p05_years, mc.min_years);
    end
    if caseConfig.thermal.enableDutyCycleSearch
        fprintf('Max duty cycle for %.1f-year requirement: %.1f%%\n', caseConfig.thermal.minLifetimeYears, metrics.max_duty_cycle*100);
    end
end
