function print_solar_stats(solarCfg)
%PRINT_SOLAR_STATS Display irradiance and parameter summary for solar model.

    if nargin < 1 || isempty(solarCfg) || ~isfield(solarCfg, 'enabled') || ~solarCfg.enabled
        return;
    end

    irr = solarCfg.monthlyIrradiance_Wm2(:)';
    if isempty(irr)
        irrMin = NaN; irrMean = NaN; irrMax = NaN;
    else
        irrMin = min(irr);
        irrMean = mean(irr);
        irrMax = max(irr);
    end
    fprintf('\nSolar exposure preset: %s\n', solarCfg.description);
    fprintf('  Irradiance stats (W/m^2): min %.1f | mean %.1f | max %.1f\n', irrMin, irrMean, irrMax);
    fprintf('  Surface area: %.2f m^2 | Absorptivity: %.2f | Heat capacity: %.0f J/K | Convection: %.1f W/K\n', ...
        solarCfg.panelArea_m2, solarCfg.absorptivity, solarCfg.heatCapacity_JpK, solarCfg.convection_WpK);
    if isfield(solarCfg, 'sunriseHours') && isfield(solarCfg, 'sunsetHours')
        fprintf('  Sunrise hours range: %.1f-%.1f | Sunset hours range: %.1f-%.1f\n', ...
            min(solarCfg.sunriseHours), max(solarCfg.sunriseHours), ...
            min(solarCfg.sunsetHours), max(solarCfg.sunsetHours));
    end
end
