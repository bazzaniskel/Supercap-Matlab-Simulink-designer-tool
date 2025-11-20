function [is_valid, test_result] = evaluate_results(caseConfig, Results, parallel_modules, options)
%EVALUATE_RESULTS Check voltage/current/lifetime constraints for a simulation.

    if nargin < 4
        options = struct();
    end

    if ~isfield(options, 'skipLifetime')
        options.skipLifetime = false;
    end

    Cell_Current = Results.Sim_Electrical_Ouput.Cell_Current_A;
    Cell_Voltage = Results.Sim_Electrical_Ouput.Cell_Voltage_V;
    Cell_Power = Results.Sim_Electrical_Ouput.Cell_Power_W;

    if isfield(Results.Sim_Electrical_Ouput, 'Cell_Ploss_W')
        Cell_Losses = Results.Sim_Electrical_Ouput.Cell_Ploss_W;
    else
        Cell_ResESR1s_Ohm = evalin('base', 'Cell_ResESR1s_Ohm');
        Cell_Losses.Time = Cell_Current.Time;
        Cell_Losses.Data = Cell_Current.Data.^2 * Cell_ResESR1s_Ohm;
    end

    series_modules = caseConfig.system.seriesModules;
    module_num_cell_series = caseConfig.system.moduleNumCellSeries;

    system_voltage = Cell_Voltage.Data * series_modules * module_num_cell_series;
    system_current = Cell_Current.Data * parallel_modules;
    system_power = Cell_Power.Data * parallel_modules * series_modules * module_num_cell_series;

    test_result = struct();
    test_result.max_voltage = max(system_voltage);
    test_result.min_voltage = min(system_voltage);
    test_result.max_current = max(abs(system_current));
    test_result.max_power = max(abs(system_power));

    if caseConfig.constraints.lifetime.enabled && ~options.skipLifetime
        mcDefaults = config.default_analysis().ambientMonteCarlo;
        if isfield(caseConfig, 'analysis') && isfield(caseConfig.analysis, 'ambientMonteCarlo')
            mcOptions = config.merge_structs(mcDefaults, caseConfig.analysis.ambientMonteCarlo);
        else
            mcOptions = mcDefaults;
        end
        allow_mc = mcOptions.enabled && mcOptions.enableInDesign;
        lifetime_info = simulation.analyze_lifetime(Cell_Voltage, Cell_Losses, Cell_Current, caseConfig, allow_mc);
        test_result.lifetime_years = lifetime_info.deterministic_years;
        lifetime_ok = test_result.lifetime_years >= caseConfig.constraints.lifetime.minYears;
    else
        test_result.lifetime_years = 1000;
        lifetime_ok = true;
    end

    voltage_ok = (test_result.min_voltage >= caseConfig.operating.systemVoltage.min) && ...
        (test_result.max_voltage <= caseConfig.operating.systemVoltage.max);

    if caseConfig.constraints.currentLimit.enabled
        current_ok = (test_result.max_current <= caseConfig.constraints.currentLimit.maxSystemCurrent);
    else
        current_ok = true;
    end

    duration_ok = abs(Cell_Voltage.Time(end) - caseConfig.profile.time(end)) < Cell_Voltage.Time(end) * 0.01;

    if ~voltage_ok
        if test_result.min_voltage < caseConfig.operating.systemVoltage.min
            reason = sprintf('Min voltage %.1f V < limit %.1f V', test_result.min_voltage, caseConfig.operating.systemVoltage.min);
        else
            reason = sprintf('Max voltage %.1f V > limit %.1f V', test_result.max_voltage, caseConfig.operating.systemVoltage.max);
        end
        is_valid = false;
        test_result.failure_reason = reason;
    elseif ~current_ok
        reason = sprintf('Max current %.1f A > limit %.1f A', test_result.max_current, caseConfig.constraints.currentLimit.maxSystemCurrent);
        is_valid = false;
        test_result.failure_reason = reason;
    elseif ~lifetime_ok
        reason = sprintf('Lifetime %.1f years < limit %.1f years', test_result.lifetime_years, caseConfig.constraints.lifetime.minYears);
        is_valid = false;
        test_result.failure_reason = reason;
    elseif ~duration_ok
        reason = sprintf('Duration mismatch: %.1f s vs %.1f s input', Cell_Voltage.Time(end), caseConfig.profile.time(end));
        is_valid = false;
        test_result.failure_reason = reason;
    else
        is_valid = true;
        test_result.failure_reason = '';
    end
end
