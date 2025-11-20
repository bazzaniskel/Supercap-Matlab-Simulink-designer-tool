function jitter = resolve_temperature_jitter(options)
%RESOLVE_TEMPERATURE_JITTER Normalize jitter settings into absolute sigma.

    jitter = struct('mode', 'none', 'sigma', 0, 'delta99', 0, 'fraction', 0, 'smoothingHours', 0);
    if nargin == 0 || isempty(options) || ~isstruct(options)
        return;
    end
    if isfield(options, 'smoothingHours')
        jitter.smoothingHours = max(0, options.smoothingHours);
    end

    delta99 = [];
    if isfield(options, 'temperatureJitter_99pct_C') && ~isempty(options.temperatureJitter_99pct_C)
        delta99 = options.temperatureJitter_99pct_C;
    elseif isfield(options, 'temperatureJitter_pct') && ~isempty(options.temperatureJitter_pct)
        delta99 = options.temperatureJitter_pct;
    end

    if isempty(delta99) || delta99 <= 0
        return;
    end

    if delta99 <= 1
        % Backward compatibility with old fraction-based jitter.
        jitter.mode = 'fraction';
        jitter.fraction = delta99;
    else
        jitter.mode = 'absolute';
        jitter.delta99 = delta99;
        z99 = 2.5758293035489004; % two-sided 99th percentile
        jitter.sigma = delta99 / z99;
    end
end
