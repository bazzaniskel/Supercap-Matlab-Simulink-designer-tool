function search_result = parallel_search(baseCase, periods, start_voltage)
%PARALLEL_SEARCH Binary search for minimum parallel modules meeting lifetime target.

    constraints = baseCase.constraints;
    max_modules = constraints.maxParallelModules;
    divisor = max(1, constraints.parallelDivisor);

    lower_bound = 1;
    upper_bound = max_modules;
    best_modules = 0;
    best_eval = [];
    iteration = 0;
    max_iterations = ceil(log2(max_modules)) + 5;

    fprintf('\n--- LIFETIME PARALLEL MODULE SEARCH ---\n');
    fprintf('Search range: 1 to %d parallel modules (start voltage %.1f V)\n', max_modules, start_voltage);

    search_start = tic;

    while lower_bound <= upper_bound && iteration < max_iterations
        iteration = iteration + 1;
        trial_modules = floor((lower_bound + upper_bound)/2);
        fprintf('Iteration %d: Testing %d parallel modules... ', iteration, trial_modules);

        variant = lifetime.prepare_variant(baseCase, trial_modules, start_voltage);
        evalResult = lifetime.evaluate_configuration(variant, periods);

        if evalResult.success
            fprintf('PASS (Lifetime %.2f y)\n', evalResult.timeline.achieved_years);
            best_modules = trial_modules;
            best_eval = evalResult;
            upper_bound = trial_modules - 1;
        else
            fprintf('FAIL (%s)\n', evalResult.failure_reason);
            lower_bound = trial_modules + 1;
            if isempty(best_eval)
                best_eval = evalResult;
            end
        end

        design.print_progress('Lifetime binary search', iteration, max_iterations, search_start);
    end

    if best_modules == 0
        search_result = struct('success', false, 'failure_reason', best_eval.failure_reason);
        return;
    end

    if divisor > 1
        adjusted_modules = ceil(best_modules/divisor) * divisor;
        if adjusted_modules ~= best_modules
            fprintf('Valid configuration must be divisible by %d -> testing %d modules...\n', divisor, adjusted_modules);
            variant = lifetime.prepare_variant(baseCase, adjusted_modules, start_voltage);
            evalResult = lifetime.evaluate_configuration(variant, periods);
            if ~evalResult.success
                search_result = struct('success', false, 'failure_reason', ...
                    sprintf('Divisibility constraint failed: %s', evalResult.failure_reason));
                return;
            end
            best_modules = adjusted_modules;
            best_eval = evalResult;
        end
    end

    search_result = best_eval;
    search_result.success = true;
    search_result.min_parallel_modules = best_modules;
    search_result.start_voltage = start_voltage;
end
