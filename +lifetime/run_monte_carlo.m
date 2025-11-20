function mc = run_monte_carlo(timeline, periods, caseConfig)
%RUN_MONTE_CARLO Evaluate percentile lifetime using stored step inputs.

    mcOpts = caseConfig.lifetime.monteCarlo;
    ambientMC = caseConfig.analysis.ambientMonteCarlo;
    jitter = config.resolve_temperature_jitter(ambientMC);
    if mcOpts.numTrials <= 0
        mc = struct('enabled', false);
        return;
    end

    if ~isempty(mcOpts.seed)
        prev = rng;
        rng(mcOpts.seed, 'twister');
    else
        prev = [];
    end

    numPoints = numel(timeline.soh_percent);
    achieved_years = zeros(mcOpts.numTrials, 1);
    steady_samples = NaN(mcOpts.numTrials, numPoints);

    for trial = 1:mcOpts.numTrials
        consumed_fraction = max(0, 1 - caseConfig.operating.SOH_percent/100);
        elapsed_years = 0;
        point_idx = 1;

        for stepIdx = 1:numel(timeline.steps)
            step = timeline.steps(stepIdx);
            inputs = step.inputs;
            for k = 1:step.activeMonths
                monthIdx = step.monthIndices(k);
                period = periods(monthIdx);
                jittered = lifetime.apply_jitter(period.profile, jitter);
                [frac_per_day, info] = lifetime.compute_fraction_for_profile(inputs, jittered);
                days_in_month = step.monthDays(k);
                delta = frac_per_day * days_in_month;
                consumed_fraction = consumed_fraction + delta;
                elapsed_years = elapsed_years + days_in_month/365.25;
                point_idx = point_idx + 1;
                if point_idx <= numPoints
                    steady_samples(trial, point_idx) = info.steadyTemp;
                end
                if consumed_fraction >= 1 || elapsed_years >= caseConfig.lifetime.maxYears || ...
                        (caseConfig.lifetime.stopAtTarget && elapsed_years >= caseConfig.lifetime.targetYears)
                    break;
                end
            end
            if consumed_fraction >= 1 || elapsed_years >= caseConfig.lifetime.maxYears || ...
                    (caseConfig.lifetime.stopAtTarget && elapsed_years >= caseConfig.lifetime.targetYears)
                break;
            end
        end
        achieved_years(trial) = elapsed_years;
    end

    if ~isempty(prev)
        rng(prev);
    end

    mc = struct();
    mc.enabled = true;
    mc.numTrials = mcOpts.numTrials;
    mc.passPercentile = mcOpts.passPercentile;
    mc.requirementYears = mcOpts.requirementYears;
    mc.passYears = prctile(achieved_years, mcOpts.passPercentile);
    mc.pass = mc.passYears >= mcOpts.requirementYears;
    mc.values = achieved_years;
    mc.tempStats = compute_temp_stats(steady_samples, timeline.soh_percent);
    if mc.pass
        mc.failure_reason = '';
    else
        mc.failure_reason = sprintf('%.1fth percentile lifetime %.2f years < %.2f years requirement', ...
            mcOpts.passPercentile, mc.passYears, mcOpts.requirementYears);
    end
end

function stats = compute_temp_stats(samples, soh_axis)
    stats = struct();
    stats.soh = soh_axis;
    stats.mean = mean_omit_nan(samples);
    stats.p10 = percentile_omit_nan(samples, 10);
    stats.p25 = percentile_omit_nan(samples, 25);
    stats.p75 = percentile_omit_nan(samples, 75);
    stats.p90 = percentile_omit_nan(samples, 90);
end

function values = percentile_omit_nan(samples, p)
    numCols = size(samples, 2);
    values = NaN(1, numCols);
    for c = 1:numCols
        col = samples(:, c);
        col = col(~isnan(col));
        if ~isempty(col)
            values(c) = prctile(col, p);
        end
    end
end

function values = mean_omit_nan(samples)
    numCols = size(samples, 2);
    values = NaN(1, numCols);
    for c = 1:numCols
        col = samples(:, c);
        col = col(~isnan(col));
        if ~isempty(col)
            values(c) = mean(col);
        end
    end
end
