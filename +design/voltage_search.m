function voltage_result = voltage_search(caseConfig)
%VOLTAGE_SEARCH Grid search across voltage range combined with parallel search.

    constraints = caseConfig.constraints;
    range = constraints.voltageOptimization.range;
    num_points = constraints.voltageOptimization.points;

    fprintf('\n--- VOLTAGE OPTIMIZATION (Grid Search - %d points) ---\n', num_points);
    fprintf('Finding maximum voltage that minimizes parallel modules\n');
    fprintf('Voltage range: %.1f - %.1f V\n', range(1), range(2));

    voltage_result = struct('success', false, 'optimal_voltage', 0, ...
        'min_parallel_modules', inf, 'voltage_results', []);

    test_voltages = linspace(range(1), range(2), num_points);
    grid_start = tic;
    for idx = 1:numel(test_voltages)
        test_voltage = test_voltages(idx);
        fprintf('Point %d/%d: Testing %.1f V... ', idx, num_points, test_voltage);
        test_config = caseConfig;
        test_config.operating.startVoltage = test_voltage;
        result = design.parallel_search(test_config);
        if result.success
            voltage_result.voltage_results = [voltage_result.voltage_results; struct( ...
                'voltage', test_voltage, 'parallel_modules', result.min_parallel_modules, 'success', true)];
            fprintf('SUCCESS (%d modules)\n', result.min_parallel_modules);
        else
            voltage_result.voltage_results = [voltage_result.voltage_results; struct( ...
                'voltage', test_voltage, 'parallel_modules', inf, 'success', false)];
            fprintf('FAILED (%s)\n', result.failure_reason);
        end

        design.print_progress('Voltage grid', idx, num_points, grid_start);
    end

    successful = voltage_result.voltage_results([voltage_result.voltage_results.success]);
    if isempty(successful)
        voltage_result.success = false;
        voltage_result.failure_reason = 'No valid configuration found within voltage range';
        fprintf('\n✗ VOLTAGE OPTIMIZATION FAILED!\n');
        return;
    end

    min_modules = min([successful.parallel_modules]);
    candidates = successful([successful.parallel_modules] == min_modules);
    [~, idx] = max([candidates.voltage]);
    voltage_result.success = true;
    voltage_result.optimal_voltage = candidates(idx).voltage;
    voltage_result.min_parallel_modules = min_modules;

    fprintf('\n✓ VOLTAGE OPTIMIZATION SUCCESSFUL!\n');
    fprintf('Optimal starting voltage: %.1f V\n', voltage_result.optimal_voltage);
    fprintf('Minimum parallel modules: %d\n', voltage_result.min_parallel_modules);
end
