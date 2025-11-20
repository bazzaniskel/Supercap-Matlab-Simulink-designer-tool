function operating = configure_operating_conditions(operationMode, constraints)
%CONFIGURE_OPERATING_CONDITIONS Collect environmental and schedule inputs.

    fprintf('\n--- OPERATING CONDITIONS ---\n');
    operating = struct();
    operating.SOH_percent = runner.get_valid_input('State of Health (SOH) [0-100%]: ', @(x) x >= 0 && x <= 100);

    [environment, baseTemp] = runner.configure_environment_profile();
    environment = runner.configure_solar_exposure(environment);
    if isfield(environment, 'temperature_C') && ~isempty(environment.temperature_C)
        baseTemp = environment.temperature_C;
    end
    operating.environment = environment;
    operating.environmentTemp = baseTemp;

    if ~constraints.voltageOptimization.enabled
        operating.startVoltage = runner.get_valid_input('Starting voltage [V]: ', @(x) x > 0);
    else
        range = constraints.voltageOptimization.range;
        fprintf('Starting voltage will be optimized within %.1f - %.1f V\n', range(1), range(2));
        operating.startVoltage = mean(range);
    end

    fprintf('\n--- OPERATING SCHEDULE ---\n');
    operating.dutyCycle = runner.get_valid_input('Duty cycle [0-1]: ', @(x) x >= 0 && x <= 1);
    operating.hoursPerDay = runner.get_valid_input('Operating hours per day [0-24]: ', @(x) x >= 0 && x <= 24);

    fprintf('\n--- VOLTAGE LIMITS ---\n');
    operating.systemVoltage.min = runner.get_valid_input('Minimum system voltage [V]: ', @(x) x > 0);
    operating.systemVoltage.max = runner.get_valid_input('Maximum system voltage [V]: ', @(x) x > operating.systemVoltage.min);

    operating.monteCarlo = runner.configure_monte_carlo(environment);
end
