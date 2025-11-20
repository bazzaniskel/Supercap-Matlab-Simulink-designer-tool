function [soc_values, voltage_values] = generate_soc_range(v_min, v_max, v_step, n_modules, cell_specs)
    % Generate SOC range based on voltage limits and step
    % Returns both SOC values and corresponding voltage values
    
    voltage_values = v_min:v_step:v_max;
    soc_values = arrayfun(@(v) voltage_to_soc(v, n_modules, cell_specs), voltage_values);
end