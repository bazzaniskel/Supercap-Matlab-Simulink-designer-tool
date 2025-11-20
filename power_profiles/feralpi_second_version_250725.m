% turbine_load1 - Custom power profile definition
% This file should be placed in the power_profiles folder
% The variable name must match the filename with a _pp suffix (without .m extension)

% Define the turbine load function (if using turbine-based profile)

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

    % Define 10-minute window (60 seconds)
    window_duration = 2*60; % seconds
    
    % Smart analysis: Divide profile into 1-minute sections and select the best one
    fprintf('Analyzing power profile for optimal %.1f-minute section...\n', window_duration/60);
    

    total_duration = time_raw(end);
    
    % Calculate number of possible 10-minute sections
    num_sections = floor(total_duration / window_duration);
    
    if num_sections < 1
        fprintf('Warning: Profile duration (%.1f s) is less than %.1f minutes. Using entire profile.\n', total_duration, window_duration/60);
        time = time_raw;
        power = power_raw;
        selected_section = 1;
        section_std = std(power_raw);
    else
        fprintf('Profile duration: %.1f s (%.1f minutes)\n', total_duration, total_duration/60);
        fprintf('Number of %.1f-minute sections: %d\n', window_duration/60, num_sections);
        
        % Analyze each %.1f-minute section  
        section_stats = zeros(num_sections, 3); % [section_number, start_time, std_dev]
        
        for i = 1:num_sections
            start_time = (i-1) * window_duration;
            end_time = i * window_duration;
            
            % Find indices for this section
            section_indices = time_raw >= start_time & time_raw <= end_time;
            
            if sum(section_indices) > 1 % Need at least 2 points for std calculation
                section_power = power_raw(section_indices);
                section_std = std(section_power);
                
                section_stats(i, :) = [i, start_time, section_std];
            else
                section_stats(i, :) = [i, start_time, 0];
                fprintf('  Section %d (%.1f-%.1f s): insufficient data\n', ...
                    i, start_time, end_time);
            end
        end
        
        % Find section with highest standard deviation
        [max_std, best_section_idx] = max(section_stats(:, 3));
        selected_section = section_stats(best_section_idx, 1);
        start_time = section_stats(best_section_idx, 2);
        end_time = start_time + window_duration;
        
        % Extract the best section
        section_indices = time_raw >= start_time & time_raw <= end_time;
        time = time_raw(section_indices);
        power = power_raw(section_indices);
        
        fprintf('\nSelected Section %d (%.1f-%.1f s) with highest std deviation: %.3f MW\n', ...
            selected_section, start_time, end_time, max_std);
    end
    
    % Update the raw data to use the selected section
    time_raw = time;
    power_raw = power;

    % Convert power from MW to W
    power_raw = power_raw * 1e6; % Convert MW to W

    % Make power profile zero-mean (remove DC component)
    power_raw = power_raw - trapz(time_raw, power_raw) / window_duration;

    power_raw = power_raw / max(abs(power_raw)) * 15e6; % normalize to 15MW

    fprintf('Successfully loaded power profile from %s\n', excel_file);
    fprintf('  Selected section: %d (%.1f-%.1f s)\n', selected_section, time_raw(1), time_raw(end));
    fprintf('  Power range: %.1f to %.1f W\n', min(power_raw), max(power_raw));
    fprintf('  Number of data points: %d\n', length(time_raw));
    fprintf('  Section std deviation: %.3f MW\n', max_std);
    
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

% Create the power profile structure
feralpi_second_version_250725_pp = struct();

% Basic information
feralpi_second_version_250725_pp.name = 'Feralpi Power Profile';
feralpi_second_version_250725_pp.description = 'Power profile loaded from feralpi.xlsx Excel file';

dt = time_raw(2) - time_raw(1);
time_raw = 0:dt:window_duration;

% Time vector definition - use the data from Excel
feralpi_second_version_250725_pp.time_data = time_raw;

% Power data from Excel
feralpi_second_version_250725_pp.power_data = power_raw;

% Calculated parameters
feralpi_second_version_250725_pp.max_power = max(abs(feralpi_second_version_250725_pp.power_data));
feralpi_second_version_250725_pp.duration = feralpi_second_version_250725_pp.time_data(end);
feralpi_second_version_250725_pp.time_step = feralpi_second_version_250725_pp.time_data(2) - feralpi_second_version_250725_pp.time_data(1);

% Profile type and units
feralpi_second_version_250725_pp.Switch_CurrentOrPower = -1; % -1 = power profile, 1 = current profile
feralpi_second_version_250725_pp.units = 'W';

% Optional: Add additional metadata
feralpi_second_version_250725_pp.created_by = 'Excel Import';
feralpi_second_version_250725_pp.creation_date = datestr(now);
feralpi_second_version_250725_pp.notes = sprintf('Power profile imported from %s (Time: %.1f-%.1f s, Power: %.1f-%.1f W)', ...
    excel_file, time_raw(1), time_raw(end), min(power_raw), max(power_raw));