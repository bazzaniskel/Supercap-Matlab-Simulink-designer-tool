function design_result = parallel_search(caseConfig)
%PARALLEL_SEARCH Binary search for minimum parallel modules satisfying constraints.

    constraints = caseConfig.constraints;
    design_result = init_result_struct();
    max_parallel_modules = constraints.maxParallelModules;
    divisor = max(1, constraints.parallelDivisor);

    lower_bound = 1;
    upper_bound = max_parallel_modules;
    min_valid_modules = 0;
    iteration = 0;
    max_iterations = ceil(log2(max_parallel_modules)) + 5;

    fprintf('\n--- BINARY SEARCH FOR MINIMUM PARALLEL MODULES ---\n');
    fprintf('Search range: 1 to %d parallel modules\n', max_parallel_modules);
    if constraints.currentLimit.enabled
        fprintf('Maximum current constraint: %.1f A\n', constraints.currentLimit.maxSystemCurrent);
    else
        fprintf('No current limit constraint\n');
    end
    if constraints.lifetime.enabled
        fprintf('Minimum lifetime requirement: %.1f years\n', constraints.lifetime.minYears);
    else
        fprintf('No lifetime limit constraint\n');
    end
    fprintf('Voltage window: %.1f - %.1f V\n', ...
        caseConfig.operating.systemVoltage.min, caseConfig.operating.systemVoltage.max);
    if divisor > 1
        fprintf('Divisibility constraint: Must be divisible by %d\n', divisor);
    end

    search_start = tic;

    while lower_bound <= upper_bound && iteration < max_iterations
        iteration = iteration + 1;
        test_modules = floor((lower_bound + upper_bound) / 2);
        fprintf('Iteration %d: Testing %d parallel modules... ', iteration, test_modules);

        [is_valid, test_result] = design.test_configuration(caseConfig, test_modules);
        design_result.max_tested_modules = max(design_result.max_tested_modules, test_modules);

        if is_valid
            min_valid_modules = test_modules;
            design_result = update_success_result(design_result, test_result);
            upper_bound = test_modules - 1;
            fprintf('VALID (V: %.1f-%.1f V, I: %.1f A, P: %.2f MW, Lifetime: %.1f years)\n', ...
                test_result.min_voltage, test_result.max_voltage, ...
                test_result.max_current, test_result.max_power/1e6, ...
                test_result.lifetime_years);
        else
            lower_bound = test_modules + 1;
            fprintf('INVALID (%s)\n', test_result.failure_reason);
            if isempty(design_result.failure_reason)
                design_result.failure_reason = test_result.failure_reason;
            end
        end

        design.print_progress('Binary search', iteration, max_iterations, search_start);
    end

    if min_valid_modules == 0
        design_result.success = false;
        design_result.failure_reason = 'No configuration meets constraints';
        fprintf('\n✗ Binary search failed! No valid configuration found.\n');
        return;
    end

    design_result.min_modules_without_constraint = min_valid_modules;

    if divisor > 1
        min_valid_modules = ceil(min_valid_modules / divisor) * divisor;
        fprintf('\nVerifying configuration with divisibility constraint (%d modules)... ', min_valid_modules);
        [is_valid, test_result] = design.test_configuration(caseConfig, min_valid_modules);
        if ~is_valid
            design_result.success = false;
            design_result.failure_reason = sprintf('Configuration with divisibility constraint failed: %s', test_result.failure_reason);
            fprintf('INVALID (%s)\n', test_result.failure_reason);
            return;
        end
        design_result = update_success_result(design_result, test_result);
    end

    design_result.success = true;
    design_result.min_parallel_modules = min_valid_modules;
    fprintf('\n✓ Binary search successful!\n');
    fprintf('Minimum parallel modules: %d\n', design_result.min_parallel_modules);
end

function result = init_result_struct()
    result = struct();
    result.success = false;
    result.min_parallel_modules = 0;
    result.min_modules_without_constraint = 0;
    result.max_voltage = 0;
    result.min_voltage = 0;
    result.max_current = 0;
    result.max_power = 0;
    result.max_tested_modules = 0;
    result.failure_reason = '';
    result.lifetime_years = 0;
end

function result = update_success_result(result, test_result)
    result.max_voltage = test_result.max_voltage;
    result.min_voltage = test_result.min_voltage;
    result.max_current = test_result.max_current;
    result.max_power = test_result.max_power;
    result.lifetime_years = test_result.lifetime_years;
end
