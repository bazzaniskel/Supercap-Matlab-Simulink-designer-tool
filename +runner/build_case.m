function caseConfig = build_case()
%BUILD_CASE Collect all user inputs and assemble a case configuration.

    caseConfig = struct();
    caseConfig.operation = runner.select_operation_mode();
    caseConfig.cell = runner.select_cell();
    [caseConfig.system, caseConfig.constraints] = runner.configure_system(caseConfig.operation, caseConfig.cell);
    caseConfig.operating = runner.configure_operating_conditions(caseConfig.operation, caseConfig.constraints);
    caseConfig.profile = profiles.configure_profile();
    caseConfig.timestep = runner.select_timestep(caseConfig.profile);
    caseConfig.cooling = runner.configure_cooling(caseConfig.cell.specs, caseConfig.operating.environmentTemp);
    caseConfig.thermal = runner.query_thermal_limit_definition(caseConfig.constraints);
    caseConfig.performance = runner.configure_performance_analysis();
    caseConfig.simulation = runner.select_simulation_backend(caseConfig.profile);

    if strcmp(caseConfig.operation.mode, 'lifetime')
        caseConfig.lifetime = runner.configure_lifetime_mode(caseConfig);
    else
        caseConfig.lifetime = struct();
    end

    baseAnalysis = config.default_analysis();
    if isfield(caseConfig.operating, 'monteCarlo') && ~isempty(caseConfig.operating.monteCarlo)
        baseAnalysis.ambientMonteCarlo = config.merge_structs(baseAnalysis.ambientMonteCarlo, caseConfig.operating.monteCarlo);
    end
    caseConfig.analysis = baseAnalysis;
end
