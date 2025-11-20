function save_configuration_file(results_folder, caseConfig, metrics)
%SAVE_CONFIGURATION_FILE Persist human-readable configuration text file.

    config_file = fullfile(results_folder, 'simulation_configuration.txt');
    fid = fopen(config_file, 'w');
    if fid == -1
        fprintf('Warning: Could not create configuration file\n');
        return;
    end

    fprintf(fid, 'SUPERCAPACITOR SIMULATION CONFIGURATION\n');
    fprintf(fid, '=======================================\n\n');
    fprintf(fid, 'TIMESTAMP: %s\n\n', datestr(now));

    fprintf(fid, 'OPERATION MODE:\n');
    if strcmp(caseConfig.operation.mode, 'design')
        fprintf(fid, '  Mode: Design optimization\n');
        fprintf(fid, '  Maximum parallel modules searched: %d\n', caseConfig.constraints.maxParallelModules);
        fprintf(fid, '  Current limit enabled: %s\n', results.conditional_string(caseConfig.constraints.currentLimit.enabled, 'Yes', 'No'));
        if caseConfig.constraints.currentLimit.enabled
            fprintf(fid, '  Maximum system current: %.1f A\n', caseConfig.constraints.currentLimit.maxSystemCurrent);
        end
        fprintf(fid, '  Result: Minimum configuration with %d parallel modules\n', caseConfig.system.parallelModules);
    else
        fprintf(fid, '  Mode: Simulation with specified configuration\n');
    end
    fprintf(fid, '\n');

    fprintf(fid, 'SYSTEM CONFIGURATION:\n');
    fprintf(fid, '  Cell Type: %s\n', caseConfig.cell.name);
    fprintf(fid, '  Series Modules: %d\n', caseConfig.system.seriesModules);
    fprintf(fid, '  Parallel Modules: %d\n', caseConfig.system.parallelModules);
    fprintf(fid, '  Total Modules: %d\n', caseConfig.system.seriesModules * caseConfig.system.parallelModules);
    fprintf(fid, '\n');

    fprintf(fid, 'OPERATING CONDITIONS:\n');
    fprintf(fid, '  State of Health: %.1f%%\n', caseConfig.operating.SOH_percent);
    if isfield(caseConfig.operating, 'environment') && isfield(caseConfig.operating.environment, 'profileName') ...
            && ~isempty(caseConfig.operating.environment.profileName)
        fprintf(fid, '  Environmental Temperature: %.1f°C (profile: %s)\n', ...
            caseConfig.operating.environmentTemp, caseConfig.operating.environment.profileName);
    else
        fprintf(fid, '  Environmental Temperature: %.1f°C\n', caseConfig.operating.environmentTemp);
    end
    fprintf(fid, '  Starting Voltage: %.1f V\n', caseConfig.operating.startVoltage);
    fprintf(fid, '  Initial SOC: %.2f%%\n', caseConfig.sim.initialSOC);
    fprintf(fid, '  Duty Cycle: %.3f\n', caseConfig.operating.dutyCycle);
    fprintf(fid, '  Operating Hours/Day: %.1f\n', caseConfig.operating.hoursPerDay);
    fprintf(fid, '\n');

    fprintf(fid, 'CELL SPECIFICATIONS:\n');
    fprintf(fid, '  Rated Capacitance: %.0f F\n', caseConfig.cell.specs.Cell_CapRated_F);
    fprintf(fid, '  Rated Voltage: %.1f V\n', caseConfig.cell.specs.Cell_VoltRated_V);
    fprintf(fid, '  ESR (10ms): %.3f mΩ\n', caseConfig.cell.specs.Cell_ResESR10ms_Ohm * 1e3);
    fprintf(fid, '  ESR (1s): %.3f mΩ\n', caseConfig.cell.specs.Cell_ResESR1s_Ohm * 1e3);
    fprintf(fid, '  Cells in Series per Module: %d\n', caseConfig.system.moduleNumCellSeries);
    fprintf(fid, '\n');

    fprintf(fid, 'POWER PROFILE:\n');
    fprintf(fid, '  Type: %s\n', caseConfig.profile.mode);
    fprintf(fid, '  Duration: %.2f s\n', caseConfig.profile.duration);
    fprintf(fid, '  Max Value: %.2f %s\n', caseConfig.profile.maxValue, caseConfig.profile.units);
    fprintf(fid, '  Description: %s\n', caseConfig.profile.description);
    fprintf(fid, '\n');

    fprintf(fid, 'LIMITS AND CONSTRAINTS:\n');
    fprintf(fid, '  System Voltage Min: %.1f V\n', caseConfig.operating.systemVoltage.min);
    fprintf(fid, '  System Voltage Max: %.1f V\n', caseConfig.operating.systemVoltage.max);
    fprintf(fid, '  Cell SOC Min: %.1f%%\n', caseConfig.limits.cellSOC(1));
    fprintf(fid, '  Cell SOC Max: %.1f%%\n', caseConfig.limits.cellSOC(2));
    fprintf(fid, '  Cell Voltage Min: %.3f V\n', caseConfig.limits.cellVoltage(1));
    fprintf(fid, '  Cell Voltage Max: %.3f V\n', caseConfig.limits.cellVoltage(2));
    if caseConfig.constraints.currentLimit.enabled
        fprintf(fid, '  System Current Max: %.1f A\n', caseConfig.constraints.currentLimit.maxSystemCurrent);
    end
    fprintf(fid, '\n');

    fprintf(fid, 'COOLING SYSTEM:\n');
    fprintf(fid, '  Method: %s\n', caseConfig.cooling.method);
    fprintf(fid, '  Cooling Temperature: %.1f°C\n', caseConfig.cooling.mediumTemp);
    fprintf(fid, '  Thermal Resistance to Cooling: %.3f K/W\n', caseConfig.cooling.rthCooling);
    fprintf(fid, '\n');

    if isfield(caseConfig, 'analysis') && isfield(caseConfig.analysis, 'ambientMonteCarlo')
        mcCfg = caseConfig.analysis.ambientMonteCarlo;
        fprintf(fid, 'ANALYSIS SETTINGS:\n');
        fprintf(fid, '  Monte Carlo Enabled: %s\n', results.conditional_string(mcCfg.enabled, 'Yes', 'No'));
        if mcCfg.enabled
            if isfield(mcCfg, 'temperatureJitter_99pct_C')
                delta99 = mcCfg.temperatureJitter_99pct_C;
            elseif isfield(mcCfg, 'temperatureJitter_pct')
                delta99 = mcCfg.temperatureJitter_pct;
            else
                delta99 = 0;
            end
            z99 = 2.5758293035489004;
            sigmaC = delta99 / z99;
            fprintf(fid, '  Trials: %d | Days/Month: %d | 99%% Deviation: ±%.1f°C (σ=%.2f°C) | Smooth Window: %.1f h\n', ...
                mcCfg.numTrials, mcCfg.daysPerMonth, delta99, sigmaC, mcCfg.smoothingHours);
            fprintf(fid, '  Run During Design: %s\n', results.conditional_string(mcCfg.enableInDesign, 'Yes', 'No'));
        end
        fprintf(fid, '\n');
    end

    fprintf(fid, 'SIMULATION RESULTS:\n');
    fprintf(fid, '  System Max Current: %.1f A\n', metrics.system_max_current);
    fprintf(fid, '  System Min Voltage: %.1f V\n', metrics.system_min_voltage);
    fprintf(fid, '  System Max Voltage: %.1f V\n', metrics.system_max_voltage);
    fprintf(fid, '  System Max Power: %.2f MW\n', metrics.system_max_power/1e6);
    fprintf(fid, '  Lifetime: %.1f years\n', metrics.lifetime_years);
    if isfield(metrics, 'lifetime_monteCarlo') && isstruct(metrics.lifetime_monteCarlo) ...
            && isfield(metrics.lifetime_monteCarlo, 'enabled') && metrics.lifetime_monteCarlo.enabled
        mc = metrics.lifetime_monteCarlo;
        fprintf(fid, '  Monte Carlo Lifetime (N=%d): Mean %.1f y | Min %.1f y | 5th pct %.1f y | 95th pct %.1f y\n', ...
            mc.numTrials, mc.mean_years, mc.min_years, mc.p05_years, mc.p95_years);
    end
    fprintf(fid, '\n');

    fprintf(fid, 'THERMAL ANALYSIS:\n');
    fprintf(fid, '  Estimated Temp Rise: %.2f°C\n', metrics.estimated_temp_rise);
    fprintf(fid, '  Estimated Steady Temp: %.2f°C\n', metrics.estimated_steady_temp);
    if caseConfig.thermal.enableDutyCycleSearch
        fprintf(fid, '  Max Duty Cycle for %.1f year lifetime: %.1f%%\n', caseConfig.thermal.minLifetimeYears, metrics.max_duty_cycle*100);
    end

    fclose(fid);
end
