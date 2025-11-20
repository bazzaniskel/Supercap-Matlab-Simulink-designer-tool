% turbine_load1 - Custom power profile definition
% This file should be placed in the power_profiles folder
% The variable name must match the filename with a _pp suffix (without .m extension)

% Define the turbine load function (if using turbine-based profile)


% Create the power profile structure
flaxress_250721_pp = struct();

% Basic information
flaxress_250721_pp.name = 'CustomPowerProfile1';
flaxress_250721_pp.description = 'Custom power profile for flaxress_250721';

t = [0,30];
p = [0,125e3];
p = p - trapz(t, p)/t(end);
f = @(x) interp1(t, p, mod(x,t(end)));

t1 = linspace(0,240,1000);
% Time vector definition
%flaxress_250721_pp.time_data = [0,10, 25,60,79,92,109,145,160];  % 200.1 seconds, 2000 points
flaxress_250721_pp.time_data = t1;
% Power data calculation
%flaxress_250721_pp.power_data = [0,0,-8.64,-8.64,0,0,-8.64,-8.64,0];
flaxress_250721_pp.power_data = f(t1);

% Calculated parameters
flaxress_250721_pp.max_power = max(abs(flaxress_250721_pp.power_data));
flaxress_250721_pp.duration = flaxress_250721_pp.time_data(end);
flaxress_250721_pp.time_step = flaxress_250721_pp.time_data(2) - flaxress_250721_pp.time_data(1);

% Profile type and units
flaxress_250721_pp.Switch_CurrentOrPower = -1; % -1 = power profile, 1 = current profile
flaxress_250721_pp.units = 'W';

% Optional: Add additional metadata
flaxress_250721_pp.created_by = 'User';
flaxress_250721_pp.creation_date = datestr(now);
flaxress_250721_pp.notes = 'flaxress_250721 power profile';