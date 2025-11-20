function analyze_supercap_system(aging_conditions, cell_specs, simulation_specs)
    % Create main results directory with timestamp
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    main_results_dir = fullfile('results', timestamp);
    mkdir(main_results_dir);
    
    % Initialize log file
    log_file = fullfile(main_results_dir, 'analysis_log.txt');
    fileID = fopen(log_file, 'w');
    
    % Initialize table for collecting all results
    all_results = table();
    
    % Get all possible module configurations
    if isstruct(simulation_specs.module_range)
        module_configs = simulation_specs.module_range.min:simulation_specs.module_range.max;
    else
        module_configs = simulation_specs.module_range;
    end
    
    % Helper function for logging
    function log_message(msg, varargin)
        formatted_msg = sprintf(msg, varargin{:});
        timestamp_str = datestr(now, 'yyyy-mm-dd HH:MM:SS');
        full_msg = sprintf('[%s] %s', timestamp_str, formatted_msg);
        fprintf(fileID, '%s\n', full_msg);
        fprintf('%s\n', full_msg);
    end
    
    % Calculate total iterations for progress bar
    total_cells = length(fieldnames(cell_specs));
    total_aging = length(fieldnames(aging_conditions));
    total_v_min = length(simulation_specs.v_min);
    total_modules = length(module_configs);
    total_iterations = total_cells * total_aging * total_v_min * total_modules;
    current_iteration = 0;
    
    % Create progress bar
    h = waitbar(0, 'Initializing...', 'Name', 'Analysis Progress');
    start_time = datetime('now');
    
    % Log initial configuration
    log_message('=== Starting Analysis ===');
    log_message('Results directory: %s', main_results_dir);
    log_message('Configuration Summary:');
    log_message('- Module range: %s', mat2str(module_configs));
    log_message('- V_min range: %s', mat2str(simulation_specs.v_min));
    log_message('- V_max: %d V', simulation_specs.v_max);
    log_message('- Environment temperature: %.1f °C', simulation_specs.env_temp);
    
    % Log cell specifications
    cell_names = fieldnames(cell_specs);
    log_message('Analyzing %d cell types:', length(cell_names));
    for i = 1:length(cell_names)
        current_cell = cell_names{i};
        cell = cell_specs.(current_cell);
        log_message('  %s:', current_cell);
        log_message('    - ESR (10ms): %.3f mΩ', cell.Cell_ResESR10ms_Ohm * 1000);
        log_message('    - ESR (1s): %.3f mΩ', cell.Cell_ResESR1s_Ohm * 1000);
        log_message('    - Rated Capacity: %.0f F', cell.Cell_CapRated_F);
    end
    
    % For each module configuration
    for n_modules = module_configs
        log_message('');
        log_message('=== Starting analysis for %d modules configuration ===', n_modules);
        
        % Initialize results table for this module configuration
        config_results = table();
        
        % Create directory for this module configuration
        module_dir = fullfile(main_results_dir, sprintf('modules_%d', n_modules));
        mkdir(module_dir);
        
        % Iterate through each cell type
        for cell_idx = 1:length(cell_names)
            current_cell = cell_names{cell_idx};
            log_message('');
            log_message('--- Processing cell: %s ---', current_cell);
            
            % Create cell directory
            cell_dir = fullfile(module_dir, current_cell);
            mkdir(cell_dir);
            
            % Iterate through aging conditions
            aging_names = fieldnames(aging_conditions);
            for aging_idx = 1:length(aging_names)
                current_aging = aging_names{aging_idx};
                aging_params = aging_conditions.(current_aging);
                
                % Create aging directory
                aging_dir = fullfile(cell_dir, current_aging);
                mkdir(aging_dir);
                
                log_message('  Analyzing aging condition: %s (SOH: %.1f%%)', ...
                    aging_params.name, aging_params.Cell_SOH_PU);
                
                % For each V_min value
                for v_min = simulation_specs.v_min
                    current_iteration = current_iteration + 1;
                    
                    % Update progress bar
                    progress = current_iteration / total_iterations;
                    elapsed_time = datetime('now') - start_time;
                    estimated_total = elapsed_time / progress;
                    remaining_time = estimated_total - elapsed_time;
                    
                    waitbar_msg = sprintf(['Progress: %.1f%%\n' ...
                        'Module: %d/%d\nCell: %s\nAging: %s\nV_min: %d\n' ...
                        'Remaining: %s'], ...
                        progress*100, n_modules, max(module_configs), ...
                        current_cell, current_aging, v_min, ...
                        char(duration(remaining_time, 'Format', 'hh:mm:ss')));
                    waitbar(progress, h, waitbar_msg);
                    
                    log_message('    Processing V_min = %d V:', v_min);
                    
                    % Create voltage configuration directory
                    voltage_dir = fullfile(aging_dir, sprintf('Vmin_%d', v_min));
                    mkdir(voltage_dir);
                    plots_dir = fullfile(voltage_dir, 'plots');
                    mkdir(plots_dir);
                    
                    % Run optimization
                    log_message('      Searching for optimal configuration...');
                    [optimal_soc, optimal_load] = optimize_system(n_modules, ...
                        simulation_specs.load_profile, fileID, ...
                        simulation_specs.env_temp, simulation_specs.rth_cooling, ...
                        cell_specs.(current_cell), aging_params, ...
                        v_min, simulation_specs.v_max, simulation_specs.v_step);
                    
                    if ~isnan(optimal_soc) && ~isnan(optimal_load)
                        log_message('      Found optimal configuration:');
                        log_message('        - SOC: %.1f%%', optimal_soc);
                        log_message('        - Load Factor: %.3f', optimal_load);
                        log_message('      Running detailed simulation...');
                        
                        % Run simulation with optimal parameters
                        Results = run_simulation(optimal_soc, optimal_load, n_modules, ...
                            simulation_specs, cell_specs.(current_cell), aging_params);
                        
                        % Calculate metrics
                        time_mask = Results.Sim_Electrical_Ouput.Cell_Current_A.Time < 60;
                        rms_current = sqrt(mean(Results.Sim_Electrical_Ouput.Cell_Current_A.Data(time_mask).^2));
                        mean_losses = mean(Results.Sim_Electrical_Ouput.Cell_Ploss_W.Data(time_mask));
                        mean_esr = 1000 * mean_losses / (rms_current^2);
                        max_temp = max(Results.Sim_Electrical_Ouput.Cell_Temp_degC.Data);
                        min_voltage = min(Results.Sim_Electrical_Ouput.Cell_Voltage_V.Data * 54 * n_modules);
                        max_voltage = max(Results.Sim_Electrical_Ouput.Cell_Voltage_V.Data * 54 * n_modules);
                        
                        log_message('      Simulation results:');
                        log_message('        - RMS Current (60s): %.2f A', rms_current);
                        log_message('        - Mean ESR: %.2f mΩ', mean_esr);
                        log_message('        - Maximum Temperature: %.1f °C', max_temp);
                        log_message('        - Voltage range: %.1f V - %.1f V', min_voltage, max_voltage);
                        
                        % Save plots
                        log_message('      Generating plots...');
                        save_plots(Results, plots_dir, n_modules, current_cell, ...
                            current_aging, optimal_soc, optimal_load);
                        
                        % Create results row
                        row = table();
                        row.Cell_Type = {current_cell};
                        row.Aging_Condition = {current_aging};
                        row.SOH = aging_params.Cell_SOH_PU;
                        row.V_min = v_min;
                        row.V_max = simulation_specs.v_max;
                        row.N_Modules = n_modules;
                        row.Optimal_SOC = optimal_soc;
                        row.Load_Factor = optimal_load;
                        row.RMS_Current_60s = rms_current;
                        row.Mean_ESR_mOhm = mean_esr;
                        row.System_ESR_mOhm = mean_esr * 54 * n_modules;
                        row.Max_Temperature = max_temp;
                        row.Min_System_Voltage = min_voltage;
                        row.Max_System_Voltage = max_voltage;
                        
                        % Append to configuration results
                        config_results = [config_results; row];
                        
                        % Save simulation results
                        save(fullfile(voltage_dir, 'simulation_results.mat'), 'Results', ...
                            'optimal_soc', 'optimal_load');
                        
                        log_message('      Results saved successfully');
                    else
                        log_message('      No valid solution found for this configuration');
                    end
                end
            end
        end
        
        % Save results for this module configuration
        log_message('Saving Excel results for %d modules configuration...', n_modules);
        excel_filename = fullfile(module_dir, sprintf('results_modules_%d.xlsx', n_modules));
        
        % Sort results by V_min, Cell_Type, and Aging_Condition
        config_results = sortrows(config_results, {'V_min', 'Cell_Type', 'Aging_Condition'});
        
        % Write to Excel
        writetable(config_results, excel_filename, 'Sheet', 'Results');
        
        % Append to complete results
        all_results = [all_results; config_results];
    end
    
    % Close progress bar
    close(h);
    
    % Save complete results sorted by modules, V_min, cell type, and aging condition
    log_message('Saving complete results...');
    all_results = sortrows(all_results, {'N_Modules', 'V_min', 'Cell_Type', 'Aging_Condition'});
    writetable(all_results, fullfile(main_results_dir, 'complete_results.xlsx'), 'Sheet', 'All Results');
    
    % Close log file and print final message
    log_message('');
    log_message('=== Analysis Completed ===');
    log_message('Total execution time: %s', char(datetime('now') - start_time));
    log_message('Results saved in: %s', main_results_dir);
    
    fclose(fileID);
end

function Results = run_simulation(optimal_soc, optimal_load, n_modules, simulation_specs, cell_specs, aging_params)
    % Set up parameters structure
    params = struct();
    params.Cell_ResESR10ms_Ohm = cell_specs.Cell_ResESR10ms_Ohm;
    params.Cell_ResESR1s_Ohm = cell_specs.Cell_ResESR1s_Ohm;
    params.Cell_CapRated_F = cell_specs.Cell_CapRated_F;
    params.Cell_VoltRated_V = cell_specs.Cell_VoltRated_V;
    params.Cell_SoCInit_PU = optimal_soc;
    params.Cell_SOH_PU = aging_params.Cell_SOH_PU;
    
    % Set block parameters
    blockPath = 'Supercap_Thermo_Electrical_Cell_Simulation_Model/Supercap Cell Model/Supercapacitor system';
    setBlockParameters(blockPath, params);
    
    % Set SOC in model
    set_param('Supercap_Thermo_Electrical_Cell_Simulation_Model/Input signals/Sim_SocInit_pc', ...
        'Value', num2str(optimal_soc));
    
    % Scale current
    cell_current_A = simulation_specs.load_profile * optimal_load;
    block_path = 'Supercap_Thermo_Electrical_Cell_Simulation_Model/Input signals/Current or Power Input';
    set_param(block_path, 'rep_seq_y', mat2str(cell_current_A));
    
    % Run simulation
    Results = sim('Supercap_Thermo_Electrical_Cell_Simulation_Model');
end

function save_plots(Results, plots_dir, n_modules, cell_name, aging_condition, optimal_soc, optimal_load)
    % Current plot
    figure('Position', [100 100 800 400]);
    plot(Results.Sim_Electrical_Ouput.Cell_Current_A.Time, ...
        Results.Sim_Electrical_Ouput.Cell_Current_A.Data, 'LineWidth', 1.5)
    grid on
    xlabel('Time [s]')
    ylabel('Current [A]')
    title(sprintf('Cell Current\nCell: %s, Aging: %s\nSOC: %.1f%%, Load: %.3f', ...
        cell_name, aging_condition, optimal_soc, optimal_load))
    savefig(fullfile(plots_dir, 'current.fig'))
    saveas(gcf, fullfile(plots_dir, 'current.png'))
    close;
    
    % Voltage plot
    figure('Position', [100 100 800 400]);
    plot(Results.Sim_Electrical_Ouput.Cell_Voltage_V.Time, ...
        n_modules * 54 * Results.Sim_Electrical_Ouput.Cell_Voltage_V.Data, 'b-', ...
        Results.Sim_Electrical_Ouput.Cell_OCV_V.Time, ...
        n_modules * 54 * Results.Sim_Electrical_Ouput.Cell_OCV_V.Data, 'r--', 'LineWidth', 1.5)
    grid on
    xlabel('Time [s]')
    ylabel('Voltage [V]')
    title(sprintf('System Voltage\nCell: %s, Aging: %s\nSOC: %.1f%%, Load: %.3f', ...
        cell_name, aging_condition, optimal_soc, optimal_load))
    legend('Terminal Voltage', 'OCV')
    savefig(fullfile(plots_dir, 'voltage.fig'))
    saveas(gcf, fullfile(plots_dir, 'voltage.png'))
    close;
    
    % Temperature plot
    figure('Position', [100 100 800 400]);
    plot(Results.Sim_Electrical_Ouput.Cell_Temp_degC.Time, ...
        Results.Sim_Electrical_Ouput.Cell_Temp_degC.Data, 'LineWidth', 1.5)
    grid on
    xlabel('Time [s]')
    ylabel('Temperature [°C]')
    title(sprintf('Cell Temperature\nCell: %s, Aging: %s\nSOC: %.1f%%, Load: %.3f', ...
        cell_name, aging_condition, optimal_soc, optimal_load))
    savefig(fullfile(plots_dir, 'temperature.fig'))
    saveas(gcf, fullfile(plots_dir, 'temperature.png'))
    close;
    
    % C-rate plot
    figure('Position', [100 100 800 400]);
    plot(Results.Sim_Electrical_Ouput.Cell_Current_A.Time, ...
        Results.Sim_Electrical_Ouput.Cell_Current_A.Data / 33, 'LineWidth', 1.5)
    grid on
    xlabel('Time [s]')
    ylabel('C Rate')
    title(sprintf('Cell C Rate\nCell: %s, Aging: %s\nSOC: %.1f%%, Load: %.3f', ...
        cell_name, aging_condition, optimal_soc, optimal_load))
    savefig(fullfile(plots_dir, 'c_rate.fig'))
    saveas(gcf, fullfile(plots_dir, 'c_rate.png'))
    close;
    
    % Use existing plot functions
    plot_rack_electrical_simulations(Results, n_modules, plots_dir);
    plot_system_voltage_drop_graph(Results, n_modules, plots_dir, 60);
    
    % Save also as PNG versions
    open(fullfile(plots_dir, 'rack_electrical_simulations.fig'));
    saveas(gcf, fullfile(plots_dir, 'rack_electrical_simulations.png'));
    close;
    
    open(fullfile(plots_dir, 'system_voltage_drop_graph.fig'));
    saveas(gcf, fullfile(plots_dir, 'system_voltage_drop_graph.png'));
    close;
end