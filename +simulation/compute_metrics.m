function metrics = compute_metrics(Results, caseConfig)
%COMPUTE_METRICS Derive electrical, thermal and lifetime metrics.

    Cell_Current = Results.Sim_Electrical_Ouput.Cell_Current_A;
    Cell_Voltage = Results.Sim_Electrical_Ouput.Cell_Voltage_V;
    Cell_Power = Results.Sim_Electrical_Ouput.Cell_Power_W;
    Cell_Losses = Results.Sim_Electrical_Ouput.Cell_Ploss_W;

    series_modules = caseConfig.system.seriesModules;
    module_num_cell_series = caseConfig.system.moduleNumCellSeries;
    parallel_modules = caseConfig.system.parallelModules;

    System_Voltage = Cell_Voltage.Data * series_modules * module_num_cell_series;
    System_Current = Cell_Current.Data * parallel_modules;
    System_Power = Cell_Power.Data * parallel_modules * series_modules * module_num_cell_series;

    environment = caseConfig.operating.environment;
    lifetime_info = simulation.analyze_lifetime(Cell_Voltage, Cell_Losses, Cell_Current, caseConfig);

    metrics.cell_max_current = max(abs(Cell_Current.Data));
    metrics.cell_rms_current = sqrt(mean(Cell_Current.Data.^2));
    metrics.system_max_current = max(abs(System_Current));
    metrics.system_rms_current = sqrt(mean(System_Current.^2));

    metrics.cell_min_voltage = min(Cell_Voltage.Data);
    metrics.cell_max_voltage = max(Cell_Voltage.Data);
    metrics.system_start_voltage = System_Voltage(1);
    metrics.system_min_voltage = min(System_Voltage);
    metrics.system_max_voltage = max(System_Voltage);
    metrics.voltage_range_system = metrics.system_max_voltage - metrics.system_min_voltage;

    metrics.cell_max_power = max(abs(Cell_Power.Data));
    metrics.system_max_power = max(abs(System_Power));

    Cell_ResESR1s_Ohm = caseConfig.cell.specs.Cell_ResESR1s_Ohm;
    rms_current_duty = metrics.cell_rms_current * sqrt(caseConfig.operating.dutyCycle);
    metrics.cell_average_losses = rms_current_duty^2 * Cell_ResESR1s_Ohm;
    metrics.cell_max_losses = metrics.cell_max_current^2 * Cell_ResESR1s_Ohm;
    metrics.system_average_losses = metrics.cell_average_losses * parallel_modules * series_modules * module_num_cell_series;
    metrics.system_max_losses = metrics.cell_max_losses * parallel_modules * series_modules * module_num_cell_series;

    metrics.pulse_efficiency = trapz(Cell_Power.Time, abs(Cell_Voltage.Data .* Cell_Current.Data)) / ...
        (trapz(Cell_Power.Time, abs(Cell_Voltage.Data .* Cell_Current.Data)) + ...
        trapz(Cell_Power.Time, abs(Cell_Losses.Data)));

    if numel(Cell_Current.Time) > 1
        dt = Cell_Current.Time(2) - Cell_Current.Time(1);
        energy_cell = trapz(Cell_Current.Time, abs(Cell_Power.Data)) * dt / 3600;
        metrics.cell_energy = energy_cell;
        metrics.system_energy = energy_cell * parallel_modules * series_modules * module_num_cell_series;
    else
        metrics.cell_energy = 0;
        metrics.system_energy = 0;
    end

    metrics.estimated_temp_rise = metrics.cell_average_losses * caseConfig.cooling.rthEnvironment;
    metrics.estimated_steady_temp = caseConfig.operating.environment.temperature_C + metrics.estimated_temp_rise;
    metrics.lifetime_years = lifetime_info.deterministic_years;
    metrics.lifetime_analysis = lifetime_info;
    metrics.lifetime_monteCarlo = lifetime_info.monteCarlo;
end
