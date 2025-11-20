function is_valid = check_constraints(metrics, baseCaseConfig)
%CHECK_CONSTRAINTS Verify voltage/current limits for performance runs.

    voltage_ok = (metrics.system_min_voltage >= baseCaseConfig.operating.systemVoltage.min) && ...
                 (metrics.system_max_voltage <= baseCaseConfig.operating.systemVoltage.max);

    if ~voltage_ok
        is_valid = false;
        return;
    end

    if isfield(baseCaseConfig, 'constraints') && baseCaseConfig.constraints.currentLimit.enabled
        current_ok = metrics.system_max_current <= baseCaseConfig.constraints.currentLimit.maxSystemCurrent;
        is_valid = current_ok;
    else
        is_valid = true;
    end
end
