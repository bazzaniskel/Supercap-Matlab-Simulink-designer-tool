function efficiency_curve_analysis(caseConfig, results_folder)
%EFFICIENCY_CURVE_ANALYSIS Run SoH sweep and generate efficiency plots.

    effCfg = caseConfig.performance.efficiency;
    if ~effCfg.enabled
        return;
    end

    soh_values = effCfg.soh_min:effCfg.soh_step:effCfg.soh_max;
    num_points = numel(soh_values);

    eta_charge = zeros(1, num_points);
    eta_discharge = zeros(1, num_points);
    eta_round = zeros(1, num_points);

    for idx = 1:num_points
        soh = soh_values(idx);
        cfg = caseConfig;
        cfg.operating.SOH_percent = soh;
        cfg.performance = struct();
        cfg.analysis = disable_monte_carlo(caseConfig);
        cfg = config.finalize_case(cfg);

        simOutput = simulation.run_case(cfg);
        eff = compute_efficiency_from_results(simOutput.Results);

        eta_charge(idx) = eff.charge;
        eta_discharge(idx) = eff.discharge;
        eta_round(idx) = eff.round_trip;
    end

    save_efficiency_data(results_folder, soh_values, eta_charge, eta_discharge, eta_round);
    plot_efficiency_curve(results_folder, soh_values, eta_charge, eta_discharge, eta_round);
end

function analysis = disable_monte_carlo(caseConfig)
    if isfield(caseConfig, 'analysis')
        analysis = caseConfig.analysis;
    else
        analysis = config.default_analysis();
    end
    if isfield(analysis, 'ambientMonteCarlo')
        analysis.ambientMonteCarlo.enabled = false;
    end
end

function eff = compute_efficiency_from_results(Results)
    Cell_Power = Results.Sim_Electrical_Ouput.Cell_Power_W;
    Cell_Losses = Results.Sim_Electrical_Ouput.Cell_Ploss_W;

    t = Cell_Power.Time;
    P = Cell_Power.Data;
    loss = Cell_Losses.Data;

    % Discharge phase (power > 0)
    mask_discharge = P > 0;
    E_out = trapz(t(mask_discharge), P(mask_discharge));
    E_loss_dis = trapz(t(mask_discharge), loss(mask_discharge));
    if any(mask_discharge)
        eff_dis = safe_divide(E_out, E_out + E_loss_dis);
    else
        eff_dis = 1;
    end

    % Charge phase (power < 0)
    mask_charge = P < 0;
    if any(mask_charge)
        P_in = -P(mask_charge);
        E_in = trapz(t(mask_charge), P_in);
        E_loss_charge = trapz(t(mask_charge), loss(mask_charge));
        E_store = max(E_in - E_loss_charge, 0);
        eff_ch = safe_divide(E_store, E_in);
    else
        eff_ch = 1;
    end

    eff = struct('charge', eff_ch, 'discharge', eff_dis, 'round_trip', eff_ch * eff_dis);
end

function val = safe_divide(num, den)
    if den <= 0
        val = 0;
    else
        val = num / den;
        if ~isfinite(val)
            val = 0;
        end
    end
end

function save_efficiency_data(results_folder, soh_values, eta_charge, eta_discharge, eta_round)
    T = table(soh_values(:), eta_charge(:), eta_discharge(:), eta_round(:), ...
        'VariableNames', {'SOH_percent', 'Efficiency_Charge', 'Efficiency_Discharge', 'Efficiency_RoundTrip'});
    csv_path = fullfile(results_folder, 'efficiency_vs_soh.csv');
    writetable(T, csv_path);
end

function plot_efficiency_curve(results_folder, soh_values, ~, ~, eta_round)
    figure('Position', [200, 200, 1000, 500]);
    plot(soh_values, eta_round, '-^', 'LineWidth', 2);
    xlabel('SOH (%)');
    ylabel('Round-trip Efficiency (pu)');
    minEta = min(eta_round);
    maxEta = max(eta_round);
    span = maxEta - minEta;
    if span < 0.02
        padding = max(0.005, span * 0.1);
        ylim([max(0, minEta - padding), min(1, maxEta + padding)]);
    else
        ylim([max(0, minEta - 0.02), min(1, maxEta + 0.02)]);
    end
    grid on;
    title('Round-trip Efficiency vs SOH');
    saveas(gcf, fullfile(results_folder, 'efficiency_vs_soh.png'));
    close(gcf);
end
