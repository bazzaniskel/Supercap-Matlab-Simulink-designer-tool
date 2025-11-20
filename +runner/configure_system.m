function [systemConfig, constraints] = configure_system(operationMode, cellConfig)
%CONFIGURE_SYSTEM Collect system-level parameters and design constraints.

    fprintf('\n--- SYSTEM CONFIGURATION ---\n');
    systemConfig = struct();
    constraints = struct();

    systemConfig.seriesModules = runner.get_valid_input( ...
        'Number of series modules: ', @(x) x > 0 && x == round(x));
    systemConfig.parallelModules = [];
    systemConfig.moduleNumCellSeries = cellConfig.moduleNumCellSeries;
    systemConfig.moduleRatedVoltage = cellConfig.moduleRatedVoltage;
    systemConfig.cellVoltRated = cellConfig.voltRated;

    constraints.currentLimit.enabled = false;
    constraints.currentLimit.maxSystemCurrent = inf;
    constraints.lifetime.enabled = false;
    constraints.lifetime.minYears = 0;
    constraints.voltageOptimization = struct('enabled', operationMode.optimizeVoltage, ...
        'range', [0, 0], 'points', 0);

    is_search_mode = any(strcmp(operationMode.mode, {'design','lifetime'}));

    if is_search_mode
        fprintf('\n--- DESIGN CONSTRAINTS ---\n');
        constraints.maxParallelModules = runner.get_valid_input( ...
            'Maximum number of parallel modules to consider: ', @(x) x > 0 && x == round(x));

        fprintf('\nCurrent limit constraint:\n');
        fprintf('1. No current limit\n');
        fprintf('2. Set maximum system current limit\n');
        current_limit_choice = runner.get_valid_input('Select option (1-2): ', @(x) any(x == [1, 2]));
        if current_limit_choice == 2
            constraints.currentLimit.enabled = true;
            constraints.currentLimit.maxSystemCurrent = runner.get_valid_input('Maximum system current [A]: ', @(x) x > 0);
        end

        if strcmp(operationMode.mode, 'lifetime')
            fprintf('\nLifetime requirement (mandatory in lifetime mode):\n');
            constraints.lifetime.enabled = true;
            constraints.lifetime.minYears = runner.get_valid_input('Target lifetime [years]: ', @(x) x > 0);
        else
            fprintf('\nLifetime limit constraint:\n');
            fprintf('1. No lifetime limit\n');
            fprintf('2. Set minimum lifetime requirement\n');
            lifetime_choice = runner.get_valid_input('Select option (1-2): ', @(x) any(x == [1, 2]));
            if lifetime_choice == 2
                constraints.lifetime.enabled = true;
                constraints.lifetime.minYears = runner.get_valid_input('Minimum lifetime [years]: ', @(x) x > 0);
            end
        end

        if operationMode.optimizeVoltage
            fprintf('\n--- VOLTAGE OPTIMIZATION PARAMETERS ---\n');
            fprintf('Voltage optimization will find the maximum starting voltage that minimizes parallel modules.\n');
            v_min_range = runner.get_valid_input('Minimum voltage for optimization range [V]: ', @(x) x > 0);
            v_max_range = runner.get_valid_input('Maximum voltage for optimization range [V]: ', @(x) x > v_min_range);
            number_points = runner.get_valid_input('Number of voltage points to test: ', @(x) x > 0 && x == round(x));
            constraints.voltageOptimization.range = [v_min_range, v_max_range];
            constraints.voltageOptimization.points = number_points;
        else
            constraints.voltageOptimization.range = [0, 0];
            constraints.voltageOptimization.points = 0;
        end

        constraints.parallelDivisor = 1;
    else
        systemConfig.parallelModules = runner.get_valid_input( ...
            'Number of parallel modules: ', @(x) x > 0 && x == round(x));
        constraints.maxParallelModules = systemConfig.parallelModules;
        constraints.parallelDivisor = 1;
    end
end
