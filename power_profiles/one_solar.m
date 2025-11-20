% This file should be placed in the power_profiles folder
% The variable name must match the filename with a _pp suffix (without .m extension)

% Create the power profile structure
one_solar_pp = struct();

% Basic information
one_solar_pp.name = 'one_solar';
one_solar_pp.description = 'Sinusoidal oscillating pulse with 2 harmonics for solar application';

% Time parameters
duration = 10 * 60; % 10 minutes in seconds
sample_rate = 10; % 10 Hz sampling rate for smooth sinusoids
time_step = 1/sample_rate; % 0.1 seconds

% Time vector definition
one_solar_pp.time_data = 0:time_step:duration;

% Harmonic parameters
% Harmonic 1: 2 kW amplitude, 5s period
A1 = 20000; % 20 kW in Watts
T1 = 5; % 5 seconds period
f1 = 1/T1; % frequency in Hz

% Harmonic 2: 200 kW amplitude, 60s period
A2 = 200000; % 200 kW in Watts
T2 = 60; % 60 seconds period
f2 = 1/T2; % frequency in Hz

% Harmonic 3: 10 kW amplitude, 1s period
A3 = 10000; % 10 kW in Watts
T3 = 1; % 1 second period
f3 = 1/T3; % frequency in Hz

% add random noise of 10 kW
noise = 10000 * randn(size(one_solar_pp.time_data));

% Power data calculation - sum of two sinusoidal harmonics
harmonic1 = A1 * sin(2*pi*f1*one_solar_pp.time_data);
harmonic2 = A2 * sin(2*pi*f2*one_solar_pp.time_data);
harmonic3 = A3 * sin(2*pi*f3*one_solar_pp.time_data);
one_solar_pp.power_data = harmonic1 + harmonic2 + harmonic3 + noise;

% Calculated parameters
one_solar_pp.max_power = max(abs(one_solar_pp.power_data));
one_solar_pp.duration = one_solar_pp.time_data(end);
one_solar_pp.time_step = time_step;

% Profile type and units
one_solar_pp.Switch_CurrentOrPower = -1; % -1 = power profile, 1 = current profile
one_solar_pp.units = 'W';

% Optional: Add additional metadata
one_solar_pp.created_by = 'User';
one_solar_pp.creation_date = datestr(now);
one_solar_pp.notes = 'Sinusoidal oscillating pulse with 2 harmonics: 2kW@5s period + 200kW@60s period, 10min duration';

% Display some key information
fprintf('Power Profile: %s\n', one_solar_pp.name);
fprintf('Duration: %.1f seconds (%.1f minutes)\n', one_solar_pp.duration, one_solar_pp.duration/60);
fprintf('Time step: %.3f seconds\n', one_solar_pp.time_step);
fprintf('Number of points: %d\n', length(one_solar_pp.time_data));
fprintf('Maximum power: %.2f kW\n', one_solar_pp.max_power/1000);
fprintf('Minimum power: %.2f kW\n', min(one_solar_pp.power_data)/1000);
fprintf('Harmonic 1: %.1f kW amplitude, %.1f s period\n', A1/1000, T1);
fprintf('Harmonic 2: %.1f kW amplitude, %.1f s period\n', A2/1000, T2);