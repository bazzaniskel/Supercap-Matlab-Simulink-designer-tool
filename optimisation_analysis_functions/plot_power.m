function plot_power(Results, module_dir, number_of_racks, cells_per_module)
    % Default value for number_of_racks
    if nargin < 3
        number_of_racks = 1;
    end
    
    if nargin < 4
        cells_per_module  = 54;
    end

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

    % Get power data and time vector
    power_data = Results.Sim_Electrical_Ouput.Cell_Power_W.Data * cells_per_module * number_of_racks;
    time_vector = Results.Sim_Electrical_Ouput.Cell_Power_W.Time;
    
    % Calculate RMS power and find max/min
    power_rms = sqrt(trapz(time_vector, power_data.^2) / (time_vector(end) - time_vector(1)));
    [max_power, max_p_idx] = max(power_data);
    [min_power, min_p_idx] = min(power_data);
    
    % Scale power values for display
    [scaled_power, power_unit] = scale_units(power_data, 'W');
    [scaled_max_power, ~] = scale_units(max_power, 'W');
    [scaled_min_power, ~] = scale_units(min_power, 'W');
    [scaled_rms_power, ~] = scale_units(power_rms, 'W');
    
    % Create figure
    figure('Position', [100 100 1200 800]);
    
    % Plot power
    plot(time_vector, scaled_power, 'LineWidth', 1.5)
    hold on
    % Add markers for max and min points
    plot(time_vector(max_p_idx), scaled_power(max_p_idx), 'rx', 'MarkerSize', 10, 'LineWidth', 2)
    plot(time_vector(min_p_idx), scaled_power(min_p_idx), 'bx', 'MarkerSize', 10, 'LineWidth', 2)
    hold off
    
    % Set axis limits
    padding_factor = 0.1;
    ylim(calculate_limits(scaled_power, padding_factor));
    xlim([time_vector(1) time_vector(end)]);
    
    grid on
    xlabel('Time [s]')
    ylabel(['Power [' power_unit ']'])
    
    % Set title based on number_of_racks
    if number_of_racks == 1
        title_prefix = 'Module';
    else
        title_prefix = 'System';
    end
    title(sprintf('%s Power (Max: %.1f %s, Min: %.1f %s, RMS: %.1f %s)', ...
          title_prefix, scaled_max_power, power_unit, ...
          scaled_min_power, power_unit, scaled_rms_power, power_unit))
    
    set(gca, 'FontName', 'Arial', 'FontSize', 14)
    
    % Save and close
    savefig(fullfile(module_dir, 'power_results.fig'))
    close;
end