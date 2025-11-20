function [optimal_soc, optimal_load] = optimize_system(n_modules, original_current, fileID, env_temp, rth_cooling, cell_specs, aging_condition, v_min, v_max, v_step)
    % Convert voltage limits to SOC limits
    [soc_values, voltage_values] = generate_soc_range(v_min, v_max, v_step, n_modules, cell_specs);
    
    tolerance = 0.01;
    best_load = -Inf;
    best_soc = NaN;
    
    % Initial log
    log_message = sprintf('\nStarting optimization for %d modules', n_modules);
    fprintf(fileID, '%s\n', log_message);
    fprintf('%s\n', log_message);
    
    fprintf(fileID, '\nVoltage range: %.1f V to %.1f V (step: %.1f V)\n', v_min, v_max, v_step);
    fprintf(fileID, 'Corresponding SOC range: %.1f%% to %.1f%%\n', min(soc_values), max(soc_values));
    
    % Grid search through SOC values
    load_results = zeros(size(soc_values));
    voltage_results = zeros(size(soc_values));
    
    for i = 1:length(soc_values)
        current_soc = soc_values(i);
        [load_factor, max_v, min_v, temp, failure_reason] = find_max_load(current_soc, n_modules, ...
            original_current, tolerance, fileID, env_temp, rth_cooling, cell_specs, aging_condition);
        
        load_results(i) = load_factor;
        voltage_results(i) = voltage_values(i);
        
        if load_factor > best_load && ~isnan(load_factor)
            best_load = load_factor;
            best_soc = current_soc;
            best_voltage = voltage_values(i);
        end
        
        log_message = sprintf('Grid Search - SOC %.1f%% (%.1f V): Load=%.3f, V_max=%.3f V, SS Temp=%.3f °C ', ...
            current_soc, voltage_values(i), load_factor, max_v, temp);
        fprintf(fileID, '%s\n', log_message);
        fprintf('%s\n', log_message);
    end
    
    optimal_soc = best_soc;
    optimal_load = best_load;
    
    log_message = sprintf('\nOptimal solution found: SOC=%.1f%% (%.1f V), Load=%.3f', ...
        optimal_soc, best_voltage, optimal_load);
    fprintf(fileID, '%s\n', log_message);
    fprintf('%s\n', log_message);
end