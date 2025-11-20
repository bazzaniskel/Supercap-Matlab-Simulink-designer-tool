function [max_load, final_max_v, final_min_v, final_temp, failure_reason] = find_max_load(soc, n_modules, original_current, ...
    tolerance, fileID, env_temp, rth_cooling, cell_specs, aging_condition, max_iterations, min_valid_load, v_min_limit, v_max_limit, temp_limit)
    
    if nargin < 10
        max_iterations = 30;
    end
    if nargin < 11
        min_valid_load = 0.001;
    end
    if nargin < 12
        v_min_limit = 850;  % Default minimum system voltage
    end
    if nargin < 13
        v_max_limit = 1300;  % Default maximum system voltage
    end
    if nargin < 14
        temp_limit = 50;
    end
    
    load_left = min_valid_load;
    load_right = 2;
    
    max_load = 0;
    final_max_v = NaN;
    final_min_v = NaN;
    final_temp = NaN;
    failure_reason = '';
    
    last_evaluations = struct('load', [], 'valid', []);
    
    fprintf(fileID, 'Starting load optimization for SOC=%.1f%% (V_min=%.1f V, V_max=%.1f V)\n', ...
        soc, v_min_limit, v_max_limit);
    
    iteration = 0;
    while (load_right - load_left) > tolerance && iteration < max_iterations
        iteration = iteration + 1;
        current_load = (load_left + load_right) / 2;
        
        fprintf(fileID, '  Load Iteration %d/%d - Testing load: %.3f\n', ...
            iteration, max_iterations, current_load);
        
        try
            [min_voltage, max_voltage, steady_temp] = evaluate_point(soc, current_load, n_modules, ...
                original_current, env_temp, rth_cooling, cell_specs, aging_condition);
            
            fprintf(fileID, '    Results: V_min=%.1f, V_max=%.1f, T=%.1f\n', ...
                min_voltage, max_voltage, steady_temp);
            
            last_evaluations.load(end+1) = current_load;
            
            is_valid = true;
            if max_voltage > v_max_limit
                failure_reason = sprintf('high_voltage (%.1fV > %.1fV limit)', max_voltage, v_max_limit);
                is_valid = false;
            elseif min_voltage < v_min_limit
                failure_reason = sprintf('low_voltage (%.1fV < %.1fV limit)', min_voltage, v_min_limit);
                is_valid = false;
            elseif steady_temp > temp_limit
                failure_reason = sprintf('high_temp (%.1fC > %.1fC limit)', steady_temp, temp_limit);
                is_valid = false;
            end
            
            last_evaluations.valid(end+1) = is_valid;
            
            if is_valid
                load_left = current_load;
                
                if current_load > max_load
                    max_load = current_load;
                    final_max_v = max_voltage;
                    final_min_v = min_voltage;
                    final_temp = steady_temp;
                    failure_reason = '';
                end
            else
                load_right = current_load;
                fprintf(fileID, '    Failed due to: %s\n', failure_reason);
            end
            
            if length(last_evaluations.load) >= 3
                load_changes = diff(last_evaluations.load(end-2:end));
                if all(abs(load_changes) < tolerance/2)
                    fprintf(fileID, '    Converged due to minimal load changes\n');
                    break;
                end
            end
            
        catch ME
            fprintf(fileID, '    Error in simulation: %s\n', ME.message);
            load_right = current_load;
            failure_reason = 'simulation_error';
        end
    end
    
    if iteration >= max_iterations
        fprintf(fileID, '  Warning: Reached maximum iterations\n');
    end
    
    if max_load == 0
        fprintf(fileID, '  Warning: No valid solution found\n');
    else
        fprintf(fileID, '  Best valid solution: Load=%.3f, V_max=%.1f, V_min=%.1f, T=%.1f\n', ...
            max_load, final_max_v, final_min_v, final_temp);
    end
end