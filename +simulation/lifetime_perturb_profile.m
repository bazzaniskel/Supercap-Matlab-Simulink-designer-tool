function profile = lifetime_perturb_profile(baseProfile, jitter)
%LIFETIME_PERTURB_PROFILE Apply smooth random jitter to an ambient profile.
%
%   Jitter struct fields:
%     - mode: 'absolute', 'fraction', or 'none'
%     - sigma: absolute sigma in °C (for absolute mode)
%     - fraction: fraction of daily swing (legacy)
%     - smoothingHours: optional smoothing window

    profile = baseProfile;
    if nargin < 2 || isempty(jitter) || ~isstruct(jitter) || strcmp(jitter.mode, 'none')
        return;
    end

    hours = baseProfile.hours(:)';
    temps = baseProfile.temps(:)';
    n = numel(hours);
    if n < 2
        return;
    end

    switch jitter.mode
        case 'absolute'
            sigma = jitter.sigma;
        case 'fraction'
            swing = max(temps) - min(temps);
            if swing < 1
                swing = 1;
            end
            sigma = jitter.fraction * swing;
        otherwise
            sigma = 0;
    end

    if sigma <= 0
        return;
    end

    noise = randn(1, n) * sigma;
    smoothingHours = 0;
    if isfield(jitter, 'smoothingHours')
        smoothingHours = jitter.smoothingHours;
    end
    if smoothingHours > 0 && n > 2
        avg_step = max(eps, (hours(end) - hours(1)) / (n - 1));
        window = max(1, round(smoothingHours / avg_step));
        if mod(window, 2) == 0
            window = window + 1;
        end
        noise = smoothdata(noise, 'gaussian', window);
    end

    perturbedTemps = temps + noise;
    perturbedTemps = min(max(perturbedTemps, -60), 120);

    profile.temps = perturbedTemps;
    profile.meanTemp = trapz(hours, perturbedTemps) / max(hours(end) - hours(1), eps);
end
