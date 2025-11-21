function [Results, elapsed_time] = run_case_ode(caseConfig)
%RUN_CASE_ODE Solve the simplified RC + CPL model directly in MATLAB.

    start_time = tic;
    params = derive_parameters(caseConfig);

    [time_grid, load_profile] = build_cell_profile(caseConfig, params);
    n_pts = numel(time_grid);

    V_main = zeros(n_pts, 1);
    V_fast = zeros(n_pts, 1); % terminal-side capacitor voltage (fast branch)
    Vbus = zeros(n_pts, 1);
    Iload = zeros(n_pts, 1);
    Pcell = zeros(n_pts, 1);
    Ploss = zeros(n_pts, 1);
    Tcell = zeros(n_pts, 1);

    V_main(1) = params.v_main_start;
    V_fast(1) = params.v_main_start; % start aligned with main cap
    Tcell(1) = params.t_start;

    for k = 1:n_pts
        i_r_delta = (V_main(k) - V_fast(k)) / params.R_delta;
        Vt = V_fast(k); % node before ESR
        if strcmp(load_profile.type, 'power')
            P_req = load_profile.values(k);
            [Iload(k), Vbus(k)] = solve_constant_power(P_req, Vt, params.R_esr_fast, params.vmin);
            Pcell(k) = Vbus(k) * Iload(k);
        else
            Iload(k) = load_profile.values(k);
            Vbus(k) = Vt - params.R_esr_fast * Iload(k);
            Pcell(k) = Vbus(k) * Iload(k);
        end

        if Vbus(k) < 0
            Vbus(k) = 0;
            Pcell(k) = 0;
        end

        Ploss(k) = (Iload(k).^2) * params.R_esr_fast + params.R_delta * (i_r_delta.^2);

        if k < n_pts
            dt = time_grid(k+1) - time_grid(k);
            I_main = i_r_delta;              % current leaving main node to fast node
            dV_main = -I_main / params.C_main;
            dV_fast = (i_r_delta - Iload(k)) / params.C_fast; % KCL at fast node: C_fast dV/dt = i_delta - Iload
            V_main(k+1) = max(V_main(k) + dt * dV_main, 0);
            V_fast(k+1) = max(V_fast(k) + dt * dV_fast, 0);

            cooling = 0;
            if params.Rth > 0 && isfinite(params.Rth)
                cooling = (Tcell(k) - params.T_amb) / params.Rth;
            end
            Tcell(k+1) = Tcell(k) + (dt / params.Cth) * (Ploss(k) - cooling);
        end
    end

    elapsed_time = toc(start_time);
    Results = pack_results(time_grid, Vbus, V_main, Iload, Pcell, Ploss, Tcell);
end

function params = derive_parameters(caseConfig)
    specs = caseConfig.cell.specs;
    soh = max(0, min(1, caseConfig.operating.SOH_percent / 100));

    [coeffC, coeffR] = lookup_soh_coeffs(soh);
    params.R_esr_fast = max(specs.Cell_ResESR10ms_Ohm * coeffR, eps);
    R_esr1s = specs.Cell_ResESR1s_Ohm * coeffR;
    params.R_delta = max(R_esr1s - params.R_esr_fast, eps);
    tau_const = 0.03;
    params.C_fast = tau_const / params.R_delta;
    params.C_main = specs.Cell_CapRated_F * coeffC;

    params.Rth = max(caseConfig.cooling.rthCooling, 0);
    params.Cth = max(specs.Cell_HeatCapa_JpK, eps);
    params.T_amb = caseConfig.operating.environmentTemp;
    params.t_start = caseConfig.cooling.initialCellTemp;

    series_modules = ensure_positive(caseConfig.system.seriesModules, 1);
    cells_per_module = ensure_positive(caseConfig.system.moduleNumCellSeries, 1);
    start_v = caseConfig.operating.startVoltage / (series_modules * cells_per_module);
    params.v_main_start = min(start_v, specs.Cell_VoltRated_V);

    params.vmin = max(1e-3, 0.05 * specs.Cell_VoltRated_V);
end

function [time_grid, load_profile] = build_cell_profile(caseConfig, params)
    t_end = caseConfig.sim.timeEnd;
    dt = caseConfig.sim.timeStep;
    n_steps = max(1, ceil(t_end / max(dt, eps)));
    time_grid = (0:n_steps)' * dt;
    time_grid(end) = t_end;

    profile_time = caseConfig.profile.time(:);
    if isempty(profile_time)
        profile_time = [0; t_end];
    end
    profile_values = caseConfig.profile.systemInput(:);
    if isempty(profile_values)
        profile_values = zeros(size(profile_time));
    end
    if numel(profile_values) ~= numel(profile_time)
        error('Profile time vector length does not match the input waveform.');
    end

    parallel = ensure_positive(caseConfig.system.parallelModules, 1);
    series = ensure_positive(caseConfig.system.seriesModules, 1);
    cells_per_module = ensure_positive(caseConfig.system.moduleNumCellSeries, 1);

    switch caseConfig.profile.switchCurrentOrPower
        case 1
            cell_signal = profile_values / parallel;
            load_profile.type = 'current';
        otherwise
            denom = parallel * series * cells_per_module;
            cell_signal = profile_values / denom;
            load_profile.type = 'power';
    end

    load_profile.values = interp1(profile_time, cell_signal, time_grid, 'linear', 'extrap');
end

function [I, Vbus] = solve_constant_power(P_req, Vc, R_cell, vmin)
    if abs(P_req) < 1e-9
        I = 0;
        Vbus = Vc;
        return;
    end

    if R_cell <= 1e-12
        Vbus = max(Vc, vmin);
        I = P_req / max(Vbus, vmin);
        return;
    end

    disc = Vc.^2 - 4 * R_cell * P_req;
    if disc >= 0
        I = (Vc - sqrt(disc)) / (2 * R_cell);
        Vbus = Vc - R_cell * I;
    else
        Vbus = max(min(Vc, vmin), 1e-6);
        I = min(P_req / max(Vbus, vmin), (Vc - Vbus) / R_cell);
    end

    if Vbus < vmin && P_req > 0
        Vbus = max(vmin, 1e-6);
        I = min(P_req / Vbus, (Vc - Vbus) / R_cell);
        I = max(I, 0);
    end
end

function Results = pack_results(time_grid, Vbus, Vc, Iload, Pcell, Ploss, Tcell)
    Results = struct();
    Results.tout = time_grid;

    SimOut = struct();
    SimOut.Cell_Voltage_V = build_ts(time_grid, Vbus);
    SimOut.Cell_OCV_V = build_ts(time_grid, Vc);
    SimOut.Cell_Current_A = build_ts(time_grid, Iload);
    SimOut.Cell_Power_W = build_ts(time_grid, Pcell);
    SimOut.Cell_Ploss_W = build_ts(time_grid, Ploss);
    SimOut.Cell_Temp_degC = build_ts(time_grid, Tcell);

    Results.Sim_Electrical_Ouput = SimOut;
end

function ts = build_ts(time, data)
    ts = struct('Time', time, 'Data', data);
end

function val = ensure_positive(value, defaultVal)
    if nargin < 2
        defaultVal = 1;
    end
    if isempty(value) || ~isfinite(value) || value <= 0
        val = defaultVal;
    else
        val = value;
    end
end

function [coeffC, coeffR] = lookup_soh_coeffs(soh_pu)
    ageing = max(0, min(1, 1 - soh_pu));
    [lutC, lutR] = load_soh_lookup();

    if ~isempty(lutC)
        coeffC = interp1(lutC.ageing, lutC.coeff, ageing, 'linear', 'extrap');
    else
        coeffC = 0.8 + 0.2 * soh_pu;
    end

    if ~isempty(lutR)
        coeffR = interp1(lutR.ageing, lutR.coeff, ageing, 'linear', 'extrap');
    else
        coeffR = 2 - soh_pu;
    end

    coeffC = max(coeffC, eps);
    coeffR = max(coeffR, eps);
end

function [lutC, lutR] = load_soh_lookup()
    persistent cache
    if ~isempty(cache)
        lutC = cache.C;
        lutR = cache.R;
        return;
    end

    lutC = [];
    lutR = [];
    mat_path = fullfile('supercap_cell', 'ESR.mat');
    if exist(mat_path, 'file')
        try
            data = load(mat_path, 'C', 'ESR');
            lutC = build_lut(data, 'C');
            lutR = build_lut(data, 'ESR');
        catch ME
            warning('Failed to load SOH lookup from %s: %s', mat_path, ME.message);
        end
    end
    cache = struct('C', lutC, 'R', lutR);
end

function lut = build_lut(dataStruct, fieldName)
    if ~isfield(dataStruct, fieldName)
        lut = [];
        return;
    end
    raw = dataStruct.(fieldName);
    if ~ismatrix(raw) || size(raw, 2) < 2
        lut = [];
        return;
    end
    age = raw(:, 1);
    coeff = raw(:, 2);
    [age, idx] = unique(age, 'stable');
    coeff = coeff(idx);
    lut = struct('ageing', age(:), 'coeff', coeff(:));
end
