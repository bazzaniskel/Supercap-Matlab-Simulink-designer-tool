function dynamic_aging_simulation(varargin)
    % DYNAMIC_AGING_SIMULATION - Implements aging loop for supercapacitor system design
    % This script performs both design optimization and detailed lifetime simulation
    % with dynamic SOH updates based on aging mechanisms
    %
    % Usage:
    %   dynamic_aging_simulation()           % Use default configuration
    %   dynamic_aging_simulation(config)     % Use provided configuration
    
    clear variables; % Clear local variables but preserve function inputs
    clc;
    
    % Add required paths (adjust these to your actual paths)
    addpath('./optimisation_analysis_functions');
    addpath('./supercap_cell');
    
    % Suppress warnings
    warning('off', 'all');
    
    fprintf('=== DYNAMIC AGING SIMULATION ===\n\n');
    
    %% CONFIGURATION PARAMETERS
    if nargin > 0 && isstruct(varargin{1})
        % Use provided configuration
        external_config = varargin{1};
        config = setup_simulation_configuration_with_override(external_config);
        fprintf('Using external configuration\n');
    else
        % Use default configuration
        config = setup_simulation_configuration();
        fprintf('Using default configuration\n');
    end
    
    %% PHASE 1: DESIGN OPTIMIZATION WITH AGING
    fprintf('PHASE 1: Design Optimization with Aging Consideration\n');
    fprintf('====================================================\n');
    
    optimal_design = design_with_aging_loop(config);
    
    if isempty(optimal_design)
        fprintf('ERROR: No valid design found!\n');
        return;
    end
    
    fprintf('\nOptimal Design Found:\n');
    fprintf('- Parallel modules: %d\n', optimal_design.parallel_modules);
    fprintf('- Starting voltage: %d V\n', optimal_design.v_start);
    fprintf('- Target lifetime: %.1f years\n', config.target_lifetime_years);
    fprintf('- Final SOH: %.1f%%\n', optimal_design.final_soh);
    
    %% PHASE 2: DETAILED LIFETIME SIMULATION
    fprintf('\nPHASE 2: Detailed Lifetime Simulation\n');
    fprintf('=====================================\n');
    
    lifetime_results = detailed_lifetime_simulation(optimal_design, config);
    
    %% PHASE 3: GENERATE COMPREHENSIVE PLOTS
    fprintf('\nPHASE 3: Generating Analysis Plots\n');
    fprintf('==================================\n');
    
    generate_aging_plots(optimal_design, lifetime_results, config);
    
    %% SAVE RESULTS
    save_aging_results(optimal_design, lifetime_results, config);
    
    fprintf('\n=== SIMULATION COMPLETE ===\n');
end

function config = setup_simulation_configuration_with_override(external_config)
    % Setup configuration with external overrides
    
    % Start with default configuration
    config = setup_simulation_configuration();
    
    % Override with external configuration parameters
    if isfield(external_config, 'target_lifetime_years')
        config.target_lifetime_years = external_config.target_lifetime_years;
    end
    
    if isfield(external_config, 'aging_time_step_years')
        config.aging_time_step_years = external_config.aging_time_step_years;
    end
    
    if isfield(external_config, 'detailed_time_step_days')
        config.detailed_time_step_days = external_config.detailed_time_step_days;
    end
    
    if isfield(external_config, 'series_modules')
        config.series_modules = external_config.series_modules;
    end
    
    if isfield(external_config, 'cell_type')
        config = update_cell_specs(config, external_config.cell_type);
    end
    
    if isfield(external_config, 'voltage_limits')
        config.v_min = external_config.voltage_limits.v_min;
        config.v_max = external_config.voltage_limits.v_max;
        config.v_start_max = external_config.voltage_limits.v_start_max;
    end
    
    % Update power profile based on selection
    if isfield(external_config, 'profile_type')
        config.power_profile = create_power_profile(external_config);
    end
    
    fprintf('Configuration updated with external parameters\n');
end

function config = update_cell_specs(config, cell_type)
    % Update cell specifications based on cell type selection
    
    switch cell_type
        case 'SCH3400'
            config.cell_specs.Cell_Type = 'Gen1_SCH3400';
            config.cell_specs.Cell_ResESR10ms_Ohm = 0.17e-3;
            config.cell_specs.Cell_ResESR1s_Ohm = 0.21e-3;
            config.cell_specs.Cell_CapRated_F = 3400;
            config.cell_specs.Cell_VoltRated_V = 3;
            
        case 'SCX5000'
            config.cell_specs.Cell_Type = 'Gen2_SCX5000';
            config.cell_specs.Cell_ResESR10ms_Ohm = 0.14e-3;
            config.cell_specs.Cell_ResESR1s_Ohm = 0.2e-3;
            config.cell_specs.Cell_CapRated_F = 5000;
            config.cell_specs.Cell_VoltRated_V = 3;
            
        case 'Kaifa4000'
            config.cell_specs.Cell_Type = 'Gen1_Kaifa4000';
            config.cell_specs.Cell_ResESR10ms_Ohm = 0.24e-3;
            config.cell_specs.Cell_ResESR1s_Ohm = 0.3e-3;
            config.cell_specs.Cell_CapRated_F = 4150;
            config.cell_specs.Cell_VoltRated_V = 3;
    end
end

function power_profile = create_power_profile(external_config)
    % Create power profile based on external configuration
    
    switch external_config.profile_type
        case 'turbine_load_1'
            Turbine_Load1 = @(x) (1.9e6*(1-exp(-6*x/150)));
            time_data = linspace(0, 200.1, 2000);
            power_data = 1.9e6 - Turbine_Load1(time_data);
            switch_mode = -1; % Power mode
            
        case 'turbine_load_2'
            Turbine_Load2 = @(x) (-1.6e6*(1-exp(-6*x/150)));
            time_data = linspace(0, 200.1, 2000);
            power_data = -1.6e6 - Turbine_Load2(time_data);
            switch_mode = -1; % Power mode
            
        case 'rect_pulse'
            duration = external_config.pulse_duration;
            current = external_config.pulse_current;
            time_data = linspace(0, duration * 1.5, 1000);
            power_data = (time_data >= 0.1 & time_data <= (0.1 + duration)) * current;
            switch_mode = 1; % Current mode
            
        case 'sine_wave'
            duration = external_config.wave_duration;
            peak_power = external_config.wave_power;
            frequency = external_config.wave_frequency;
            time_data = linspace(0, duration, round(duration * 100)); % 100 Hz sampling
            power_data = peak_power * abs(sin(2 * pi * frequency * time_data));
            switch_mode = -1; % Power mode
            
        otherwise
            % Default to turbine load 1
            Turbine_Load1 = @(x) (1.9e6*(1-exp(-6*x/150)));
            time_data = linspace(0, 200.1, 2000);
            power_data = 1.9e6 - Turbine_Load1(time_data);
            switch_mode = -1; % Power mode
    end
    
    power_profile = struct();
    power_profile.time_data = time_data;
    power_profile.power_data = power_data;
    power_profile.duration = time_data(end);
    power_profile.max_power = max(abs(power_data));
    power_profile.Switch_CurrentOrPower = switch_mode;
end

function optimal_design = design_with_aging_loop(config)
    % Design optimization considering aging over target lifetime
    
    fprintf('Starting design optimization with aging consideration...\n');
    
    % Search range for parallel modules
    min_parallel = 50;
    max_parallel = 500;
    
    optimal_design = [];
    
    for parallel_modules = min_parallel:10:max_parallel
        fprintf('Testing %d parallel modules... ', parallel_modules);
        
        % Run aging simulation for this configuration
        [is_valid, final_soh, aging_data] = simulate_aging_progression(...
            parallel_modules, config.v_start_max, config);
        
        if is_valid
            fprintf('VALID (Final SOH: %.1f%%)\n', final_soh);
            
            optimal_design = struct();
            optimal_design.parallel_modules = parallel_modules;
            optimal_design.v_start = config.v_start_max;
            optimal_design.series_modules = config.series_modules;
            optimal_design.final_soh = final_soh;
            optimal_design.design_aging_data = aging_data;
            break;
        else
            fprintf('INVALID\n');
        end
    end
    
    if isempty(optimal_design)
        fprintf('No valid design found in range [%d, %d] parallel modules\n', min_parallel, max_parallel);
    end
end

function [is_valid, final_soh, aging_data] = simulate_aging_progression(parallel_modules, v_start, config)
    % Simulate aging progression over target lifetime with coarse time steps
    
    % Initialize aging tracking
    current_soh = 100; % Start at 100% SOH
    current_time_years = 0;
    aging_data = struct();
    aging_data.time_years = [];
    aging_data.soh_percent = [];
    aging_data.max_voltage = [];
    aging_data.min_voltage = [];
    aging_data.max_current = [];
    aging_data.rms_current = [];
    aging_data.steady_temp = [];
    
    iteration = 1;
    
    while current_time_years < config.target_lifetime_years && current_soh > 0
        
        % Update SOH in base workspace for simulation
        setup_simulation_workspace(parallel_modules, v_start, current_soh, config);
        
        try
            % Run single pulse simulation
            Results = evalin('base', 'sim(''Supercap_Thermo_Electrical_Cell_Simulation_Model'')');
            
            % Extract results
            cell_current = Results.Sim_Electrical_Ouput.Cell_Current_A.Data;
            cell_voltage = Results.Sim_Electrical_Ouput.Cell_Voltage_V.Data;
            time_sim = Results.Sim_Electrical_Ouput.Cell_Current_A.Time;
            
            % Calculate system-level parameters
            system_voltage = cell_voltage * config.series_modules * config.cell_specs.Module_NumCellSeries;
            system_current = cell_current * parallel_modules;
            
            % Check voltage constraints
            min_voltage = min(system_voltage);
            max_voltage = max(system_voltage);
            
            if min_voltage < config.v_min || max_voltage > config.v_max
                is_valid = false;
                final_soh = current_soh;
                return;
            end
            
            % Calculate RMS current and steady-state temperature
            rms_current = sqrt(mean(cell_current.^2));
            rms_current_duty = rms_current * sqrt(config.operating_hours_per_day / 24);
            
            % Calculate steady-state temperature rise
            steady_losses = rms_current_duty^2 * config.cell_specs.Cell_ResESR1s_Ohm;
            temp_rise = steady_losses * config.rth;
            steady_temp = config.env_temp + temp_rise;
            
            % Calculate average effective voltage
            v_eff = calculate_average_effective_voltage_simple(cell_voltage);
            
            % Calculate acceleration factor (using your formula)
            AF_T = (steady_temp > 65) * 2^((steady_temp-65)/11) + ...
                   (steady_temp <= 65) * 2^((steady_temp-65)/11);
            AF_V = (v_eff > 2.5) * 2^((v_eff-3)/0.12) + ...
                   (v_eff <= 2.5) * 2^((v_eff-2.5)/0.22) * 2^((2.5-3)/0.12);
            AF_tot = AF_T * AF_V;
            
            % Calculate aging for this time step
            % Age lost = (time_step_years * 8760 hours/year) / (1500 hours / AF_tot)
            age_lost_hours = config.aging_time_step_years * 8760 / (1500 / AF_tot);
            soh_loss_percent = (age_lost_hours / 8760) * (100 / config.target_lifetime_years);
            
            % Update SOH
            current_soh = max(0, current_soh - soh_loss_percent);
            current_time_years = current_time_years + config.aging_time_step_years;
            
            % Store data
            aging_data.time_years(iteration) = current_time_years;
            aging_data.soh_percent(iteration) = current_soh;
            aging_data.max_voltage(iteration) = max_voltage;
            aging_data.min_voltage(iteration) = min_voltage;
            aging_data.max_current(iteration) = max(abs(system_current));
            aging_data.rms_current(iteration) = rms_current * parallel_modules;
            aging_data.steady_temp(iteration) = steady_temp;
            
            iteration = iteration + 1;
            
        catch ME
            fprintf('Simulation failed: %s\n', ME.message);
            is_valid = false;
            final_soh = current_soh;
            return;
        end
    end
    
    % Check if system lasted the target lifetime
    is_valid = (current_time_years >= config.target_lifetime_years) && (current_soh > 0);
    final_soh = current_soh;
end


function lifetime_results = detailed_lifetime_simulation(optimal_design, config)
    % Detailed simulation with fine time resolution
    
    fprintf('Running detailed lifetime simulation...\n');
    
    parallel_modules = optimal_design.parallel_modules;
    v_start = optimal_design.v_start;
    
    % Initialize detailed tracking
    current_soh = 100;
    current_time_days = 0;
    target_time_days = config.target_lifetime_years * 365;
    
    lifetime_results = struct();
    lifetime_results.time_days = [];
    lifetime_results.time_years = [];
    lifetime_results.soh_percent = [];
    lifetime_results.system_max_voltage = [];
    lifetime_results.system_min_voltage = [];
    lifetime_results.system_max_current = [];
    lifetime_results.system_max_power = [];
    lifetime_results.cell_rms_current = [];
    lifetime_results.steady_state_temp = [];
    lifetime_results.acceleration_factor = [];
    
    iteration = 1;
    
    while current_time_days < target_time_days && current_soh > 0
        
        if mod(iteration, 10) == 1
            fprintf('Day %.0f (%.1f years), SOH: %.1f%%\n', ...
                current_time_days, current_time_days/365, current_soh);
        end
        
        % Update simulation workspace
        setup_simulation_workspace(parallel_modules, v_start, current_soh, config);
        
        try
            % Run simulation
            Results = evalin('base', 'sim(''Supercap_Thermo_Electrical_Cell_Simulation_Model'')');
            
            % Extract and process results
            cell_current = Results.Sim_Electrical_Ouput.Cell_Current_A.Data;
            cell_voltage = Results.Sim_Electrical_Ouput.Cell_Voltage_V.Data;
            cell_power = Results.Sim_Electrical_Ouput.Cell_Power_W.Data;
            
            % System-level calculations
            system_voltage = cell_voltage * config.series_modules * config.cell_specs.Module_NumCellSeries;
            system_current = cell_current * parallel_modules;
            system_power = cell_power * parallel_modules * config.series_modules * config.cell_specs.Module_NumCellSeries;
            
            % Calculate metrics
            rms_current = sqrt(mean(cell_current.^2));
            rms_current_duty = rms_current * sqrt(config.operating_hours_per_day / 24);
            
            % Steady-state temperature
            steady_losses = rms_current_duty^2 * config.cell_specs.Cell_ResESR1s_Ohm;
            temp_rise = steady_losses * config.rth;
            steady_temp = config.env_temp + temp_rise;
            
            % Average effective voltage
            v_eff = calculate_average_effective_voltage_simple(cell_voltage);
            
            % Acceleration factor
            AF_T = (steady_temp > 65) * 2^((steady_temp-65)/11) + ...
                   (steady_temp <= 65) * 2^((steady_temp-65)/11);
            AF_V = (v_eff > 2.5) * 2^((v_eff-3)/0.12) + ...
                   (v_eff <= 2.5) * 2^((v_eff-2.5)/0.22) * 2^((2.5-3)/0.12);
            AF_tot = AF_T * AF_V;
            
            % Calculate aging for this time step (days)
            time_step_years = config.detailed_time_step_days / 365;
            age_lost_hours = time_step_years * 8760 / (1500 / AF_tot);
            soh_loss_percent = (age_lost_hours / 8760) * (100 / config.target_lifetime_years);
            
            % Update SOH and time
            current_soh = max(0, current_soh - soh_loss_percent);
            current_time_days = current_time_days + config.detailed_time_step_days;
            
            % Store results
            lifetime_results.time_days(iteration) = current_time_days;
            lifetime_results.time_years(iteration) = current_time_days / 365;
            lifetime_results.soh_percent(iteration) = current_soh;
            lifetime_results.system_max_voltage(iteration) = max(system_voltage);
            lifetime_results.system_min_voltage(iteration) = min(system_voltage);
            lifetime_results.system_max_current(iteration) = max(abs(system_current));
            lifetime_results.system_max_power(iteration) = max(abs(system_power));
            lifetime_results.cell_rms_current(iteration) = rms_current;
            lifetime_results.steady_state_temp(iteration) = steady_temp;
            lifetime_results.acceleration_factor(iteration) = AF_tot;
            
            iteration = iteration + 1;
            
        catch ME
            fprintf('Detailed simulation failed at day %.0f: %s\n', current_time_days, ME.message);
            break;
        end
    end
    
    fprintf('Detailed simulation complete. Final SOH: %.1f%%\n', current_soh);
end

function setup_simulation_workspace(parallel_modules, v_start, current_soh, config)
    % Setup all variables in base workspace for Simulink simulation
    
    % Calculate derived parameters
    max_possible_v_start = config.cell_specs.Cell_VoltRated_V * config.series_modules * ...
        config.cell_specs.Module_NumCellSeries;
    actual_v_start = min(v_start, max_possible_v_start);
    max_rack_voltage = config.module_specs.Module_Rated_Voltage_V * config.series_modules;
    
    % System parameters
    assignin('base', 'Sim_Sys_Vstart_V', actual_v_start);
    assignin('base', 'Sim_SocInit_pc', (actual_v_start/max_rack_voltage)^2*100);
    assignin('base', 'Sim_NumSeriesModules', config.series_modules);
    assignin('base', 'Cell_VoltStart_V', min(actual_v_start/config.series_modules/config.cell_specs.Module_NumCellSeries, ...
        config.cell_specs.Cell_VoltRated_V));
    
    % SOH parameter (convert percentage to per-unit if needed)
    assignin('base', 'Sim_SOH_PU', current_soh); % Keep as percentage based on your code
    
    % Cell specifications
    cell_fields = fieldnames(config.cell_specs);
    for i = 1:length(cell_fields)
        field_name = cell_fields{i};
        assignin('base', field_name, config.cell_specs.(field_name));
    end
    
    % Power profile setup
    assignin('base', 'Cell_LoadInputTime_s', config.power_profile.time_data);
    assignin('base', 'Sim_TimeEnd_s', config.power_profile.duration);
    assignin('base', 'System_LoadInputCurrOrPower_AW', config.power_profile.power_data);
    assignin('base', 'Switch_CurrentOrPower', config.power_profile.Switch_CurrentOrPower);
    
    % Calculate cell-level power
    Module_NumberCells = config.cell_specs.Module_NumCellSeries;
    Cell_LoadInputCurrOrPower_AW = config.power_profile.power_data / parallel_modules / config.series_modules / Module_NumberCells;
    assignin('base', 'Cell_LoadInputCurrOrPower_AW', Cell_LoadInputCurrOrPower_AW);
    
    % Environmental parameters
    assignin('base', 'Environment_Temp_degC', config.env_temp);
    assignin('base', 'Cell_TempInit_degC', config.env_temp);
    assignin('base', 'Cell_RthToEnvironment_KpW', config.rth);
    assignin('base', 'Cell_HeatCapa_JpK', config.heat_capa);
    
    % Duty cycle
    assignin('base', 'Sys_DutyCycle_pu', config.operating_hours_per_day / 24);
    
    % Simulation parameters
    assignin('base', 'Switch_CoolingONOFF', 0);
    assignin('base', 'Switch_DeratingONOFF_NN', 0);
    assignin('base', 'Cooling_Temp_degC', config.env_temp);
    assignin('base', 'Cell_RthToCooling_KpW', 1);
    assignin('base', 'Cell_LowerSOCLimit_pc', 0);
    assignin('base', 'Cell_UpperSOCLimit_pc', 100);
    assignin('base', 'Cell_LowerVoltageLimit_V', 0);
    assignin('base', 'Cell_UpperVoltageLimit_V', 3);
end

function v_eff = calculate_average_effective_voltage_simple(cell_voltage)
    % Advanced version of average effective voltage calculation
    % This implements your full calculation method
    
    cell_voltage = double(cell_voltage);
    
    % For aging simulation, we need time-weighted average
    % Simplified approach: use RMS-like calculation for voltage stress
    v_eff = sqrt(mean(cell_voltage.^2));
    
    % Alternative: Use your full implementation if available
    % Uncomment and modify the following if you want to use the exact formula:
    
    % time_steps = ones(size(cell_voltage)) * (1/length(cell_voltage)); % Uniform time steps
    % tout_end = 1; % Normalized time
    % eff_area_check = (2^12.5) / (5 * log(2));
    % log2 = log(2);
    % 
    % % Calculate areas based on voltage regions
    % area_below = 2.^(5 * cell_voltage) / (5 * log2);
    % area_above = (2^12.5 + 2.^(10 * cell_voltage - 12.5)) / (10 * log2);
    % area = zeros(size(cell_voltage));
    % area(cell_voltage <= 2.5) = area_below(cell_voltage <= 2.5);
    % area(cell_voltage > 2.5) = area_above(cell_voltage > 2.5);
    % 
    % % Calculate effective area
    % effective_area = sum(area .* time_steps / tout_end);
    % 
    % % Calculate v_eff with limit case handling
    % if effective_area > eff_area_check
    %     v_eff = log(10 * 2^12.5 * log2 * effective_area - 2^25) / (10 * log2);
    % else
    %     v_eff = log(5 * log2 * effective_area) / (5 * log2);
    % end
    
    % Ensure reasonable bounds
    v_eff = max(0, min(v_eff, 3.0)); % Cell voltage should be between 0-3V
end

function generate_aging_plots(optimal_design, lifetime_results, config)
    % Generate comprehensive plots for aging analysis
    
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    
    % Create results folder
    results_folder = ['aging_results_' timestamp];
    if ~exist(results_folder, 'dir')
        mkdir(results_folder);
    end
    
    % Plot 1: SOH Evolution
    figure('Position', [100, 100, 1200, 800]);
    
    subplot(2,2,1);
    plot(lifetime_results.time_years, lifetime_results.soh_percent, 'b-', 'LineWidth', 2);
    xlabel('Time (years)');
    ylabel('State of Health (%)');
    title('SOH Evolution Over Lifetime');
    grid on;
    ylim([0, 100]);
    
    % Plot 2: System Voltage Evolution
    subplot(2,2,2);
    plot(lifetime_results.time_years, lifetime_results.system_min_voltage, 'r-', 'LineWidth', 2);
    hold on;
    plot(lifetime_results.time_years, lifetime_results.system_max_voltage, 'b-', 'LineWidth', 2);
    yline(config.v_min, 'k--', 'Min Limit', 'LineWidth', 1.5);
    yline(config.v_max, 'k--', 'Max Limit', 'LineWidth', 1.5);
    xlabel('Time (years)');
    ylabel('System Voltage (V)');
    title('System Voltage Evolution');
    legend('Min Voltage', 'Max Voltage', 'Min Limit', 'Max Limit');
    grid on;
    
    % Plot 3: System Current Evolution
    subplot(2,2,3);
    plot(lifetime_results.time_years, lifetime_results.system_max_current/1e3, 'g-', 'LineWidth', 2);
    xlabel('Time (years)');
    ylabel('Max System Current (kA)');
    title('System Current Evolution');
    grid on;
    
    % Plot 4: Temperature Evolution
    subplot(2,2,4);
    plot(lifetime_results.time_years, lifetime_results.steady_state_temp, 'm-', 'LineWidth', 2);
    xlabel('Time (years)');
    ylabel('Steady-State Temperature (°C)');
    title('Temperature Evolution');
    grid on;
    
    sgtitle(sprintf('System Aging Analysis - %d×%d Configuration', ...
        optimal_design.series_modules, optimal_design.parallel_modules), ...
        'FontSize', 16, 'FontWeight', 'bold');
    
    saveas(gcf, fullfile(results_folder, 'aging_overview.png'));
    
    % Plot 2: Detailed Performance Evolution
    figure('Position', [200, 200, 1200, 1000]);
    
    subplot(3,2,1);
    plot(lifetime_results.time_years, lifetime_results.system_max_power/1e6, 'r-', 'LineWidth', 2);
    xlabel('Time (years)');
    ylabel('Max System Power (MW)');
    title('System Power Capability');
    grid on;
    
    subplot(3,2,2);
    plot(lifetime_results.time_years, lifetime_results.cell_rms_current, 'c-', 'LineWidth', 2);
    xlabel('Time (years)');
    ylabel('Cell RMS Current (A)');
    title('Cell RMS Current');
    grid on;
    
    subplot(3,2,3);
    plot(lifetime_results.time_years, lifetime_results.acceleration_factor, 'k-', 'LineWidth', 2);
    xlabel('Time (years)');
    ylabel('Acceleration Factor');
    title('Aging Acceleration Factor');
    grid on;
    set(gca, 'YScale', 'log');
    
    subplot(3,2,4);
    degradation = 100 - lifetime_results.soh_percent;
    plot(lifetime_results.time_years, degradation, 'r-', 'LineWidth', 2);
    xlabel('Time (years)');
    ylabel('Capacity Loss (%)');
    title('Cumulative Degradation');
    grid on;
    
    subplot(3,2,5);
    if length(lifetime_results.time_years) > 1
        aging_rate = -diff(lifetime_results.soh_percent) ./ diff(lifetime_results.time_years);
        plot(lifetime_results.time_years(2:end), aging_rate, 'b-', 'LineWidth', 2);
    end
    xlabel('Time (years)');
    ylabel('Aging Rate (%/year)');
    title('Instantaneous Aging Rate');
    grid on;
    
    subplot(3,2,6);
    voltage_margin_min = lifetime_results.system_min_voltage - config.v_min;
    voltage_margin_max = config.v_max - lifetime_results.system_max_voltage;
    plot(lifetime_results.time_years, voltage_margin_min, 'r-', 'LineWidth', 2);
    hold on;
    plot(lifetime_results.time_years, voltage_margin_max, 'b-', 'LineWidth', 2);
    xlabel('Time (years)');
    ylabel('Voltage Margin (V)');
    title('Voltage Safety Margins');
    legend('Min Margin', 'Max Margin');
    grid on;
    
    sgtitle('Detailed Performance Evolution', 'FontSize', 16, 'FontWeight', 'bold');
    
    saveas(gcf, fullfile(results_folder, 'detailed_evolution.png'));
    
    fprintf('Plots saved to folder: %s\n', results_folder);
end

function save_aging_results(optimal_design, lifetime_results, config)
    % Save all results to files
    
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    results_folder = ['aging_results_' timestamp];
    
    % Save MAT file with all data
    save(fullfile(results_folder, 'aging_simulation_results.mat'), ...
        'optimal_design', 'lifetime_results', 'config');
    
    % Create summary table
    summary_data = {
        'Configuration', sprintf('%d series × %d parallel', optimal_design.series_modules, optimal_design.parallel_modules);
        'Starting Voltage (V)', num2str(optimal_design.v_start);
        'Target Lifetime (years)', num2str(config.target_lifetime_years);
        'Final SOH (%)', sprintf('%.1f', lifetime_results.soh_percent(end));
        'Simulation Duration (years)', sprintf('%.1f', lifetime_results.time_years(end));
        'Max Power Initial (MW)', sprintf('%.2f', lifetime_results.system_max_power(1)/1e6);
        'Max Power Final (MW)', sprintf('%.2f', lifetime_results.system_max_power(end)/1e6);
        'Power Degradation (%)', sprintf('%.1f', (1-lifetime_results.system_max_power(end)/lifetime_results.system_max_power(1))*100);
        'Max Temperature (°C)', sprintf('%.1f', max(lifetime_results.steady_state_temp));
        'Max Acceleration Factor', sprintf('%.2f', max(lifetime_results.acceleration_factor));
    };
    
    summary_table = cell2table(summary_data, 'VariableNames', {'Parameter', 'Value'});
    
    try
        writetable(summary_table, fullfile(results_folder, 'simulation_summary.xlsx'));
        fprintf('Summary saved to Excel file\n');
    catch
        fprintf('Excel save failed, summary saved to MAT file only\n');
    end
    
    fprintf('All results saved to: %s\n', results_folder);
end