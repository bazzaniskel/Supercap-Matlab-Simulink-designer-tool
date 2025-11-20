function [min_voltage, max_voltage, steady_temp] = evaluate_point(soc, load_factor, n_modules, ...
    original_current, env_temp, rth_cooling, cell_specs, aging_condition)

    % Set up parameters structure
    params = struct();
    params.Cell_ResESR10ms_Ohm = cell_specs.Cell_ResESR10ms_Ohm;
    params.Cell_ResESR1s_Ohm = cell_specs.Cell_ResESR1s_Ohm;
    params.Cell_CapRated_F = cell_specs.Cell_CapRated_F;
    params.Cell_VoltRated_V = cell_specs.Cell_VoltRated_V;
    params.Cell_SoCInit_PU = soc;  
    params.Cell_SOH_PU = aging_condition.Cell_SOH_PU;

    % Set block parameters
    blockPath = 'Supercap_Thermo_Electrical_Cell_Simulation_Model/Supercap Cell Model/Supercapacitor system';
    setBlockParameters(blockPath, params);
    
    % Set SOC in model
    set_param('Supercap_Thermo_Electrical_Cell_Simulation_Model/Input signals/Sim_SocInit_pc', ...
        'Value', num2str(soc));

    % Scale current
    cell_current_A = original_current * load_factor;
    
    % Set current input
    block_path = 'Supercap_Thermo_Electrical_Cell_Simulation_Model/Input signals/Current or Power Input';
    set_param(block_path, 'rep_seq_t', mat2str(linspace(0,60,length(cell_current_A))))
    set_param(block_path, 'rep_seq_y', mat2str(cell_current_A));
    
    % Run simulation
    Results = sim('Supercap_Thermo_Electrical_Cell_Simulation_Model');
    
    % Calculate voltages using Module_NumCellSeries from cell_specs
    string_voltage = n_modules * cell_specs.Module_NumCellSeries * Results.Sim_Electrical_Ouput.Cell_Voltage_V.Data;
    min_voltage = min(string_voltage);
    max_voltage = max(string_voltage);
    
    % Calculate steady state temperature
    mean_losses = mean(Results.Sim_Electrical_Ouput.Cell_Ploss_W.Data)*1/20;
    steady_temp = env_temp + mean_losses * rth_cooling;

end
