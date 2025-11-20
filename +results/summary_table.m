function summary_table = summary_table(caseConfig, metrics)
%SUMMARY_TABLE Build human-readable summary table from config and metrics.

    config_params = cell(0, 2);

    is_design = strcmp(caseConfig.operation.mode, 'design');
    config_params = [config_params; {
        '--- OPERATION MODE ---', '';
        'Operation Mode', results.conditional_string(is_design, 'Design Optimization', 'Simulation');
    }];

    if is_design
        config_params = [config_params; {
            'Max Parallel Modules Searched', num2str(caseConfig.constraints.maxParallelModules);
            'Current Limit Enabled', results.conditional_string(caseConfig.constraints.currentLimit.enabled, 'Yes', 'No');
        }];
        if caseConfig.constraints.currentLimit.enabled
            config_params = [config_params; {
                'Max System Current Limit (A)', sprintf('%.1f', caseConfig.constraints.currentLimit.maxSystemCurrent);
            }];
        end
    end

    cfg = caseConfig;
    config_params = [config_params; {
        '', '';
        '--- SYSTEM CONFIGURATION ---', '';
        'Cell Type', cfg.cell.name;
        'Series Modules', num2str(cfg.system.seriesModules);
        'Parallel Modules', num2str(cfg.system.parallelModules);
        'Total Modules', num2str(cfg.system.seriesModules * cfg.system.parallelModules);
        'State of Health (%)', num2str(cfg.operating.SOH_percent);
        'Environmental Temp (°C)', format_environment_label(cfg.operating);
        'Starting Voltage (V)', num2str(cfg.operating.startVoltage);
        'Initial SOC (%)', sprintf('%.2f', cfg.sim.initialSOC);
        'Duty Cycle', num2str(cfg.operating.dutyCycle);
        'Operating Hours/Day', num2str(cfg.operating.hoursPerDay);
        '', '';
        '--- ELECTRICAL RESULTS ---', '';
        'Cell Max Current (A)', sprintf('%.3f', metrics.cell_max_current);
        'Cell RMS Current (A)', sprintf('%.3f', metrics.cell_rms_current);
        'System Max Current (A)', sprintf('%.1f', metrics.system_max_current);
        'System RMS Current (A)', sprintf('%.1f', metrics.system_rms_current);
        '', '';
        'Cell Min Voltage (V)', sprintf('%.4f', metrics.cell_min_voltage);
        'Cell Max Voltage (V)', sprintf('%.4f', metrics.cell_max_voltage);
        'System Min Voltage (V)', sprintf('%.1f', metrics.system_min_voltage);
        'System Max Voltage (V)', sprintf('%.1f', metrics.system_max_voltage);
        'System Voltage Range (V)', sprintf('%.1f', metrics.voltage_range_system);
        '', '';
        'Cell Max Power (W)', sprintf('%.2f', metrics.cell_max_power);
        'System Max Power (W)', sprintf('%.0f', metrics.system_max_power);
        'System Max Power (MW)', sprintf('%.3f', metrics.system_max_power/1e6);
        'System Pulse Efficiency (%)', sprintf('%.2f', metrics.pulse_efficiency*100);
        '', '';
        '--- CONSTRAINT CHECK ---', '';
        'Voltage Min Constraint', sprintf('%.1f V >= %.1f V: %s', metrics.system_min_voltage, cfg.operating.systemVoltage.min, ...
            results.conditional_string(metrics.system_min_voltage >= cfg.operating.systemVoltage.min, 'SATISFIED', 'VIOLATED'));
        'Voltage Max Constraint', sprintf('%.1f V <= %.1f V: %s', metrics.system_max_voltage, cfg.operating.systemVoltage.max, ...
            results.conditional_string(metrics.system_max_voltage <= cfg.operating.systemVoltage.max, 'SATISFIED', 'VIOLATED'));
        '', '';
        'Lifetime (years)', sprintf('%.1f', metrics.lifetime_years);
    }];

    if isfield(metrics, 'lifetime_monteCarlo') && isstruct(metrics.lifetime_monteCarlo) ...
            && isfield(metrics.lifetime_monteCarlo, 'enabled') && metrics.lifetime_monteCarlo.enabled
        mc = metrics.lifetime_monteCarlo;
        config_params = [config_params; {
            'Monte Carlo Enabled', results.conditional_string(mc.enabled, 'Yes', 'No');
            'Run During Design', results.conditional_string(isfield(mc, 'runDuringDesign') && mc.runDuringDesign, 'Yes', 'No');
            'Monte Carlo Trials', sprintf('%d', mc.numTrials);
            'MC Mean Lifetime (years)', sprintf('%.1f', mc.mean_years);
            'MC Min Lifetime (years)', sprintf('%.1f', mc.min_years);
            'MC 5th Percentile (years)', sprintf('%.1f', mc.p05_years);
            'MC 95th Percentile (years)', sprintf('%.1f', mc.p95_years);
        }];
    end

    if is_design && caseConfig.constraints.currentLimit.enabled
        config_params = [config_params; {
            'Current Constraint', sprintf('%.1f A <= %.1f A: %s', metrics.system_max_current, ...
                caseConfig.constraints.currentLimit.maxSystemCurrent, ...
                results.conditional_string(metrics.system_max_current <= caseConfig.constraints.currentLimit.maxSystemCurrent, 'SATISFIED', 'VIOLATED'));
        }];
    end

    config_params = [config_params; {
        '', '';
        '--- LOSS ANALYSIS ---', '';
        'Cell Average Losses (W)', sprintf('%.4f', metrics.cell_average_losses);
        'Cell Max Losses (W)', sprintf('%.4f', metrics.cell_max_losses);
        'System Average Losses (W)', sprintf('%.1f', metrics.system_average_losses);
        'System Max Losses (W)', sprintf('%.1f', metrics.system_max_losses);
        'System Average Losses (kW)', sprintf('%.3f', metrics.system_average_losses/1e3);
        'System Max Losses (kW)', sprintf('%.3f', metrics.system_max_losses/1e3);
        '', '';
        '--- THERMAL ANALYSIS ---', '';
        'Estimated Temp Rise (°C)', sprintf('%.2f', metrics.estimated_temp_rise);
        'Estimated Steady Temp (°C)', sprintf('%.2f', metrics.estimated_steady_temp);
    }];

    if isfield(metrics, 'cell_energy') && ~isempty(metrics.cell_energy)
        config_params = [config_params; {
            '', '';
            '--- ENERGY ANALYSIS ---', '';
            'Cell Energy (Wh)', sprintf('%.4f', metrics.cell_energy);
            'System Energy (Wh)', sprintf('%.1f', metrics.system_energy);
            'System Energy (kWh)', sprintf('%.4f', metrics.system_energy/1e3);
        }];
    end

    if is_design
        voltage_min_margin = metrics.system_min_voltage - cfg.operating.systemVoltage.min;
        voltage_max_margin = cfg.operating.systemVoltage.max - metrics.system_max_voltage;
        margin_params = {
            '', '';
            '--- DESIGN MARGINS ---', '';
            'Voltage Min Margin (V)', sprintf('%.1f', voltage_min_margin);
            'Voltage Max Margin (V)', sprintf('%.1f', voltage_max_margin);
        };
        if caseConfig.constraints.currentLimit.enabled
            current_margin = caseConfig.constraints.currentLimit.maxSystemCurrent - metrics.system_max_current;
            margin_params = [margin_params; {
                'Current Margin (A)', sprintf('%.1f', current_margin);
            }];
        end
        config_params = [config_params; margin_params];
    end

    valid_rows = ~cellfun(@isempty, config_params(:,1));
    summary_table = cell2table(config_params(valid_rows, :), 'VariableNames', {'Parameter', 'Value'});
end

function label = format_environment_label(operating)
    temp = operating.environmentTemp;
    if isfield(operating, 'environment') && isfield(operating.environment, 'profileName') ...
            && ~isempty(operating.environment.profileName)
        label = sprintf('%.1f (%s)', temp, operating.environment.profileName);
    else
        label = sprintf('%.1f', temp);
    end
end
