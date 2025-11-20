function evalResult = evaluate_configuration(caseConfig, periods)
%EVALUATE_CONFIGURATION Run deterministic timeline (and optional MC) for a variant.

    timeline = lifetime.time_march(caseConfig, periods, caseConfig.lifetime);

    evalResult = struct();
    evalResult.timeline = timeline;
    evalResult.success = timeline.success;
    evalResult.failure_reason = timeline.failure_reason;
    evalResult.startResults = timeline.firstResults;
    evalResult.endResults = timeline.lastResults;
    evalResult.min_parallel_modules = caseConfig.system.parallelModules;
    evalResult.start_voltage = caseConfig.operating.startVoltage;
    evalResult.caseConfig = caseConfig;

    if caseConfig.lifetime.monteCarlo.enabled && timeline.success
        mcSummary = lifetime.run_monte_carlo(timeline, periods, caseConfig);
        evalResult.mc = mcSummary;
        evalResult.success = mcSummary.pass;
        if ~mcSummary.pass
            evalResult.failure_reason = mcSummary.failure_reason;
        end
    else
        evalResult.mc = struct('enabled', false);
    end
end
