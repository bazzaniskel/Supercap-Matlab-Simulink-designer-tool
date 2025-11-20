function stepInputs = build_step_inputs(caseConfig, simResults)
%BUILD_STEP_INPUTS Pre-compute data needed for lifetime consumption per step.

    outputs = simResults.Sim_Electrical_Ouput;
    Cell_Voltage = outputs.Cell_Voltage_V;
    Cell_Current = outputs.Cell_Current_A;

    if isfield(outputs, 'Cell_Ploss_W')
        Cell_Losses = outputs.Cell_Ploss_W;
    else
        Cell_ResESR1s_Ohm = caseConfig.cell.specs.Cell_ResESR1s_Ohm;
        Cell_Losses.Time = Cell_Current.Time;
        Cell_Losses.Data = Cell_Current.Data.^2 * Cell_ResESR1s_Ohm;
    end

    cellSpecs = caseConfig.cell.specs;
    duty_cycle = caseConfig.operating.dutyCycle;
    hours_per_day = caseConfig.operating.hoursPerDay;

    time_hours.cycling = hours_per_day * duty_cycle;
    time_hours.idle    = hours_per_day * (1 - duty_cycle);
    time_hours.standby = max(0, 24 - hours_per_day);

    f_v = @(u) (u > 2.5) .* 2.^((u - cellSpecs.Cell_VoltRated_V) / 0.2) + ...
               (u <= 2.5) .* 2.^((u - 2.5) / 0.1771) .* 2.^((2.5 - cellSpecs.Cell_VoltRated_V) / 0.2);

    f_t = @(u) (u > cellSpecs.Cell_MaxRatedTemp_degC) .* 2.^((u - cellSpecs.Cell_MaxRatedTemp_degC) / 20) + ...
               (u <= cellSpecs.Cell_MaxRatedTemp_degC) .* 2.^((u - cellSpecs.Cell_MaxRatedTemp_degC) / 8.217);

    af_v_values = f_v(Cell_Voltage.Data);
    AF_V.cycling = trapz(Cell_Current.Time, af_v_values) / Cell_Current.Time(end);
    AF_V.idle    = f_v(Cell_Voltage.Data(1));
    AF_V.standby = f_v(cellSpecs.Cell_VoltRated_V * sqrt(0.5));

    stepInputs = struct();
    stepInputs.Cell_Losses = Cell_Losses;
    stepInputs.duty_cycle = duty_cycle;
    stepInputs.hours_per_day = hours_per_day;
    stepInputs.rth_cooling = caseConfig.cooling.rthCooling;
    stepInputs.heat_capa = cellSpecs.Cell_HeatCapa_JpK;
    stepInputs.time_hours = time_hours;
    stepInputs.AF_V = AF_V;
    stepInputs.f_t = f_t;
    stepInputs.Cell_RatedLifetime_h = cellSpecs.Cell_RatedLifetime_h;
end
