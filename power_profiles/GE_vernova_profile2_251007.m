% GE_vernova_profile2_251007 - Custom power profile definition
% This file should be placed in the power_profiles folder
% The variable name must match the filename with a _pp suffix (without .m extension)

% Create the power profile structure
GE_vernova_profile2_251007_pp = struct();

% Basic information
GE_vernova_profile2_251007_pp.name = 'UltracapacitorPowerProfile2';
GE_vernova_profile2_251007_pp.description = 'Ultracapacitor power profile: 5-phase 100Hz oscillation with decay';

% Simulation parameters
dt = 0.0001; % 0.1 ms time step (10 kHz sampling for 100 Hz signal)
f = 100; % Frequency 100 Hz
T = 1/f; % Period = 10 ms

%% PHASE 1: 0-300ms - Sine oscillating between 1.5 MW and -1 MW
t1 = 0:dt:0.3-dt;
% Oscillazione tra 1.5 MW e -1 MW
% Valore medio: (1.5 + (-1))/2 = 0.25 MW
% Ampiezza: (1.5 - (-1))/2 = 1.25 MW
% P(t) = 0.25 + 1.25*sin(2*pi*f*t)
P1 = 0.25e6 + 1.25e6 * sin(2*pi*f*t1);

%% PHASE 2: 300-600ms - Sine oscillating between 1 MW and 500 kW
t2 = 0.3:dt:0.6-dt;
t2_rel = t2 - 0.3;
% Oscillazione tra 1 MW e 0.5 MW
% Valore medio: (1 + 0.5)/2 = 0.75 MW
% Ampiezza: (1 - 0.5)/2 = 0.25 MW
% P(t) = 0.75 + 0.25*sin(2*pi*f*t)
% Per continuità, determino la fase iniziale
phase2 = 2*pi*f*t1(end); % Fase alla fine di Phase 1
P2 = 0.75e6 + 0.25e6 * sin(2*pi*f*t2_rel + phase2);

%% PHASE 3: 600-900ms - Decaying oscillation between 0 and 500 kW
t3 = 0.6:dt:0.9-dt;
t3_rel = t3 - 0.6;
% Oscillazione che decade da [0, 500kW] inizialmente
% Valore medio che decade: 250 kW * e^(-t/tau)
% Ampiezza che decade: 250 kW * e^(-t/tau)
% Quindi: P(t) = 250kW*(1 + sin(...))*e^(-t/tau)
% Per avere decadimento completo in 300ms, uso tau = 300ms/5 = 60ms
tau3 = 0.06;
phase3 = 2*pi*f*t2_rel(end) + phase2;
mean_level3 = 0.25e6;
amplitude3 = 0.25e6 * exp(-t3_rel/tau3) + 0.25e6;
P3 = mean_level3 + amplitude3 .* sin(2*pi*f*t3_rel + phase3);

%% PHASE 4: 900-950ms (5 cycles at 100Hz = 50ms) - Exponential transition from 0 to -0.75MW with oscillation
t4 = 0.9:dt:(0.9 + 5*T - dt);
t4_rel = t4 - 0.9;
% Transizione esponenziale da 0 a -0.75 MW in 5 cicli (50ms)
% con oscillazione di ampiezza costante 0.25 MW
% Il valore medio deve decadere da 0 a -0.75 MW
% tau per decadimento in 5 cicli: tau = 5*T/5 = 10ms
tau4 = T;
phase4 = 2*pi*f*t3_rel(end) + phase3;
% Valore medio che decade da 0 a -0.75 MW
mean_level4 = -0.75e6 * (1 - exp(-t4_rel/tau4));
% Ampiezza costante
amplitude4 = 0.25e6;
P4 = mean_level4 + amplitude4 .* sin(2*pi*f*t4_rel + phase4);

%% PHASE 5: 950-1250ms (300ms) - Constant oscillation between -500kW and -1MW
t5_start = 0.9 + 5*T;
t5 = t5_start:dt:(t5_start + 0.3 - dt);
t5_rel = t5 - t5_start;
% Oscillazione costante tra -0.5 MW e -1 MW (senza decadimento)
% Valore medio: -0.75 MW
% Ampiezza: 0.25 MW (costante)
phase5 = 2*pi*f*t4_rel(end) + phase4;
mean_level5 = -0.75e6;
amplitude5 = 0.25e6;
P5 = mean_level5 + amplitude5 .* sin(2*pi*f*t5_rel + phase5);

%% Combine all phases
GE_vernova_profile2_251007_pp.time_data = [t1, t2, t3, t4, t5];
GE_vernova_profile2_251007_pp.power_data = -[P1, P2, P3, P4, P5];

% Calculated parameters
GE_vernova_profile2_251007_pp.max_power = max(abs(GE_vernova_profile2_251007_pp.power_data));
GE_vernova_profile2_251007_pp.duration = GE_vernova_profile2_251007_pp.time_data(end);
GE_vernova_profile2_251007_pp.time_step = dt;

% Profile type and units
GE_vernova_profile2_251007_pp.Switch_CurrentOrPower = -1; % -1 = power profile, 1 = current profile
GE_vernova_profile2_251007_pp.units = 'W';

% Optional: Add additional metadata
GE_vernova_profile2_251007_pp.created_by = 'User';
GE_vernova_profile2_251007_pp.creation_date = datestr(now);
GE_vernova_profile2_251007_pp.notes = 'Five-phase ultracapacitor power profile: (1) 1.5MW/-1MW @ 100Hz for 300ms, (2) 1MW/500kW @ 100Hz for 300ms, (3) Decay 500kW/0 @ 100Hz for 300ms, (4) Decay -500kW/-1MW @ 100Hz for 50ms (5 cycles), (5) Constant -500kW/-1MW @ 100Hz for 300ms';

% Debug info
fprintf('Profile created successfully:\n');
fprintf('  Phase 1 (0-300ms): %.2f to %.2f MW\n', min(P1)/1e6, max(P1)/1e6);
fprintf('  Phase 2 (300-600ms): %.2f to %.2f MW\n', min(P2)/1e6, max(P2)/1e6);
fprintf('  Phase 3 (600-900ms): %.2f to %.2f MW\n', min(P3)/1e6, max(P3)/1e6);
fprintf('  Phase 4 (900-950ms): %.2f to %.2f MW\n', min(P4)/1e6, max(P4)/1e6);
fprintf('  Phase 5 (950-1250ms): %.2f to %.2f MW\n', min(P5)/1e6, max(P5)/1e6);
fprintf('  Total duration: %.0f ms\n', GE_vernova_profile2_251007_pp.duration*1000);
fprintf('  Sampling rate: %.1f kHz\n', 1/dt/1000);