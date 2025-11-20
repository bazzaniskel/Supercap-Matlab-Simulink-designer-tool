function soc = voltage_to_soc(voltage, n_modules, cell_specs)
    % Convert system voltage to SOC based on V^2 relationship
    % voltage: system voltage in V
    % n_modules: number of modules in string
    % cell_specs: struct containing cell specifications
    
    v_per_cell = voltage / (cell_specs.Module_NumCellSeries * n_modules);
    soc = min(100, (v_per_cell / cell_specs.Cell_VoltRated_V)^2 * 100);
end