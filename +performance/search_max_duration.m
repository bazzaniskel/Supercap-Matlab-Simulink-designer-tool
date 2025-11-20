function [best_duration, best_metrics] = search_max_duration(caseConfig, cfg, soh)
%SEARCH_MAX_DURATION Binary search for max feasible duration at given SOH.

    tolerance = cfg.tolerance_s;
    max_iterations = cfg.max_iterations;
    low = 0;
    high = cfg.max_duration_s;
    best_duration = 0;
    best_metrics = [];

    for iter = 1:max_iterations
        if (high - low) <= tolerance
            break;
        end
        mid = (low + high) / 2;
        if mid <= 0
            break;
        end
        [is_valid, metrics] = performance.simulate_pulse_case(caseConfig, soh, mid, cfg.requested_power_W);
        if is_valid
            best_duration = mid;
            best_metrics = metrics;
            low = mid;
        else
            high = mid;
        end
    end

    % Final verification at best_duration to capture metrics if empty
    if best_duration > 0 && isempty(best_metrics)
        [is_valid, metrics] = performance.simulate_pulse_case(caseConfig, soh, best_duration, cfg.requested_power_W);
        if is_valid
            best_metrics = metrics;
        end
    end
end
