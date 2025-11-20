function environment = configure_solar_exposure(environment)
%CONFIGURE_SOLAR_EXPOSURE Prompt for optional solar exposure model.

    if ~runner.get_yes_no_input('Apply outdoor solar exposure model? (y/n): ')
        environment.solar = struct('enabled', false);
        return;
    end

    refs = solar.load_reference_data();
    refNames = fieldnames(refs);

    while true
        fprintf('\nAvailable solar exposure presets:\n');
        fprintf('  0. Cancel solar model\n');
        for idx = 1:numel(refNames)
            desc = refs.(refNames{idx}).description;
            fprintf('  %d. %s - %s\n', idx, refNames{idx}, desc);
        end
        fprintf('  %d. Custom parameters\n', numel(refNames)+1);

        choice = runner.get_valid_input(sprintf('Select preset (0-%d): ', numel(refNames)+1), ...
            @(x) x >= 0 && x <= numel(refNames)+1);

        if choice == 0
            environment.solar = struct('enabled', false);
            return;
        elseif choice <= numel(refNames)
            name = refNames{choice};
            solarCfg = build_solar_from_reference(name, refs.(name));
        else
            solarCfg = build_custom_solar();
        end

        runner.print_solar_stats(solarCfg);
        previewEnv = environment;
        previewEnv.solar = solarCfg;
        previewEnv = config.normalize_environment(previewEnv);
        runner.print_environment_stats(previewEnv, 'Ambient profile with solar model');

        if runner.get_yes_no_input('Use this solar configuration? (y/n): ')
            environment.solar = solarCfg;
            break;
        else
            fprintf('Solar configuration discarded. Select another option.\n');
        end
    end
end

function solarCfg = build_solar_from_reference(name, ref)
    solarCfg = struct();
    solarCfg.enabled = true;
    solarCfg.zone = name;
    solarCfg.description = ref.description;
    solarCfg.monthlyIrradiance_Wm2 = ref.monthlyIrradiance_Wm2;
    solarCfg.sunriseHours = ref.sunriseHours;
    solarCfg.sunsetHours = ref.sunsetHours;
    solarCfg.panelArea_m2 = ref.panelArea_m2;
    solarCfg.absorptivity = ref.absorptivity;
    solarCfg.heatCapacity_JpK = ref.heatCapacity_JpK;
    solarCfg.convection_WpK = ref.convection_WpK;
end

function solarCfg = build_custom_solar()
    fprintf('\n--- CUSTOM SOLAR PARAMETERS ---\n');
    peak = runner.get_valid_input('Peak midday irradiance [W/m^2]: ', @(x) x > 0);
    area = runner.get_valid_input('Exposed surface area [m^2]: ', @(x) x > 0);
    absorptivity = runner.get_valid_input('Absorptivity [0-1]: ', @(x) x >= 0 && x <= 1);
    heatCap = runner.get_valid_input('Cabinet thermal capacity [J/K]: ', @(x) x > 0);
    convection = runner.get_valid_input('Convection coefficient [W/K]: ', @(x) x > 0);
    sunrise = runner.get_valid_input('Typical sunrise hour [0-24]: ', @(x) x >= 0 && x <= 24);
    sunset = runner.get_valid_input(sprintf('Typical sunset hour [%.1f-24]: ', sunrise), @(x) x > sunrise && x <= 24);

    monthly = build_monthly_profile(peak);
    sunriseVec = repmat(sunrise, 1, 12);
    sunsetVec = repmat(sunset, 1, 12);

    solarCfg = struct();
    solarCfg.enabled = true;
    solarCfg.zone = 'Custom';
    solarCfg.description = 'User-defined solar exposure';
    solarCfg.monthlyIrradiance_Wm2 = monthly;
    solarCfg.sunriseHours = sunriseVec;
    solarCfg.sunsetHours = sunsetVec;
    solarCfg.panelArea_m2 = area;
    solarCfg.absorptivity = absorptivity;
    solarCfg.heatCapacity_JpK = heatCap;
    solarCfg.convection_WpK = convection;
end

function monthly = build_monthly_profile(peak)
    base = (0:11) / 11;
    shape = 0.55 + 0.45 * sin(pi * base);
    monthly = peak * shape;
end
