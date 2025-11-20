% turbine_load1 - Custom power profile definition
% This file should be placed in the power_profiles folder
% The variable name must match the filename with a _pp suffix (without .m extension)

% Define the turbine load function (if using turbine-based profile)


% Create the power profile structure
endesa_170625_pp = struct();

% Basic information
endesa_170625_pp.name = 'CustomPowerProfile1';
endesa_170625_pp.description = 'Custom power profile for Turbine Load 1';

% Time vector definition
endesa_170625_pp.time_data = [22.2,22.23,22.300001,25,27.5,28.5,30]-22.2;  % 200.1 seconds, 2000 points

% Power data calculation
endesa_170625_pp.power_data = [0,0,3.7e6,3.7e6,2.21e6,0,0]/8;

% Calculated parameters
endesa_170625_pp.max_power = max(abs(endesa_170625_pp.power_data));
endesa_170625_pp.duration = endesa_170625_pp.time_data(end);
endesa_170625_pp.time_step = endesa_170625_pp.time_data(2) - endesa_170625_pp.time_data(1);

% Profile type and units
endesa_170625_pp.Switch_CurrentOrPower = -1; % -1 = power profile, 1 = current profile
endesa_170625_pp.units = 'W';

% Optional: Add additional metadata
endesa_170625_pp.created_by = 'User';
endesa_170625_pp.creation_date = datestr(now);
endesa_170625_pp.notes = 'Custom turbine load profile based on exponential decay';