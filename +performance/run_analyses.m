function run_analyses(caseConfig, results_folder)
%RUN_ANALYSES Execute optional performance studies and persist outputs.

    if ~isfield(caseConfig, 'performance')
        return;
    end

    if isfield(caseConfig.performance, 'timeDomain') && caseConfig.performance.timeDomain.enabled
        performance.time_domain_analysis(caseConfig, results_folder);
    end

    if isfield(caseConfig.performance, 'powerDomain') && caseConfig.performance.powerDomain.enabled
        performance.power_domain_analysis(caseConfig, results_folder);
    end

    if isfield(caseConfig.performance, 'efficiency') && caseConfig.performance.efficiency.enabled
        performance.efficiency_curve_analysis(caseConfig, results_folder);
    end
end
