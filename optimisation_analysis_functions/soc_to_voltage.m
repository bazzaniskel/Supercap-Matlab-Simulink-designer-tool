function voltage = soc_to_voltage(soc, n_modules, cell_specs)
    % Convert SOC to system voltage based on V^2 relationship
    % soc: state of charge in percentage
    % n_modules: number of modules in string
    % cell_specs: struct containing cell specifications
    
    v_per_cell = cell_specs.Cell_VoltRated_V * sqrt(soc/100);
    voltage = v_per_cell * cell_specs.Module_NumCellSeries * n_modules;
end