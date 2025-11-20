function caseConfig = finalize_case(caseConfig)
%FINALIZE_CASE Compute derived parameters once config is complete.

    if ~isfield(caseConfig, 'simulation') || ~isstruct(caseConfig.simulation)
        caseConfig.simulation = struct();
    end
    if ~isfield(caseConfig.simulation, 'backend') || isempty(caseConfig.simulation.backend)
        caseConfig.simulation.backend = 'simulink';
    else
        caseConfig.simulation.backend = char(lower(string(caseConfig.simulation.backend)));
    end

    system = caseConfig.system;
    cellSpecs = caseConfig.cell.specs;
    operating = caseConfig.operating;
    if ~isfield(operating, 'environment') || isempty(operating.environment)
        envStruct = struct('mode', 'constant', 'temperature_C', operating.environmentTemp, ...
            'monthlyTemps', operating.environmentTemp, 'profileName', '', 'source', '');
    else
        envStruct = operating.environment;
        if ~isfield(envStruct, 'temperature_C') || isempty(envStruct.temperature_C)
            envStruct.temperature_C = operating.environmentTemp;
        end
    end
    envStruct = config.normalize_environment(envStruct);
    operating.environmentTemp = envStruct.temperature_C;
    operating.environment = envStruct;
    caseConfig.operating = operating;

    if ~isfield(caseConfig, 'analysis') || isempty(caseConfig.analysis)
        caseConfig.analysis = config.default_analysis();
    else
        caseConfig.analysis = config.merge_structs(config.default_analysis(), caseConfig.analysis);
    end
    if isfield(operating, 'monteCarlo') && ~isempty(operating.monteCarlo)
        caseConfig.analysis.ambientMonteCarlo = config.merge_structs(caseConfig.analysis.ambientMonteCarlo, operating.monteCarlo);
    end

    moduleRatedVoltage = system.moduleRatedVoltage;
    max_rack_voltage = moduleRatedVoltage * system.seriesModules;
    caseConfig.sim.initialSOC = (operating.startVoltage / max_rack_voltage)^2 * 100;

    caseConfig.sim.timeEnd = caseConfig.profile.time(end);
    caseConfig.sim.timeStep = caseConfig.timestep.value;
    caseConfig.sim.isUPS = true;

    cell_lower_soc = (operating.startVoltage / (system.moduleNumCellSeries * cellSpecs.Cell_VoltRated_V * system.seriesModules))^2 * 100;
    caseConfig.limits.systemVoltage = operating.systemVoltage;
    caseConfig.limits.cellSOC = [cell_lower_soc, 100];
    caseConfig.limits.cellVoltage = [0, cellSpecs.Cell_VoltRated_V];

    caseConfig.profile.duration = caseConfig.profile.time(end);
end
