% turbine_load1 - Custom power profile definition
% This file should be placed in the power_profiles folder
% The variable name must match the filename with a _pp suffix (without .m extension)

% Define the turbine load function (if using turbine-based profile)


% Create the power profile structure
siemens_ag_is_250721_pp = struct();

% Basic information
siemens_ag_is_250721_pp.name = 'CustomPowerProfile1';
siemens_ag_is_250721_pp.description = 'Custom power profile for Turbine Load 1';

% Time vector definition
siemens_ag_is_250721_pp.time_data = [0,0.1,0.1+1e-3, 30.1,30.1+1e-3, 31.1, 31.1+1e-3, 61.1, 61.1+1e-3, 61+61.1];

% Power data calculation
siemens_ag_is_250721_pp.power_data = [0,0,400e3,400e3,0,0,400e3,400e3,-400e3,-400e3];

% Calculated parameters
siemens_ag_is_250721_pp.max_power = max(abs(siemens_ag_is_250721_pp.power_data));
siemens_ag_is_250721_pp.duration = siemens_ag_is_250721_pp.time_data(end);
siemens_ag_is_250721_pp.time_step = siemens_ag_is_250721_pp.time_data(2) - siemens_ag_is_250721_pp.time_data(1);

% Profile type and units
siemens_ag_is_250721_pp.Switch_CurrentOrPower = -1; % -1 = power profile, 1 = current profile
siemens_ag_is_250721_pp.units = 'W';

% Optional: Add additional metadata
siemens_ag_is_250721_pp.created_by = 'User';
siemens_ag_is_250721_pp.creation_date = datestr(now);
siemens_ag_is_250721_pp.notes = 'Custom turbine load profile based on exponential decay';