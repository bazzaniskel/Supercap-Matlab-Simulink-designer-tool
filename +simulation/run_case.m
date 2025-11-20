function simOutput = run_case(caseConfig)
%RUN_CASE Execute the selected electrical model and post-process results.

    simulation.assign_base_variables(caseConfig);

    backend = 'simulink';
    if isfield(caseConfig, 'simulation') && isfield(caseConfig.simulation, 'backend')
        backend = lower(string(caseConfig.simulation.backend));
    end

    if backend ~= "ode"
        banner_backend = upper(char(backend));
        fprintf('\n===============================================================\n');
        fprintf('                RUNNING %s SIMULATION                \n', banner_backend);
        fprintf('===============================================================\n');
    end

    switch backend
        case "ode"
            [Results, elapsed_time] = simulation.run_case_ode(caseConfig);
        otherwise
            [Results, elapsed_time] = run_simulink_backend(caseConfig);
    end

    metrics = simulation.compute_metrics(Results, caseConfig);
    if caseConfig.thermal.enableDutyCycleSearch
        thermal_result = simulation.thermal_performance(caseConfig, Results);
        metrics.max_duty_cycle = thermal_result.duty_cycle_max;
    else
        metrics.max_duty_cycle = 0;
    end

    simOutput = struct('Results', Results, 'metrics', metrics, 'elapsed_time', elapsed_time);
end

function [Results, elapsed_time] = run_simulink_backend(caseConfig)
    model_name = 'Supercap_Thermo_Electrical_Cell_Simulation_Model';
    model_path = fullfile('CellModel', [model_name '.slx']);
    if ~exist(model_path, 'file')
        error('Simulink model %s not found in CellModel folder!', model_path);
    end
    if ~bdIsLoaded(model_name)
        fprintf('Opening Simulink model %s...\n', model_name);
        open_system(model_path);
    else
        fprintf('Simulink model %s is already open.\n', model_name);
    end

    start_time = tic;
    try
        Results = sim(model_name);
    catch ME
        error('Simulation failed: %s', ME.message);
    end
    elapsed_time = toc(start_time);
    fprintf('Simulink simulation completed successfully in %.1f s!\n', elapsed_time);
end
