function caseConfig = optimize_case(caseConfig)
%OPTIMIZE_CASE Run the requested design optimization workflow.

    if ~strcmp(caseConfig.operation.mode, 'design')
        return;
    end

    fprintf('\n===============================================================\n');
    fprintf('                    DESIGN OPTIMIZATION                       \n');
    fprintf('===============================================================\n');

    fprintf('\nDo you want to constrain the number of parallel modules to be a multiple of a specific number?\n');
    fprintf('1. No constraint\n');
    fprintf('2. Yes, specify a number\n');
    choice = runner.get_valid_input('Select option (1-2): ', @(x) any(x == [1, 2]));
    if choice == 2
        caseConfig.constraints.parallelDivisor = runner.get_valid_input( ...
            'Enter the number that parallel modules should be divisible by: ', @(x) x > 0 && x == round(x));
    end

    if caseConfig.operation.optimizeVoltage
        result = design.voltage_search(caseConfig);
        if result.success
            caseConfig.operating.startVoltage = result.optimal_voltage;
            caseConfig.system.parallelModules = result.min_parallel_modules;
        else
            error('Voltage optimization failed: %s', result.failure_reason);
        end
    else
        result = design.parallel_search(caseConfig);
        if result.success
            caseConfig.system.parallelModules = result.min_parallel_modules;
        else
            error('Design optimization failed: %s', result.failure_reason);
        end
    end
end
