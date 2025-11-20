% Feralpi Power Profile Analysis and Visualization
% This script analyzes the power profile and creates visualization plots

% Read power profile data from Excel file
excel_file = 'feralpi.xlsx';
excel_path = fullfile(fileparts(mfilename('fullpath')), excel_file);

try
    % Read the Excel file
    [num_data, txt_data, raw_data] = xlsread(excel_path);
    
    % Extract time and power data
    % Assuming first column is time [s] and second column is power [MW]
    time_raw = num_data(:, 1);  % Time in seconds
    power_raw = num_data(:, 2); % Power in MW
    
    % Remove any NaN values
    valid_indices = ~isnan(time_raw) & ~isnan(power_raw);
    time_raw = time_raw(valid_indices);
    power_raw = power_raw(valid_indices);
    
    % Store original data for plotting
    original_time = time_raw;
    original_power = power_raw;
    
    % Smart analysis: Divide profile into 1-minute sections and select top sections
    fprintf('Analyzing power profile for top sections with highest variance...\n');
    
    % Define 1-minute window (60 seconds)
    window_duration = 60; % seconds
    total_duration = time_raw(end);
    
    % Calculate number of possible 1-minute sections
    num_sections = floor(total_duration / window_duration);
    
    % Ask user for number of sections to select
    fprintf('Profile duration: %.1f s (%.1f minutes)\n', total_duration, total_duration/60);
    fprintf('Number of available 1-minute sections: %d\n', num_sections);
    
    if num_sections < 1
        fprintf('Warning: Profile duration (%.1f s) is less than 1 minute. Using entire profile.\n', total_duration);
        num_top_sections = 1;
    else
        % Prompt user for number of sections to select
        max_sections = min(num_sections, 20); % Limit to reasonable number
        fprintf('\nHow many sections with highest variance do you want to select?\n');
        fprintf('Available range: 1 to %d sections\n', max_sections);
        fprintf('Recommended: 5-10 sections for good coverage\n');
        
        % Use input function for user selection
        while true
            try
                num_top_sections = input(sprintf('Enter number of sections (1-%d): ', max_sections));
                if isscalar(num_top_sections) && num_top_sections >= 1 && num_top_sections <= max_sections
                    break;
                else
                    fprintf('Invalid input. Please enter a number between 1 and %d.\n', max_sections);
                end
            catch
                fprintf('Invalid input. Please enter a number between 1 and %d.\n', max_sections);
            end
        end
        
        fprintf('Selected %d sections for analysis.\n', num_top_sections);
    end
    
    fprintf('Selecting top %d sections with highest variance\n', num_top_sections);
    
    % Analyze each 1-minute section
    section_stats = zeros(num_sections, 3); % [section_number, start_time, std_dev]
    section_data = cell(num_sections, 1); % Store section data for later use
    
    for i = 1:num_sections
        start_time = (i-1) * window_duration;
        end_time = i * window_duration;
        
        % Find indices for this section
        section_indices = time_raw >= start_time & time_raw <= end_time;
        
        if sum(section_indices) > 1 % Need at least 2 points for std calculation
            section_power = power_raw(section_indices);
            section_time = time_raw(section_indices);
            section_std = std(section_power);
            
            section_stats(i, :) = [i, start_time, section_std];
            section_data{i} = struct('time', section_time, 'power', section_power, 'std', section_std);
        else
            section_stats(i, :) = [i, start_time, 0];
            section_data{i} = struct('time', [], 'power', [], 'std', 0);
        end
    end
    
    % Sort sections by standard deviation (variance) in descending order
    [sorted_stds, sort_indices] = sort(section_stats(:, 3), 'descend');
    
    % Select top sections
    top_section_indices = sort_indices(1:num_top_sections);
    
    fprintf('\nSelected top %d sections with highest variance:\n', num_top_sections);
    for i = 1:num_top_sections
        section_idx = top_section_indices(i);
        fprintf('  %d. Section %d (std = %.3f MW)\n', i, section_idx, sorted_stds(i));
    end
    
    % Concatenate the top sections with zero mean
    concatenated_time = [];
    concatenated_power = [];
    current_time_offset = 0;
    selected_segments = []; % Store selected segment info for plotting
    
    for i = 1:num_top_sections
        section_idx = top_section_indices(i);
        section_info = section_data{section_idx};
        
        if ~isempty(section_info.time)
            % Remove mean from this section
            section_power_zero_mean = section_info.power - trapz(section_info.time, section_info.power) / window_duration;
            
            % Adjust time to be continuous
            section_time_adjusted = section_info.time - section_info.time(1) + current_time_offset;
            
            % Concatenate
            concatenated_time = [concatenated_time; section_time_adjusted];
            concatenated_power = [concatenated_power; section_power_zero_mean];
            
            % Store segment info for plotting
            selected_segments = [selected_segments; section_info.time(1), section_info.time(end), section_idx];
            
            % Update time offset for next section
            current_time_offset = concatenated_time(end) + (section_info.time(2) - section_info.time(1));
            
            fprintf('  Added Section %d: %.1f-%.1f s (mean removed, std = %.3f MW)\n', ...
                section_idx, section_info.time(1), section_info.time(end), section_info.std);
        end
    end
    
    % Update the raw data to use the concatenated sections
    time_raw = concatenated_time;
    power_raw = concatenated_power;

    power_raw = power_raw - trapz(time_raw, power_raw) / time_raw(end);
    
    % Convert power from MW to W
    power_raw = power_raw * 1e6; % Convert MW to W

    % Normalize to 15MW peak
    power_raw = power_raw / max(abs(power_raw)) * 15e6; % normalize to 15MW

    fprintf('\nSuccessfully loaded power profile from %s\n', excel_file);
    fprintf('  Concatenated %d sections with highest variance\n', num_top_sections);
    fprintf('  Total duration: %.1f s (%.1f minutes)\n', time_raw(end), time_raw(end)/60);
    fprintf('  Power range: %.1f to %.1f W\n', min(power_raw), max(power_raw));
    fprintf('  Number of data points: %d\n', length(time_raw));
    
    % Create visualization plots
    create_visualization_plots(original_time, original_power, selected_segments, time_raw, power_raw, num_top_sections);
    
catch ME
    fprintf('Error reading Excel file %s: %s\n', excel_file, ME.message);
    fprintf('Falling back to hardcoded profile...\n');
    
    % Fallback to original hardcoded data
    t = [0,10, 25,60,75,85];
    p = [0,0,-8.64,-8.64,0,0];
    p = p - trapz(t, p)/t(end);
    p = p*1e6;
    time_raw = t;
    power_raw = p;
    selected_section = 1;
    max_std = std(p);
end

function create_visualization_plots(original_time, original_power, selected_segments, final_time, final_power, num_sections)
    % Create figure with two subplots
    figure('Position', [100, 100, 1400, 800]);
    
    % Subplot 1: Original profile with selected segments highlighted
    subplot(2,1,1);
    plot(original_time/3600, original_power, 'b-', 'LineWidth', 1.5);
    hold on;
    
    % Highlight selected segments with stars and different colors
    colors = lines(num_sections);
    for i = 1:size(selected_segments, 1)
        start_time = selected_segments(i, 1);
        end_time = selected_segments(i, 2);
        section_num = selected_segments(i, 3);
        
        % Find indices for this segment
        segment_indices = original_time >= start_time & original_time <= end_time;
        
        % Plot segment with different color
        plot(original_time(segment_indices)/3600, original_power(segment_indices), ...
            'Color', colors(i,:), 'LineWidth', 3);
        
        % Add star at beginning of segment
        plot(start_time/3600, original_power(original_time == start_time), ...
            'p', 'MarkerSize', 12, 'MarkerFaceColor', colors(i,:), ...
            'MarkerEdgeColor', 'k', 'LineWidth', 2);
        
        % Add text label
        text(start_time/3600, original_power(original_time == start_time), ...
            sprintf('S%d', section_num), 'FontSize', 10, 'FontWeight', 'bold', ...
            'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom');
    end
    
    xlabel('Time (hours)', 'FontWeight', 'bold');
    ylabel('Power (MW)', 'FontWeight', 'bold');
    title('Original Power Profile with Selected Segments Highlighted', 'FontWeight', 'bold', 'FontSize', 14);
    grid on;
    legend('Original Profile', 'Selected Segments', 'Location', 'best');
    
    % Set proper x and y limits for first subplot
    xlim([0, original_time(end)/3600]);
    y_limits = ylim;
    y_range = y_limits(2) - y_limits(1);
    y_padding = y_range * 0.1;
    ylim([y_limits(1) - y_padding, y_limits(2) + y_padding]);
    
    % Add summary text (positioned to avoid overlap)
    text(0.02, 0.95, sprintf('Selected %d segments with highest variance', num_sections), ...
        'Units', 'normalized', 'FontSize', 10, 'FontWeight', 'bold', ...
        'VerticalAlignment', 'top', 'BackgroundColor', 'white', 'EdgeColor', 'black');
    
    % Subplot 2: Final concatenated profile
    subplot(2,1,2);
    plot(final_time/60, final_power/1e6, 'r-', 'LineWidth', 2);
    xlabel('Time (minutes)', 'FontWeight', 'bold');
    ylabel('Power (MW)', 'FontWeight', 'bold');
    title('Final Concatenated Power Profile (Zero-Mean Sections)', 'FontWeight', 'bold', 'FontSize', 14);
    grid on;
    
    % Set proper x and y limits for second subplot
    xlim([0, final_time(end)/60]);
    y_limits = ylim;
    y_range = y_limits(2) - y_limits(1);
    y_padding = y_range * 0.1;
    ylim([y_limits(1) - y_padding, y_limits(2) + y_padding]);
    
    % Add summary information (positioned to avoid overlap)
    text(0.02, 0.95, sprintf('Duration: %.1f minutes | Peak: %.1f MW | Zero-mean sections', ...
        final_time(end)/60, max(abs(final_power))/1e6), ...
        'Units', 'normalized', 'FontSize', 10, 'FontWeight', 'bold', ...
        'VerticalAlignment', 'top', 'BackgroundColor', 'white', 'EdgeColor', 'black');
    
    % Adjust layout
    sgtitle('Feralpi Power Profile Analysis and Visualization', 'FontWeight', 'bold', 'FontSize', 16);
    
    fprintf('\nVisualization created successfully!\n');
    fprintf('  - Top subplot: Original profile with selected segments highlighted\n');
    fprintf('  - Bottom subplot: Final concatenated profile\n');
end 