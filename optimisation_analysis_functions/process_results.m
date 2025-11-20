function process_results(Results, n_modules, module_dir)
    time = Results.Sim_Electrical_Ouput.Cell_Current_A.Time;
    dt = time(2) - time(1);
    window_points = round(60/dt);
    
    % Calculate metrics
    losses_mean = movmean(Results.Sim_Electrical_Ouput.Cell_Ploss_W.Data, window_points)*1/1200;
    current_rms = sqrt(movmean(Results.Sim_Electrical_Ouput.Cell_Current_A.Data.^2, window_points));
    
    valid_indices = current_rms > 1e-6;
    esr_rolling = nan(size(current_rms));
    esr_rolling(valid_indices) = 1000 * losses_mean(valid_indices) ./ (current_rms(valid_indices).^2);
    
    % Generate plots
    plot_voltage(Results, n_modules, module_dir);
    plot_current(Results, module_dir);
    plot_esr(time, esr_rolling, module_dir);
    plot_temperature(Results, module_dir);
    plot_C_rate(Results, module_dir);
end
