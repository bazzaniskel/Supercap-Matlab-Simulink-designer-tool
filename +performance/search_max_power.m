function [best_power, best_metrics] = search_max_power(caseConfig, cfg, soh)
%SEARCH_MAX_POWER Binary search for max deliverable power at given SOH.

    tolerance = cfg.tolerance_W;
    max_iterations = cfg.max_iterations;
    low = 0;
    high = cfg.max_power_W;
    best_power = 0;
    best_metrics = [];

    for iter = 1:max_iterations
        if (high - low) <= tolerance
            break;
        end
        mid = (low + high) / 2;
        if mid <= 0
            break;
        end
        [is_valid, metrics] = performance.simulate_pulse_case(caseConfig, soh, cfg.pulse_duration_s, mid);
        if is_valid
            best_power = mid;
            best_metrics = metrics;
            low = mid;
        else
            high = mid;
        end
    end

    if best_power > 0 && isempty(best_metrics)
        [is_valid, metrics] = performance.simulate_pulse_case(caseConfig, soh, cfg.pulse_duration_s, best_power);
        if is_valid
            best_metrics = metrics;
        end
    end
end
