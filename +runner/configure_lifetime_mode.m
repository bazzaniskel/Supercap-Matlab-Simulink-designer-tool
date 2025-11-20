function lifetimeCfg = configure_lifetime_mode(caseConfig)
%CONFIGURE_LIFETIME_MODE Gather settings specific to lifetime time-marching mode.

    fprintf('\n--- LIFETIME SIMULATION SETTINGS ---\n');
    lifetimeCfg = struct();

    if ~isfield(caseConfig.constraints, 'lifetime') || ~caseConfig.constraints.lifetime.enabled
        error('Lifetime mode requires a lifetime constraint. Please ensure it is enabled.');
    end

    target_years = caseConfig.constraints.lifetime.minYears;
    lifetimeCfg.targetYears = target_years;

    lifetimeCfg.timeStepMonths = runner.get_valid_input( ...
        'Aging simulation timestep [months]: ', @(x) x > 0 && x == round(x));

    lifetimeCfg.maxYears = runner.get_valid_input( ...
        sprintf('Maximum simulated years (>= %.1f): ', target_years), @(x) x >= target_years);

    fprintf('\nLifetime results will stop once either the target is met or SOH reaches 0.\n');
    lifetimeCfg.stopAtTarget = true;

    fprintf('\n--- LIFETIME MONTE CARLO OPTIONS ---\n');
    if runner.get_yes_no_input('Run Monte Carlo on lifetime timeline? (y/n): ')
        lifetimeCfg.monteCarlo.enabled = true;
        lifetimeCfg.monteCarlo.numTrials = runner.get_valid_input('Number of lifetime Monte Carlo trials: ', ...
            @(x) x > 0 && x == round(x));
        lifetimeCfg.monteCarlo.passPercentile = runner.get_valid_input('Required passing percentile [50-99.9]: ', ...
            @(x) x >= 50 && x < 100);
        lifetimeCfg.monteCarlo.seed = input('Random seed for lifetime Monte Carlo (Enter for random): ', 's');
        if isempty(strtrim(lifetimeCfg.monteCarlo.seed))
            lifetimeCfg.monteCarlo.seed = [];
        else
            val = str2double(lifetimeCfg.monteCarlo.seed);
            if isnan(val)
                fprintf('Invalid seed. Using random seed.\n');
                lifetimeCfg.monteCarlo.seed = [];
            else
                lifetimeCfg.monteCarlo.seed = val;
            end
        end
        lifetimeCfg.monteCarlo.requirementYears = target_years;
    else
        lifetimeCfg.monteCarlo = struct('enabled', false);
    end
end
