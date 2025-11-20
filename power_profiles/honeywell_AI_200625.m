% turbine_load1 - Custom power profile definition
% This file should be placed in the power_profiles folder
% The variable name must match the filename with a _pp suffix (without .m extension)

% Define the turbine load function (if using turbine-based profile)


% Create the power profile structure
honeywell_AI_200625_pp = struct();

% Basic information
honeywell_AI_200625_pp.name = 'CustomPowerProfile1';
honeywell_AI_200625_pp.description = 'Custom power profile for Honeywell AI';

pp = [-0.01879710794822823, -42.85863469110703;
4.981602177024527, -41.94826495322229;
6.119748634752538, 253.02565866663397;
10.10215552456831, 232.91336744660336;
10.940285396612836, -56.150524291883386;
11.021739531055156, 29.56490223661018;
16.973419906505885, -0.6038417357222698;
17.717932809553346, 196.88557721249956;
20.081208420612935, 185.15397042834078;
20.918232580425205, -106.4309451996732;
21.002266710076107, -14.833129595616398;
24.210675037317785, 0.33785651540932804;
26.97384990570731, 0.3765564435381492;
27.762222727300646, 197.8665896763336;
30.03740993052441, 185.29341302651886;
30.917556867394385, -107.97157090993971;
31.001959567789367, -15.5334140093739;
34.29882487361095, 1.3194832638170055;
36.97391133416466, 0.5166133262898285;
37.71805566646803, 197.16569097800271;
40.12482262532941, 184.59435718190838;
40.199642486378245, 155.18364037323957;
43.043902918466, 140.0974255333528;
43.09550282263761, 157.74520704461582;
49.96603006308702, 122.54731526927202;
50.01615568428231, -163.1662684055014;
54.85106670516184, -139.5691408001672;
55.15182043233348, 146.14935715119432;
55.99179315809842, -138.7128281047478;
59.90380303579436, -119.33030695800122;
];


t = pp(:,1);
p = pp(:,2);
f = @(x) interp1(t, p, mod(x,t(end)));

t1 = linspace(0,t(end),t(end)*1000);
% Time vector definition

honeywell_AI_200625_pp.time_data = t1;
% Power data calculation

base_power = f(t1);

% Add sinusoidal signal between specified points
x_start = t(24);  % 24th point
x_end = t(25);    % 25th point
amplitude = 20;
frequency = 30 / (x_end - x_start);  % 30/(49.96603006308702 - 43.09550282263761)


% Create sinusoidal signal that is zero outside the specified region
sinusoidal_signal = zeros(size(t1));
region_mask = (t1 >= x_start) & (t1 <= x_end);
sinusoidal_signal(region_mask) = amplitude * sin(2 * pi * frequency * (t1(region_mask) - x_start));

p1 = base_power + sinusoidal_signal;
p1 = p1 - trapz(t1, p1)/t1(end);
p1 = p1*1e6;

% Combine base power with sinusoidal signal
honeywell_AI_200625_pp.power_data = p1;

% Calculated parameters
honeywell_AI_200625_pp.max_power = max(abs(honeywell_AI_200625_pp.power_data));
honeywell_AI_200625_pp.duration = honeywell_AI_200625_pp.time_data(end);
honeywell_AI_200625_pp.time_step = honeywell_AI_200625_pp.time_data(2) - honeywell_AI_200625_pp.time_data(1);

% Profile type and units
honeywell_AI_200625_pp.Switch_CurrentOrPower = -1; % -1 = power profile, 1 = current profile
honeywell_AI_200625_pp.units = 'W';

% Optional: Add additional metadata
honeywell_AI_200625_pp.created_by = 'User';
honeywell_AI_200625_pp.creation_date = datestr(now);
honeywell_AI_200625_pp.notes = 'Custom turbine load profile based on exponential decay';