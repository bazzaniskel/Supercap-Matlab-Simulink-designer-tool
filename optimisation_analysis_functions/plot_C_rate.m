function plot_C_rate(Results, module_dir)
    figure('Position', [100 100 800 400]);
    plot(Results.Sim_Electrical_Ouput.Cell_Current_A.Time, ...
         Results.Sim_Electrical_Ouput.Cell_Current_A.Data / 33, 'LineWidth', 1.5)
    grid on
    xlabel('Time [s]')
    ylabel('C Rate')
    title('Cell C Rate')
    set(gca, 'FontName', 'Arial', 'FontSize', 14)
    savefig(fullfile(module_dir, 'C_rate_results.fig'))
    close;
end