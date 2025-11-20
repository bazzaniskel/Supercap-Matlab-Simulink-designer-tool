%% CONTAINERIZED SOLUTION DESIGNER
% Interactive tool to optimize placement of cabinets and power electronics
% in 20ft or 40ft shipping containers for supercapacitor systems

clear; clc; close all;

fprintf('===============================================================\n');
fprintf('             CONTAINERIZED SOLUTION DESIGNER                  \n');
fprintf('===============================================================\n\n');

%% SYSTEM INPUTS
fprintf('--- SYSTEM REQUIREMENTS ---\n');

system_max_current = get_valid_input('Maximum system current [A]: ', @(x) x > 0);
min_cabinets_system = get_valid_input('Minimum number of cabinets at system level: ', @(x) x > 0 && x == round(x));

fprintf('\n--- CONTAINER CONFIGURATION ---\n');

% Container door width (only on one side)
default_door_width = 0.8; % 80cm default
door_width = get_valid_input(sprintf('Container door width [m] (default %.1f m): ', default_door_width), ...
    @(x) x > 0 && x <= 2.44, default_door_width);

%% CONTAINER TYPE SELECTION
fprintf('\n--- CONTAINER TYPE ---\n');
fprintf('1. 20ft container (5.898m × 2.352m)\n');
fprintf('2. 40ft container (12.032m × 2.352m)\n');

container_choice = get_valid_input('Select container type (1-2): ', @(x) x == 1 || x == 2);

if container_choice == 1
    container = struct('name', '20ft', 'length_m', 5.898, 'width_m', 2.352);
else
    container = struct('name', '40ft', 'length_m', 12.032, 'width_m', 2.352);
end

fprintf('Selected: %s container\n', container.name);

% Required free space (aisle/clearance) in front of equipment
default_front_clearance = 1.0;
front_clearance_m = get_valid_input(sprintf('Required free space in front of equipment [m] (default %.1f m): ', default_front_clearance), ...
    @(x) x >= 0 && x <= container.width_m, default_front_clearance);

%% GET AVAILABLE POWER ELECTRONICS
fprintf('\n--- POWER ELECTRONICS SELECTION ---\n');
power_electronics = get_available_power_electronics();

fprintf('\nAvailable power electronics:\n');
for i = 1:length(power_electronics)
    pe = power_electronics(i);
    fprintf('%d. %s - Max Current: %.0f A, Size: %.2f×%.2f m, Rack Mounted: %s\n', ...
        i, pe.name, pe.max_current_A, pe.width_m, pe.length_m, ...
        conditional_string(pe.is_rack_mounted, 'Yes', 'No'));
end

pe_choice = get_valid_input(sprintf('Select power electronics (1-%d): ', length(power_electronics)), ...
    @(x) x >= 1 && x <= length(power_electronics));

selected_pe = power_electronics(pe_choice);
fprintf('Selected: %s\n', selected_pe.name);

%% GET AVAILABLE CABINETS
fprintf('\n--- CABINET SELECTION ---\n');
cabinets = get_available_cabinets();

fprintf('\nAvailable cabinets:\n');
for i = 1:length(cabinets)
    cab = cabinets(i);
    fprintf('%d. %s - Size: %.2f×%.2f m\n', ...
        i, cab.name, cab.width_m, cab.length_m);
end

cabinet_choice = get_valid_input(sprintf('Select cabinet type (1-%d): ', length(cabinets)), ...
    @(x) x >= 1 && x <= length(cabinets));

selected_cabinet = cabinets(cabinet_choice);
fprintf('Selected: %s\n', selected_cabinet.name);

%% DESIGN OPTIMIZATION
fprintf('\n===============================================================\n');
fprintf('                    OPTIMIZING DESIGN                         \n');
fprintf('===============================================================\n');

% HVAC space allocation (1m × full width)
hvac_length = 1.5;
hvac_width = container.width_m;

% Calculate available space (door is only on one side)
available_length = container.length_m - hvac_length;
available_width = container.width_m;

fprintf('Container dimensions: %.3f m × %.3f m\n', container.length_m, container.width_m);
fprintf('HVAC space: %.3f m × %.3f m\n', hvac_length, hvac_width);
fprintf('Door width: %.3f m (one side only)\n', door_width);
fprintf('Available space: %.3f m × %.3f m\n', available_length, available_width);

% Soft pre-check: if PE doesn't fit half width, allow deeper with warning; final decision inside design_* functions
if selected_pe.length_m > available_length
    fprintf('\n✗ ERROR: PE too long for container length (%.3fm > %.3fm).\n', selected_pe.length_m, available_length);
    return;
end
if selected_pe.width_m > available_width/2
    fprintf('Warning: PE width %.3fm exceeds half-row width %.3fm. Will try rotation, aisle adjustment, or single-row fallback.\n', ...
        selected_pe.width_m, available_width/2);
end

% Design based on power electronics type
if selected_pe.is_rack_mounted
    design_result = design_rack_mounted_container(container, selected_pe, selected_cabinet, ...
        available_length, available_width, system_max_current, min_cabinets_system, door_width, front_clearance_m);
else
    design_result = design_skid_mounted_container(container, selected_pe, selected_cabinet, ...
        available_length, available_width, system_max_current, min_cabinets_system, door_width, front_clearance_m);
end

if ~design_result.success
    fprintf('\n✗ DESIGN FAILED: %s\n', design_result.error_message);
    return;
end

%% DISPLAY RESULTS
fprintf('\n===============================================================\n');
fprintf('                    DESIGN RESULTS                            \n');
fprintf('===============================================================\n');

fprintf('\nOPTIMIZED SOLUTION:\n');
fprintf('  Container Type: %s\n', container.name);
fprintf('  Power Electronics: %s (%s)\n', selected_pe.name, ...
    conditional_string(selected_pe.is_rack_mounted, 'Rack Mounted', 'Skid Mounted'));
fprintf('  Cabinet Type: %s\n', selected_cabinet.name);

fprintf('\nCONTAINER LAYOUT:\n');
fprintf('  Number of Containers: %d\n', design_result.num_containers);
fprintf('  Cabinets per Container: %d\n', design_result.cabinets_per_container);
fprintf('  Power Electronics per Container: %d\n', design_result.pe_per_container);
fprintf('  Total System Cabinets: %d\n', design_result.total_cabinets);
fprintf('  Total Power Electronics: %d\n', design_result.total_pe);

fprintf('\nLAYOUT DETAILS:\n');
fprintf('  Row 1 (Top): %d PE + %d Cabinets\n', design_result.row1.pe_count, design_result.row1.cabinet_count);
fprintf('  Row 2 (Bottom): %d PE + %d Cabinets%s\n', design_result.row2.pe_count, design_result.row2.cabinet_count, ...
    conditional_string(design_result.row2.has_door, ' + Door', ''));

fprintf('\nCURRENT ANALYSIS:\n');
fprintf('  System Max Current: %.0f A\n', system_max_current);
fprintf('  Current per Cabinet: %.1f A\n', design_result.current_per_cabinet);
fprintf('  Current per PE Unit: %.0f A\n', selected_pe.max_current_A);
fprintf('  Container Current Capacity: %.0f A\n', design_result.container_current_capacity);
fprintf('  Container Current Utilization: %.1f%%\n', ...
    (design_result.cabinets_per_container * design_result.current_per_cabinet) / design_result.container_current_capacity * 100);

fprintf('\nSPACE UTILIZATION:\n');
fprintf('  Row 1 Length Utilization: %.1f%% (%.3f m used of %.3f m)\n', ...
    design_result.row1.length_utilization, design_result.row1.used_length, design_result.row1.available_length);
fprintf('  Row 2 Length Utilization: %.1f%% (%.3f m used of %.3f m)\n', ...
    design_result.row2.length_utilization, design_result.row2.used_length, design_result.row2.available_length);

fprintf('\nDESIGN VERIFICATION:\n');
fprintf('  Min Cabinets Requirement: %s (%d >= %d)\n', ...
    conditional_string(design_result.total_cabinets >= min_cabinets_system, '✓ PASS', '✗ FAIL'), ...
    design_result.total_cabinets, min_cabinets_system);
fprintf('  Current Capacity: %s (%.0f A >= %.0f A)\n', ...
    conditional_string(design_result.total_current_capacity >= system_max_current, '✓ PASS', '✗ FAIL'), ...
    design_result.total_current_capacity, system_max_current);

%% GENERATE VISUALIZATION AND SAVE RESULTS
fprintf('\n===============================================================\n');
fprintf('                    GENERATING RESULTS                        \n');
fprintf('===============================================================\n');

% Create results folder with timestamp
timestamp = datestr(now, 'yyyymmdd_HHMMSS');
subfolder_name = sprintf('%s_Container_%s_%s_%.0fA_%dCAB_%dPE', ...
    timestamp, ...
    container.name, ...
    strrep(selected_pe.name, ' ', '_'), ...
    system_max_current, ...
    design_result.total_cabinets, ...
    design_result.total_pe);

% Clean up folder name
subfolder_name = strrep(subfolder_name, '.', 'p');
subfolder_name = strrep(subfolder_name, '-', 'm');

% Create main results folder if it doesn't exist
if ~exist('results', 'dir')
    mkdir('results');
end

% Create results folder
results_folder = fullfile('results', subfolder_name);
if ~exist(results_folder, 'dir')
    mkdir(results_folder);
end

% Generate visualization
fig_handle = visualize_container_design(design_result, container, selected_pe, selected_cabinet, ...
    hvac_length, hvac_width, door_width);

% Save figure
saveas(fig_handle, fullfile(results_folder, 'container_layout.png'));
savefig(fig_handle, fullfile(results_folder, 'container_layout.fig'));
close(fig_handle);

% Save results
save_container_design(design_result, container, selected_pe, selected_cabinet, ...
    system_max_current, min_cabinets_system, door_width, results_folder);

fprintf('\n===============================================================\n');
fprintf('                    DESIGN COMPLETE                           \n');
fprintf('===============================================================\n');
fprintf('Results saved to: %s\n', results_folder);

%% ===================================================================
%% FIXED FUNCTION DEFINITIONS
%% ===================================================================

function power_electronics = get_available_power_electronics()
    % Database of available power electronics devices
    %struct('name', 'SMA SUNNY CENTRAL 4000 UP-US', 'max_current_A', 4750, 'width_m',1.588, 'length_m', 2.78, 'is_rack_mounted', false);
    power_electronics = [
        struct('name', 'Freqcon 1500A', 'max_current_A', 1500, 'width_m', 0.6, 'length_m', 3.39, 'is_rack_mounted', true);
        struct('name', 'SMA SUNNY CENTRAL 4000 UP-US', 'max_current_A', 4750, 'width_m',1.588, 'length_m', 2.78, 'is_rack_mounted', true);
    ];
end

function cabinets = get_available_cabinets()
    % Database of available cabinet types
    
    cabinets = [
        struct('name', 'Skelgrid 2.0', 'width_m', 0.6, 'length_m', 0.6);
    ];
end

function design_result = design_rack_mounted_container(container, selected_pe, selected_cabinet, ...
    available_length, available_width, system_max_current, min_cabinets_system, door_width, front_clearance_m)
    
    walls_thickness = 0.2;
    
    design_result = struct();
    design_result.success = false;
    
    % Row dimensions
    row_width = available_width / 2;
    row1_length = available_length - walls_thickness*2;  % Top row has full length
    row2_length = available_length - door_width - walls_thickness*2;  % Bottom row reduced by door

    % Depth allowances with front clearance (aisle)
    two_row_depth = max(0, row_width - front_clearance_m);
    single_row_depth = max(0, container.width_m - front_clearance_m);

    % Consider PE rotation
    pe_orients = [struct('len_x', selected_pe.length_m, 'depth', selected_pe.width_m), ...
                  struct('len_x', selected_pe.width_m, 'depth', selected_pe.length_m)];

    % Try to keep two-row layout if PE depth fits with clearance in half-width
    fits_two_row = [pe_orients(1).depth <= two_row_depth, pe_orients(2).depth <= two_row_depth];
    [~, chosen_orient] = max(fits_two_row); % pick an orient that fits; if none, choose 1
    achieved_clearance = front_clearance_m;
    two_row_forced = false;
    if ~any(fits_two_row)
        % Check if we can still do two rows with reduced clearance (warn user)
        % Achieved clearance is row_width - PE depth (using best orientation)
        [min_depth, best_k] = min([pe_orients(1).depth, pe_orients(2).depth]);
        if min_depth < row_width && pe_orients(best_k).len_x <= max(row1_length, row2_length)
            % We can place PE in one row and keep the other row shallower
            chosen_orient = best_k;
            use_single_row = false;
            achieved_clearance = max(0, row_width - min_depth);
            two_row_forced = true;
            fprintf('Warning: Requested clearance %.2fm not achievable. Achieved clearance: %.2fm. Using two rows (one shallower).\n', front_clearance_m, achieved_clearance);
        else
            % Fallback to single-row layout using full width with clearance
            fits_single_row = [pe_orients(1).depth <= single_row_depth, pe_orients(2).depth <= single_row_depth];
            if ~any(fits_single_row)
                design_result.error_message = sprintf(['PE too deep even with rotation and clearance (%.2fm). ', ...
                    'PE: %.3f×%.3f m, Container width: %.3f m'], front_clearance_m, selected_pe.width_m, selected_pe.length_m, container.width_m);
                return;
            end
            [~, chosen_orient] = max(fits_single_row);
            use_single_row = true;
            fprintf('Warning: Two-row placement infeasible with %.2fm clearance. Using single-row layout.\n', front_clearance_m);
        end
    else
        use_single_row = false;
    end

    pe_len_x = pe_orients(chosen_orient).len_x;
    pe_depth_y = pe_orients(chosen_orient).depth;

    % Adjust cabinet depth allowances based on achieved clearance when forcing two rows
    if two_row_forced
        two_row_depth = max(0, row_width - achieved_clearance);
    end
    
    % Try different configurations to minimize containers
    min_containers = inf;
    best_config = struct();
    
    % Test different numbers of PE per container
    for total_pe = 1:10  % Reasonable upper limit
        
        container_current_capacity = total_pe * selected_pe.max_current_A;
        current_per_cabinet = system_max_current / min_cabinets_system;
        max_cabinets_by_current = floor(container_current_capacity / current_per_cabinet);
        
        if max_cabinets_by_current <= 0
            continue;
        end
        
        % Try different PE distributions between rows
        best_cabinets = -inf;
        best_layout = struct();
        
        for pe_row1 = 0:total_pe
            pe_row2 = total_pe - pe_row1;
            
            % Check if PE fit in their respective rows (using chosen orientation)
            if use_single_row
                % Place all PE in the longer available row
                % Feasibility checked above; just ensure aggregate length fits
                if pe_row1 > 0 && pe_row2 > 0
                    continue; % single-row layout cannot split PE across rows
                end
            else
                if pe_row1 * pe_len_x > row1_length || pe_row2 * pe_len_x > row2_length
                    continue;
                end
            end
            
            % Calculate remaining space for cabinets
            remaining_row1 = row1_length - pe_row1 * pe_len_x;
            remaining_row2 = row2_length - pe_row2 * pe_len_x;
            
            % Max cabinets that fit physically (respect depth with clearance)
            cab_depth_two_row = two_row_depth;           % use (possibly reduced) achieved two-row depth
            cab_depth_single_row = single_row_depth;     % full width with clearance for single-row
            if use_single_row
                % Only one row used
                if remaining_row1 >= remaining_row2
                    max_cab_row1 = (selected_cabinet.width_m <= cab_depth_single_row) * floor(remaining_row1 / selected_cabinet.length_m);
                    max_cab_row2 = 0;
                else
                    max_cab_row1 = 0;
                    max_cab_row2 = (selected_cabinet.width_m <= cab_depth_single_row) * floor(remaining_row2 / selected_cabinet.length_m);
                end
            else
                max_cab_row1 = (selected_cabinet.width_m <= cab_depth_two_row) * floor(remaining_row1 / selected_cabinet.length_m);
                max_cab_row2 = (selected_cabinet.width_m <= cab_depth_two_row) * floor(remaining_row2 / selected_cabinet.length_m);
            end
            max_cabinets_physical = max_cab_row1 + max_cab_row2;
            
            % Total cabinets limited by both current and space
            total_cabinets = min(max_cabinets_by_current, max_cabinets_physical);
            
            % Skip only if truly infeasible
            if total_cabinets < 0
                continue;
            end
            
            if total_cabinets > best_cabinets
                best_cabinets = total_cabinets;
                
                % Distribute cabinets between rows optimally
                cab_row1 = min(max_cab_row1, max(0,total_cabinets));
                cab_row2 = max(0,total_cabinets) - cab_row1;
                
                % Adjust if row2 can't fit all remaining cabinets
                if cab_row2 > max_cab_row2
                    cab_row2 = max_cab_row2;
                    cab_row1 = max(0,total_cabinets) - cab_row2;
                end
                
                best_layout.total_pe = total_pe;
                best_layout.total_cabinets = max(0,total_cabinets);
                best_layout.container_current_capacity = container_current_capacity;
                best_layout.row1 = struct('pe_count', pe_row1, 'cabinet_count', cab_row1, ...
                    'available_length', row1_length, 'used_length', pe_row1 * pe_len_x + cab_row1 * selected_cabinet.length_m, ...
                    'has_door', false);
                best_layout.row2 = struct('pe_count', pe_row2, 'cabinet_count', cab_row2, ...
                    'available_length', row2_length, 'used_length', pe_row2 * pe_len_x + cab_row2 * selected_cabinet.length_m, ...
                    'has_door', true);
            end
        end
        
        if best_cabinets > 0
            num_containers = ceil(min_cabinets_system / best_cabinets);
            
            if num_containers < min_containers
                min_containers = num_containers;
                best_config = best_layout;
                best_config.num_containers = num_containers;
            end
        end
    end
    
    if min_containers == inf || best_config.total_cabinets <= 0
        design_result.error_message = sprintf(['No valid configuration found with requested clearance %.2fm. ', ...
            'Try reducing clearance or increasing PE count. Achieved two-row clearance considered if possible.'], front_clearance_m);
        return;
    end
    
    % Finalize design
    design_result.success = true;
    design_result.num_containers = best_config.num_containers;
    design_result.cabinets_per_container = best_config.total_cabinets;
    design_result.pe_per_container = best_config.total_pe;
    design_result.container_current_capacity = best_config.container_current_capacity;
    design_result.current_per_cabinet = system_max_current / min_cabinets_system;
    
    design_result.total_cabinets = design_result.num_containers * design_result.cabinets_per_container;
    design_result.total_pe = design_result.num_containers * design_result.pe_per_container;
    design_result.total_current_capacity = design_result.num_containers * design_result.container_current_capacity;
    
    % Detailed row information
    design_result.row1 = best_config.row1;
    design_result.row2 = best_config.row2;
    
    % Calculate utilizations
    design_result.row1.length_utilization = (design_result.row1.used_length / design_result.row1.available_length) * 100;
    design_result.row2.length_utilization = (design_result.row2.used_length / design_result.row2.available_length) * 100;
    
    design_result.layout_type = 'rack_mounted';
    design_result.row_width = row_width;
    design_result.achieved_clearance = achieved_clearance;
end

function design_result = design_skid_mounted_container(container, selected_pe, selected_cabinet, ...
    available_length, available_width, system_max_current, min_cabinets_system, door_width, front_clearance_m)
    
    walls_thickness = 0.2; % 20 cm doors, more than enough 
    
    design_result = struct();
    design_result.success = false;
    
    % Row dimensions
    row_width = available_width / 2;
    row1_length = available_length - walls_thickness*2;  % Top row has full length
    row2_length = available_length - door_width - walls_thickness*2;  % Bottom row reduced by door
    
    % Effective depths allowing for aisle/clearance
    two_row_depth = max(0, row_width - front_clearance_m);
    single_row_depth = max(0, container.width_m - front_clearance_m);
    
    % Orientation options: [length_along_x, depth_along_y]
    pe_orients = [struct('len_x', selected_pe.length_m, 'depth', selected_pe.width_m), ...
                  struct('len_x', selected_pe.width_m, 'depth', selected_pe.length_m)];
    
    % Feasibility per row with two-row layout (equipment depth must fit in half-width aisle scheme)
    fit_row1 = [ (pe_orients(1).depth <= two_row_depth) && (pe_orients(1).len_x <= row1_length), ...
                 (pe_orients(2).depth <= two_row_depth) && (pe_orients(2).len_x <= row1_length) ];
    fit_row2 = [ (pe_orients(1).depth <= two_row_depth) && (pe_orients(1).len_x <= row2_length), ...
                 (pe_orients(2).depth <= two_row_depth) && (pe_orients(2).len_x <= row2_length) ];
    
    % Single-row fallback feasibility (use full container width with aisle)
    fit_single_row1 = [ (pe_orients(1).depth <= single_row_depth) && (pe_orients(1).len_x <= row1_length), ...
                        (pe_orients(2).depth <= single_row_depth) && (pe_orients(2).len_x <= row1_length) ];
    fit_single_row2 = [ (pe_orients(1).depth <= single_row_depth) && (pe_orients(1).len_x <= row2_length), ...
                        (pe_orients(2).depth <= single_row_depth) && (pe_orients(2).len_x <= row2_length) ];
    
    % Choose placement strategy
    chosen_row = 0; % 1 or 2
    chosen_orient = 0; % 1 or 2
    use_single_row = false;
    
    % Prefer two-row if possible, maximizing remaining length
    best_remaining = -inf;
    for k = 1:2
        if fit_row1(k)
            rem = row1_length - pe_orients(k).len_x;
            if rem > best_remaining
                best_remaining = rem; chosen_row = 1; chosen_orient = k; use_single_row = false; 
            end
        end
        if fit_row2(k)
            rem = row2_length - pe_orients(k).len_x;
            if rem > best_remaining
                best_remaining = rem; chosen_row = 2; chosen_orient = k; use_single_row = false; 
            end
        end
    end
    
    % If two-row impossible, try single-row (prefer the longer row)
    if chosen_row == 0
        best_remaining = -inf;
        for k = 1:2
            if fit_single_row1(k)
                rem = row1_length - pe_orients(k).len_x;
                if rem > best_remaining
                    best_remaining = rem; chosen_row = 1; chosen_orient = k; use_single_row = true;
                end
            end
            if fit_single_row2(k)
                rem = row2_length - pe_orients(k).len_x;
                if rem > best_remaining
                    best_remaining = rem; chosen_row = 2; chosen_orient = k; use_single_row = true;
                end
            end
        end
    end
    
    if chosen_row == 0
        design_result.error_message = sprintf(['Selected power electronics too large even with rotation and aisle of %.2fm.\n' ...
            'PE dimensions: %.3f m × %.3f m. Container width: %.3f m'], ...
            front_clearance_m, selected_pe.width_m, selected_pe.length_m, container.width_m);
        return;
    end
    
    % Final chosen PE footprint
    pe_len_x = pe_orients(chosen_orient).len_x;
    pe_depth_y = pe_orients(chosen_orient).depth;
    
    % Cabinet depth constraint based on chosen layout
    cab_depth_two_row = two_row_depth;
    cab_depth_single_row = single_row_depth;
    
    % For skid-mounted, typically 1 PE per container
    pe_per_container = 1;
    container_current_capacity = pe_per_container * selected_pe.max_current_A;
    current_per_cabinet = system_max_current / min_cabinets_system;
    max_cabinets_by_current = floor(container_current_capacity / current_per_cabinet);
    
    % Determine optimal skid placement and cabinets distribution
    if chosen_row == 1
        remaining_row1 = row1_length - pe_len_x;
        remaining_row2 = row2_length;
        
        % Cabinet depth feasibility per row
        max_cab_row1 = ( (selected_cabinet.width_m <= (use_single_row && true)*cab_depth_single_row + (~use_single_row)*cab_depth_two_row) ) ...
                        * floor(remaining_row1 / selected_cabinet.length_m);
        max_cab_row2 = ( (selected_cabinet.width_m <= (use_single_row && false)*cab_depth_single_row + cab_depth_two_row) ) ...
                        * floor(remaining_row2 / selected_cabinet.length_m);
        if use_single_row
            % Single-row: restrict cabinets to chosen row only
            max_cab_row2 = 0;
        end
        max_cabinets_physical = max_cab_row1 + max_cab_row2;
        
        % First, compute the maximum allowed by current and space
        cabinets_per_container_max = min(max_cabinets_by_current, max_cabinets_physical);
        
        % Then, cap to only what is needed to meet the system requirement across containers
        num_containers_tmp = max(1, ceil(min_cabinets_system / max(1, cabinets_per_container_max)));
        cabinets_per_container = min(cabinets_per_container_max, ceil(min_cabinets_system / num_containers_tmp));
        
        if cabinets_per_container <= 0
            design_result.error_message = 'No space for required cabinets';
            return;
        end
        
        % Distribute cabinets optimally
        cab_row1 = min(max_cab_row1, cabinets_per_container);
        cab_row2 = cabinets_per_container - cab_row1;
        if cab_row2 > max_cab_row2
            cab_row2 = max_cab_row2; cab_row1 = cabinets_per_container - cab_row2;
        end
        
        row1_config = struct('pe_count', 1, 'cabinet_count', cab_row1, ...
            'available_length', row1_length, 'used_length', pe_len_x + cab_row1 * selected_cabinet.length_m, ...
            'has_door', false);
        row2_config = struct('pe_count', 0, 'cabinet_count', cab_row2, ...
            'available_length', row2_length, 'used_length', cab_row2 * selected_cabinet.length_m, ...
            'has_door', true);
        
    else
        % chosen_row == 2
        remaining_row1 = row1_length;
        remaining_row2 = row2_length - pe_len_x;
        
        % Cabinet depth feasibility per row
        max_cab_row1 = (selected_cabinet.width_m <= (use_single_row && false)*cab_depth_single_row + cab_depth_two_row) ...
                        * floor(remaining_row1 / selected_cabinet.length_m);
        max_cab_row2 = (selected_cabinet.width_m <= (use_single_row && true)*cab_depth_single_row + (~use_single_row)*cab_depth_two_row) ...
                        * floor(remaining_row2 / selected_cabinet.length_m);
        if use_single_row
            % Single-row: restrict cabinets to chosen row only
            max_cab_row1 = 0;
        end
        max_cabinets_physical = max_cab_row1 + max_cab_row2;
        
        % First, compute the maximum allowed by current and space
        cabinets_per_container_max = min(max_cabinets_by_current, max_cabinets_physical);
        
        % Then, cap to only what is needed to meet the system requirement across containers
        num_containers_tmp = max(1, ceil(min_cabinets_system / max(1, cabinets_per_container_max)));
        cabinets_per_container = min(cabinets_per_container_max, ceil(min_cabinets_system / num_containers_tmp));
        
        if cabinets_per_container <= 0
            design_result.error_message = 'No space for required cabinets';
            return;
        end
        
        % Distribute cabinets optimally
        cab_row1 = min(max_cab_row1, cabinets_per_container);
        cab_row2 = cabinets_per_container - cab_row1;
        if cab_row2 > max_cab_row2
            cab_row2 = max_cab_row2; cab_row1 = cabinets_per_container - cab_row2;
        end
        
        row1_config = struct('pe_count', 0, 'cabinet_count', cab_row1, ...
            'available_length', row1_length, 'used_length', cab_row1 * selected_cabinet.length_m, ...
            'has_door', false);
        row2_config = struct('pe_count', 1, 'cabinet_count', cab_row2, ...
            'available_length', row2_length, 'used_length', pe_len_x + cab_row2 * selected_cabinet.length_m, ...
            'has_door', true);
    end
    
    % Calculate number of containers needed
    num_containers = ceil(min_cabinets_system / cabinets_per_container);
    
    % Finalize design
    design_result.success = true;
    design_result.num_containers = num_containers;
    design_result.cabinets_per_container = cabinets_per_container;
    design_result.pe_per_container = pe_per_container;
    design_result.container_current_capacity = container_current_capacity;
    design_result.current_per_cabinet = current_per_cabinet;
    
    design_result.total_cabinets = design_result.num_containers * design_result.cabinets_per_container;
    design_result.total_pe = design_result.num_containers * design_result.pe_per_container;
    design_result.total_current_capacity = design_result.num_containers * design_result.container_current_capacity;
    
    % Detailed row information
    design_result.row1 = row1_config;
    design_result.row2 = row2_config;
    
    % Store PE footprint/orientation for drawing
    design_result.pe_len_x = pe_len_x;
    design_result.pe_depth_y = pe_depth_y;
    design_result.pe_row = chosen_row;
    design_result.row_width = row_width;
    design_result.front_clearance_m = front_clearance_m;
    design_result.layout_type = 'skid_mounted';
end

function fig_handle = visualize_container_design(design_result, container, selected_pe, selected_cabinet, ...
    hvac_length, hvac_width, door_width)
    
    % COMPLETELY REDESIGNED: Fixed visualization with proper alignment and legend placement
    
    fig_handle = figure('Position', [100, 100, 1600, 800]);
    
    % Create main plot area (leave space for legend on right)
    subplot('Position', [0.05, 0.1, 0.7, 0.8]);
    
    % Container outline
    rectangle('Position', [0, 0, container.length_m, container.width_m], ...
        'EdgeColor', 'k', 'LineWidth', 3);
    hold on;
    
    % HVAC space (at the front of container)
    rectangle('Position', [0, 0, hvac_length, container.width_m], ...
        'FaceColor', [0.8, 0.8, 1.0], 'EdgeColor', 'b', 'LineWidth', 2);
    text(hvac_length/2, container.width_m/2, 'HVAC', 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
    
    % Door clearance (affects bottom row only)
    door_x = container.length_m - door_width;
    door_y = 0;
    door_height = container.width_m / 2;
    rectangle('Position', [door_x, door_y, door_width, door_height], ...
        'FaceColor', [1.0, 1.0, 0.8], 'EdgeColor', 'red', 'LineWidth', 2);
    text(door_x + door_width/2, door_height/2, 'DOOR', 'HorizontalAlignment', 'center', ...
        'FontWeight', 'bold', 'FontSize', 10, 'Rotation', 90);
    
    % Row separation line
    row_separation_y = container.width_m / 2;
    plot([hvac_length, container.length_m], [row_separation_y, row_separation_y], 'k--', 'LineWidth', 2);
    
    % Equipment start position
    equipment_start_x = hvac_length;
    
    % ROW 1 (Top row: y = row_separation_y to container.width_m)
    row1_y_start = row_separation_y;
    row1_y_center = row1_y_start + design_result.row_width / 2;
    current_x_row1 = equipment_start_x;
    
    % Place PE in row 1
    for i = 1:design_result.row1.pe_count
        pe_y = container.width_m - design_result.pe_depth_y;  % Back against top wall
        rectangle('Position', [current_x_row1, pe_y, design_result.pe_len_x, design_result.pe_depth_y], ...
            'FaceColor', [1.0, 0.7, 0.7], 'EdgeColor', 'r', 'LineWidth', 2);
                 text(current_x_row1 + design_result.pe_len_x/2, pe_y + design_result.pe_depth_y/2, 'PE', ...
            'HorizontalAlignment', 'center', 'FontSize', 12, 'FontWeight', 'bold');
        current_x_row1 = current_x_row1 + selected_pe.length_m;
    end
    
    % Place cabinets in row 1
    for i = 1:design_result.row1.cabinet_count
        cab_y = container.width_m - selected_cabinet.width_m;  % Back against top wall
        rectangle('Position', [current_x_row1, cab_y, selected_cabinet.length_m, selected_cabinet.width_m], ...
            'FaceColor', [0.7, 1.0, 0.7], 'EdgeColor', 'g', 'LineWidth', 2);
        text(current_x_row1 + selected_cabinet.length_m/2, cab_y + selected_cabinet.width_m/2, 'CAB', ...
            'HorizontalAlignment', 'center', 'FontSize', 10, 'FontWeight', 'bold');
        current_x_row1 = current_x_row1 + selected_cabinet.length_m;
    end
    
    % ROW 2 (Bottom row: y = 0 to row_separation_y)
    row2_y_start = 0;
    row2_y_center = row2_y_start + design_result.row_width / 2;
    current_x_row2 = equipment_start_x;
    
    % Place PE in row 2
    for i = 1:design_result.row2.pe_count
        pe_y = 0;  % Back against bottom wall
        rectangle('Position', [current_x_row2, pe_y, design_result.pe_len_x, design_result.pe_depth_y], ...
            'FaceColor', [1.0, 0.7, 0.7], 'EdgeColor', 'r', 'LineWidth', 2);
                 text(current_x_row2 + design_result.pe_len_x/2, pe_y + design_result.pe_depth_y/2, 'PE', ...
            'HorizontalAlignment', 'center', 'FontSize', 12, 'FontWeight', 'bold');
        current_x_row2 = current_x_row2 + selected_pe.length_m;
    end
    
    % Place cabinets in row 2 (stop before door area)
    row2_max_x = container.length_m - door_width;
    for i = 1:design_result.row2.cabinet_count
        if current_x_row2 + selected_cabinet.length_m <= row2_max_x
            cab_y = row2_y_center - selected_cabinet.width_m / 2;  % Center in row
            rectangle('Position', [current_x_row2, cab_y, selected_cabinet.length_m, selected_cabinet.width_m], ...
                'FaceColor', [0.7, 1.0, 0.7], 'EdgeColor', 'g', 'LineWidth', 2);
            text(current_x_row2 + selected_cabinet.length_m/2, cab_y + selected_cabinet.width_m/2, 'CAB', ...
                'HorizontalAlignment', 'center', 'FontSize', 10, 'FontWeight', 'bold');
            current_x_row2 = current_x_row2 + selected_cabinet.length_m;
        end
    end
    
    % Add dimension annotations
    text(container.length_m/2, -0.3, sprintf('Container Length: %.3f m', container.length_m), ...
        'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'Color', 'blue', 'FontSize', 12);
    
    text(-0.5, container.width_m/2, sprintf('Width: %.3f m', container.width_m), ...
        'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'Color', 'blue', 'Rotation', 90, 'FontSize', 12);
    
    % Row labels and dimensions
    text(equipment_start_x - 0.3, row1_y_center, sprintf('ROW 1\n%.3fm', design_result.row_width), ...
        'HorizontalAlignment', 'center', 'FontSize', 10, 'Color', 'blue', 'FontWeight', 'bold');
    text(equipment_start_x - 0.3, row2_y_center, sprintf('ROW 2\n%.3fm', design_result.row_width), ...
        'HorizontalAlignment', 'center', 'FontSize', 10, 'Color', 'red', 'FontWeight', 'bold');
    
    % Formatting
    xlabel('Length (m)', 'FontWeight', 'bold', 'FontSize', 12);
    ylabel('Width (m)', 'FontWeight', 'bold', 'FontSize', 12);
    title(sprintf('%s Container Layout - %d Cabinets + %d PE Units\n%s (%s Layout)', ...
        container.name, design_result.cabinets_per_container, design_result.pe_per_container, ...
        selected_pe.name, upper(strrep(design_result.layout_type, '_', ' '))), 'FontWeight', 'bold', 'FontSize', 14);
    
    axis equal;
    grid on;
    
    % Set axis limits with padding
    xlim([-0.8, container.length_m + 0.3]);
    ylim([-0.5, container.width_m + 0.2]);
    
    % Create legend on the right side
    legend_x = 0.78;
    legend_y = 0.7;
    legend_width = 0.15;
    legend_height = 0.06;
    legend_spacing = 0.08;
    
    % HVAC legend
    subplot('Position', [legend_x, legend_y, legend_width, legend_height]);
    rectangle('Position', [0, 0, 1, 1], 'FaceColor', [0.8, 0.8, 1.0], 'EdgeColor', 'b', 'LineWidth', 2);
    text(1.1, 0.5, 'HVAC Space', 'VerticalAlignment', 'middle', 'FontSize', 11, 'FontWeight', 'bold');
    axis off;
    
    % Cabinet legend
    legend_y = legend_y - legend_spacing;
    subplot('Position', [legend_x, legend_y, legend_width, legend_height]);
    rectangle('Position', [0, 0, 1, 1], 'FaceColor', [0.7, 1.0, 0.7], 'EdgeColor', 'g', 'LineWidth', 2);
    text(1.1, 0.5, sprintf('Cabinet (%s)', selected_cabinet.name), 'VerticalAlignment', 'middle', 'FontSize', 11, 'FontWeight', 'bold');
    axis off;
    
    % Power Electronics legend
    legend_y = legend_y - legend_spacing;
    subplot('Position', [legend_x, legend_y, legend_width, legend_height]);
    rectangle('Position', [0, 0, 1, 1], 'FaceColor', [1.0, 0.7, 0.7], 'EdgeColor', 'r', 'LineWidth', 2);
    text(1.1, 0.5, 'Power Electronics', 'VerticalAlignment', 'middle', 'FontSize', 11, 'FontWeight', 'bold');
    axis off;
    
    % Door legend
    legend_y = legend_y - legend_spacing;
    subplot('Position', [legend_x, legend_y, legend_width, legend_height]);
    rectangle('Position', [0, 0, 1, 1], 'FaceColor', [1.0, 1.0, 0.8], 'EdgeColor', 'red', 'LineWidth', 2);
    text(1.1, 0.5, 'Door Clearance', 'VerticalAlignment', 'middle', 'FontSize', 11, 'FontWeight', 'bold');
    axis off;
    
    % Summary information box
    legend_y = legend_y - legend_spacing * 1.5;
    summary_height = 0.25;
    subplot('Position', [legend_x, legend_y - summary_height, legend_width + 0.05, summary_height]);
    
    summary_text = sprintf(['LAYOUT SUMMARY:\n\n' ...
        'Row 1 (Top):\n' ...
        '• %d PE + %d Cabinets\n' ...
        '• Length: %.1f%% used\n' ...
        '• %.2fm of %.2fm\n\n' ...
        'Row 2 (Bottom + Door):\n' ...
        '• %d PE + %d Cabinets\n' ...
        '• Length: %.1f%% used\n' ...
        '• %.2fm of %.2fm\n\n' ...
        'Total per Container:\n' ...
        '• %d PE Units\n' ...
        '• %d Cabinets\n' ...
        '• %.0f A Capacity'], ...
        design_result.row1.pe_count, design_result.row1.cabinet_count, ...
        design_result.row1.length_utilization, design_result.row1.used_length, design_result.row1.available_length, ...
        design_result.row2.pe_count, design_result.row2.cabinet_count, ...
        design_result.row2.length_utilization, design_result.row2.used_length, design_result.row2.available_length, ...
        design_result.pe_per_container, design_result.cabinets_per_container, design_result.container_current_capacity);
    
    text(0, 1, summary_text, 'FontSize', 9, 'VerticalAlignment', 'top', ...
        'HorizontalAlignment', 'left', 'FontWeight', 'normal');
    axis off;
end

function save_container_design(design_result, container, selected_pe, selected_cabinet, ...
    system_max_current, min_cabinets_system, door_width, results_folder)
    
    % FIXED: Save design results to CSV and text files in results folder
    
    fprintf('Saving results to %s...\n', results_folder);
    
    % Save detailed text summary
    save_text_summary(design_result, container, selected_pe, selected_cabinet, ...
        system_max_current, min_cabinets_system, door_width, results_folder);
    
    % Save CSV summary
    save_csv_summary(design_result, container, selected_pe, selected_cabinet, ...
        system_max_current, min_cabinets_system, door_width, results_folder);
    
    % Save configuration file
    save_configuration_summary(design_result, container, selected_pe, selected_cabinet, ...
        system_max_current, min_cabinets_system, door_width, results_folder);
    
    fprintf('✓ All results saved to %s\n', results_folder);
end

function save_text_summary(design_result, container, selected_pe, selected_cabinet, ...
    system_max_current, min_cabinets_system, door_width, results_folder)
    
    filename = fullfile(results_folder, 'container_design_summary.txt');
    
    fid = fopen(filename, 'w');
    if fid == -1
        fprintf('Warning: Could not create text summary file\n');
        return;
    end
    
    fprintf(fid, 'CONTAINERIZED SOLUTION DESIGN RESULTS\n');
    fprintf(fid, '====================================\n\n');
    fprintf(fid, 'TIMESTAMP: %s\n\n', datestr(now));
    
    fprintf(fid, 'INPUT REQUIREMENTS:\n');
    fprintf(fid, '  System Max Current: %.0f A\n', system_max_current);
    fprintf(fid, '  Min Cabinets (System): %d\n', min_cabinets_system);
    fprintf(fid, '  Door Width: %.3f m\n', door_width);
    
    fprintf(fid, '\nSELECTED COMPONENTS:\n');
    fprintf(fid, '  Container: %s (%.3f × %.3f m)\n', container.name, container.length_m, container.width_m);
    fprintf(fid, '  Power Electronics: %s\n', selected_pe.name);
    fprintf(fid, '    - Max Current: %.0f A\n', selected_pe.max_current_A);
    fprintf(fid, '    - Dimensions: %.3f × %.3f m\n', selected_pe.width_m, selected_pe.length_m);
    fprintf(fid, '    - Type: %s\n', conditional_string(selected_pe.is_rack_mounted, 'Rack Mounted', 'Skid Mounted'));
    fprintf(fid, '  Cabinet: %s (%.3f × %.3f m)\n', selected_cabinet.name, selected_cabinet.width_m, selected_cabinet.length_m);
    
    fprintf(fid, '\nOPTIMIZED DESIGN:\n');
    fprintf(fid, '  Number of Containers: %d\n', design_result.num_containers);
    fprintf(fid, '  Layout Type: %s\n', design_result.layout_type);
    
    fprintf(fid, '\nPER CONTAINER LAYOUT:\n');
    fprintf(fid, '  Row 1 (Top): %d PE + %d Cabinets\n', design_result.row1.pe_count, design_result.row1.cabinet_count);
    fprintf(fid, '    - Available Length: %.3f m\n', design_result.row1.available_length);
    fprintf(fid, '    - Used Length: %.3f m (%.1f%%)\n', design_result.row1.used_length, design_result.row1.length_utilization);
    fprintf(fid, '  Row 2 (Bottom + Door): %d PE + %d Cabinets\n', design_result.row2.pe_count, design_result.row2.cabinet_count);
    fprintf(fid, '    - Available Length: %.3f m\n', design_result.row2.available_length);
    fprintf(fid, '    - Used Length: %.3f m (%.1f%%)\n', design_result.row2.used_length, design_result.row2.length_utilization);
    fprintf(fid, '  Row Width: %.3f m\n', design_result.row_width);
    
    fprintf(fid, '\nTOTAL SYSTEM:\n');
    fprintf(fid, '  Total Cabinets: %d\n', design_result.total_cabinets);
    fprintf(fid, '  Total Power Electronics: %d\n', design_result.total_pe);
    fprintf(fid, '  Total Current Capacity: %.0f A\n', design_result.total_current_capacity);
    
    fprintf(fid, '\nCURRENT ANALYSIS:\n');
    fprintf(fid, '  Current per Cabinet: %.1f A\n', design_result.current_per_cabinet);
    fprintf(fid, '  Container Current Capacity: %.0f A\n', design_result.container_current_capacity);
    fprintf(fid, '  Container Current Utilization: %.1f%%\n', ...
        (design_result.cabinets_per_container * design_result.current_per_cabinet) / design_result.container_current_capacity * 100);
    
    fprintf(fid, '\nDESIGN VERIFICATION:\n');
    fprintf(fid, '  Min Cabinets: %s (%d >= %d)\n', ...
        conditional_string(design_result.total_cabinets >= min_cabinets_system, 'PASS', 'FAIL'), ...
        design_result.total_cabinets, min_cabinets_system);
    fprintf(fid, '  Current Capacity: %s (%.0f A >= %.0f A)\n', ...
        conditional_string(design_result.total_current_capacity >= system_max_current, 'PASS', 'FAIL'), ...
        design_result.total_current_capacity, system_max_current);
    
    fclose(fid);
end

function save_csv_summary(design_result, container, selected_pe, selected_cabinet, ...
    system_max_current, min_cabinets_system, door_width, results_folder)
    
    filename = fullfile(results_folder, 'container_design_data.csv');
    
    % Create summary data table
    summary_data = {};
    row = 1;
    
    % Add all key parameters
    summary_data{row, 1} = 'Parameter'; summary_data{row, 2} = 'Value'; summary_data{row, 3} = 'Unit'; row = row + 1;
    summary_data{row, 1} = 'Timestamp'; summary_data{row, 2} = datestr(now); summary_data{row, 3} = ''; row = row + 1;
    summary_data{row, 1} = ''; summary_data{row, 2} = ''; summary_data{row, 3} = ''; row = row + 1;
    
    summary_data{row, 1} = 'INPUT REQUIREMENTS'; summary_data{row, 2} = ''; summary_data{row, 3} = ''; row = row + 1;
    summary_data{row, 1} = 'System Max Current'; summary_data{row, 2} = system_max_current; summary_data{row, 3} = 'A'; row = row + 1;
    summary_data{row, 1} = 'Min Cabinets System'; summary_data{row, 2} = min_cabinets_system; summary_data{row, 3} = ''; row = row + 1;
    summary_data{row, 1} = 'Door Width'; summary_data{row, 2} = door_width; summary_data{row, 3} = 'm'; row = row + 1;
    summary_data{row, 1} = ''; summary_data{row, 2} = ''; summary_data{row, 3} = ''; row = row + 1;
    
    % ... (rest of CSV data structure)
    summary_data{row, 1} = 'CONTAINER'; summary_data{row, 2} = ''; summary_data{row, 3} = ''; row = row + 1;
    summary_data{row, 1} = 'Container Type'; summary_data{row, 2} = container.name; summary_data{row, 3} = ''; row = row + 1;
    summary_data{row, 1} = 'Container Length'; summary_data{row, 2} = container.length_m; summary_data{row, 3} = 'm'; row = row + 1;
    summary_data{row, 1} = 'Container Width'; summary_data{row, 2} = container.width_m; summary_data{row, 3} = 'm'; row = row + 1;
    
    % Add detailed row information
    summary_data{row, 1} = ''; summary_data{row, 2} = ''; summary_data{row, 3} = ''; row = row + 1;
    summary_data{row, 1} = 'ROW 1 LAYOUT'; summary_data{row, 2} = ''; summary_data{row, 3} = ''; row = row + 1;
    summary_data{row, 1} = 'Row 1 PE Count'; summary_data{row, 2} = design_result.row1.pe_count; summary_data{row, 3} = ''; row = row + 1;
    summary_data{row, 1} = 'Row 1 Cabinet Count'; summary_data{row, 2} = design_result.row1.cabinet_count; summary_data{row, 3} = ''; row = row + 1;
    summary_data{row, 1} = 'Row 1 Available Length'; summary_data{row, 2} = design_result.row1.available_length; summary_data{row, 3} = 'm'; row = row + 1;
    summary_data{row, 1} = 'Row 1 Used Length'; summary_data{row, 2} = design_result.row1.used_length; summary_data{row, 3} = 'm'; row = row + 1;
    summary_data{row, 1} = 'Row 1 Length Utilization'; summary_data{row, 2} = design_result.row1.length_utilization; summary_data{row, 3} = '%'; row = row + 1;
    
    summary_data{row, 1} = ''; summary_data{row, 2} = ''; summary_data{row, 3} = ''; row = row + 1;
    summary_data{row, 1} = 'ROW 2 LAYOUT'; summary_data{row, 2} = ''; summary_data{row, 3} = ''; row = row + 1;
    summary_data{row, 1} = 'Row 2 PE Count'; summary_data{row, 2} = design_result.row2.pe_count; summary_data{row, 3} = ''; row = row + 1;
    summary_data{row, 1} = 'Row 2 Cabinet Count'; summary_data{row, 2} = design_result.row2.cabinet_count; summary_data{row, 3} = ''; row = row + 1;
    summary_data{row, 1} = 'Row 2 Available Length'; summary_data{row, 2} = design_result.row2.available_length; summary_data{row, 3} = 'm'; row = row + 1;
    summary_data{row, 1} = 'Row 2 Used Length'; summary_data{row, 2} = design_result.row2.used_length; summary_data{row, 3} = 'm'; row = row + 1;
    summary_data{row, 1} = 'Row 2 Length Utilization'; summary_data{row, 2} = design_result.row2.length_utilization; summary_data{row, 3} = '%'; row = row + 1;
    summary_data{row, 1} = 'Row 2 Has Door'; summary_data{row, 2} = conditional_string(design_result.row2.has_door, 'Yes', 'No'); summary_data{row, 3} = ''; row = row + 1;
    
    % Convert to table and save
    summary_table = cell2table(summary_data, 'VariableNames', {'Parameter', 'Value', 'Unit'});
    
    try
        writetable(summary_table, filename);
        fprintf('✓ CSV data saved\n');
    catch ME
        fprintf('Warning: Could not save CSV file: %s\n', ME.message);
    end
end

function save_configuration_summary(design_result, container, selected_pe, selected_cabinet, ...
    system_max_current, min_cabinets_system, door_width, results_folder)
    
    filename = fullfile(results_folder, 'container_configuration.txt');
    
    fid = fopen(filename, 'w');
    if fid == -1
        fprintf('Warning: Could not create configuration file\n');
        return;
    end
    
    fprintf(fid, 'CONTAINER DESIGN CONFIGURATION\n');
    fprintf(fid, '==============================\n\n');
    fprintf(fid, 'Generated: %s\n\n', datestr(now));
    
    fprintf(fid, 'This file contains the optimized container design configuration\n');
    fprintf(fid, 'for the supercapacitor system containerized solution.\n\n');
    
    fprintf(fid, 'DESIGN SUMMARY:\n');
    fprintf(fid, '- %d × %s containers required\n', design_result.num_containers, container.name);
    fprintf(fid, '- %d cabinets per container (%d total)\n', design_result.cabinets_per_container, design_result.total_cabinets);
    fprintf(fid, '- %d power electronics per container (%d total)\n', design_result.pe_per_container, design_result.total_pe);
    fprintf(fid, '- %.0f A current capacity per container (%.0f A total)\n', design_result.container_current_capacity, design_result.total_current_capacity);
    
    fprintf(fid, '\nDETAILED LAYOUT PER CONTAINER:\n');
    fprintf(fid, 'Row 1 (Top): %d PE + %d Cabinets (%.1f%% length used)\n', ...
        design_result.row1.pe_count, design_result.row1.cabinet_count, design_result.row1.length_utilization);
    fprintf(fid, 'Row 2 (Bottom + Door): %d PE + %d Cabinets (%.1f%% length used)\n', ...
        design_result.row2.pe_count, design_result.row2.cabinet_count, design_result.row2.length_utilization);
    
    fprintf(fid, '\nCONSTRAINTS SATISFIED:\n');
    fprintf(fid, '✓ Minimum cabinets: %d >= %d\n', design_result.total_cabinets, min_cabinets_system);
    fprintf(fid, '✓ Current capacity: %.0f A >= %.0f A\n', design_result.total_current_capacity, system_max_current);
    
    fclose(fid);
end

function value = get_valid_input(prompt, validation_func, default_value)
    % Get valid input from user with optional default value
    if nargin < 3
        default_value = [];
    end
    
    while true
        try
            if isempty(default_value)
                value = input(prompt);
                if isempty(value)
                    continue;
                end
            else
                user_input = input(prompt);
                if isempty(user_input)
                    value = default_value;
                else
                    value = user_input;
                end
            end
            
            if validation_func(value)
                break;
            else
                fprintf('Invalid input. Please try again.\n');
            end
        catch
            fprintf('Invalid input format. Please enter a number.\n');
        end
    end
end

function str = conditional_string(condition, true_str, false_str)
    % Helper function for conditional string assignment
    if condition
        str = true_str;
    else
        str = false_str;
    end
end