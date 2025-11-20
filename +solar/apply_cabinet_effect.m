function environment = apply_cabinet_effect(environment)
%APPLY_CABINET_EFFECT Modify daily profiles to include solar heating.

    if ~isfield(environment, 'solar') || isempty(environment.solar)
        return;
    end
    solarCfg = environment.solar;
    if ~isfield(solarCfg, 'enabled') || ~solarCfg.enabled
        return;
    end

    if ~isfield(environment, 'dailyProfiles') || isempty(environment.dailyProfiles)
        return;
    end

    monthlyIrr = ensure_length(solarCfg, 'monthlyIrradiance_Wm2', 12, 400);
    sunrise = ensure_length(solarCfg, 'sunriseHours', 12, 6);
    sunset = ensure_length(solarCfg, 'sunsetHours', 12, 18);

    absorptivity = getfield_with_default(solarCfg, 'absorptivity', 0.7);
    area = getfield_with_default(solarCfg, 'panelArea_m2', 3.0);
    heatCapacity = getfield_with_default(solarCfg, 'heatCapacity_JpK', 45000);
    convection = getfield_with_default(solarCfg, 'convection_WpK', 15);

    for idx = 1:numel(environment.dailyProfiles)
        profile = environment.dailyProfiles{idx};
        hours = profile.hours(:)';
        temps = profile.temps(:)';
        if numel(hours) < 2
            hours = [0 24];
            temps = [temps temps];
        end

        flux = compute_solar_flux(hours, monthlyIrr(min(idx, numel(monthlyIrr))), ...
            sunrise(min(idx, numel(sunrise))), sunset(min(idx, numel(sunset))));
        flux = flux * absorptivity * area; % Convert to watts incident on cabinet

        Tcab = solar.solve_cabinet_temperature(hours, temps, flux, heatCapacity, convection);
        profile.temps = Tcab;
        profile.meanTemp = trapz(hours, Tcab) / (hours(end) - hours(1));
        environment.dailyProfiles{idx} = profile;
    end

    environment.monthlyTemps = cellfun(@(p) p.meanTemp, environment.dailyProfiles);
    environment.temperature_C = mean(environment.monthlyTemps);
end

function values = ensure_length(cfg, fieldName, n, default)
    if isfield(cfg, fieldName) && ~isempty(cfg.(fieldName))
        values = cfg.(fieldName)(:)' ;
    else
        values = default * ones(1, n);
    end
    if numel(values) < n
        values = [values repmat(values(end), 1, n - numel(values))];
    elseif numel(values) > n
        values = values(1:n);
    end
end

function value = getfield_with_default(s, field, default)
    if isfield(s, field) && ~isempty(s.(field))
        value = s.(field);
    else
        value = default;
    end
end

function flux = compute_solar_flux(hours, peakIrradiance, sunrise, sunset)
    flux = zeros(size(hours));
    if sunset <= sunrise
        return;
    end
    daylight = sunset - sunrise;
    mask = hours >= sunrise & hours <= sunset;
    phase = (hours(mask) - sunrise) / daylight;
    shape = sin(pi * phase);
    shape(shape < 0) = 0;
    flux(mask) = peakIrradiance * shape;
    % Use mid-interval flux for segments
    flux = flux(1:end-1);
end
