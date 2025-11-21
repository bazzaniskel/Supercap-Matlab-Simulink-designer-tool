function run_mode(caseConfig)
%RUN_MODE Entry point for lifetime-focused simulations.

    fprintf('\n===============================================================\n');
    fprintf('                LIFETIME SIMULATION MODE                       \n');
    fprintf('===============================================================\n');

    results_folder = results.create_folder(caseConfig);
    periods = lifetime.build_periods(caseConfig.operating.environment);

    if isempty(periods)
        error('Unable to build monthly temperature periods for lifetime simulation.');
    end

    if caseConfig.operation.optimizeVoltage && caseConfig.constraints.voltageOptimization.points > 0
        search_result = lifetime.voltage_search(caseConfig, periods);
    else
        search_result = lifetime.parallel_search(caseConfig, periods, caseConfig.operating.startVoltage);
    end

    if ~search_result.success
        fprintf('\n✗ Lifetime simulation failed: %s\n', search_result.failure_reason);
        return;
    end

    fprintf('\n✓ Lifetime target satisfied with %d parallel modules @ %.1f V start\n', ...
        search_result.min_parallel_modules, search_result.start_voltage);
    fprintf('Achieved lifetime: %.2f years | Final SOH: %.1f%%%%\n', ...
        search_result.timeline.achieved_years, search_result.timeline.final_soh);

    if search_result.mc.enabled
        fprintf('Monte Carlo (%d trials, %.1fth pct): %.2f years (Requirement %.2f years)\n', ...
            search_result.mc.numTrials, search_result.mc.passPercentile, ...
            search_result.mc.passYears, search_result.mc.requirementYears);
    end

    lifetime.plot_soh_history(search_result.timeline, caseConfig, results_folder);
    lifetime.plot_waveform_comparison(search_result.startResults, search_result.endResults, ...
        caseConfig, search_result.min_parallel_modules, results_folder, ...
        caseConfig.operating.SOH_percent, search_result.timeline.final_soh);
    lifetime.plot_steady_temperature(search_result.timeline, search_result.mc, results_folder);
    startMetrics = simulation.compute_metrics(search_result.startResults, search_result.caseConfig);
    results.generate_plots(search_result.startResults, results_folder, search_result.caseConfig, startMetrics);

    lifetime.save_summary(results_folder, caseConfig, search_result);

    performance.run_analyses(search_result.caseConfig, results_folder);

    fprintf('\nResults saved to: %s\n', results_folder);
end
