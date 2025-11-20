function timeline = time_march(caseConfig, periods, options)
%TIME_MARCH Integrate SOH over monthly steps using repeated simulations.

    monthsPerStep = max(1, options.timeStepMonths);
    targetYears = options.targetYears;
    maxYears = options.maxYears;

    initial_soh = max(0, min(100, caseConfig.operating.SOH_percent));
    consumed_fraction = max(0, 1 - initial_soh/100);
    soh_percent = initial_soh;
    elapsed_years = 0;

    numMonths = numel(periods);
    monthCursor = 1;
    maxSteps = ceil(maxYears * 12 / monthsPerStep) + 5;

    timeline = init_timeline_struct(initial_soh);

    for stepIdx = 1:maxSteps
        [monthIndices, monthDays, avgTemp] = next_step(monthCursor, monthsPerStep, periods);
        monthCursor = monthIndices(end) + 1;
        if monthCursor > numMonths
            monthCursor = 1;
        end

        stepCase = caseConfig;
        stepCase.operating.environmentTemp = avgTemp;
        stepCase.cooling.initialCellTemp = avgTemp;
        stepCase.operating.SOH_percent = max(soh_percent, 0);

        [valid, step_result, simResults] = design.run_test(stepCase, stepCase.system.parallelModules, ...
            stepCase.operating.startVoltage, struct('skipLifetime', true));
        if ~valid
            timeline.success = false;
            timeline.failure_reason = sprintf('Constraints violated: %s', step_result.failure_reason);
            timeline.stats = lifetime.update_stats(timeline.stats, step_result);
            return;
        end

        if isempty(timeline.firstResults)
            timeline.firstResults = simResults;
        end
        timeline.lastResults = simResults;
        timeline.stats = lifetime.update_stats(timeline.stats, step_result);

        stepInputs = lifetime.build_step_inputs(stepCase, simResults);
        stepStruct = struct('inputs', stepInputs, 'monthIndices', monthIndices, 'monthDays', monthDays, ...
            'activeMonths', numel(monthIndices));
        timeline.steps(end+1) = stepStruct; 

        monthsUsed = 0;
        for idx = 1:numel(monthIndices)
            monthsUsed = idx;
            period = periods(monthIndices(idx));
            [frac_per_day, info] = lifetime.compute_fraction_for_profile(stepInputs, period.profile);
            delta_fraction = frac_per_day * period.days;
            consumed_fraction = consumed_fraction + delta_fraction;
            elapsed_years = elapsed_years + period.days / 365.25;
            soh_percent = max(0, (1 - consumed_fraction) * 100);

            timeline.time_years(end+1) = elapsed_years; 
            timeline.soh_percent(end+1) = soh_percent; 
            timeline.month_labels{end+1} = period.profile.label; 
            timeline.acceleration(end+1) = frac_per_day; 
            timeline.mean_temps(end+1) = period.profile.meanTemp; 
            timeline.steady_temps(end+1) = info.steadyTemp;

            if consumed_fraction >= 1 || elapsed_years >= maxYears || (options.stopAtTarget && elapsed_years >= targetYears)
                break;
            end
        end
        timeline.steps(end).activeMonths = monthsUsed;

        if consumed_fraction >= 1 || elapsed_years >= maxYears || (options.stopAtTarget && elapsed_years >= targetYears)
            break;
        end
    end

    timeline.achieved_years = elapsed_years;
    timeline.final_soh = soh_percent;
    timeline.consumed_fraction = consumed_fraction;

    if elapsed_years >= targetYears && soh_percent > 0
        timeline.success = true;
        timeline.failure_reason = '';
    elseif consumed_fraction >= 1
        timeline.success = false;
        timeline.failure_reason = sprintf('SOH reached 0%% after %.2f years (target %.2f years)', elapsed_years, targetYears);
    else
        timeline.success = false;
        timeline.failure_reason = sprintf('Maximum simulated years %.2f reached before meeting target %.2f years', ...
            elapsed_years, targetYears);
    end
end

function [indices, days, avgTemp] = next_step(cursor, monthsPerStep, periods)
    numMonths = numel(periods);
    indices = zeros(1, monthsPerStep);
    days = zeros(1, monthsPerStep);
    temps = zeros(1, monthsPerStep);
    month = cursor;
    for k = 1:monthsPerStep
        if month > numMonths
            month = 1;
        end
        indices(k) = month;
        days(k) = periods(month).days;
        temps(k) = periods(month).profile.meanTemp;
        month = month + 1;
    end
    weights = days / sum(days);
    avgTemp = sum(weights .* temps);
end

function timeline = init_timeline_struct(initial_soh)
    timeline = struct();
    timeline.success = false;
    timeline.failure_reason = '';
    emptyStep = struct('inputs', [], 'monthIndices', [], 'monthDays', [], 'activeMonths', 0);
    timeline.steps = repmat(emptyStep, 0, 1);
    timeline.time_years = 0;
    timeline.soh_percent = initial_soh;
    timeline.steady_temps = NaN;
    timeline.month_labels = {};
    timeline.acceleration = [];
    timeline.mean_temps = [];
    timeline.stats = struct('min_voltage', inf, 'max_voltage', -inf, 'max_current', -inf, 'max_power', -inf);
    timeline.firstResults = [];
    timeline.lastResults = [];
end
