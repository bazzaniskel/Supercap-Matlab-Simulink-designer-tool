function plot_system_voltage_drop_graph(Results, n_modules, module_dir, pulse_duration_s)
    if nargin < 4
        pulse_duration_s = 60;
    end
    
    % Calculate voltage drop and system-level values
    Cell_VoltageDrop_V = Results.Sim_Electrical_Ouput.Cell_Voltage_V.Data - Results.Sim_Electrical_Ouput.Cell_OCV_V.Data;
    Sys_VoltageDrop_V = n_modules * 54 * Cell_VoltageDrop_V;
    
    % Calculate pulse metrics
    time_mask = Results.Sim_Electrical_Ouput.Cell_Current_A.Time < pulse_duration_s;
    avg_losses_pulse_W = mean(Results.Sim_Electrical_Ouput.Cell_Ploss_W.Data(time_mask));
    rms_current_pulse_A = sqrt(mean(Results.Sim_Electrical_Ouput.Cell_Current_A.Data(time_mask).^2));
    avg_esr_pulse_mOhm = 1000 * avg_losses_pulse_W / (rms_current_pulse_A^2);
    Rack_esr_pulse_mOhm = n_modules * 54 * avg_esr_pulse_mOhm;

    % Improved ESR calculation with current threshold
    current_data = Results.Sim_Electrical_Ouput.Cell_Current_A.Data;
    current_threshold = max(abs(current_data)) * 0.01;
    
    % Calculate instantaneous ESR only when current is above threshold
    instantaneous_ESR = zeros(size(current_data));
    valid_points = abs(current_data) > current_threshold;
    instantaneous_ESR(valid_points) = 1000 * abs(Cell_VoltageDrop_V(valid_points)) ./ abs(current_data(valid_points));
    
    % Initialize filtered ESR array
    filtered_ESR = zeros(size(instantaneous_ESR));
    
    % Find first valid ESR measurement
    first_valid_idx = find(valid_points, 1);
    if ~isempty(first_valid_idx)
        % Initialize with a better starting value based on the average of next few valid points
        next_few_points = 10; % Number of points to average
        valid_indices = find(valid_points);
        end_idx = min(first_valid_idx + next_few_points, length(valid_indices));
        initial_points = valid_indices(1:end_idx);
        filtered_ESR(1:first_valid_idx) = mean(instantaneous_ESR(initial_points));
    end
    
    % Apply improved filter
    tau_filter = 0.5e-1;
    for i = first_valid_idx+1:length(filtered_ESR)
        if valid_points(i)
            filtered_ESR(i) = (1 - tau_filter) * filtered_ESR(i-1) + tau_filter * instantaneous_ESR(i);
        else
            filtered_ESR(i) = filtered_ESR(i-1);
        end
    end
    
    % Handle units for power and current
    function [scaled_value, unit_str] = scale_units(value, base_unit)
        if max(abs(value)) > 1e6
            scaled_value = value / 1e6;
            switch base_unit
                case 'W'
                    unit_str = 'MW';
                case 'A'
                    unit_str = 'MA';
            end
        elseif max(abs(value)) > 1e3
            scaled_value = value / 1e3;
            switch base_unit
                case 'W'
                    unit_str = 'kW';
                case 'A'
                    unit_str = 'kA';
            end
        else
            scaled_value = value;
            unit_str = base_unit;
        end
    end

    % Helper function to calculate axis limits with improved padding
    function limits = calculate_limits(data, padding_factor)
        data_min = min(data);
        data_max = max(data);
        data_range = data_max - data_min;
        
        % If data range is very small, expand it to avoid tight limits
        if data_range < eps*1e3
            center = (data_max + data_min) / 2;
            data_range = abs(center) * 0.1;  % Use 10% of center value
            data_min = center - data_range/2;
            data_max = center + data_range/2;
        end
        
        % Calculate padded limits
        padding = data_range * padding_factor;
        limits = [data_min - padding, data_max + padding];
        
        % If limits are very close to zero, include zero
        if abs(limits(1)) < data_range * 0.1
            limits(1) = 0;
        end
        if abs(limits(2)) < data_range * 0.1
            limits(2) = 0;
        end
        
        % Ensure limits don't cross zero unnecessarily
        if data_min > 0 && limits(1) < 0
            limits(1) = 0;
        end
        if data_max < 0 && limits(2) > 0
            limits(2) = 0;
        end
    end

    % Plot results
    figure('Position', [100 100 1200 800]);
    padding_factor = 0.1;
    
    % Voltage Drop
    subplot(3, 1, 1);
    time_vector = Results.Sim_Electrical_Ouput.Cell_Voltage_V.Time;
    [max_dV, max_dV_idx] = max(Sys_VoltageDrop_V);
    [min_dV, min_dV_idx] = min(Sys_VoltageDrop_V);
    
    plot(time_vector, Sys_VoltageDrop_V, 'LineWidth', 1.5);
    hold on
    plot(time_vector(max_dV_idx), max_dV, 'kx', 'MarkerSize', 10, 'LineWidth', 2)
    plot(time_vector(min_dV_idx), min_dV, 'rx', 'MarkerSize', 10, 'LineWidth', 2)
    hold off
    
    ylim(calculate_limits(Sys_VoltageDrop_V, padding_factor));
    grid on;
    xlabel('Time [s]');
    ylabel('\DeltaV [V]');
    title(sprintf('System Voltage Drop (Max: %.1f V, Min: %.1f V)', max_dV, min_dV));
    set(gca, 'FontName', 'Arial', 'FontSize', 14);
    
    % Current with scaled units
    subplot(3, 1, 2);
    [scaled_current, current_unit] = scale_units(current_data, 'A');
    % Find max absolute current point
    [~, max_curr_idx] = max(abs(current_data));
    max_current_abs = abs(current_data(max_curr_idx));
    
    % Calculate RMS current
    current_rms = sqrt(trapz(time_vector, current_data.^2) / (time_vector(end) - time_vector(1)));
    
    plot(time_vector, scaled_current, 'r-', 'LineWidth', 1.5);
    hold on
    plot(time_vector(max_curr_idx), scaled_current(max_curr_idx), 'kx', 'MarkerSize', 10, 'LineWidth', 2)
    hold off
    
    ylim(calculate_limits(scaled_current, padding_factor));
    grid on;
    xlabel('Time [s]');
    ylabel(['Current [', current_unit, ']']);
    title(sprintf('Rack Current (|I|_{max}: %.1f A, I_{RMS}: %.1f A)', max_current_abs, current_rms));
    set(gca, 'FontName', 'Arial', 'FontSize', 14);
    
    % ESR
    subplot(3, 1, 3);
    yyaxis left;
    module_esr = filtered_ESR * 54;
    plot(time_vector, module_esr, 'LineWidth', 1.5);
    ylim(calculate_limits(module_esr, padding_factor));
    ylabel(['Module ESR [m' char(937) ']']);  % Using Unicode for Omega
    
    yyaxis right;
    rack_esr = filtered_ESR * 54 * n_modules;
    plot(time_vector, rack_esr, 'LineWidth', 1.5);
    ylim(calculate_limits(rack_esr, padding_factor));
    ylabel(['Rack ESR [m' char(937) ']']);    % Using Unicode for Omega
    grid on;
    xlabel('Time [s]');
    title(['ESR (Avg Cell: ' num2str(avg_esr_pulse_mOhm,'%.2f') ' m' char(937) ...
           ', Avg Module: ' num2str(avg_esr_pulse_mOhm * 54,'%.2f') ' m' char(937) ...
           ', Avg Rack: ' num2str(Rack_esr_pulse_mOhm,'%.2f') ' m' char(937) ')']);
    set(gca, 'FontName', 'Arial', 'FontSize', 14);
    
    % Save and close the figure
    savefig(fullfile(module_dir, 'system_voltage_drop_graph.fig'));
    close
end