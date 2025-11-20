% turbine_load1 - Custom power profile definition
% This file should be placed in the power_profiles folder
% The variable name must match the filename with a _pp suffix (without .m extension)

% Define the turbine load function (if using turbine-based profile)


% Create the power profile structure
marubeni_250903_pp = struct();

% Basic information
marubeni_250903_pp.name = 'CustomPowerProfile1';
marubeni_250903_pp.description = 'Custom power profile for Turbine Load 1';

% Time vector definition
marubeni_250903_pp.time_data = [0, 0.1, 0.10001, 1.35, 1.35001, 1.35+1.25, 1.35+1.25+0.0001, 2.7];  % 200.1 seconds, 2000 points

% Power data calculation
marubeni_250903_pp.power_data = [0,0,100,100,-100, -100, 0, 0]*1e6;

% Calculated parameters
marubeni_250903_pp.max_power = max(abs(marubeni_250903_pp.power_data));
marubeni_250903_pp.duration = marubeni_250903_pp.time_data(end);
marubeni_250903_pp.time_step = marubeni_250903_pp.time_data(2) - marubeni_250903_pp.time_data(1);

% Profile type and units
marubeni_250903_pp.Switch_CurrentOrPower = -1; % -1 = power profile, 1 = current profile
marubeni_250903_pp.units = 'W';

% Optional: Add additional metadata
marubeni_250903_pp.created_by = 'User';
marubeni_250903_pp.creation_date = datestr(now);
marubeni_250903_pp.notes = 'Custom turbine load profile based on exponential decay';