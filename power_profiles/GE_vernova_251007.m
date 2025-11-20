% GE_vernova_251007 - Custom power profile definition
% This file should be placed in the power_profiles folder
% The variable name must match the filename with a _pp suffix (without .m extension)

% Create the power profile structure
GE_vernova_251007_pp = struct();

% Basic information
GE_vernova_251007_pp.name = 'UltracapacitorPowerProfile';
GE_vernova_251007_pp.description = 'Ultracapacitor power profile: 2.5 MW for 1 sec + decaying cosine at 1 Hz';

% Time vector definition
% Total duration: 1 second (constant) + 10 seconds (cosine) = 11 seconds
% Use high resolution for smooth cosine wave
dt = 0.001; % 1 ms time step
t_constant = 0:dt:(1-dt); % First second: constant power (stop before 1s)
t_cosine = 1:dt:11; % Next 10 seconds: cosine wave (start at 1s)

% Combine time vectors
GE_vernova_251007_pp.time_data = [t_constant, t_cosine];

% Power data calculation
% Part 1: Constant 2.5 MW for 1 second
P_constant = 2.5e6 * ones(size(t_constant));

% Part 2: Decaying cosine wave
% P(t) = 1.5 MW + A(t) * cos(2*pi*f*t)
% where A(t) = 1.0 MW * e^(-t/tau) is the decaying amplitude
% At t=1s: A(0) = 1.0 MW, so P = 1.5 + 1.0*cos(0) = 2.5 MW ✓
% At t=2s (after 1 period): A(1) ≈ 0, so P ≈ 1.5 MW ✓

t_rel = t_cosine - 1; % Time relative to start of cosine section (starts at 0)
tau = 0.2; % Time constant (5*tau = 1 second for one period decay)
amplitude = 1.0e6 * exp(-t_rel/tau); % Decaying amplitude from 1 MW to ~0
P_cosine = (1.5e6 + amplitude) .* cos(2*pi*1*t_rel); % Cosine with decaying amplitude

% Combine power vectors
GE_vernova_251007_pp.power_data = [P_constant, P_cosine];

% Calculated parameters
GE_vernova_251007_pp.max_power = max(abs(GE_vernova_251007_pp.power_data));
GE_vernova_251007_pp.duration = GE_vernova_251007_pp.time_data(end);
GE_vernova_251007_pp.time_step = dt;

% Profile type and units
GE_vernova_251007_pp.Switch_CurrentOrPower = -1; % -1 = power profile, 1 = current profile
GE_vernova_251007_pp.units = 'W';

% Optional: Add additional metadata
GE_vernova_251007_pp.created_by = 'User';
GE_vernova_251007_pp.creation_date = datestr(now);
GE_vernova_251007_pp.notes = 'Ultracapacitor power profile with 1s constant 2.5MW followed by decaying 1Hz cosine wave';