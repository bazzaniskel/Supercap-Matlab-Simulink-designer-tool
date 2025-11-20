function plot_rack_electrical_simulations(Results, n_modules, module_dir)
    % Helper function to scale units
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

    % Helper function to calculate axis limits
    function limits = calculate_limits(data, padding_factor)
        data_min = min(data);
        data_max = max(data);
        data_range = data_max - data_min;
        % If data range is very small, expand it
        if data_range < eps*1e3
            center = (data_max + data_min) / 2;
            data_range = abs(center) * 0.1;
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

    % Create figure - Modified dimensions to be wider
    figure('Position', [100 100 1200 800]);  % Changed from [100 100 800 800]
    padding_factor = 0.1;

    % Rack Voltage
    subplot(3, 1, 1);
    rack_voltage = n_modules * 54 * Results.Sim_Electrical_Ouput.Cell_Voltage_V.Data;
    rack_ocv = n_modules * 54 * Results.Sim_Electrical_Ouput.Cell_OCV_V.Data;
    time_vector = Results.Sim_Electrical_Ouput.Cell_Voltage_V.Time;
    
    % Find min and max voltage points
    [max_voltage, max_v_idx] = max(rack_voltage);
    [min_voltage, min_v_idx] = min(rack_voltage);
    
    % Plot voltages and markers
    plot(time_vector, rack_voltage, 'b-', ...
         time_vector, rack_ocv, 'r--', 'LineWidth', 1.5)
    hold on
    plot(time_vector(max_v_idx), max_voltage, 'kx', 'MarkerSize', 10, 'LineWidth', 2)
    plot(time_vector(min_v_idx), min_voltage, 'rx', 'MarkerSize', 10, 'LineWidth', 2)
    hold off
    
    ylim(calculate_limits([rack_voltage; rack_ocv], padding_factor));
    grid on
    xlabel('Time [s]')
    ylabel('Voltage [V]')
    title(sprintf('Rack Voltage (Max: %.1f V, Min: %.1f V)', max_voltage, min_voltage))
    legend('Terminal Voltage', 'OCV')
    set(gca, 'FontName', 'Arial', 'FontSize', 14);

    % Rack Current with scaled units
    subplot(3, 1, 2);
    current = Results.Sim_Electrical_Ouput.Cell_Current_A.Data;
    [scaled_current, current_unit] = scale_units(current, 'A');
    time_vector = Results.Sim_Electrical_Ouput.Cell_Current_A.Time;
    
    % Find max absolute current point
    [~, max_curr_idx] = max(abs(current));
    max_current_abs = abs(current(max_curr_idx));
    
    % Calculate RMS current
    dt = mean(diff(time_vector)); % Average time step
    current_rms = sqrt(trapz(time_vector, current.^2) / (time_vector(end) - time_vector(1)));
    
    % Plot current and marker
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

    % Rack Power with scaled units
    subplot(3, 1, 3);
    rack_power = Results.Sim_Electrical_Ouput.Cell_Power_W.Data * 54 * n_modules;
    [scaled_power, power_unit] = scale_units(rack_power, 'W');
    time_vector = Results.Sim_Electrical_Ouput.Cell_Power_W.Time;
    
    % Find min and max power points
    [max_power, max_p_idx] = max(rack_power);
    [min_power, min_p_idx] = min(rack_power);
    [scaled_max_power, ~] = scale_units(max_power, 'W');
    [scaled_min_power, ~] = scale_units(min_power, 'W');
    
    % Plot power and markers
    plot(time_vector, scaled_power, 'LineWidth', 1.5);
    hold on
    plot(time_vector(max_p_idx), scaled_power(max_p_idx), 'kx', 'MarkerSize', 10, 'LineWidth', 2)
    plot(time_vector(min_p_idx), scaled_power(min_p_idx), 'rx', 'MarkerSize', 10, 'LineWidth', 2)
    hold off
    
    ylim(calculate_limits(scaled_power, padding_factor));
    grid on;
    xlabel('Time [s]');
    ylabel(['Power [', power_unit, ']']);
    title(sprintf('Rack Power (Max: %.1f %s, Min: %.1f %s)', ...
          scaled_max_power, power_unit, scaled_min_power, power_unit));
    set(gca, 'FontName', 'Arial', 'FontSize', 14);

    % Save and close the figure
    savefig(fullfile(module_dir, 'rack_electrical_simulations.fig'));
    close;
end