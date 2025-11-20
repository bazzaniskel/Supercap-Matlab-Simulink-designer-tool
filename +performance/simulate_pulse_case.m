function [is_valid, metrics] = simulate_pulse_case(baseCaseConfig, soh_percent, pulse_duration_s, pulse_power_W)
%SIMULATE_PULSE_CASE Build temporary case for a constant-power pulse and evaluate it.

    if pulse_duration_s <= 0 || pulse_power_W <= 0
        is_valid = false;
        metrics = [];
        return;
    end

    tempCase = baseCaseConfig;
    tempCase.operating.SOH_percent = soh_percent;

    timestep = min(pulse_duration_s/100, 0.001);
    timestep = max(timestep, 1e-4);
    num_points = max(round(pulse_duration_s / timestep), 2);
    time_vector = linspace(0, pulse_duration_s, num_points);
    system_input = ones(1, num_points) * pulse_power_W;

    profile = struct();
    profile.mode = 'power';
    profile.switchCurrentOrPower = -1;
    profile.units = 'W';
    profile.name = 'Power';
    profile.time = time_vector;
    profile.systemInput = system_input;
    profile.maxValue = pulse_power_W;
    profile.description = sprintf('Performance pulse: %.2f s @ %.1f kW', pulse_duration_s, pulse_power_W/1e3);
    profile.duration = pulse_duration_s;

    tempCase.profile = profile;
    tempCase.sim.timeEnd = pulse_duration_s;
    tempCase.sim.timeStep = timestep;

    tempCase.constraints.lifetime.enabled = false;
    options = struct('skipLifetime', true);

    try
        [is_valid, test_result, simResults] = design.run_test(tempCase, tempCase.system.parallelModules, tempCase.operating.startVoltage, options);
        if ~is_valid
            metrics = [];
            return;
        end

        metrics = simulation.compute_metrics(simResults, tempCase);
        is_valid = performance.check_constraints(metrics, baseCaseConfig);
    catch ME
        fprintf('    Simulation failed for SOH %.0f%%: %s\n', soh_percent, ME.message);
        is_valid = false;
        metrics = [];
    end
end
