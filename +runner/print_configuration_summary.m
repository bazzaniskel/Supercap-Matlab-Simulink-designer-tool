function print_configuration_summary(caseConfig)
%PRINT_CONFIGURATION_SUMMARY Mirror the previous console summary.

    fprintf('\n===============================================================\n');
    fprintf('                    CONFIGURATION SUMMARY                     \n');
    fprintf('===============================================================\n');

    if strcmp(caseConfig.operation.mode, 'design')
        if caseConfig.operation.optimizeVoltage
            fprintf('\nOPERATION MODE:\n  Mode: Design optimization (parallel modules + voltage)\n');
            fprintf('  Voltage optimization range: %.1f - %.1f V\n', ...
                caseConfig.constraints.voltageOptimization.range(1), ...
                caseConfig.constraints.voltageOptimization.range(2));
            fprintf('  Optimal starting voltage: %.1f V\n', caseConfig.operating.startVoltage);
            fprintf('  Minimum parallel modules: %d\n', caseConfig.system.parallelModules);
        else
            fprintf('\nOPERATION MODE:\n  Mode: Design optimization (parallel modules only)\n');
            fprintf('  Result: Minimum configuration with %d parallel modules\n', caseConfig.system.parallelModules);
        end
    else
        fprintf('\nOPERATION MODE:\n  Mode: Simulation with specified configuration\n');
    end

    fprintf('\nSYSTEM CONFIGURATION:\n');
    fprintf('  Cell Type: %s\n', caseConfig.cell.name);
    fprintf('  Configuration: %d series × %d parallel (%d total modules)\n', ...
        caseConfig.system.seriesModules, caseConfig.system.parallelModules, ...
        caseConfig.system.seriesModules * caseConfig.system.parallelModules);

    if strcmp(caseConfig.operation.mode, 'design')
        fprintf('\nDESIGN CONSTRAINTS:\n');
        fprintf('  Maximum parallel modules searched: %d\n', caseConfig.constraints.maxParallelModules);
        if caseConfig.constraints.currentLimit.enabled
            fprintf('  Maximum system current: %.1f A\n', caseConfig.constraints.currentLimit.maxSystemCurrent);
        else
            fprintf('  Maximum system current: No limit\n');
        end
        if caseConfig.constraints.lifetime.enabled
            fprintf('  Minimum lifetime: %.1f years\n', caseConfig.constraints.lifetime.minYears);
        else
            fprintf('  Minimum lifetime: No limit\n');
        end
    end

    fprintf('\nOPERATING CONDITIONS:\n');
    fprintf('  SOH: %.1f%%\n', caseConfig.operating.SOH_percent);
    if isfield(caseConfig.operating, 'environment')
        env = caseConfig.operating.environment;
    else
        env = struct();
    end
    if isfield(env, 'profileName') && ~isempty(env.profileName)
        fprintf('  Temperature: %.1f°C (profile: %s)\n', caseConfig.operating.environmentTemp, env.profileName);
    else
        fprintf('  Temperature: %.1f°C\n', caseConfig.operating.environmentTemp);
    end
    fprintf('  Starting Voltage: %.1f V (SOC: %.1f%%)\n', caseConfig.operating.startVoltage, caseConfig.sim.initialSOC);
    fprintf('  Duty Cycle: %.3f (%.1f%% active)\n', caseConfig.operating.dutyCycle, caseConfig.operating.dutyCycle*100);
    fprintf('  Operating Hours/Day: %.1f\n', caseConfig.operating.hoursPerDay);

    fprintf('\nPOWER PROFILE:\n');
    fprintf('  Type: %s\n', caseConfig.profile.mode);
    fprintf('  Duration: %.2f s\n', caseConfig.profile.duration);
    fprintf('  Max Value: %.2f %s\n', caseConfig.profile.maxValue, caseConfig.profile.units);
    fprintf('  Description: %s\n', caseConfig.profile.description);

    fprintf('\nLIMITS:\n');
    fprintf('  System Voltage: %.1f - %.1f V\n', caseConfig.operating.systemVoltage.min, caseConfig.operating.systemVoltage.max);
    fprintf('  Cell SOC: %.1f - %.1f%%\n', caseConfig.limits.cellSOC(1), caseConfig.limits.cellSOC(2));
    fprintf('  Cell Voltage: %.3f - %.3f V\n', caseConfig.limits.cellVoltage(1), caseConfig.limits.cellVoltage(2));

    fprintf('\nCOOLING SYSTEM:\n');
    fprintf('  Method: %s\n', caseConfig.cooling.method);
    fprintf('  Cooling Temperature: %.1f°C\n', caseConfig.cooling.mediumTemp);
    fprintf('  Thermal Resistance to Cooling: %.3f K/W\n', caseConfig.cooling.rthCooling);
end
