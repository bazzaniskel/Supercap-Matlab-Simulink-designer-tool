function should_run = confirm_execution()
%CONFIRM_EXECUTION Ask user confirmation before running simulation.
    response = input('\nProceed with simulation? (y/n): ', 's');
    should_run = strcmpi(response, 'y');
end
