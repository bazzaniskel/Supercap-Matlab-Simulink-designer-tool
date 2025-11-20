function copy_case_to_base(caseConfig, parallel_modules, start_voltage)
%COPY_CASE_TO_BASE Assign required variables for Simulink design evaluation.

    if nargin < 3
        start_voltage = caseConfig.operating.startVoltage;
    end

    series_modules = caseConfig.system.seriesModules;
    module_num_cell_series = caseConfig.system.moduleNumCellSeries;
    cellSpecs = caseConfig.cell.specs;
    module_rated_voltage = caseConfig.system.moduleRatedVoltage;
    max_possible_v_start = cellSpecs.Cell_VoltRated_V * series_modules * module_num_cell_series;
    actual_v_start = min(start_voltage, max_possible_v_start);
    max_rack_voltage = module_rated_voltage * series_modules;

    assignin('base', 'Cell_specs', cellSpecs);
    cell_fields = fieldnames(cellSpecs);
    for idx = 1:numel(cell_fields)
        field_name = cell_fields{idx};
        assignin('base', field_name, cellSpecs.(field_name));
    end
    assignin('base', 'Sim_Sys_Vstart_V', actual_v_start);
    assignin('base', 'Sim_SocInit_pc', (actual_v_start / max_rack_voltage)^2 * 100);
    assignin('base', 'Sim_NumSeriesModules', series_modules);
    assignin('base', 'Cell_VoltStart_V', min(actual_v_start / series_modules / module_num_cell_series, cellSpecs.Cell_VoltRated_V));

    assignin('base', 'Sim_SOH_PU', caseConfig.operating.SOH_percent);
    assignin('base', 'Environment_Temp_degC', caseConfig.operating.environmentTemp);
    assignin('base', 'Cell_TempInit_degC', caseConfig.cooling.initialCellTemp);

    assignin('base', 'Cell_LoadInputTime_s', caseConfig.profile.time);
    assignin('base', 'Sim_TimeEnd_s', caseConfig.profile.time(end));
    assignin('base', 'System_LoadInputCurrOrPower_AW', caseConfig.profile.systemInput);
    assignin('base', 'Switch_CurrentOrPower', caseConfig.profile.switchCurrentOrPower);

    if caseConfig.profile.switchCurrentOrPower == 1
        cell_input = caseConfig.profile.systemInput / parallel_modules;
    else
        cell_input = caseConfig.profile.systemInput / parallel_modules / series_modules / module_num_cell_series;
    end
    assignin('base', 'Cell_LoadInputCurrOrPower_AW', cell_input);

    assignin('base', 'Switch_CoolingONOFF', caseConfig.cooling.switchCooling);
    assignin('base', 'Switch_DeratingONOFF_NN', caseConfig.cooling.switchDerating);
    assignin('base', 'Cooling_Temp_degC', caseConfig.cooling.mediumTemp);
    assignin('base', 'Cell_RthToCooling_KpW', caseConfig.cooling.rthCooling);
    assignin('base', 'Cell_RthToEnvironment_KpW', caseConfig.cooling.rthEnvironment);
    assignin('base', 'Cell_HeatCapa_JpK', cellSpecs.Cell_HeatCapa_JpK);

    assignin('base', 'Sys_DutyCycle_pu', caseConfig.operating.dutyCycle);
    assignin('base', 'Sys_HoursPerDay', caseConfig.operating.hoursPerDay);

    assignin('base', 'Cell_LowerSOCLimit_pc', 0);
    assignin('base', 'Cell_UpperSOCLimit_pc', 100);
    assignin('base', 'Cell_LowerVoltageLimit_V', 0);
    assignin('base', 'Cell_UpperVoltageLimit_V', 3);
    assignin('base', 'Sim_TimeStep_s', min(caseConfig.profile.time(end)/100, 0.001));
    assignin('base', 'Sys_IsUPS', true);
end
