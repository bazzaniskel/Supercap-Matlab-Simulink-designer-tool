function operation = select_operation_mode()
%SELECT_OPERATION_MODE Prompt the user to choose how to run the tool.

    fprintf('\n===============================================================\n');
    fprintf('                    OPERATION MODE SELECTION                  \n');
    fprintf('===============================================================\n');

    fprintf('\nOperation modes:\n');
    fprintf('1. Design optimization\n');
    fprintf('2. Simulation with specified configuration\n');
    fprintf('3. Lifetime-focused simulation (time-marching)\n');

    choice = runner.get_valid_input('Select operation mode (1-3): ', @(x) any(x == [1, 2, 3]));
    switch choice
        case 1
            operation.mode = 'design';
        case 2
            operation.mode = 'simulation';
        otherwise
            operation.mode = 'lifetime';
    end

    if strcmp(operation.mode, 'design')
        fprintf('\nOptimization types:\n');
        fprintf('1. Parallel modules optimization only\n');
        fprintf('2. Parallel modules + maximum voltage optimization\n');
        optimization_type = runner.get_valid_input('Select optimization type (1-2): ', @(x) any(x == [1, 2]));
        operation.optimizeVoltage = (optimization_type == 2);
    elseif strcmp(operation.mode, 'lifetime')
        fprintf('\nLifetime mode can either use a fixed starting voltage or search for the best one.\n');
        operation.optimizeVoltage = runner.get_yes_no_input('Optimize starting voltage during lifetime search? (y/n): ');
    else
        operation.optimizeVoltage = false;
    end
end
