function stats = update_stats(stats, test_result)
%UPDATE_STATS Track min/max voltage/current across steps.

    if isfield(test_result, 'min_voltage') && stats.min_voltage > test_result.min_voltage
        stats.min_voltage = test_result.min_voltage;
    end
    if isfield(test_result, 'max_voltage') && stats.max_voltage < test_result.max_voltage
        stats.max_voltage = test_result.max_voltage;
    end
    if isfield(test_result, 'max_current') && stats.max_current < test_result.max_current
        stats.max_current = test_result.max_current;
    end
    if isfield(test_result, 'max_power') && stats.max_power < test_result.max_power
        stats.max_power = test_result.max_power;
    end
end
