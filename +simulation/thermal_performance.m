function thermal_result = thermal_performance(caseConfig, Results)
%THERMAL_PERFORMANCE Binary search for maximum duty cycle at lifetime requirement.

    design.copy_case_to_base(caseConfig, caseConfig.system.parallelModules, caseConfig.operating.startVoltage);
    Cell_Voltage = Results.Sim_Electrical_Ouput.Cell_Voltage_V;
    Cell_Losses = Results.Sim_Electrical_Ouput.Cell_Ploss_W;
    Cell_Current = Results.Sim_Electrical_Ouput.Cell_Current_A;

    duty_cycle_max = 1;
    duty_cycle_min = 0;
    min_lifetime_years = caseConfig.thermal.minLifetimeYears;

    mcDefaults = config.default_analysis().ambientMonteCarlo;
    if isfield(caseConfig, 'analysis') && isfield(caseConfig.analysis, 'ambientMonteCarlo')
        mcOptions = config.merge_structs(mcDefaults, caseConfig.analysis.ambientMonteCarlo);
    else
        mcOptions = mcDefaults;
    end
    allow_mc_design = mcOptions.enabled && mcOptions.enableInDesign;

    while duty_cycle_max - duty_cycle_min > 1e-3
        duty_cycle_mid = (duty_cycle_max + duty_cycle_min) / 2;
        lifetime_info = simulation.analyze_lifetime(Cell_Voltage, Cell_Losses, Cell_Current, ...
            override_caseconfig(caseConfig, duty_cycle_mid), allow_mc_design);
        lifetime_years = lifetime_info.deterministic_years;
        if lifetime_years >= min_lifetime_years
            duty_cycle_min = duty_cycle_mid;
        else
            duty_cycle_max = duty_cycle_mid;
        end
    end

    thermal_result.duty_cycle_max = duty_cycle_max;
end

function cfg = override_caseconfig(caseConfig, duty_cycle)
    cfg = caseConfig;
    cfg.operating.dutyCycle = duty_cycle;
end
