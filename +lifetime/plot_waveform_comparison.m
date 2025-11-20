function plot_waveform_comparison(startResults, endResults, caseConfig, parallel_modules, results_folder, soh_init, soh_final)
%PLOT_WAVEFORM_COMPARISON Compare power, voltage, current at start/end of life.

    if isempty(startResults) || isempty(endResults)
        return;
    end

    startData = extract_waveforms(startResults, caseConfig, parallel_modules);
    endData = extract_waveforms(endResults, caseConfig, parallel_modules);

    fig = figure('Name', 'Start vs End Waveforms', 'Position', [150 150 1100 650]);
    titles = {'System Power (MW)', 'System Voltage (V)', 'System Current (A)'};
    labels = {sprintf('SOH_{init}=%.0f%%%%', soh_init), sprintf('SOH_{final}=%.0f%%%%', soh_final)};
    for idx = 1:3
        subplot(3,1,idx);
        plot(startData.time, startData.values{idx}, 'LineWidth', 1.3);
        hold on;
        plot(endData.time, endData.values{idx}, '--', 'LineWidth', 1.3);
        grid on;
        xlabel('Time (s)');
        ylabel(titles{idx});
        legend(labels, 'Location', 'best');
    end
    sgtitle('System Response: Beginning vs End of Life');
    saveas(fig, fullfile(results_folder, 'waveform_comparison.png'));
    close(fig);
end

function data = extract_waveforms(results, caseConfig, parallel_modules)
    outputs = results.Sim_Electrical_Ouput;
    series_modules = caseConfig.system.seriesModules;
    module_num_cell_series = caseConfig.system.moduleNumCellSeries;

    cell_voltage = outputs.Cell_Voltage_V;
    cell_current = outputs.Cell_Current_A;
    cell_power = outputs.Cell_Power_W;

    system_voltage = cell_voltage.Data * series_modules * module_num_cell_series;
    system_current = cell_current.Data * parallel_modules;
    system_power = cell_power.Data * series_modules * module_num_cell_series * parallel_modules / 1e6;

    data.time = cell_voltage.Time;
    data.values = {system_power, system_voltage, system_current};
end
