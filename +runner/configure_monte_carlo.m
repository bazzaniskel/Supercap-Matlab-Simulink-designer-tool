function monteCarlo = configure_monte_carlo(environment)
%CONFIGURE_MONTE_CARLO Gather Monte Carlo settings for ambient temperatures.

    if nargin < 1
        environment = struct();
    end

    defaults = config.default_analysis().ambientMonteCarlo;

    fprintf('\n--- AMBIENT TEMPERATURE MONTE CARLO ANALYSIS ---\n');
    fprintf('This optional analysis perturbs the hourly ambient curves to assess\n');
    fprintf('lifetime variability. It can significantly increase simulation time.\n');

    if ~runner.get_yes_no_input('Enable Monte Carlo ambient analysis? (y/n): ')
        monteCarlo = defaults;
        monteCarlo.enabled = false;
        return;
    end

    monteCarlo = defaults;
    monteCarlo.enabled = true;
    monteCarlo.numTrials = runner.get_valid_input(sprintf('Number of trials [%d]: ', defaults.numTrials), ...
        @(x) x > 0 && x == round(x));
    monteCarlo.daysPerMonth = runner.get_valid_input(sprintf('Sampled days per month [%d]: ', defaults.daysPerMonth), ...
        @(x) x > 0 && x == round(x));

    default_delta = defaults.temperatureJitter_99pct_C;
    jitter_prompt = sprintf('Temperature deviation at 99th percentile (°C) [%.1f]: ', default_delta);
    delta99 = runner.get_valid_input(jitter_prompt, @(x) x >= 0 && x <= 60);
    monteCarlo.temperatureJitter_99pct_C = delta99;
    monteCarlo.temperatureJitter_pct = delta99; % backward compatibility

    smoothing_prompt = sprintf('Smoothing window (hours) [%.1f]: ', defaults.smoothingHours);
    monteCarlo.smoothingHours = runner.get_valid_input(smoothing_prompt, @(x) x >= 0);

    design_prompt = sprintf('Run Monte Carlo during design/binary search? [%s]: ', runner.yesno_string(defaults.enableInDesign));
    monteCarlo.enableInDesign = runner.get_yes_no_input(design_prompt);

    seed_input = input('Random seed (press Enter for random): ', 's');
    if isempty(strtrim(seed_input))
        monteCarlo.randomSeed = [];
    else
        seed_val = str2double(seed_input);
        if isnan(seed_val)
            fprintf('Invalid seed. Using auto-generated RNG seed.\n');
            monteCarlo.randomSeed = [];
        else
            monteCarlo.randomSeed = seed_val;
        end
    end

    display_jitter_ranges(environment, delta99);
end

function display_jitter_ranges(environment, delta99)
    env = environment;
    if ~isfield(env, 'dailyProfiles') || isempty(env.dailyProfiles)
        env = config.normalize_environment(env);
    end
    if ~isfield(env, 'dailyProfiles') || isempty(env.dailyProfiles)
        return;
    end
    fprintf('\nAmbient temperature ranges with 99%% deviation ±%.1f°C:\n', delta99);
    fprintf(' Month  BaseMin  BaseMean  BaseMax  99%%Min  99%%Max\n');
    for idx = 1:numel(env.dailyProfiles)
        prof = env.dailyProfiles{idx};
        baseMin = min(prof.temps);
        baseMax = max(prof.temps);
        baseMean = env.monthlyTemps(idx);
        mcMin = baseMin - delta99;
        mcMax = baseMax + delta99;
        fprintf('  %3s  %7.1f  %8.1f  %8.1f  %7.1f  %7.1f\n', prof.label, baseMin, baseMean, baseMax, mcMin, mcMax);
    end
    fprintf('\n');
end
