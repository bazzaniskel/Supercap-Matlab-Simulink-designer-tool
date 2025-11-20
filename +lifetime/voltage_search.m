function best = voltage_search(baseCase, periods)
%VOLTAGE_SEARCH Sweep voltages and run parallel search for each candidate.

    range = baseCase.constraints.voltageOptimization.range;
    points = baseCase.constraints.voltageOptimization.points;
    voltages = linspace(range(1), range(2), points);

    fprintf('\n--- VOLTAGE OPTIMIZATION (LIFETIME MODE) ---\n');
    best = struct('success', false, 'failure_reason', 'No valid voltage point');
    best_modules = inf;

    for idx = 1:numel(voltages)
        v = voltages(idx);
        fprintf('\nTesting start voltage %.1f V (%d/%d)\n', v, idx, numel(voltages));
        result = lifetime.parallel_search(baseCase, periods, v);
        if result.success && result.min_parallel_modules < best_modules
            best = result;
            best_modules = result.min_parallel_modules;
        elseif ~result.success && ~best.success
            best = result;
        end
    end
end
