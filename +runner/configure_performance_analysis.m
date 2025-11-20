function performanceConfig = configure_performance_analysis()
%CONFIGURE_PERFORMANCE_ANALYSIS Collect optional performance search inputs.

    performanceConfig = struct();

    fprintf('\n--- OPTIONAL PERFORMANCE ANALYSIS ---\n');

    % Time-domain search (fixed power, max duration)
    if runner.get_yes_no_input('Run time-domain performance search (fixed power, max duration)? (y/n): ')
        timeConfig.enabled = true;
        timeConfig.requested_power_kW = runner.get_valid_input('Requested constant system power [kW]: ', @(x) x > 0);
        timeConfig.requested_power_W = timeConfig.requested_power_kW * 1e3;
        timeConfig.max_duration_s = runner.get_valid_input('Maximum pulse duration to consider [s]: ', @(x) x > 0);
        timeConfig.soh_min = runner.get_valid_input('Minimum SOH to evaluate [0-100%%]: ', @(x) x >= 0 && x <= 100);
        timeConfig.soh_step = 5;  % Fixed 5%% steps as requested
        timeConfig.tolerance_s = 0.1;
        timeConfig.max_iterations = 25;
        performanceConfig.timeDomain = timeConfig;
    else
        performanceConfig.timeDomain = struct('enabled', false);
    end

    % Power-domain search (fixed duration, max power)
    if runner.get_yes_no_input('Run power-domain performance search (fixed duration, max power)? (y/n): ')
        powerConfig.enabled = true;
        powerConfig.pulse_duration_s = runner.get_valid_input('Fixed pulse duration [s]: ', @(x) x > 0);
        powerConfig.max_power_kW = runner.get_valid_input('Maximum power to consider [kW]: ', @(x) x > 0);
        powerConfig.max_power_W = powerConfig.max_power_kW * 1e3;
        powerConfig.soh_min = runner.get_valid_input('Minimum SOH to evaluate [0-100%%]: ', @(x) x >= 0 && x <= 100);
        powerConfig.soh_step = 5;
        powerConfig.tolerance_W = powerConfig.max_power_W * 0.01; % 1%% resolution
        powerConfig.max_iterations = 25;
        performanceConfig.powerDomain = powerConfig;
    else
        performanceConfig.powerDomain = struct('enabled', false);
    end

    if runner.get_yes_no_input('Run efficiency vs SOH analysis? (y/n): ')
        effConfig.enabled = true;
        effConfig.soh_min = 0;
        effConfig.soh_max = 100;
        effConfig.soh_step = 5;
        fprintf('  Efficiency curve will evaluate SOH from 0%% to 100%% in 5%% steps.\n');
        performanceConfig.efficiency = effConfig;
    else
        performanceConfig.efficiency = struct('enabled', false);
    end
end
