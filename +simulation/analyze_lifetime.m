function lifetime = analyze_lifetime(Cell_Voltage, Cell_Losses, Cell_Current, caseConfig, includeMonteCarlo)
%ANALYZE_LIFETIME Compute deterministic (and optional Monte Carlo) lifetimes.

    if nargin < 5
        includeMonteCarlo = true;
    end

    analysisDefaults = config.default_analysis();
    if ~isfield(caseConfig, 'analysis') || isempty(caseConfig.analysis)
        caseConfig.analysis = analysisDefaults;
    else
        caseConfig.analysis = config.merge_structs(analysisDefaults, caseConfig.analysis);
    end

    environment = caseConfig.operating.environment;
    lifetime_years = simulation.calculate_lifetime_years(Cell_Voltage, Cell_Losses, Cell_Current, ...
        caseConfig.operating.dutyCycle, caseConfig.operating.hoursPerDay, ...
        environment, caseConfig.cooling.rthCooling, ...
        caseConfig.cell.specs.Cell_HeatCapa_JpK, caseConfig.cell.specs);

    lifetime = struct();
    lifetime.deterministic_years = lifetime_years;
    lifetime.monteCarlo = struct('enabled', false);

    if includeMonteCarlo && isfield(caseConfig, 'analysis') ...
            && isfield(caseConfig.analysis, 'ambientMonteCarlo')
        mcOptions = caseConfig.analysis.ambientMonteCarlo;
        if mcOptions.enabled
            mcStats = simulation.run_monte_carlo_lifetime(Cell_Voltage, Cell_Losses, Cell_Current, ...
                caseConfig.operating.dutyCycle, caseConfig.operating.hoursPerDay, ...
                environment, caseConfig.cooling.rthCooling, ...
                caseConfig.cell.specs.Cell_HeatCapa_JpK, caseConfig.cell.specs, mcOptions);
            mcStats.runDuringDesign = mcOptions.enableInDesign;
            lifetime.monteCarlo = mcStats;
        end
    end
end
