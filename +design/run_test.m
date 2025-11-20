function [is_valid, test_result, simResults] = run_test(caseConfig, parallel_modules, start_voltage_override, options)
%RUN_TEST Shared simulation wrapper for binary search and performance analyses.

    if nargin < 3
        start_voltage_override = caseConfig.operating.startVoltage;
    end
    if nargin < 4
        options = struct();
    end

    backend = 'simulink';
    if isfield(caseConfig, 'simulation') && isfield(caseConfig.simulation, 'backend')
        backend = lower(string(caseConfig.simulation.backend));
    end

    switch backend
        case "ode"
            [Results, ~] = simulation.run_case_ode(caseConfig);
        otherwise
            design.copy_case_to_base(caseConfig, parallel_modules, start_voltage_override);
            model_name = 'Supercap_Thermo_Electrical_Cell_Simulation_Model';
            model_path = fullfile('CellModel', [model_name '.slx']);
            if ~bdIsLoaded(model_name)
                evalin('base', sprintf('open_system(''%s'')', model_path));
            end
            try
                Results = evalin('base', sprintf('sim(''%s'')', model_name));
            catch ME
                is_valid = false;
                test_result = failure_result(sprintf('Simulation failed: %s', ME.message));
                if nargout >= 3
                    simResults = struct();
                end
                return;
            end
    end

    [is_valid, test_result] = design.evaluate_results(caseConfig, Results, parallel_modules, options);
    if nargout >= 3
        simResults = Results;
    end
end

function result = failure_result(reason)
    result = struct('failure_reason', reason);
end
