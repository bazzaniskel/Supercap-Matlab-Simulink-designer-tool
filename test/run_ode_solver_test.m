function run_ode_solver_test(config_path)
%RUN_ODE_SOLVER_TEST Execute the MATLAB ODE backend and plot key variables.
%
%   run_ode_solver_test() loads the sample JSON configuration shipped with
%   the repository, switches it to the ODE backend, runs the simulation, and
%   plots voltage, current, power, losses, and temperature traces.
%
%   run_ode_solver_test(PATH) uses the configuration file located at PATH.

    project_root = fileparts(fileparts(mfilename('fullpath')));
    addpath(genpath(project_root));

    if nargin < 1 || isempty(config_path)
        config_path = fullfile('configs', 'template_case_config.m');
    end

    caseConfig = load_case_config(config_path);
    caseConfig.simulation = struct('backend', 'ode');
    caseConfig = config.finalize_case(caseConfig);

    simOutput = simulation.run_case(caseConfig);
    outputs = simOutput.Results.Sim_Electrical_Ouput;
    t = outputs.Cell_Voltage_V.Time;

    figure('Name', 'ODE Solver Test', 'Position', [100 100 960 720]);
    tiledlayout(3, 2, 'Padding', 'compact');

    nexttile;
    plot(t, outputs.Cell_Voltage_V.Data, 'LineWidth', 1.5);
    hold on;
    plot(t, outputs.Cell_OCV_V.Data, '--', 'LineWidth', 1.2);
    hold off;
    grid on;
    xlabel('Time [s]');
    ylabel('Voltage [V]');
    legend({'Cell V', 'OCV'}, 'Location', 'best');
    title('Cell Voltage vs OCV');

    nexttile;
    plot(t, outputs.Cell_Current_A.Data, 'LineWidth', 1.5);
    grid on;
    xlabel('Time [s]');
    ylabel('Current [A]');
    title('Cell Current');

    nexttile;
    plot(t, outputs.Cell_Power_W.Data / 1e3, 'LineWidth', 1.5);
    grid on;
    xlabel('Time [s]');
    ylabel('Power [kW]');
    title('Cell Power');

    nexttile;
    plot(t, outputs.Cell_Ploss_W.Data, 'LineWidth', 1.5);
    grid on;
    xlabel('Time [s]');
    ylabel('Losses [W]');
    title('I^2R Losses');

    nexttile;
    plot(t, outputs.Cell_Temp_degC.Data, 'LineWidth', 1.5);
    grid on;
    xlabel('Time [s]');
    ylabel('Temperature [°C]');
    title('Cell Temperature');

    sgtitle('ODE Backend Simulation Outputs');
end

function caseConfig = load_case_config(config_path)
    configInfo = struct('path', config_path, 'displayName', 'test_case', 'functionName', '');
    [~, func_name, ext] = fileparts(config_path);
    if strcmpi(ext, '.m')
        configInfo.functionName = func_name;
    end
    caseConfig = runner.load_case_from_file(configInfo);
end
