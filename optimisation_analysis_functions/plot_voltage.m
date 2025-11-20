function plot_voltage(Results, n_modules, module_dir, cells_per_module)
    if nargin < 4
        cells_per_module = 54;
    end
    
    % Calculate system voltages
    terminal_voltage = n_modules * cells_per_module * Results.Sim_Electrical_Ouput.Cell_Voltage_V.Data;
    ocv = n_modules * cells_per_module * Results.Sim_Electrical_Ouput.Cell_OCV_V.Data;
    time_vector = Results.Sim_Electrical_Ouput.Cell_Voltage_V.Time;
    
    % Find max and min terminal voltage points
    [max_v, max_v_idx] = max(terminal_voltage);
    [min_v, min_v_idx] = min(terminal_voltage);
    
    % Helper function to calculate axis limits with padding
    function limits = calculate_limits(data, padding_factor)
        data_min = min(data);
        data_max = max(data);
        data_range = data_max - data_min;
        
        if data_range < eps*1e3
            center = (data_max + data_min) / 2;
            data_range = abs(center) * 0.1;
            data_min = center - data_range/2;
            data_max = center + data_range/2;
        end
        
        padding = data_range * padding_factor;
        limits = [data_min - padding, data_max + padding];
        
        if abs(limits(1)) < data_range * 0.1
            limits(1) = 0;
        end
        if abs(limits(2)) < data_range * 0.1
            limits(2) = 0;
        end
        
        if data_min > 0 && limits(1) < 0
            limits(1) = 0;
        end
        if data_max < 0 && limits(2) > 0
            limits(2) = 0;
        end
    end
    
    % Create figure with square aspect ratio
    figure('Position', [100 100 800 800]);
    
    % Plot voltages
    plot(time_vector, terminal_voltage, 'b-', ...
         time_vector, ocv, 'r--', 'LineWidth', 1.5)
    hold on
    % Add markers for max and min points
    plot(time_vector(max_v_idx), max_v, 'kx', 'MarkerSize', 10, 'LineWidth', 2)
    plot(time_vector(min_v_idx), min_v, 'rx', 'MarkerSize', 10, 'LineWidth', 2)
    hold off
    
    % Set axis limits
    padding_factor = 0.1;
    ylim(calculate_limits([terminal_voltage; ocv], padding_factor));
    xlim([time_vector(1) time_vector(end)]);
    
    grid on
    xlabel('Time [s]')
    ylabel('Voltage [V]')
    title(sprintf('System Voltage (Max: %.1f V, Min: %.1f V)', max_v, min_v))
    legend('Terminal Voltage', 'OCV')
    set(gca, 'FontName', 'Arial', 'FontSize', 14)
    
    % Save and close
    savefig(fullfile(module_dir, 'voltage_results.fig'))
    close;
end