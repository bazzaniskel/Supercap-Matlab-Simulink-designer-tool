% turbine_load1 - Custom power profile definition
% This file should be placed in the power_profiles folder
% The variable name must match the filename with a _pp suffix (without .m extension)

% Define the turbine load function (if using turbine-based profile)


% Create the power profile structure
hydraquip_170625_pp = struct();

% Basic information
hydraquip_170625_pp.name = 'CustomPowerProfile1';
hydraquip_170625_pp.description = 'Custom power profile for hydraquip_170625';

t = [0,1.5,1.5001,3];
p = [40,40,-40,-40]/16;
p = p - trapz(t, p)/t(end);
p = p*1e6;
f = @(x) interp1(t, p, mod(x,t(end)));

t1 = linspace(0,6,1000);
% Time vector definition
%hydraquip_170625_pp.time_data = [0,10, 25,60,79,92,109,145,160];  % 200.1 seconds, 2000 points
hydraquip_170625_pp.time_data = t1;
% Power data calculation
%hydraquip_170625_pp.power_data = [0,0,-8.64,-8.64,0,0,-8.64,-8.64,0];
hydraquip_170625_pp.power_data = f(t1);

% Calculated parameters
hydraquip_170625_pp.max_power = max(abs(hydraquip_170625_pp.power_data));
hydraquip_170625_pp.duration = hydraquip_170625_pp.time_data(end);
hydraquip_170625_pp.time_step = hydraquip_170625_pp.time_data(2) - hydraquip_170625_pp.time_data(1);

% Profile type and units
hydraquip_170625_pp.Switch_CurrentOrPower = -1; % -1 = power profile, 1 = current profile
hydraquip_170625_pp.units = 'W';

% Optional: Add additional metadata
hydraquip_170625_pp.created_by = 'User';
hydraquip_170625_pp.creation_date = datestr(now);
hydraquip_170625_pp.notes = 'hydraquip_170625 power profile';