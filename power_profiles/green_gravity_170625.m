% turbine_load1 - Custom power profile definition
% This file should be placed in the power_profiles folder
% The variable name must match the filename with a _pp suffix (without .m extension)

% Define the turbine load function (if using turbine-based profile)


% Create the power profile structure
green_gravity_170625_pp = struct();

% Basic information
green_gravity_170625_pp.name = 'CustomPowerProfile1';
green_gravity_170625_pp.description = 'Custom power profile for Green Gravity';

t = [0,10, 25,60,75,85];
p = [0,0,-8.64,-8.64,0,0];
p = p - trapz(t, p)/t(end);
p = p*1e6;
f = @(x) interp1(t, p, mod(x,85));

t1 = linspace(0,170,1000);
% Time vector definition
%green_gravity_170625_pp.time_data = [0,10, 25,60,79,92,109,145,160];  % 200.1 seconds, 2000 points
green_gravity_170625_pp.time_data = t1;
% Power data calculation
%green_gravity_170625_pp.power_data = [0,0,-8.64,-8.64,0,0,-8.64,-8.64,0];
green_gravity_170625_pp.power_data = f(t1);

% Calculated parameters
green_gravity_170625_pp.max_power = max(abs(green_gravity_170625_pp.power_data));
green_gravity_170625_pp.duration = green_gravity_170625_pp.time_data(end);
green_gravity_170625_pp.time_step = green_gravity_170625_pp.time_data(2) - green_gravity_170625_pp.time_data(1);

% Profile type and units
green_gravity_170625_pp.Switch_CurrentOrPower = -1; % -1 = power profile, 1 = current profile
green_gravity_170625_pp.units = 'W';

% Optional: Add additional metadata
green_gravity_170625_pp.created_by = 'User';
green_gravity_170625_pp.creation_date = datestr(now);
green_gravity_170625_pp.notes = 'Custom turbine load profile based on exponential decay';