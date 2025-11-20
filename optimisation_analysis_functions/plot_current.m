function plot_current(Results, module_dir, number_of_racks)
    % Default value for number_of_racks
    if nargin < 3
        number_of_racks = 1;
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

    % Get current data and time vector
    current_data = Results.Sim_Electrical_Ouput.Cell_Current_A.Data;
    time_vector = Results.Sim_Electrical_Ouput.Cell_Current_A.Time;
    
    % Scale current based on number of racks
    current_data = current_data * number_of_racks;
    
    % Calculate RMS current and find max absolute current
    current_rms = sqrt(trapz(time_vector, current_data.^2) / (time_vector(end) - time_vector(1)));
    [~, max_curr_idx] = max(abs(current_data));
    max_current_abs = abs(current_data(max_curr_idx));
    
    % Create figure
    figure('Position', [100 100 1200 800]);
    
    % Plot current
    plot(time_vector, current_data, 'LineWidth', 1.5)
    hold on
    % Add marker for maximum absolute current
    plot(time_vector(max_curr_idx), current_data(max_curr_idx), 'rx', 'MarkerSize', 10, 'LineWidth', 2)
    hold off
    
    % Set axis limits
    padding_factor = 0.1;
    ylim(calculate_limits(current_data, padding_factor));
    xlim([time_vector(1) time_vector(end)]);
    
    grid on
    xlabel('Time [s]')
    ylabel('Current [A]')
    
    % Set title based on number_of_racks
    if number_of_racks == 1
        title_prefix = 'Module';
    else
        title_prefix = 'System';
    end
    title(sprintf('%s Current (|I|_{max}: %.1f A, I_{RMS}: %.1f A)', ...
          title_prefix, max_current_abs, current_rms))
    
    set(gca, 'FontName', 'Arial', 'FontSize', 14)
    
    % Save and close
    savefig(fullfile(module_dir, 'current_results.fig'))
    close;
end