% turbine_load1 - Custom power profile definition
% This file should be placed in the power_profiles folder
% The variable name must match the filename with a _pp suffix (without .m extension)

% Define the turbine load function (if using turbine-based profile)


% Create the power profile structure
Cablecar_251013_pp = struct();

% Basic information
Cablecar_251013_pp.name = 'CustomPowerProfile1';
Cablecar_251013_pp.description = 'Custom power profile for Turbine Load 1';

data = readtable("./Lastprofil_Cablecar.csv");
data = sortrows(data, 'x');

[~, idx] = unique(data.x, 'stable');
data = data(idx, :);


% Time vector definition
Cablecar_251013_pp.time_data = data.x;

% Power data calculation
Cablecar_251013_pp.power_data = data.y*1e3;

% Calculated parameters
Cablecar_251013_pp.max_power = max(abs(Cablecar_251013_pp.power_data));
Cablecar_251013_pp.duration = Cablecar_251013_pp.time_data(end);
Cablecar_251013_pp.time_step = Cablecar_251013_pp.time_data(2) - Cablecar_251013_pp.time_data(1);

% Profile type and units
Cablecar_251013_pp.Switch_CurrentOrPower = -1; % -1 = power profile, 1 = current profile
Cablecar_251013_pp.units = 'W';

% Optional: Add additional metadata
Cablecar_251013_pp.created_by = 'User';
Cablecar_251013_pp.creation_date = datestr(now);
Cablecar_251013_pp.notes = 'Custom turbine load profile based on exponential decay';