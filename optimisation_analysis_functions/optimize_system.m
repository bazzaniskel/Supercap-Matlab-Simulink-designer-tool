function [optimal_soc, optimal_load] = optimize_system(n_modules, original_current, fileID, env_temp, rth_cooling, cell_specs, aging_condition, v_min, v_max, v_step)
    % Convert voltage limits to SOC limits
    [soc_values, voltage_values] = generate_soc_range(v_min, v_max, v_step, n_modules, cell_specs);
    
    tolerance = 0.001;
    best_load = -Inf;
    best_soc = NaN;
    last_valid_soc = NaN;
    last_valid_load = -Inf;
    
    % Initial log
    log_message = sprintf('\nStarting optimization for %d modules', n_modules);
    fprintf(fileID, '%s\n', log_message);
    fprintf('%s\n', log_message);
    
    fprintf(fileID, '\nVoltage range: %.1f V to %.1f V (step: %.1f V)\n', v_min, v_max, v_step);
    fprintf(fileID, 'Corresponding SOC range: %.1f%% to %.1f%%\n', min(soc_values), max(soc_values));
    
    % Grid search through SOC values
    load_results = zeros(size(soc_values));
    voltage_results = zeros(size(soc_values));
    valid_solutions = false(size(soc_values));
    
    for i = 1:length(soc_values)
        current_soc = soc_values(i);
        [load_factor, max_v, min_v, temp, failure_reason] = find_max_load(current_soc, n_modules, ...
            original_current, tolerance, fileID, env_temp, rth_cooling, cell_specs, aging_condition, 20, 0.001, v_min, v_max);
        
        load_results(i) = load_factor;
        voltage_results(i) = voltage_values(i);
        
        log_message = sprintf('Grid Search - SOC %.1f%% (%.1f V): Load=%.3f, V_max=%.3f V, SS Temp=%.3f °C', ...
            current_soc, voltage_values(i), load_factor, max_v, temp);
        
        if ~isnan(load_factor)
            valid_solutions(i) = true;
            last_valid_soc = current_soc;
            last_valid_load = load_factor;
            
            if load_factor > best_load
                best_load = load_factor;
                best_soc = current_soc;
            end
            
            % Check if we're at the maximum SOC with increasing trend
            if i > 1 && i == length(soc_values) && valid_solutions(i-1) && load_results(i) > load_results(i-1)
                log_message = [log_message ' - Reached maximum SOC with increasing trend, stopping search'];
                fprintf(fileID, '%s\n', log_message);
                fprintf('%s\n', log_message);
                optimal_soc = current_soc;
                optimal_load = load_factor;
                return;
            end
        else
            % If we encounter first invalid solution after valid ones
            if i > 1 && valid_solutions(i-1)
                log_message = [log_message ' - Found transition point, starting binary search'];
                fprintf(fileID, '%s\n', log_message);
                fprintf('%s\n', log_message);
                
                % Binary search between last valid and first invalid point
                [transition_soc, transition_load] = binary_search_transition(...
                    soc_values(i-1), current_soc, n_modules, original_current, ...
                    tolerance, fileID, env_temp, rth_cooling, cell_specs, aging_condition);
                
                if ~isnan(transition_soc)
                    % Now perform fine-tuning around the transition point
                    [optimal_soc, optimal_load] = fine_tune_optimization_internal(transition_soc, transition_load, ...
                        n_modules, original_current, tolerance, fileID, env_temp, rth_cooling, ...
                        cell_specs, aging_condition);
                else
                    optimal_soc = last_valid_soc;
                    optimal_load = last_valid_load;
                end
                return;
            end
            
            log_message = [log_message ' - No valid solution'];
        end
        
        fprintf(fileID, '%s\n', log_message);
        fprintf('%s\n', log_message);
    end
    
    % If we haven't returned early, proceed with fine-tuning
    if ~isnan(best_soc)
        [optimal_soc, optimal_load] = fine_tune_optimization_internal(best_soc, best_load, n_modules, ...
            original_current, tolerance, fileID, env_temp, rth_cooling, cell_specs, aging_condition);
    else
        optimal_soc = NaN;
        optimal_load = NaN;
        log_message = sprintf('\nNo valid solution found in the entire range');
        fprintf(fileID, '%s\n', log_message);
        fprintf('%s\n', log_message);
    end
end

function [transition_soc, transition_load] = binary_search_transition(lower_soc, upper_soc, n_modules, ...
    original_current, tolerance, fileID, env_temp, rth_cooling, cell_specs, aging_condition)
    % Binary search to find the precise transition point between valid and invalid solutions
    
    max_iterations = 10;  % Maximum number of binary search iterations
    soc_tolerance = 0.1;  % Minimum SOC difference to continue search
    
    best_valid_soc = lower_soc;
    best_valid_load = NaN;
    
    fprintf(fileID, '\nStarting binary search between SOC %.1f%% and %.1f%%\n', lower_soc, upper_soc);
    
    iteration = 0;
    while (upper_soc - lower_soc) > soc_tolerance && iteration < max_iterations
        iteration = iteration + 1;
        mid_soc = (lower_soc + upper_soc) / 2;
        
        [load_factor, max_v, min_v, temp, ~] = find_max_load(mid_soc, n_modules, ...
            original_current, tolerance, fileID, env_temp, rth_cooling, cell_specs, aging_condition);
        
        log_message = sprintf('Binary Search Iteration %d - SOC %.1f%%: Load=%.3f', ...
            iteration, mid_soc, load_factor);
        fprintf(fileID, '%s\n', log_message);
        fprintf('%s\n', log_message);
        
        if ~isnan(load_factor)  % Valid solution
            lower_soc = mid_soc;
            best_valid_soc = mid_soc;
            best_valid_load = load_factor;
        else  % Invalid solution
            upper_soc = mid_soc;
        end
    end
    
    transition_soc = best_valid_soc;
    transition_load = best_valid_load;
    
    log_message = sprintf('Binary search complete - Found transition at SOC %.1f%% with Load=%.3f', ...
        transition_soc, transition_load);
    fprintf(fileID, '%s\n', log_message);
    fprintf('%s\n', log_message);
end

function [optimal_soc, optimal_load] = fine_tune_optimization_internal(center_soc, center_load, n_modules, ...
    original_current, tolerance, fileID, env_temp, rth_cooling, cell_specs, aging_condition)
    
    % Fine tuning parameters
    soc_step = 1; % 1% SOC step for fine tuning
    search_range = 5; % ±5% SOC around best point
    
    fprintf(fileID, '\nStarting fine-tuning around SOC=%.1f%%\n', center_soc);
    
    best_soc = center_soc;
    best_load = center_load;
    
    % Define fine tuning search points
    soc_points = (center_soc-search_range):soc_step:(center_soc+search_range);
    
    % Search around the best point
    for current_soc = soc_points
        % Skip invalid SOC values
        if current_soc < 0 || current_soc > 100
            continue;
        end
        
        [load_factor, max_v, min_v, temp, ~] = find_max_load(current_soc, n_modules, ...
            original_current, tolerance, fileID, env_temp, rth_cooling, cell_specs, aging_condition);
        
        if ~isnan(load_factor) && load_factor > best_load
            best_load = load_factor;
            best_soc = current_soc;
            
            log_message = sprintf('Found better solution - SOC %.1f%%: Load=%.3f, V_max=%.3f V, V_min=%.3f V, T=%.1f°C', ...
                current_soc, load_factor, max_v, min_v, temp);
        else
            log_message = sprintf('Testing - SOC %.1f%%: Load=%.3f, V_max=%.3f V, V_min=%.3f V, T=%.1f°C', ...
                current_soc, load_factor, max_v, min_v, temp);
        end
        
        fprintf(fileID, '%s\n', log_message);
        fprintf('%s\n', log_message);
    end
    
    % Final results
    optimal_soc = best_soc;
    optimal_load = best_load;
    
    log_message = sprintf('Fine-tuning complete - Final solution: SOC=%.1f%%, Load=%.3f', ...
        optimal_soc, optimal_load);
    fprintf(fileID, '%s\n', log_message);
    fprintf('%s\n', log_message);
end