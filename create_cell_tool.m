function create_cell_tool()
%CREATE_CELL_TOOL Interactive helper to add a new cell as JSON.
%   Prompts for all required fields and saves the definition into /cells.

    fprintf('\n===============================================================\n');
    fprintf('                  CREATE/UPDATE CELL DEFINITION                \n');
    fprintf('===============================================================\n');

    cellDir = runner.get_cell_directory();
    fprintf('Cell definitions directory: %s\n', cellDir);

    name = ask_text('Cell display name', 'CustomCell');
    cell_type = ask_text('Cell_Type identifier', name);
    module_name = ask_text('Module name', 'Custom Module');

    module_series = ask_numeric('Module_NumCellSeries', 1, @(x) x > 0 && x == round(x));
    cell_volt_rated = ask_numeric('Cell_VoltRated_V', 3, @(x) x > 0);
    module_rated_voltage = ask_numeric('Module_RatedVoltage_V', cell_volt_rated * module_series, @(x) x > 0);

    cap_f = ask_numeric('Cell_CapRated_F', 1000, @(x) x > 0);
    esr_10ms = ask_numeric('Cell_ResESR10ms_Ohm', 0.2e-3, @(x) x > 0);
    esr_1s = ask_numeric('Cell_ResESR1s_Ohm', 0.25e-3, @(x) x > 0);

    heat_capa = ask_numeric('Cell_HeatCapa_JpK', 35000/54, @(x) x > 0);
    max_temp = ask_numeric('Cell_MaxRatedTemp_degC', 65, @(x) x > -100 && x < 200);
    rated_life = ask_numeric('Cell_RatedLifetime_h', 1500, @(x) x >= 0);
    lower_soc = ask_numeric('Cell_LowerSOCLimit_pc', 0, @(x) x >= 0);

    rth_nat = ask_numeric('Cell_RthToCooling_KpW_naturalCooling', 1.35*max(module_series,1), @(x) x >= 0);
    rth_forced = ask_numeric('Cell_RthToCooling_KpW_forcedAirCooling', 0.17*max(module_series,1), @(x) x >= 0);
    rth_liquid = ask_numeric('Cell_RthToCooling_KpW_liquidCooling', rth_forced/10, @(x) x >= 0);
    rth_env_nat = ask_numeric('Cell_RthToEnvironment_KpW_naturalCooling', rth_nat, @(x) x >= 0);
    rth_env_forced = ask_numeric('Cell_RthToEnvironment_KpW_forcedAirCooling', rth_forced, @(x) x >= 0);
    rth_env_liquid = ask_numeric('Cell_RthToEnvironment_KpW_liquidCooling', rth_liquid, @(x) x >= 0);

    spec = struct();
    spec.name = name;
    spec.Cell_Type = cell_type;
    spec.Cell_ResESR10ms_Ohm = esr_10ms;
    spec.Cell_ResESR1s_Ohm = esr_1s;
    spec.Cell_CapRated_F = cap_f;
    spec.Cell_VoltRated_V = cell_volt_rated;
    spec.Module_NumCellSeries = module_series;
    spec.Module_RatedVoltage_V = module_rated_voltage;
    spec.Module_Name = module_name;
    spec.Cell_HeatCapa_JpK = heat_capa;
    spec.Cell_MaxRatedTemp_degC = max_temp;
    spec.Cell_RatedLifetime_h = rated_life;
    spec.Cell_LowerSOCLimit_pc = lower_soc;
    spec.Cell_RthToCooling_KpW_naturalCooling = rth_nat;
    spec.Cell_RthToCooling_KpW_forcedAirCooling = rth_forced;
    spec.Cell_RthToCooling_KpW_liquidCooling = rth_liquid;
    spec.Cell_RthToEnvironment_KpW_naturalCooling = rth_env_nat;
    spec.Cell_RthToEnvironment_KpW_forcedAirCooling = rth_env_forced;
    spec.Cell_RthToEnvironment_KpW_liquidCooling = rth_env_liquid;

    file_name = sprintf('%s.json', matlab.lang.makeValidName(name));
    file_path = fullfile(cellDir, file_name);
    if exist(file_path, 'file')
        overwrite = runner.get_yes_no_input(sprintf('File %s exists. Overwrite? (y/n): ', file_path));
        if ~overwrite
            fprintf('Cancelled. No file written.\n');
            return;
        end
    end

    try
        jsonStr = jsonencode(spec, 'PrettyPrint', true);
    catch
        jsonStr = jsonencode(spec);
    end

    fid = fopen(file_path, 'w');
    if fid == -1
        error('Could not write %s', file_path);
    end
    fprintf(fid, '%s\n', jsonStr);
    fclose(fid);
    fprintf('✓ Saved cell definition to %s\n', file_path);
end

function val = ask_numeric(prompt, defaultVal, validator)
    if nargin < 3 || isempty(validator)
        validator = @(x) isfinite(x);
    end
    while true
        txt = input(sprintf('%s [default %.6g]: ', prompt, defaultVal), 's');
        if isempty(txt)
            val = defaultVal;
            return;
        end
        num = str2double(txt);
        if ~isnan(num) && validator(num)
            val = num;
            return;
        end
        fprintf('  Invalid entry. Please retry.\n');
    end
end

function txt = ask_text(prompt, defaultVal)
    if nargin < 2
        defaultVal = '';
    end
    raw = input(sprintf('%s [%s]: ', prompt, defaultVal), 's');
    if isempty(strtrim(raw))
        txt = defaultVal;
    else
        txt = strtrim(raw);
    end
end
