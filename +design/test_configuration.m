function [is_valid, test_result] = test_configuration(caseConfig, parallel_modules, start_voltage_override)
%TEST_CONFIGURATION Simulate a configuration and check constraints.

    if nargin < 3 || isempty(start_voltage_override)
        start_voltage_override = caseConfig.operating.startVoltage;
    end

    [is_valid, test_result] = design.run_test(caseConfig, parallel_modules, start_voltage_override);
end
