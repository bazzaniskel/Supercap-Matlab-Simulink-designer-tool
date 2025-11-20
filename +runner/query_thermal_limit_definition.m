function thermal = query_thermal_limit_definition(existingConstraints)
%QUERY_THERMAL_LIMIT_DEFINITION Ask whether to compute max thermal load.

    fprintf('\nDo you want to determine the maximum thermal load the system can handle?\n');
    fprintf('1. Yes\n');
    fprintf('2. No\n');
    choice = runner.get_valid_input('Select option (1-2): ', @(x) any(x == [1, 2]));

    thermal.enableDutyCycleSearch = (choice == 1);
    thermal.minLifetimeYears = existingConstraints.lifetime.minYears;

    if thermal.enableDutyCycleSearch && ~existingConstraints.lifetime.enabled
        thermal.minLifetimeYears = runner.get_valid_input('Enter the target lifetime in years: ', @(x) x > 0);
    end
end
