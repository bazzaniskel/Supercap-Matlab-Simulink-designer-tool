function plot_temperature(Results, module_dir)
    % Helper function to calculate axis limits with padding
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

    % Get temperature data and time vector
    temperature = Results.Sim_Electrical_Ouput.Cell_Temp_degC.Data;
    time_vector = Results.Sim_Electrical_Ouput.Cell_Temp_degC.Time;
    
    % Calculate max temperature and deltaT
    [max_temp, max_temp_idx] = max(temperature);
    [min_temp, min_temp_idx] = min(temperature);
    delta_T = max_temp - min_temp;
    
    % Create figure with more rectangular aspect ratio
    figure('Position', [100 100 1200 800]);  % Changed from [100 100 1200 400]
    
    % Plot temperature
    plot(time_vector, temperature, 'LineWidth', 1.5)
    hold on
    % Add markers for max and min temperature
    plot(time_vector(max_temp_idx), max_temp, 'rx', 'MarkerSize', 10, 'LineWidth', 2)
    plot(time_vector(min_temp_idx), min_temp, 'bx', 'MarkerSize', 10, 'LineWidth', 2)
    hold off
    
    % Set axis limits
    padding_factor = 0.1;  % 10% padding
    ylim(calculate_limits(temperature, padding_factor));
    xlim([time_vector(1) time_vector(end)]);  % Set x limits to exact time range
    
    grid on
    xlabel('Time [s]')
    ylabel('Temperature [°C]')
    title(sprintf('Cell Temperature (Max: %.1f °C, Min: %.1f °C, \x0394T: %.1f °C)', ...
          max_temp, min_temp, delta_T))
    set(gca, 'FontName', 'Arial', 'FontSize', 14)
    
    % Save and close
    savefig(fullfile(module_dir, 'thermal_results.fig'))
    close;
end