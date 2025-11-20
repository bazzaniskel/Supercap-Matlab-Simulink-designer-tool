function save_data(results_folder, caseConfig, simOutput)
%SAVE_DATA Persist workspace, summary tables, and configuration.

    Results = simOutput.Results;
    metrics = simOutput.metrics;
    fprintf('Saving results...\n');

    save(fullfile(results_folder, 'simulation_workspace.mat'), 'Results', 'caseConfig', 'metrics');

    summary_table = results.summary_table(caseConfig, metrics);
    try
        writetable(summary_table, fullfile(results_folder, 'simulation_summary.xlsx'));
        fprintf('✓ Excel summary saved\n');
    catch
        writetable(summary_table, fullfile(results_folder, 'simulation_summary.csv'));
        fprintf('✓ CSV summary saved (Excel not available)\n');
    end

    Cell_Current = Results.Sim_Electrical_Ouput.Cell_Current_A;
    Cell_Voltage = Results.Sim_Electrical_Ouput.Cell_Voltage_V;
    Cell_Power = Results.Sim_Electrical_Ouput.Cell_Power_W;
    System_Voltage = Cell_Voltage.Data * caseConfig.system.seriesModules * caseConfig.system.moduleNumCellSeries;
    System_Current = Cell_Current.Data * caseConfig.system.parallelModules;
    System_Power = Cell_Power.Data * caseConfig.system.parallelModules * caseConfig.system.seriesModules * caseConfig.system.moduleNumCellSeries;

    time_series_data = table(Cell_Current.Time, Cell_Current.Data, Cell_Voltage.Data, ...
        Cell_Power.Data, System_Voltage, System_Current, System_Power, ...
        'VariableNames', {'Time_s', 'Cell_Current_A', 'Cell_Voltage_V', 'Cell_Power_W', ...
        'System_Voltage_V', 'System_Current_A', 'System_Power_W'});

    try
        writetable(time_series_data, fullfile(results_folder, 'time_series_data.xlsx'));
        fprintf('✓ Time series data saved to Excel\n');
    catch
        writetable(time_series_data, fullfile(results_folder, 'time_series_data.csv'));
        fprintf('✓ Time series data saved to CSV\n');
    end

    if strcmp(caseConfig.operation.mode, 'design')
        results.save_design_summary(results_folder, caseConfig, metrics);
    end

    results.save_configuration_file(results_folder, caseConfig, metrics);
end
