% turbine_load1 - Custom power profile definition
% This file should be placed in the power_profiles folder
% The variable name must match the filename with a _pp suffix (without .m extension)

% Define the turbine load function (if using turbine-based profile)
Turbine_Load2 = @(x) (-1.6e6*(1-exp(-6*x/150)));;

% Create the power profile structure
turbine_load2_pp = struct();

% Basic information
turbine_load2_pp.name = 'CustomPowerProfile1';
turbine_load2_pp.description = 'Custom power profile for Turbine Load 1';

% Time vector definition
turbine_load2_pp.time_data = linspace(0, 200.1, 2000);  % 200.1 seconds, 2000 points

% Power data calculation
turbine_load2_pp.power_data = -1.6e6 - Turbine_Load2(turbine_load2_pp.time_data);

% Calculated parameters
turbine_load2_pp.max_power = max(abs(turbine_load2_pp.power_data));
turbine_load2_pp.duration = turbine_load2_pp.time_data(end);
turbine_load2_pp.time_step = turbine_load2_pp.time_data(2) - turbine_load2_pp.time_data(1);

% Profile type and units
turbine_load2_pp.Switch_CurrentOrPower = -1; % -1 = power profile, 1 = current profile
turbine_load2_pp.units = 'W';

% Optional: Add additional metadata
turbine_load2_pp.created_by = 'User';
turbine_load2_pp.creation_date = datestr(now);
turbine_load2_pp.notes = 'Custom turbine load profile based on exponential decay';